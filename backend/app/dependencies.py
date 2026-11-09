"""Reusable FastAPI dependencies."""

from collections.abc import Generator
import uuid

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.database import get_db as _get_db
from app.models import User

bearer_scheme = HTTPBearer(auto_error=False)

UNAUTHORIZED = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Sesi tidak valid atau sudah berakhir. Silakan masuk kembali.",
    headers={"WWW-Authenticate": "Bearer"},
)


def get_db() -> Generator[Session, None, None]:
    """Provide a SQLAlchemy session for request handlers."""
    yield from _get_db()


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Resolve the caller from ``Authorization: Bearer <jwt>``.

    Public routes (``/auth/login``, ``/auth/register``, ``/health``) must not
    depend on this. Protected routers declare ``Depends(get_current_user)``.
    """
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise UNAUTHORIZED

    try:
        subject = decode_access_token(credentials.credentials)
        user_id = uuid.UUID(subject)
    except (jwt.PyJWTError, ValueError):
        raise UNAUTHORIZED from None

    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise UNAUTHORIZED

    return user
