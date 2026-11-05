"""Request and response schemas for authentication."""

import uuid
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, StrictBool, StringConstraints

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

FullName = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=1, max_length=255),
]


class LoginRequest(BaseModel):
    """Fields of the mobile login form."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "email": "pengguna@gmail.com",
                    "password": "skinscan123",
                    "accepted_terms": True,
                    "accepted_privacy": True,
                }
            ]
        }
    )

    email: Email = Field(description="Trimmed and lowercased by the server.")
    password: str = Field(min_length=1, max_length=128)
    # Strict so that "yes", 1, "on" etc. cannot count as consent.
    accepted_terms: StrictBool = Field(description="Syarat & Ketentuan checkbox.")
    accepted_privacy: StrictBool = Field(description="Kebijakan Privasi checkbox.")


class RegisterRequest(BaseModel):
    """Fields for creating an account."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "full_name": "Budi Santoso",
                    "email": "budi@gmail.com",
                    "password": "rahasia123",
                    "accepted_terms": True,
                    "accepted_privacy": True,
                }
            ]
        }
    )

    full_name: FullName | None = Field(
        default=None,
        description="Optional display name. Trimmed; null when omitted.",
    )
    email: Email = Field(description="Trimmed and lowercased by the server.")
    # Looser upper bound than the hash needs; Argon2 accepts long inputs.
    password: str = Field(min_length=8, max_length=128)
    accepted_terms: StrictBool = Field(description="Syarat & Ketentuan, must be true.")
    accepted_privacy: StrictBool = Field(description="Kebijakan Privasi, must be true.")


class ErrorResponse(BaseModel):
    """Body of 400, 401 and 409 responses. ``detail`` is user-facing Indonesian text."""

    detail: str


class UserResponse(BaseModel):
    """Public user data; never includes the password hash."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str | None


class AuthResponse(BaseModel):
    """Bearer token plus the authenticated user (login and register)."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse
