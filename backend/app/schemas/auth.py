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

VerificationCode = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=6, max_length=6, pattern=r"^\d{6}$"),
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


class VerifyEmailRequest(BaseModel):
    """Confirm registration with the 6-digit code from email."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [{"email": "budi@gmail.com", "code": "123456"}]
        }
    )

    email: Email
    code: VerificationCode = Field(description="Six-digit OTP from the verification email.")


class ResendVerificationRequest(BaseModel):
    """Ask for a new verification code."""

    model_config = ConfigDict(
        json_schema_extra={"examples": [{"email": "budi@gmail.com"}]}
    )

    email: Email


class GoogleLoginRequest(BaseModel):
    """Google Sign-In payload from the mobile app (``id_token`` + consent)."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
                    "accepted_terms": True,
                    "accepted_privacy": True,
                }
            ]
        }
    )

    id_token: str = Field(min_length=20, max_length=8192, description="Google ID token.")
    accepted_terms: StrictBool = Field(description="Syarat & Ketentuan checkbox.")
    accepted_privacy: StrictBool = Field(description="Kebijakan Privasi checkbox.")


class ErrorResponse(BaseModel):
    """Body of 400, 401 and 409 responses. ``detail`` is user-facing Indonesian text."""

    detail: str


class UserResponse(BaseModel):
    """Public user data; never includes the password hash."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str | None
    email_verified: bool = True


class AuthResponse(BaseModel):
    """Bearer token plus the authenticated user (login / verify / Google)."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse


class RegisterPendingResponse(BaseModel):
    """Returned by ``POST /auth/register`` and ``POST /auth/resend-verification``.

    No JWT yet — the client must call ``POST /auth/verify-email`` with the OTP.
    """

    email: str
    message: str
    expires_in: int = Field(description="Seconds until the current code expires.")
