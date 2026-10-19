"""DermaScan FastAPI application entry point."""

from fastapi import FastAPI

from app.core.config import get_settings
from app.routers import items, users

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description=(
        "DermaScan backend API for facial skin-condition analysis. "
        "Includes repository foundation and PostgreSQL database setup."
    ),
    debug=settings.debug,
)

app.include_router(users.router)
app.include_router(items.router)


@app.get("/health")
def health() -> dict[str, str]:
    """Lightweight health check independent of external services."""
    return {
        "status": "ok",
        "service": "dermascan-backend",
    }
