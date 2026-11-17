"""Shared fixtures for DermaScan API tests (SQLite in-memory, no Postgres)."""

from __future__ import annotations

from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.security import create_access_token, hash_password
from app.db.database import Base
from app.dependencies import get_db
from app.main import app
from app.models import User

DEMO_EMAIL = "pengguna@gmail.com"
DEMO_PASSWORD = "skinscan123"
UNAUTHORIZED_DETAIL = "Sesi tidak valid atau sudah berakhir. Silakan masuk kembali."


@pytest.fixture
def db() -> Generator[Session, None, None]:
    """Fresh SQLite DB with one active demo user."""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session = sessionmaker(bind=engine)()
    session.add(
        User(
            email=DEMO_EMAIL,
            password_hash=hash_password(DEMO_PASSWORD),
            full_name="Pengguna Demo",
            email_verified=True,
        )
    )
    session.commit()
    yield session
    session.close()
    engine.dispose()


@pytest.fixture
def client(db: Session) -> Generator[TestClient, None, None]:
    """HTTP client with ``get_db`` overridden to the in-memory session."""
    app.dependency_overrides[get_db] = lambda: db
    yield TestClient(app)
    app.dependency_overrides.pop(get_db, None)


@pytest.fixture
def auth_header(db: Session) -> dict[str, str]:
    """Valid ``Authorization: Bearer …`` for the seeded demo user."""
    user = db.query(User).one()
    return {"Authorization": f"Bearer {create_access_token(str(user.id))}"}


@pytest.fixture
def demo_user(db: Session) -> User:
    return db.query(User).one()
