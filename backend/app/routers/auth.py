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
    RegisterPendingResponse,
    RegisterRequest,
    ResendVerificationRequest,
    UserResponse,
    VerifyEmailRequest,
)
from app.services import auth_service, email_service

router = APIRouter(prefix="/auth", tags=["auth"])

CONSENT_REQUIRED_MESSAGE = "Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu."
REGISTER_PENDING_MESSAGE = "Kode verifikasi telah dikirim ke email Anda."
RESEND_MESSAGE = "Jika email terdaftar dan belum diverifikasi, kode baru telah dikirim."


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
        403: {
            "model": ErrorResponse,
            "description": "Credentials OK but email is not verified yet.",
        },
    },
)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    """Log in with email and password.

    The 400 / 401 / 403 ``detail`` strings are Indonesian and shown as-is by the app.
    The consent check runs before the credential check, so unaccepted terms
    return 400 even when the password is wrong. 422 means the body is malformed
    and its ``detail`` is a list, not a string.
    """
    _require_consent(payload.accepted_terms, payload.accepted_privacy)

    try:
        user = auth_service.authenticate(db, payload.email, payload.password)
    except auth_service.EmailNotVerifiedError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        ) from None

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
    summary="Create an account (sends email verification code)",
    responses={
        400: {
            "model": ErrorResponse,
            "description": "Syarat & Ketentuan or Kebijakan Privasi not accepted.",
        },
        409: {
            "model": ErrorResponse,
            "description": "The email already has an account.",
        },
        503: {
            "model": ErrorResponse,
            "description": "SMTP failed to send the verification email.",
        },
    },
)
def register(
    payload: RegisterRequest,
    db: Session = Depends(get_db),
) -> RegisterPendingResponse:
    """Create an unverified account and email a 6-digit OTP.

    No bearer token is issued here. The app must call ``POST /auth/verify-email``
    with the code, which returns the same ``AuthResponse`` shape as login.
    """
    _require_consent(payload.accepted_terms, payload.accepted_privacy)

    try:
        user, expires_in = auth_service.register(
            db, payload.email, payload.password, payload.full_name
        )
    except auth_service.EmailAlreadyRegisteredError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email sudah terdaftar. Silakan masuk.",
        ) from None
    except email_service.EmailSendError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None

    return RegisterPendingResponse(
        email=user.email,
        message=REGISTER_PENDING_MESSAGE,
        expires_in=expires_in,
    )


@router.post(
    "/verify-email",
    summary="Confirm email with the 6-digit code and log in",
    responses={
        400: {
            "model": ErrorResponse,
            "description": "Wrong/expired code, or email already verified.",
        },
    },
)
def verify_email(
    payload: VerifyEmailRequest,
    db: Session = Depends(get_db),
) -> AuthResponse:
    """Exchange a valid OTP for a bearer JWT."""
    try:
        user = auth_service.verify_email(db, payload.email, payload.code)
    except auth_service.VerificationError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=exc.message,
        ) from None
    return _auth_response(user)


@router.post(
    "/resend-verification",
    summary="Resend the email verification code",
    responses={
        400: {
            "model": ErrorResponse,
            "description": "Email already verified.",
        },
        503: {
            "model": ErrorResponse,
            "description": "SMTP failed to send the verification email.",
        },
    },
)
def resend_verification(
    payload: ResendVerificationRequest,
    db: Session = Depends(get_db),
) -> RegisterPendingResponse:
    """Send a new OTP. Unknown emails get a generic success body (no enumeration)."""
    try:
        expires_in = auth_service.resend_verification(db, payload.email)
    except auth_service.VerificationError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=exc.message,
        ) from None
    except email_service.EmailSendError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None

    return RegisterPendingResponse(
        email=payload.email,
        message=RESEND_MESSAGE,
        expires_in=expires_in,
    )


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

    Public endpoint (no Authorization header). Google accounts skip email OTP
    (treated as already verified). Consent is checked before token verification.
    """
    _require_consent(payload.accepted_terms, payload.accepted_privacy)

    try:
        user = auth_service.authenticate_google(db, payload.id_token)
    except auth_service.GoogleSignInError as exc:
        import logging

        logging.getLogger(__name__).warning("Google sign-in rejected: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Login Google gagal. Coba lagi atau gunakan email.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None

    return _auth_response(user)
