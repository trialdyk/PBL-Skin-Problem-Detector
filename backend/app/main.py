"""DermaScan FastAPI application entry point."""

from fastapi import FastAPI

from app.core.config import get_settings
from app.routers import auth, items, users

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description=(
        "DermaScan backend API for facial skin-condition analysis. "
        "Implemented: health check and email/password login (JWT). "
        "Users and items routers are placeholders."
    ),
    openapi_tags=[
        {"name": "auth", "description": "Login. Issues a bearer JWT; no endpoint verifies it yet."},
        {"name": "users", "description": "Placeholder status endpoint only."},
        {"name": "items", "description": "Placeholder status endpoint only."},
        {"name": "system", "description": "Service health."},
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
