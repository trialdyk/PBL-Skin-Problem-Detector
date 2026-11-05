"""Verify Google ID tokens issued to the DermaScan Web client."""

from typing import Any

from google.auth.transport import requests
from google.oauth2 import id_token

from app.core.config import get_settings


class GoogleTokenError(Exception):
    """Raised when an ID token is missing, forged, expired, or mis-audienced."""


def verify_google_id_token(token: str) -> dict[str, Any]:
    """Return Google token claims for a valid ``id_token``.

    Requires ``GOOGLE_CLIENT_ID`` (Web client) so ``aud`` matches the mobile
    app's ``serverClientId``.
    """
    client_id = get_settings().google_client_id.strip()
    if not client_id:
        raise GoogleTokenError("GOOGLE_CLIENT_ID is not configured")

    try:
        claims = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            audience=client_id,
        )
    except ValueError as exc:
        raise GoogleTokenError(str(exc)) from exc

    if claims.get("iss") not in {"accounts.google.com", "https://accounts.google.com"}:
        raise GoogleTokenError("invalid issuer")
    if not claims.get("email"):
        raise GoogleTokenError("email claim missing")
    # Google may send bool True or the string "true".
    verified = claims.get("email_verified")
    if verified is not True and verified != "true":
        raise GoogleTokenError("email not verified")
    if not claims.get("sub"):
        raise GoogleTokenError("sub claim missing")

    return claims

