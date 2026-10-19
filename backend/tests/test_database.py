"""Tests for database configuration and connectivity."""

import pytest
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from app.core.config import get_settings
from app.db.database import engine
from app.models import User


def test_database_url_uses_psycopg_driver() -> None:
    settings = get_settings()
    assert settings.database_url.startswith("postgresql+psycopg://")
    assert str(settings.db_port) in settings.database_url
    assert settings.db_name in settings.database_url


def test_user_model_metadata_registered() -> None:
    assert User.__tablename__ == "users"
    assert "users" in User.metadata.tables


def test_database_connection() -> None:
    try:
        with engine.connect() as connection:
            result = connection.execute(text("SELECT 1"))
            assert result.scalar() == 1
    except OperationalError:
        pytest.skip("PostgreSQL is not reachable (start Docker Postgres on port 5434)")
