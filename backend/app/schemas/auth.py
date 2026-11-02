"""Request and response schemas for authentication."""

import uuid
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, StringConstraints

# Same format the Flutter login form accepts (`LoginScreen._emailPattern`).
Email = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        to_lower=True,
        max_length=255,
        pattern=r"^[A-Za-z0-9_.+-]+@[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+$",
    ),
]


class LoginRequest(BaseModel):
    """Fields of the mobile login form."""

    email: Email
    password: str = Field(min_length=1, max_length=128)
    accepted_terms: bool
    accepted_privacy: bool


class UserResponse(BaseModel):
    """Public user data; never includes the password hash."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str | None


class LoginResponse(BaseModel):
    """Bearer token plus the authenticated user."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse
