"""DermaScan FastAPI application entry point."""

from fastapi import FastAPI

from app.core.config import get_settings
from app.routers import auth, history, items, ml, users

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description=(
        "DermaScan backend API for facial skin-condition analysis. "
        "Public: POST /auth/login, POST /auth/register, POST /auth/verify-email, "
        "POST /auth/resend-verification, POST /auth/google, GET /health. "
        "Protected routes require Authorization: Bearer <access_token> "
        "(Authorize in Swagger). /users/me reads and updates the caller's profile. "
        "POST /ml/predict runs the shipped CNN on 1-3 face photos and returns a GEA grade. "
        "POST /history saves a completed scan (photos + interview + pending recommendation). "
        "Items is a placeholder."
    ),
    openapi_tags=[
        {
            "name": "auth",
            "description": (
                "Public login/register/verify-email/Google. Password sign-up sends an "
                "OTP; JWT is issued after verify-email (or Google)."
            ),
        },
        {
            "name": "users",
            "description": "Protected. Current user profile (GET/PATCH /users/me) and router status.",
        },
        {
            "name": "history",
            "description": (
                "Protected. Persist and list face-scan history with local photo storage "
                "and a pending recommendation slot for a future LLM service."
            ),
        },
        {
            "name": "items",
            "description": "Protected. Placeholder status endpoint only.",
        },
        {
            "name": "ml",
            "description": (
                "Protected. Acne severity prediction with the shipped TFLite CNN "
                "(classes IGA0-IGA4 mapped to GEA 0-4)."
            ),
        },
        {"name": "system", "description": "Public service health (no auth)."},
    ],
    debug=settings.debug,
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(history.router)
app.include_router(items.router)
app.include_router(ml.router)


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    """Lightweight health check independent of external services."""
    return {
        "status": "ok",
        "service": "dermascan-backend",
    }
