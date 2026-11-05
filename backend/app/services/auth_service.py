"""Authentication business logic."""

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password
from app.models import User

# Verified for unknown emails so response time does not reveal which accounts exist.
_DUMMY_PASSWORD_HASH = hash_password("dermascan-dummy-password")


class EmailAlreadyRegisteredError(Exception):
    """Raised when registering an email that already has an account."""


def authenticate(db: Session, email: str, password: str) -> User | None:
    """Return the active user matching the credentials, otherwise ``None``."""
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
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
    user = User(email=email, password_hash=hash_password(password), full_name=full_name)
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise EmailAlreadyRegisteredError(email) from None
    db.refresh(user)
    return user
