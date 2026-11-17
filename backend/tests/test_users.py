"""Tests for the protected users router."""

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
    session.add(
        User(
            email=EMAIL,
            password_hash=hash_password(PASSWORD),
            full_name="Pengguna",
            email_verified=True,
        )
    )
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


def test_users_status_requires_bearer_token(client: TestClient) -> None:
    response = client.get("/users/status")
    assert response.status_code == 401
    assert response.json()["detail"] == UNAUTHORIZED_DETAIL
    assert response.headers.get("www-authenticate") == "Bearer"


def test_users_status_rejects_invalid_token(client: TestClient) -> None:
    response = client.get(
        "/users/status",
        headers={"Authorization": "Bearer bukan.jwt.valid"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == UNAUTHORIZED_DETAIL


def test_users_router_status_with_token(client: TestClient, auth_header: dict[str, str]) -> None:
    response = client.get("/users/status", headers=auth_header)
    assert response.status_code == 200
    payload = response.json()
    assert payload["router"] == "users"
    assert payload["status"] == "registered"


def test_users_status_rejects_inactive_user(
    client: TestClient,
    db: Session,
    auth_header: dict[str, str],
) -> None:
    user = db.query(User).one()
    user.is_active = False
    db.commit()

    response = client.get("/users/status", headers=auth_header)
    assert response.status_code == 401


def test_get_me_requires_bearer_token(client: TestClient) -> None:
    response = client.get("/users/me")
    assert response.status_code == 401
    assert response.json()["detail"] == UNAUTHORIZED_DETAIL
    assert response.headers.get("www-authenticate") == "Bearer"


def test_get_me_returns_profile_without_secrets(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    response = client.get("/users/me", headers=auth_header)
    assert response.status_code == 200
    payload = response.json()
    assert payload["email"] == EMAIL
    assert payload["full_name"] == "Pengguna"
    assert payload["auth_provider"] == "password"
    assert payload["email_verified"] is True
    assert "id" in payload
    assert "created_at" in payload
    assert "updated_at" in payload
    assert "password_hash" not in payload
    assert "password" not in payload
    assert "google_sub" not in payload
    assert "email_verification_code_hash" not in payload
    assert "email_verification_expires_at" not in payload


def test_patch_me_updates_name_and_email(
    client: TestClient,
    db: Session,
    auth_header: dict[str, str],
) -> None:
    response = client.patch(
        "/users/me",
        headers=auth_header,
        json={"full_name": "  Budi Santoso  ", "email": "  Budi@Example.COM  "},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["full_name"] == "Budi Santoso"
    assert payload["email"] == "budi@example.com"

    user = db.query(User).one()
    assert user.full_name == "Budi Santoso"
    assert user.email == "budi@example.com"


def test_patch_me_updates_only_name_keeping_email(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    response = client.patch(
        "/users/me",
        headers=auth_header,
        json={"full_name": "Siti Aminah"},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["full_name"] == "Siti Aminah"
    assert payload["email"] == EMAIL


def test_patch_me_updates_only_email_keeping_name(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    response = client.patch(
        "/users/me",
        headers=auth_header,
        json={"email": "baru@gmail.com"},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["full_name"] == "Pengguna"
    assert payload["email"] == "baru@gmail.com"


def test_patch_me_same_email_is_idempotent(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    response = client.patch(
        "/users/me",
        headers=auth_header,
        json={"full_name": "Pengguna Baru", "email": EMAIL},
    )
    assert response.status_code == 200
    assert response.json()["email"] == EMAIL
    assert response.json()["full_name"] == "Pengguna Baru"


def test_patch_me_rejects_duplicate_email(
    client: TestClient,
    db: Session,
    auth_header: dict[str, str],
) -> None:
    db.add(
        User(
            email="lain@gmail.com",
            password_hash=hash_password(PASSWORD),
            full_name="Akun Lain",
        )
    )
    db.commit()

    response = client.patch(
        "/users/me",
        headers=auth_header,
        json={"email": "LAIN@gmail.com"},
    )
    assert response.status_code == 409
    assert response.json()["detail"] == "Email sudah digunakan oleh akun lain."


def test_patch_me_rejects_empty_or_null_payload(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    assert client.patch("/users/me", headers=auth_header, json={}).status_code == 400

    res_null_name = client.patch(
        "/users/me",
        headers=auth_header,
        json={"full_name": None, "email": EMAIL},
    )
    assert res_null_name.status_code == 400
    assert res_null_name.json()["detail"] == "Nama lengkap tidak boleh kosong."

    res_null_email = client.patch(
        "/users/me",
        headers=auth_header,
        json={"full_name": "Budi", "email": None},
    )
    assert res_null_email.status_code == 400
    assert res_null_email.json()["detail"] == "Email tidak boleh kosong."


def test_patch_me_rejects_invalid_name_or_email(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    assert (
        client.patch(
            "/users/me",
            headers=auth_header,
            json={"full_name": "   "},
        ).status_code
        == 422
    )
    assert (
        client.patch(
            "/users/me",
            headers=auth_header,
            json={"full_name": "a" * 256},
        ).status_code
        == 422
    )
    assert (
        client.patch(
            "/users/me",
            headers=auth_header,
            json={"email": "bukan-email"},
        ).status_code
        == 422
    )

