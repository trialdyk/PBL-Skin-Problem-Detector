"""Authentication business logic."""

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password
from app.models import User
from app.services.google_auth import GoogleTokenError, verify_google_id_token

# Verified for unknown emails so response time does not reveal which accounts exist.
_DUMMY_PASSWORD_HASH = hash_password("dermascan-dummy-password")


class EmailAlreadyRegisteredError(Exception):
    """Raised when registering an email that already has an account."""


class GoogleSignInError(Exception):
    """Raised when Google ID token verification fails."""


def authenticate(db: Session, email: str, password: str) -> User | None:
    """Return the active user matching the credentials, otherwise ``None``."""
    user = db.scalar(select(User).where(User.email == email))
    if user is None or user.password_hash is None:
        verify_password(password, _DUMMY_PASSWORD_HASH)
        return None
    if not verify_password(password, user.password_hash) or not user.is_active:
        return None
    return user


def register(db: Session, email: str, password: str, full_name: str | None) -> User:
    """Create an account. ``email`` must already be lowercase (the schema does this).

    Raises ``EmailAlreadyRegisteredError`` if the email is taken. The unique index
    is the source of truth, so two simultaneous requests cannot both succeed.
    """
    user = User(
        email=email,
        password_hash=hash_password(password),
        full_name=full_name,
        auth_provider="password",
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise EmailAlreadyRegisteredError(email) from None
    db.refresh(user)
    return user


def authenticate_google(db: Session, id_token_str: str) -> User:
    """Verify a Google ``id_token`` and return an active user (create or link).

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
        )
        db.add(user)
    else:
        if not user.is_active:
            raise GoogleSignInError("account inactive")
        user.google_sub = google_sub
        if user.auth_provider == "password":
            # Keep password login; mark that Google is also linked.
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
