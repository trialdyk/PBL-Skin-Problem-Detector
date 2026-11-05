"""Authentication API routes."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import create_access_token
from app.dependencies import get_db
from app.schemas.auth import ErrorResponse, LoginRequest, LoginResponse, UserResponse
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/login",
    summary="Login with email and password",
    responses={
        400: {
            "model": ErrorResponse,
            "description": "Syarat & Ketentuan or Kebijakan Privasi not accepted.",
        },
        401: {
            "model": ErrorResponse,
            "description": "Wrong email or password, or the account is inactive.",
        },
    },
)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    """Log in with email and password.

    The 400 and 401 ``detail`` strings are Indonesian and shown as-is by the app.
    The consent check runs before the credential check, so unaccepted terms
    return 400 even when the password is wrong. 422 means the body is malformed
    and its ``detail`` is a list, not a string.
    """
    if not (payload.accepted_terms and payload.accepted_privacy):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.",
        )

    user = auth_service.authenticate(db, payload.email, payload.password)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau kata sandi salah. Periksa kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return LoginResponse(
        access_token=create_access_token(str(user.id)),
        expires_in=get_settings().jwt_expire_minutes * 60,
        user=UserResponse.model_validate(user),
    )
