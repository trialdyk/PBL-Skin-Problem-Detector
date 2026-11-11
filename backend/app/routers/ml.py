"""Acne severity prediction routes (protected)."""

from __future__ import annotations

import time

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.core.config import get_settings
from app.dependencies import get_current_user
from app.schemas.auth import ErrorResponse
from app.schemas.ml import AggregatePrediction, ImagePrediction, MlPredictResponse
from app.services import ml_service

router = APIRouter(
    prefix="/ml",
    tags=["ml"],
    dependencies=[Depends(get_current_user)],
)

MAX_FILES = 3

INVALID_IMAGE_MESSAGE = "File bukan gambar yang valid."
TOO_MANY_FILES_MESSAGE = f"Maksimal {MAX_FILES} foto per permintaan."
EMPTY_FILE_MESSAGE = "File foto kosong. Pilih foto lain."
MODEL_UNAVAILABLE_MESSAGE = "Layanan analisis belum siap. Coba lagi nanti."


@router.post(
    "/predict",
    summary="Predict acne severity (GEA 0-4) from 1-3 face photos",
    responses={
        400: {
            "model": ErrorResponse,
            "description": (
                "Empty file, undecodable image, or more than three photos."
            ),
        },
        401: {
            "model": ErrorResponse,
            "description": "Missing, invalid, expired, or inactive-user bearer token.",
        },
        413: {
            "model": ErrorResponse,
            "description": "An uploaded photo exceeds ML_MAX_UPLOAD_MB.",
        },
        503: {
            "model": ErrorResponse,
            "description": (
                "Inference runtime or model artifact is unavailable on the server."
            ),
        },
    },
)
def predict(
    files: list[UploadFile] = File(
        ...,
        description="Front, left and right selfies (1-3 files, max 10 MB each).",
    ),
) -> MlPredictResponse:
    """Run the shipped CNN on the photos and average their probabilities.

    Photos are processed in memory and never stored. ``aggregate.grade`` is the
    GEA value the app displays; grade 5 cannot be produced because the model only
    has classes ``IGA0``-``IGA4``.
    """
    settings = get_settings()

    if len(files) > MAX_FILES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=TOO_MANY_FILES_MESSAGE,
        )

    max_bytes = settings.ml_max_upload_mb * 1024 * 1024
    max_mb_message = f"Ukuran gambar maksimal {settings.ml_max_upload_mb} MB."

    image_predictions: list[ImagePrediction] = []
    all_probabilities: list[list[float]] = []

    for upload in files:
        data = upload.file.read()
        if not data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=EMPTY_FILE_MESSAGE,
            )
        if len(data) > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=max_mb_message,
            )

        started = time.perf_counter()
        try:
            probabilities = ml_service.predict_probabilities(data)
        except ml_service.InvalidImageError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=INVALID_IMAGE_MESSAGE,
            ) from None
        except ml_service.ModelUnavailableError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=MODEL_UNAVAILABLE_MESSAGE,
            ) from None
        elapsed_ms = (time.perf_counter() - started) * 1000

        top = ml_service.top_index(probabilities)
        grade = ml_service.grade_for(top)
        all_probabilities.append(probabilities)
        image_predictions.append(
            ImagePrediction(
                filename=upload.filename or "photo",
                top_label=ml_service.label_for(top),
                grade=grade,
                grade_label=ml_service.grade_label_for(grade),
                predictions=ml_service.scores_for(probabilities),
                inference_ms=round(elapsed_ms, 1),
            )
        )

    mean_probabilities = ml_service.average_probabilities(all_probabilities)
    mean_top = ml_service.top_index(mean_probabilities)
    mean_grade = ml_service.grade_for(mean_top)

    return MlPredictResponse(
        model=ml_service.MODEL_ID,
        images=image_predictions,
        aggregate=AggregatePrediction(
            top_label=ml_service.label_for(mean_top),
            grade=mean_grade,
            grade_label=ml_service.grade_label_for(mean_grade),
            predictions=ml_service.scores_for(mean_probabilities),
        ),
    )