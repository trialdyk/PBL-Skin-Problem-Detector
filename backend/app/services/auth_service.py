"""Authentication business logic."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password
from app.models import User

# Verified for unknown emails so response time does not reveal which accounts exist.
_DUMMY_PASSWORD_HASH = hash_password("dermascan-dummy-password")


def authenticate(db: Session, email: str, password: str) -> User | None:
    """Return the active user matching the credentials, otherwise ``None``."""
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        verify_password(password, _DUMMY_PASSWORD_HASH)
        return None
    if not verify_password(password, user.password_hash) or not user.is_active:
        return None
    return user
