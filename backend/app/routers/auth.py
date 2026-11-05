"""Authentication API routes."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import create_access_token
from app.dependencies import get_db
from app.models import User
from app.schemas.auth import (
    AuthResponse,
    ErrorResponse,
    GoogleLoginRequest,
    LoginRequest,
    RegisterRequest,
    UserResponse,
)
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])

CONSENT_REQUIRED_MESSAGE = "Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu."


def _require_consent(accepted_terms: bool, accepted_privacy: bool) -> None:
    if not (accepted_terms and accepted_privacy):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=CONSENT_REQUIRED_MESSAGE,
        )


def _auth_response(user: User) -> AuthResponse:
    return AuthResponse(
        access_token=create_access_token(str(user.id)),
        expires_in=get_settings().jwt_expire_minutes * 60,
        user=UserResponse.model_validate(user),
    )


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
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    """Log in with email and password.

    The 400 and 401 ``detail`` strings are Indonesian and shown as-is by the app.
    The consent check runs before the credential check, so unaccepted terms
    return 400 even when the password is wrong. 422 means the body is malformed
    and its ``detail`` is a list, not a string.
    """
    _require_consent(payload.accepted_terms, payload.accepted_privacy)

    user = auth_service.authenticate(db, payload.email, payload.password)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau kata sandi salah. Periksa kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return _auth_response(user)


@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    summary="Create an account",
    responses={
        400: {
            "model": ErrorResponse,
            "description": "Syarat & Ketentuan or Kebijakan Privasi not accepted.",
        },
        409: {
            "model": ErrorResponse,
            "description": "The email already has an account.",
        },
    },
)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> AuthResponse:
    """Create an account and log it in, returning the same body as login.

    Check order: 422 (malformed body) before 400 (consent not accepted) before
    409 (email taken). A 409 reveals that the email is registered; that is
    inherent to sign-up and is why login uses a single generic message instead.
    """
    _require_consent(payload.accepted_terms, payload.accepted_privacy)

    try:
        user = auth_service.register(db, payload.email, payload.password, payload.full_name)
    except auth_service.EmailAlreadyRegisteredError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email sudah terdaftar. Silakan masuk.",
        ) from None

    return _auth_response(user)


@router.post(
    "/google",
    summary="Login or register with a Google ID token",
    responses={
        400: {
            "model": ErrorResponse,
            "description": "Syarat & Ketentuan or Kebijakan Privasi not accepted.",
        },
        401: {
            "model": ErrorResponse,
            "description": "Invalid Google ID token or inactive account.",
        },
    },
)
def login_google(payload: GoogleLoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    """Exchange a Google ``id_token`` for a DermaScan bearer JWT.

    Public endpoint (no Authorization header). The mobile app must obtain the
    token with ``serverClientId`` set to the same Web client as ``GOOGLE_CLIENT_ID``.
    Consent is checked before token verification.
    """
    _require_consent(payload.accepted_terms, payload.accepted_privacy)

    try:
        user = auth_service.authenticate_google(db, payload.id_token)
    except auth_service.GoogleSignInError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Login Google gagal. Coba lagi atau gunakan email.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None

    return _auth_response(user)
