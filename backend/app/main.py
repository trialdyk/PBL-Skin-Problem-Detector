"""DermaScan FastAPI application entry point."""

from fastapi import FastAPI

from app.core.config import get_settings
from app.routers import auth, items, users

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description=(
        "DermaScan backend API for facial skin-condition analysis. "
        "Public: POST /auth/login, POST /auth/register, POST /auth/google, GET /health. "
        "Protected routes require Authorization: Bearer <access_token> "
        "(Authorize in Swagger). Users and items are placeholders."
    ),
    openapi_tags=[
        {
            "name": "auth",
            "description": (
                "Public login/register/Google. Issues a bearer JWT used on protected routes."
            ),
        },
        {
            "name": "users",
            "description": "Protected. Placeholder status endpoint only.",
        },
        {
            "name": "items",
            "description": "Protected. Placeholder status endpoint only.",
        },
        {"name": "system", "description": "Public service health (no auth)."},
    ],
    debug=settings.debug,
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(items.router)


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    """Lightweight health check independent of external services."""
    return {
        "status": "ok",
        "service": "dermascan-backend",
    }
