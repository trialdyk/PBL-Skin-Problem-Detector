"""User profile business logic."""

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models import User


class EmailAlreadyInUseError(Exception):
    """Raised when updating a user's email to one already taken by another account."""


def update_profile(
    db: Session,
    user: User,
    *,
    full_name: str | None = None,
    email: str | None = None,
) -> User:
    """Update ``full_name`` and/or ``email`` on ``user`` and persist to the database.

    ``email`` must already be normalized (trimmed and lowercase, enforced by ``Email``).
    Raises ``EmailAlreadyInUseError`` if the unique constraint on ``users.email`` fails.
    """
    if full_name is not None:
        user.full_name = full_name
    if email is not None:
        user.email = email

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise EmailAlreadyInUseError(email or user.email) from None

    db.refresh(user)
    return user
