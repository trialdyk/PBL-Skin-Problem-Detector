"""Persist scan history rows and photo files on local disk."""

from __future__ import annotations

import json
import shutil
import uuid
from pathlib import Path
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.scan_history import ScanHistory, ScanRecommendation
from app.models.user import User

ALLOWED_ANGLES = ("front", "left", "right")
ALLOWED_SOURCES = frozenset({"ml", "rule_based"})
RECOMMENDATION_PENDING = "pending"

_BACKEND_ROOT = Path(__file__).resolve().parents[2]


class HistoryError(Exception):
    """Base error for history operations."""


class HistoryNotFoundError(HistoryError):
    """History row missing or not owned by the caller."""


class HistoryValidationError(HistoryError):
    """Invalid multipart fields or files."""


def upload_root() -> Path:
    """Absolute directory for history photos."""
    raw = Path(get_settings().history_upload_dir)
    return raw if raw.is_absolute() else _BACKEND_ROOT / raw


def photo_api_path(history_id: uuid.UUID, angle: str) -> str:
    return f"/history/{history_id}/photos/{angle}"


def _session_dir(user_id: uuid.UUID, history_id: uuid.UUID) -> Path:
    return upload_root() / str(user_id) / str(history_id)


def _ext_for(filename: str | None, content_type: str | None) -> str:
    if filename and "." in filename:
        ext = filename.rsplit(".", 1)[-1].lower()
        if ext in {"jpg", "jpeg", "png", "webp", "heic"}:
            return "jpg" if ext == "jpeg" else ext
    if content_type:
        if "png" in content_type:
            return "png"
        if "webp" in content_type:
            return "webp"
    return "jpg"


def _parse_json_field(raw: str | None, *, field: str, required: bool) -> dict[str, Any] | None:
    if raw is None or raw.strip() == "":
        if required:
            raise HistoryValidationError(f"Field {field} wajib diisi.")
        return None
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HistoryValidationError(f"Field {field} harus JSON valid.") from exc
    if not isinstance(value, dict):
        raise HistoryValidationError(f"Field {field} harus objek JSON.")
    return value


def create_history(
    db: Session,
    *,
    user: User,
    grade: int,
    grade_label: str,
    model_id: str,
    result_source: str,
    top_label: str | None,
    interview_raw: str,
    aggregate_raw: str | None,
    photos: dict[str, tuple[bytes, str | None, str | None]],
) -> ScanHistory:
    """Write photos to disk and insert history + pending recommendation."""
    if grade < 0 or grade > 5:
        raise HistoryValidationError("Grade harus antara 0 dan 5.")
    if result_source not in ALLOWED_SOURCES:
        raise HistoryValidationError("result_source harus ml atau rule_based.")
    if set(photos.keys()) != set(ALLOWED_ANGLES):
        raise HistoryValidationError("Kirim foto front, left, dan right.")

    settings = get_settings()
    max_bytes = settings.history_max_upload_mb * 1024 * 1024
    for angle, (data, _name, _ctype) in photos.items():
        if not data:
            raise HistoryValidationError(f"Foto {angle} kosong.")
        if len(data) > max_bytes:
            raise HistoryValidationError(
                f"Ukuran foto maksimal {settings.history_max_upload_mb} MB.",
            )

    interview = _parse_json_field(interview_raw, field="interview", required=True)
    aggregate = _parse_json_field(aggregate_raw, field="aggregate", required=False)
    assert interview is not None

    history_id = uuid.uuid4()
    directory = _session_dir(user.id, history_id)
    directory.mkdir(parents=True, exist_ok=True)

    paths: dict[str, str] = {}
    try:
        for angle in ALLOWED_ANGLES:
            data, filename, content_type = photos[angle]
            ext = _ext_for(filename, content_type)
            relative = f"{user.id}/{history_id}/{angle}.{ext}"
            absolute = upload_root() / relative
            absolute.parent.mkdir(parents=True, exist_ok=True)
            absolute.write_bytes(data)
            paths[angle] = relative.replace("\\", "/")

        history = ScanHistory(
            id=history_id,
            user_id=user.id,
            model_id=model_id.strip() or "unknown",
            grade=grade,
            grade_label=grade_label.strip() or f"GEA {grade}",
            top_label=top_label.strip() if top_label else None,
            result_source=result_source,
            aggregate_json=aggregate,
            interview_json=interview,
            photo_front_path=paths["front"],
            photo_left_path=paths["left"],
            photo_right_path=paths["right"],
        )
        recommendation = ScanRecommendation(
            history_id=history_id,
            status=RECOMMENDATION_PENDING,
        )
        history.recommendation = recommendation
        db.add(history)
        db.commit()
        db.refresh(history)
        return history
    except Exception:
        db.rollback()
        if directory.exists():
            shutil.rmtree(directory, ignore_errors=True)
        raise


def list_histories(
    db: Session,
    *,
    user: User,
    limit: int = 20,
    offset: int = 0,
) -> tuple[list[ScanHistory], int]:
    limit = max(1, min(limit, 100))
    offset = max(0, offset)
    total = db.scalar(
        select(func.count()).select_from(ScanHistory).where(ScanHistory.user_id == user.id),
    ) or 0
    rows = db.scalars(
        select(ScanHistory)
        .where(ScanHistory.user_id == user.id)
        .order_by(ScanHistory.created_at.desc())
        .limit(limit)
        .offset(offset),
    ).all()
    return list(rows), int(total)


def get_history(db: Session, *, user: User, history_id: uuid.UUID) -> ScanHistory:
    history = db.get(ScanHistory, history_id)
    if history is None or history.user_id != user.id:
        raise HistoryNotFoundError()
    return history


def absolute_photo_path(history: ScanHistory, angle: str) -> Path:
    if angle not in ALLOWED_ANGLES:
        raise HistoryValidationError("Sudut foto tidak valid.")
    relative = {
        "front": history.photo_front_path,
        "left": history.photo_left_path,
        "right": history.photo_right_path,
    }[angle]
    path = upload_root() / relative
    if not path.is_file():
        raise HistoryNotFoundError()
    return path


def delete_history(db: Session, *, user: User, history_id: uuid.UUID) -> None:
    history = get_history(db, user=user, history_id=history_id)
    directory = _session_dir(user.id, history_id)
    db.delete(history)
    db.commit()
    if directory.exists():
        shutil.rmtree(directory, ignore_errors=True)
