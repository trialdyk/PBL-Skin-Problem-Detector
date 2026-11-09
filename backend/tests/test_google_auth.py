"""Tests for POST /auth/google."""

from collections.abc import Generator
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.security import hash_password
from app.db.database import Base
from app.dependencies import get_db
from app.main import app
from app.models import User
from app.services.google_auth import GoogleTokenError

CONSENT_MESSAGE = "Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu."
GOOGLE_FAIL_MESSAGE = "Login Google gagal. Coba lagi atau gunakan email."


@pytest.fixture
def db() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session = sessionmaker(bind=engine)()
    yield session
    session.close()
    engine.dispose()


@pytest.fixture
def client(db: Session) -> Generator[TestClient, None, None]:
    app.dependency_overrides[get_db] = lambda: db
    yield TestClient(app)
    app.dependency_overrides.pop(get_db, None)


def google_body(**overrides: object) -> dict[str, object]:
    return {
        "id_token": "header.payload.signature-long-enough",
        "accepted_terms": True,
        "accepted_privacy": True,
        **overrides,
    }


def _claims(**overrides: object) -> dict[str, object]:
    return {
        "sub": "google-sub-123",
        "email": "baru@gmail.com",
        "email_verified": True,
        "name": "Pengguna Google",
        "iss": "https://accounts.google.com",
        **overrides,
    }


def test_google_login_creates_user(client: TestClient, db: Session) -> None:
    with patch(
        "app.services.auth_service.verify_google_id_token",
        return_value=_claims(),
    ):
        response = client.post("/auth/google", json=google_body())

    assert response.status_code == 200
    payload = response.json()
    assert payload["token_type"] == "bearer"
    assert payload["user"]["email"] == "baru@gmail.com"
    assert payload["user"]["full_name"] == "Pengguna Google"

    user = db.scalar(select(User).where(User.email == "baru@gmail.com"))
    assert user is not None
    assert user.google_sub == "google-sub-123"
    assert user.password_hash is None
    assert user.auth_provider == "google"


def test_google_login_links_existing_password_user(client: TestClient, db: Session) -> None:
    db.add(
        User(
            email="lama@gmail.com",
            password_hash=hash_password("rahasia123"),
            full_name="Akun Lama",
            auth_provider="password",
        )
    )
    db.commit()

    with patch(
        "app.services.auth_service.verify_google_id_token",
        return_value=_claims(email="lama@gmail.com", name="Dari Google"),
    ):
        response = client.post("/auth/google", json=google_body())

    assert response.status_code == 200
    user = db.scalar(select(User).where(User.email == "lama@gmail.com"))
    assert user is not None
    assert user.google_sub == "google-sub-123"
    assert user.password_hash is not None
    assert response.json()["user"]["full_name"] == "Akun Lama"


def test_google_login_rejects_invalid_token(client: TestClient) -> None:
    with patch(
        "app.services.auth_service.verify_google_id_token",
        side_effect=GoogleTokenError("bad token"),
    ):
        response = client.post("/auth/google", json=google_body())

    assert response.status_code == 401
    assert response.json()["detail"] == GOOGLE_FAIL_MESSAGE


def test_google_login_requires_consent(client: TestClient) -> None:
    response = client.post("/auth/google", json=google_body(accepted_terms=False))
    assert response.status_code == 400
    assert response.json()["detail"] == CONSENT_MESSAGE


def test_google_login_rejects_inactive_user(client: TestClient, db: Session) -> None:
    db.add(
        User(
            email="mati@gmail.com",
            password_hash=None,
            auth_provider="google",
            google_sub="google-sub-123",
            is_active=False,
        )
    )
    db.commit()

    with patch(
        "app.services.auth_service.verify_google_id_token",
        return_value=_claims(email="mati@gmail.com"),
    ):
        response = client.post("/auth/google", json=google_body())

    assert response.status_code == 401


def test_openapi_documents_google_login(client: TestClient) -> None:
    operation = client.get("/openapi.json").json()["paths"]["/auth/google"]["post"]
    assert {"200", "400", "401", "422"} <= set(operation["responses"])
    assert "security" not in operation
