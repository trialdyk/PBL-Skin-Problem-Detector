"""Reusable FastAPI dependencies."""

from collections.abc import Generator

from sqlalchemy.orm import Session

from app.db.database import get_db as _get_db


def get_db() -> Generator[Session, None, None]:
    """Provide a SQLAlchemy session for request handlers."""
    yield from _get_db()
