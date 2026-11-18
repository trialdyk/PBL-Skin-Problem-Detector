"""Scan history routes (protected)."""

from __future__ import annotations

import uuid

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    File,
    Form,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session, sessionmaker

from app.dependencies import get_current_user, get_db
from app.models import User
from app.models.scan_history import ScanHistory
from app.schemas.auth import ErrorResponse
from app.schemas.history import (
    DeleteHistoryResponse,
    HistoryCreateResponse,
    HistoryDetail,
    HistoryListItem,
    HistoryListResponse,
    HistoryPhotoUrls,
    RecommendationOut,
)
from app.services import history_service, llm_service

router = APIRouter(
    prefix="/history",
    tags=["history"],
    dependencies=[Depends(get_current_user)],
)

UNAUTHORIZED_RESPONSE = {
    401: {
        "model": ErrorResponse,
        "description": "Missing, invalid, expired, or inactive-user bearer token.",
    },
}


def _recommendation_out(history: ScanHistory) -> RecommendationOut:
    rec = history.recommendation
    if rec is None:
        return RecommendationOut(status="pending", text=None, updated_at=None)
    return RecommendationOut(
        status=rec.status,
        text=rec.text,
        updated_at=rec.updated_at,
    )


def _photos(history: ScanHistory) -> HistoryPhotoUrls:
    return HistoryPhotoUrls(
        front=history_service.photo_api_path(history.id, "front"),
        left=history_service.photo_api_path(history.id, "left"),
        right=history_service.photo_api_path(history.id, "right"),
    )


def _list_item(history: ScanHistory) -> HistoryListItem:
    return HistoryListItem(
        id=history.id,
        created_at=history.created_at,
        model_id=history.model_id,
        grade=history.grade,
        grade_label=history.grade_label,
        top_label=history.top_label,
        result_source=history.result_source,
        recommendation=_recommendation_out(history),
        photos=_photos(history),
    )


def _detail(history: ScanHistory) -> HistoryDetail:
    base = _list_item(history)
    return HistoryDetail(
        **base.model_dump(),
        interview=history.interview_json,
        aggregate=history.aggregate_json,
    )


@router.post(
    "",
    summary="Save a completed scan to history (one-shot)",
    status_code=status.HTTP_201_CREATED,
    responses={
        400: {"model": ErrorResponse, "description": "Invalid fields or photos."},
        **UNAUTHORIZED_RESPONSE,
        413: {"model": ErrorResponse, "description": "A photo exceeds HISTORY_MAX_UPLOAD_MB."},
    },
)
async def create_history(
    background_tasks: BackgroundTasks,
    front: UploadFile = File(..., description="Front selfie"),
    left: UploadFile = File(..., description="Left selfie"),
    right: UploadFile = File(..., description="Right selfie"),
    grade: int = Form(..., ge=0, le=5),
    grade_label: str = Form(...),
    model_id: str = Form(...),
    result_source: str = Form(..., description="ml or rule_based"),
    interview: str = Form(..., description="Interview answers as JSON object string"),
    top_label: str | None = Form(default=None),
    aggregate: str | None = Form(default=None, description="Optional aggregate JSON string"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HistoryCreateResponse:
    """Persist three photos on disk, create pending recommendation, and queue LLM generation."""
    photos = {
        "front": (await front.read(), front.filename, front.content_type),
        "left": (await left.read(), left.filename, left.content_type),
        "right": (await right.read(), right.filename, right.content_type),
    }
    try:
        history = history_service.create_history(
            db,
            user=current_user,
            grade=grade,
            grade_label=grade_label,
            model_id=model_id,
            result_source=result_source,
            top_label=top_label,
            interview_raw=interview,
            aggregate_raw=aggregate,
            photos=photos,
        )
    except history_service.HistoryValidationError as exc:
        message = str(exc)
        code = (
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
            if "maksimal" in message.lower()
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=code, detail=message) from None
    except history_service.HistoryStorageError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(exc),
        ) from None
    except Exception as exc:
        # Surface DB/migrate mistakes instead of a bare nginx "Internal Server Error".
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menyimpan riwayat: {exc}",
        ) from None

    if llm_service.is_configured():
        session_factory = sessionmaker(bind=db.get_bind(), autocommit=False, autoflush=False)
        background_tasks.add_task(
            history_service.generate_and_save_recommendation,
            history_id=history.id,
            session_factory=session_factory,
        )

    return HistoryCreateResponse(**_detail(history).model_dump())


@router.get(
    "",
    summary="List the caller's scan history",
    responses=UNAUTHORIZED_RESPONSE,
)
def list_history(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HistoryListResponse:
    items, total = history_service.list_histories(
        db,
        user=current_user,
        limit=limit,
        offset=offset,
    )
    return HistoryListResponse(
        items=[_list_item(row) for row in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get(
    "/{history_id}",
    summary="Get one history detail",
    responses={
        **UNAUTHORIZED_RESPONSE,
        404: {"model": ErrorResponse, "description": "History not found."},
    },
)
def get_history(
    history_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HistoryDetail:
    try:
        history = history_service.get_history(db, user=current_user, history_id=history_id)
    except history_service.HistoryNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Riwayat tidak ditemukan.",
        ) from None
    return _detail(history)


@router.get(
    "/{history_id}/photos/{angle}",
    summary="Download one history photo",
    responses={
        **UNAUTHORIZED_RESPONSE,
        404: {"model": ErrorResponse, "description": "Photo or history not found."},
    },
)
def get_history_photo(
    history_id: uuid.UUID,
    angle: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    try:
        history = history_service.get_history(db, user=current_user, history_id=history_id)
        path = history_service.absolute_photo_path(history, angle)
    except history_service.HistoryNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Foto tidak ditemukan.",
        ) from None
    except history_service.HistoryValidationError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from None

    media = {
        ".png": "image/png",
        ".webp": "image/webp",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
    }.get(path.suffix.lower(), "application/octet-stream")
    return FileResponse(path, media_type=media, filename=path.name)


@router.post(
    "/{history_id}/recommendation/retry",
    summary="Retry LLM recommendation generation for a history entry",
    responses={
        **UNAUTHORIZED_RESPONSE,
        404: {"model": ErrorResponse, "description": "History not found."},
        503: {"model": ErrorResponse, "description": "LLM recommendation service is not configured."},
    },
)
def retry_recommendation(
    history_id: uuid.UUID,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HistoryDetail:
    """Re-queue LLM recommendation generation when status is pending or failed."""
    try:
        history, should_generate = history_service.prepare_recommendation_retry(
            db,
            user=current_user,
            history_id=history_id,
        )
    except history_service.HistoryNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Riwayat tidak ditemukan.",
        ) from None
    except llm_service.LlmNotConfiguredError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None

    if should_generate:
        session_factory = sessionmaker(bind=db.get_bind(), autocommit=False, autoflush=False)
        background_tasks.add_task(
            history_service.generate_and_save_recommendation,
            history_id=history.id,
            session_factory=session_factory,
        )

    return _detail(history)


@router.delete(
    "/{history_id}",
    summary="Delete a history entry and its photos",
    responses={
        **UNAUTHORIZED_RESPONSE,
        404: {"model": ErrorResponse, "description": "History not found."},
    },
)
def delete_history(
    history_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> DeleteHistoryResponse:
    try:
        history_service.delete_history(db, user=current_user, history_id=history_id)
    except history_service.HistoryNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Riwayat tidak ditemukan.",
        ) from None
    return DeleteHistoryResponse(id=history_id, deleted=True)
