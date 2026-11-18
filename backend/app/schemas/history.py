"""Request/response schemas for scan history."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class RecommendationOut(BaseModel):
    """Embedded recommendation slot (LLM filled later)."""

    status: str
    text: str | None = None
    updated_at: datetime | None = None


class HistoryPhotoUrls(BaseModel):
    """Authenticated photo paths relative to the API base URL."""

    front: str
    left: str
    right: str


class HistoryListItem(BaseModel):
    """One row in ``GET /history``."""

    id: UUID
    created_at: datetime
    model_id: str
    grade: int
    grade_label: str
    top_label: str | None = None
    result_source: str
    recommendation: RecommendationOut
    photos: HistoryPhotoUrls


class HistoryDetail(HistoryListItem):
    """``GET /history/{id}`` including interview and aggregate snapshot."""

    interview: dict[str, Any]
    aggregate: dict[str, Any] | None = None


class HistoryListResponse(BaseModel):
    items: list[HistoryListItem]
    total: int
    limit: int
    offset: int


class HistoryCreateResponse(HistoryDetail):
    """Body of a successful ``POST /history``."""


class DeleteHistoryResponse(BaseModel):
    id: UUID
    deleted: bool = True


class InterviewPayload(BaseModel):
    """Interview answers stored on the history row."""

    gender: str | None = None
    age: int | None = Field(default=None, ge=1, le=120)
    uses_sunscreen: bool | None = None
    skin_type: str | None = None
    unhealthy_food_often: bool | None = None
    skipped: bool = False
