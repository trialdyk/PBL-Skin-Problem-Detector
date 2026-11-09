"""User ORM model (schema: migration 20260316_0001 + 20261105_0002)."""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, Uuid, func, true
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class User(Base):
    """Application account. ``email`` is stored lowercase.

    Password accounts have ``auth_provider='password'`` and a hash.
    Google accounts may have ``password_hash=None`` until they set a password.
    """

    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    full_name: Mapped[str | None] = mapped_column(String(255))
    auth_provider: Mapped[str] = mapped_column(String(32), server_default="password")
    google_sub: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, server_default=true())
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
