"""Request and response schemas for user profile endpoints."""

from datetime import datetime
import uuid

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.auth import Email, FullName


class UpdateProfileRequest(BaseModel):
    """Fields for updating the signed-in user's display name and/or email."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "full_name": "Budi Santoso",
                    "email": "budi@gmail.com",
                }
            ]
        }
    )

    full_name: FullName | None = Field(
        default=None,
        description="Display name (1-255 chars, trimmed). Omit to keep unchanged.",
    )
    email: Email | None = Field(
        default=None,
        description="Account email (trimmed and lowercased). Omit to keep unchanged.",
    )


class UserProfileResponse(BaseModel):
    """Public profile of the authenticated user; never includes secrets."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str | None
    auth_provider: str
    email_verified: bool = True
    created_at: datetime
    updated_at: datetime
