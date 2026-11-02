"""Tests for POST /auth/login, using in-memory SQLite instead of Postgres."""

from collections.abc import Generator
from datetime import timedelta

import jwt
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import get_settings
from app.core.security import hash_password
from app.db.database import Base
from app.dependencies import get_db
from app.main import app
from app.models import User

EMAIL = "pengguna@gmail.com"
PASSWORD = "skinscan123"


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
    app.dependency_overrides.pop(get_db)


def login_body(**overrides: object) -> dict[str, object]:
    return {
        "email": EMAIL,
        "password": PASSWORD,
        "accepted_terms": True,
        "accepted_privacy": True,
        **overrides,
    }


def test_login_success_returns_user_and_valid_token(client: TestClient) -> None:
    response = client.post("/auth/login", json=login_body())

    assert response.status_code == 200
    payload = response.json()
    assert payload["token_type"] == "bearer"
    assert payload["expires_in"] == get_settings().jwt_expire_minutes * 60
    assert payload["user"]["email"] == EMAIL
    assert payload["user"]["full_name"] == "Pengguna"
    assert "password_hash" not in payload["user"]

    settings = get_settings()
    claims = jwt.decode(
        payload["access_token"],
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
    )
    assert claims["sub"] == payload["user"]["id"]
    assert timedelta(seconds=claims["exp"] - claims["iat"]) == timedelta(
        minutes=settings.jwt_expire_minutes
    )


def test_login_normalizes_email_like_the_app(client: TestClient) -> None:
    response = client.post("/auth/login", json=login_body(email="  Pengguna@Gmail.com "))
    assert response.status_code == 200


@pytest.mark.parametrize(
    "overrides",
    [{"password": "salah"}, {"email": "tidakada@gmail.com"}],
)
def test_login_wrong_credentials_share_one_message(
    client: TestClient,
    overrides: dict[str, str],
) -> None:
    response = client.post("/auth/login", json=login_body(**overrides))
    assert response.status_code == 401
    assert response.json()["detail"] == "Email atau kata sandi salah. Periksa kembali."


def test_login_rejects_inactive_user(client: TestClient, db: Session) -> None:
    user = db.query(User).one()
    user.is_active = False
    db.commit()

    response = client.post("/auth/login", json=login_body())
    assert response.status_code == 401


@pytest.mark.parametrize("field", ["accepted_terms", "accepted_privacy"])
def test_login_requires_both_consents(client: TestClient, field: str) -> None:
    response = client.post("/auth/login", json=login_body(**{field: False}))
    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu."
    )


@pytest.mark.parametrize(
    "overrides",
    [{"email": ""}, {"email": "bukan-email"}, {"password": ""}],
)
def test_login_validates_form_fields(client: TestClient, overrides: dict[str, str]) -> None:
    response = client.post("/auth/login", json=login_body(**overrides))
    assert response.status_code == 422


def test_settings_require_jwt_secret_outside_development() -> None:
    settings_cls = type(get_settings())
    with pytest.raises(ValueError, match="JWT_SECRET_KEY"):
        settings_cls(app_env="production", _env_file=None)
    settings_cls(app_env="production", jwt_secret_key="x" * 48, _env_file=None)
