"""User-related API routes."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models import User
from app.schemas.auth import ErrorResponse
from app.schemas.user import UpdateProfileRequest, UserProfileResponse
from app.services import user_service

router = APIRouter(
    prefix="/users",
    tags=["users"],
    dependencies=[Depends(get_current_user)],
)

UNAUTHORIZED_RESPONSE = {
    401: {
        "model": ErrorResponse,
        "description": "Missing, invalid, expired, or inactive-user bearer token.",
    },
}


@router.get(
    "/status",
    summary="Confirm the users router is registered",
    responses=UNAUTHORIZED_RESPONSE,
)
def users_status() -> dict[str, str]:
    """Informational endpoint confirming the users router is registered.

    Requires ``Authorization: Bearer <access_token>`` from login/register.
    """
    return {
        "router": "users",
        "status": "registered",
        "note": "Placeholder only — no user business features in PBL-04",
    }


@router.get(
    "/me",
    summary="Get current user profile",
    responses=UNAUTHORIZED_RESPONSE,
)
def get_me(current_user: User = Depends(get_current_user)) -> UserProfileResponse:
    """Return the authenticated user's profile."""
    return UserProfileResponse.model_validate(current_user)


@router.patch(
    "/me",
    summary="Update current user's name and/or email",
    responses={
        400: {
            "model": ErrorResponse,
            "description": "Empty update payload or explicit null for name/email.",
        },
        **UNAUTHORIZED_RESPONSE,
        409: {
            "model": ErrorResponse,
            "description": "The requested email is already used by another account.",
        },
    },
)
def update_me(
    payload: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserProfileResponse:
    """Update the authenticated user's ``full_name`` and/or ``email``.

    Check order: 422 (malformed body / invalid email / empty string) before 401
    (invalid token) before 400 (explicit ``null`` or no fields provided) before
    409 (email already belongs to another account).
    """
    if "full_name" in payload.model_fields_set and payload.full_name is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nama lengkap tidak boleh kosong.",
        )
    if "email" in payload.model_fields_set and payload.email is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email tidak boleh kosong.",
        )
    if payload.full_name is None and payload.email is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Minimal satu data profil (nama atau email) harus diisi.",
        )

    try:
        updated = user_service.update_profile(
            db,
            current_user,
            full_name=payload.full_name,
            email=payload.email,
        )
    except user_service.EmailAlreadyInUseError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email sudah digunakan oleh akun lain.",
        ) from None

    return UserProfileResponse.model_validate(updated)
