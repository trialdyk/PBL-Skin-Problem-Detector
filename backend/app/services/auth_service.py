"""Authentication business logic."""

from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import hash_password, verify_password
from app.models import User
from app.services import email_service
from app.services.google_auth import GoogleTokenError, verify_google_id_token

# Verified for unknown emails so response time does not reveal which accounts exist.
_DUMMY_PASSWORD_HASH = hash_password("dermascan-dummy-password")

UNVERIFIED_EMAIL_MESSAGE = (
    "Email belum diverifikasi. Masukkan kode yang dikirim ke email Anda."
)
INVALID_CODE_MESSAGE = "Kode verifikasi salah atau sudah kedaluwarsa."
ALREADY_VERIFIED_MESSAGE = "Email sudah diverifikasi. Silakan masuk."


class EmailAlreadyRegisteredError(Exception):
    """Raised when registering an email that already has an account."""


class GoogleSignInError(Exception):
    """Raised when Google ID token verification fails."""


class EmailNotVerifiedError(Exception):
    """Raised when password login succeeds but email is not verified yet."""


class VerificationError(Exception):
    """Raised when verify / resend fails with a user-facing Indonesian message."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _as_aware(value: datetime) -> datetime:
    """SQLite often returns naive datetimes; treat them as UTC."""
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


def _generate_code() -> str:
    """Return a cryptographically random 6-digit code (000000–999999)."""
    return f"{secrets.randbelow(1_000_000):06d}"


def issue_email_verification(db: Session, user: User) -> tuple[str, int]:
    """Create a fresh OTP, store its hash, email it, return ``(code, expires_in_sec)``.

    The plain ``code`` is only for tests / logging; callers must not put it in API
    responses outside development helpers.
    """
    settings = get_settings()
    code = _generate_code()
    expires_in = settings.email_verification_expire_minutes * 60
    user.email_verification_code_hash = hash_password(code)
    user.email_verification_expires_at = _utcnow() + timedelta(
        minutes=settings.email_verification_expire_minutes
    )
    user.email_verified = False
    db.add(user)
    db.commit()
    db.refresh(user)

    email_service.send_verification_code(
        user.email,
        code,
        full_name=user.full_name,
        settings=settings,
    )
    return code, expires_in


def authenticate(db: Session, email: str, password: str) -> User | None:
    """Return the active, verified user matching the credentials.

    Raises ``EmailNotVerifiedError`` when credentials are correct but the email
    has not been verified yet (so the app can open the OTP screen).
    """
    user = db.scalar(select(User).where(User.email == email))
    if user is None or user.password_hash is None:
        verify_password(password, _DUMMY_PASSWORD_HASH)
        return None
    if not verify_password(password, user.password_hash) or not user.is_active:
        return None
    if not user.email_verified:
        raise EmailNotVerifiedError(UNVERIFIED_EMAIL_MESSAGE)
    return user


def register(db: Session, email: str, password: str, full_name: str | None) -> tuple[User, int]:
    """Create an unverified password account and send a verification email.

    Returns ``(user, expires_in_seconds)``. Does **not** issue a JWT — the client
    must call ``/auth/verify-email`` first.

    Raises ``EmailAlreadyRegisteredError`` if the email is taken.
    Raises ``email_service.EmailSendError`` if SMTP fails outside development.
    """
    user = User(
        email=email,
        password_hash=hash_password(password),
        full_name=full_name,
        auth_provider="password",
        email_verified=False,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise EmailAlreadyRegisteredError(email) from None
    db.refresh(user)

    _, expires_in = issue_email_verification(db, user)
    return user, expires_in


def verify_email(db: Session, email: str, code: str) -> User:
    """Mark the account verified when ``code`` matches and is not expired."""
    user = db.scalar(select(User).where(User.email == email))
    if user is None or user.password_hash is None:
        raise VerificationError(INVALID_CODE_MESSAGE)
    if user.email_verified:
        raise VerificationError(ALREADY_VERIFIED_MESSAGE)

    expires = user.email_verification_expires_at
    if (
        not user.email_verification_code_hash
        or expires is None
        or _as_aware(expires) < _utcnow()
        or not verify_password(code, user.email_verification_code_hash)
    ):
        raise VerificationError(INVALID_CODE_MESSAGE)

    user.email_verified = True
    user.email_verification_code_hash = None
    user.email_verification_expires_at = None
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def resend_verification(db: Session, email: str) -> int:
    """Send a new code. Returns ``expires_in`` seconds.

    Unknown / Google-only / already-verified emails get a generic success-shaped
    response from the router; this function raises ``VerificationError`` only for
    cases the client should show (e.g. already verified when we know the user).
    """
    user = db.scalar(select(User).where(User.email == email))
    if user is None or user.password_hash is None:
        # Do not reveal whether the email exists.
        return get_settings().email_verification_expire_minutes * 60
    if user.email_verified:
        raise VerificationError(ALREADY_VERIFIED_MESSAGE)
    if not user.is_active:
        raise VerificationError(INVALID_CODE_MESSAGE)

    _, expires_in = issue_email_verification(db, user)
    return expires_in


def authenticate_google(db: Session, id_token_str: str) -> User:
    """Verify a Google ``id_token`` and return an active user (create or link).

    Google accounts are treated as email-verified.
    Raises ``GoogleSignInError`` when the token is invalid.
    """
    try:
        claims = verify_google_id_token(id_token_str)
    except GoogleTokenError as exc:
        raise GoogleSignInError(str(exc)) from exc

    google_sub = str(claims["sub"])
    email = str(claims["email"]).strip().lower()
    full_name = claims.get("name")
    if isinstance(full_name, str):
        full_name = full_name.strip() or None
    else:
        full_name = None

    user = db.scalar(select(User).where(User.google_sub == google_sub))
    if user is None:
        user = db.scalar(select(User).where(User.email == email))

    if user is None:
        user = User(
            email=email,
            password_hash=None,
            full_name=full_name,
            auth_provider="google",
            google_sub=google_sub,
            email_verified=True,
        )
        db.add(user)
    else:
        if not user.is_active:
            raise GoogleSignInError("account inactive")
        user.google_sub = google_sub
        user.email_verified = True
        user.email_verification_code_hash = None
        user.email_verification_expires_at = None
        if user.auth_provider == "password":
            pass
        else:
            user.auth_provider = "google"
        if full_name and not user.full_name:
            user.full_name = full_name

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise GoogleSignInError("could not link Google account") from None
    db.refresh(user)
    return user
