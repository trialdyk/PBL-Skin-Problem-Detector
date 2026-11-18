"""ORM models for persisted scan history and LLM recommendation slots."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, Uuid, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from app.db.database import Base

# JSONB on Postgres; plain JSON on SQLite (tests).
JsonType = JSON().with_variant(JSONB(), "postgresql")


class ScanHistory(Base):
    """One completed face-scan session belonging to a user."""

    __tablename__ = "scan_histories"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    model_id: Mapped[str] = mapped_column(String(128), nullable=False)
    grade: Mapped[int] = mapped_column(Integer, nullable=False)
    grade_label: Mapped[str] = mapped_column(String(64), nullable=False)
    top_label: Mapped[str | None] = mapped_column(String(32), nullable=True)
    result_source: Mapped[str] = mapped_column(String(32), nullable=False)
    aggregate_json: Mapped[dict[str, Any] | None] = mapped_column(JsonType, nullable=True)
    interview_json: Mapped[dict[str, Any]] = mapped_column(JsonType, nullable=False)
    photo_front_path: Mapped[str] = mapped_column(String(512), nullable=False)
    photo_left_path: Mapped[str] = mapped_column(String(512), nullable=False)
    photo_right_path: Mapped[str] = mapped_column(String(512), nullable=False)

    recommendation: Mapped[ScanRecommendation | None] = relationship(
        back_populates="history",
        uselist=False,
        cascade="all, delete-orphan",
        lazy="joined",
    )


class ScanRecommendation(Base):
    """LLM recommendation slot for one history row (filled later by teammate)."""

    __tablename__ = "scan_recommendations"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    history_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("scan_histories.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, server_default="pending")
    text: Mapped[str | None] = mapped_column(Text, nullable=True)
    meta_json: Mapped[dict[str, Any] | None] = mapped_column(JsonType, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    history: Mapped[ScanHistory] = relationship(back_populates="recommendation")
