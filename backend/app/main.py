"""DermaScan FastAPI application entry point."""

from fastapi import FastAPI

from app.core.config import get_settings
from app.routers import auth, items, ml, users

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description=(
        "DermaScan backend API for facial skin-condition analysis. "
        "Public: POST /auth/login, POST /auth/register, POST /auth/google, GET /health. "
        "Protected routes require Authorization: Bearer <access_token> "
        "(Authorize in Swagger). POST /ml/predict runs the shipped CNN on 1-3 face "
        "photos and returns a GEA grade. Users and items are placeholders."
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
app.include_router(items.router)
app.include_router(ml.router)


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    """Lightweight health check independent of external services."""
    return {
        "status": "ok",
        "service": "dermascan-backend",
    }
