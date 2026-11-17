"""Tests for POST /auth/verify-email and /auth/resend-verification."""

from __future__ import annotations

from collections.abc import Generator
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.security import hash_password
from app.db.database import Base
from app.dependencies import get_db
from app.main import app
from app.models import User

EMAIL = "baru@gmail.com"
PASSWORD = "rahasia123"


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


@pytest.fixture
def capture_code(monkeypatch: pytest.MonkeyPatch) -> list[str]:
    codes: list[str] = []

    def _send(to_email: str, code: str, settings=None) -> None:  # noqa: ANN001
        codes.append(code)

    monkeypatch.setattr("app.services.email_service.send_verification_code", _send)
    return codes


def _register(client: TestClient) -> None:
    response = client.post(
        "/auth/register",
        json={
            "full_name": "Budi",
            "email": EMAIL,
            "password": PASSWORD,
            "accepted_terms": True,
            "accepted_privacy": True,
        },
    )
    assert response.status_code == 201


def test_verify_email_returns_token(client: TestClient, capture_code: list[str]) -> None:
    _register(client)
    code = capture_code[-1]

    response = client.post(
        "/auth/verify-email",
        json={"email": EMAIL, "code": code},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["token_type"] == "bearer"
    assert payload["user"]["email"] == EMAIL
    assert payload["user"]["email_verified"] is True
    assert payload["access_token"]


def test_verify_email_wrong_code(client: TestClient, capture_code: list[str]) -> None:
    _register(client)
    assert capture_code

    response = client.post(
        "/auth/verify-email",
        json={"email": EMAIL, "code": "000000"},
    )
    assert response.status_code == 400
    assert "salah" in response.json()["detail"].lower() or "kedaluwarsa" in response.json()[
        "detail"
    ].lower()


def test_resend_verification_sends_new_code(
    client: TestClient,
    capture_code: list[str],
) -> None:
    _register(client)
    first = capture_code[-1]

    response = client.post("/auth/resend-verification", json={"email": EMAIL})
    assert response.status_code == 200
    assert response.json()["email"] == EMAIL
    assert len(capture_code) >= 2
    # New code should work (may equal by chance; verify either latest works)
    latest = capture_code[-1]
    assert client.post(
        "/auth/verify-email",
        json={"email": EMAIL, "code": latest},
    ).status_code == 200
    assert first  # was issued


def test_login_after_verify(client: TestClient, capture_code: list[str]) -> None:
    _register(client)
    client.post("/auth/verify-email", json={"email": EMAIL, "code": capture_code[-1]})

    response = client.post(
        "/auth/login",
        json={
            "email": EMAIL,
            "password": PASSWORD,
            "accepted_terms": True,
            "accepted_privacy": True,
        },
    )
    assert response.status_code == 200


def test_google_user_is_marked_verified(client: TestClient, db: Session) -> None:
    claims = {
        "sub": "google-sub-verify",
        "email": "guser@gmail.com",
        "email_verified": True,
        "name": "G User",
        "iss": "https://accounts.google.com",
    }
    with patch(
        "app.services.auth_service.verify_google_id_token",
        return_value=claims,
    ):
        response = client.post(
            "/auth/google",
            json={
                "id_token": "header.payload.signature-long-enough",
                "accepted_terms": True,
                "accepted_privacy": True,
            },
        )
    assert response.status_code == 200
    user = db.query(User).filter_by(email="guser@gmail.com").one()
    assert user.email_verified is True
