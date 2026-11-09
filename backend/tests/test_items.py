"""Tests for the protected items router."""

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

EMAIL = "pengguna@gmail.com"
PASSWORD = "skinscan123"
UNAUTHORIZED_DETAIL = "Sesi tidak valid atau sudah berakhir. Silakan masuk kembali."


@pytest.fixture
def db() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session = sessionmaker(bind=engine)()
    session.add(User(email=EMAIL, password_hash=hash_password(PASSWORD), full_name="Pengguna"))
    session.commit()
    yield session
    session.close()
    engine.dispose()


@pytest.fixture
def client(db: Session) -> Generator[TestClient, None, None]:
    app.dependency_overrides[get_db] = lambda: db
    yield TestClient(app)
    app.dependency_overrides.pop(get_db, None)


@pytest.fixture
def auth_header(db: Session) -> dict[str, str]:
    user = db.query(User).one()
    return {"Authorization": f"Bearer {create_access_token(str(user.id))}"}


def test_items_status_requires_bearer_token(client: TestClient) -> None:
    response = client.get("/items/status")
    assert response.status_code == 401
    assert response.json()["detail"] == UNAUTHORIZED_DETAIL
    assert response.headers.get("www-authenticate") == "Bearer"


def test_items_status_rejects_invalid_token(client: TestClient) -> None:
    response = client.get(
        "/items/status",
        headers={"Authorization": "Bearer bukan.jwt.valid"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == UNAUTHORIZED_DETAIL


def test_items_router_status_with_token(client: TestClient, auth_header: dict[str, str]) -> None:
    response = client.get("/items/status", headers=auth_header)
    assert response.status_code == 200
    payload = response.json()
    assert payload["router"] == "items"
    assert payload["status"] == "registered"
