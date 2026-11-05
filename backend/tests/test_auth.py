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


@pytest.mark.parametrize("value", ["yes", "true", 1, "on", None])
@pytest.mark.parametrize("field", ["accepted_terms", "accepted_privacy"])
def test_login_consent_must_be_a_real_boolean(
    client: TestClient,
    field: str,
    value: object,
) -> None:
    response = client.post("/auth/login", json=login_body(**{field: value}))
    assert response.status_code == 422


def test_openapi_documents_login_responses(client: TestClient) -> None:
    operation = client.get("/openapi.json").json()["paths"]["/auth/login"]["post"]
    assert {"200", "400", "401", "422"} <= set(operation["responses"])
    schema = client.get("/openapi.json").json()["components"]["schemas"]["LoginRequest"]
    assert schema["examples"][0]["email"] == EMAIL


@pytest.mark.parametrize(
    "overrides",
    [
        {"email": ""},
        {"email": "bukan-email"},
        {"email": "a" * 251 + "@b.cc"},
        {"password": ""},
        {"password": "a" * 129},
    ],
)
def test_login_validates_form_fields(client: TestClient, overrides: dict[str, str]) -> None:
    response = client.post("/auth/login", json=login_body(**overrides))
    assert response.status_code == 422


def test_settings_require_jwt_secret_outside_development() -> None:
    settings_cls = type(get_settings())
    with pytest.raises(ValueError, match="JWT_SECRET_KEY"):
        settings_cls(app_env="production", _env_file=None)
    settings_cls(app_env="production", jwt_secret_key="x" * 48, _env_file=None)


# --- POST /auth/register ----------------------------------------------------

NEW_EMAIL = "budi@gmail.com"
NEW_PASSWORD = "rahasia123"


def register_body(**overrides: object) -> dict[str, object]:
    return {
        "full_name": "Budi Santoso",
        "email": NEW_EMAIL,
        "password": NEW_PASSWORD,
        "accepted_terms": True,
        "accepted_privacy": True,
        **overrides,
    }


def test_register_creates_account_and_returns_token(client: TestClient, db: Session) -> None:
    response = client.post("/auth/register", json=register_body())

    assert response.status_code == 201
    payload = response.json()
    assert payload["token_type"] == "bearer"
    assert payload["expires_in"] == get_settings().jwt_expire_minutes * 60
    assert payload["user"]["email"] == NEW_EMAIL
    assert payload["user"]["full_name"] == "Budi Santoso"
    assert "password_hash" not in payload["user"]

    settings = get_settings()
    claims = jwt.decode(
        payload["access_token"],
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
    )
    assert claims["sub"] == payload["user"]["id"]

    stored = db.query(User).filter_by(email=NEW_EMAIL).one()
    assert str(stored.id) == payload["user"]["id"]
    assert stored.is_active is True
    assert stored.password_hash != NEW_PASSWORD
    assert stored.password_hash.startswith("$argon2")


def test_registered_user_can_log_in(client: TestClient) -> None:
    client.post("/auth/register", json=register_body())

    response = client.post(
        "/auth/login",
        json=login_body(email=NEW_EMAIL, password=NEW_PASSWORD),
    )
    assert response.status_code == 200
    assert response.json()["user"]["email"] == NEW_EMAIL


def test_register_normalizes_email_and_name(client: TestClient, db: Session) -> None:
    response = client.post(
        "/auth/register",
        json=register_body(email="  Budi@Gmail.com ", full_name="  Budi  "),
    )

    assert response.status_code == 201
    assert response.json()["user"]["email"] == NEW_EMAIL
    assert response.json()["user"]["full_name"] == "Budi"
    assert db.query(User).filter_by(email=NEW_EMAIL).count() == 1


def test_register_full_name_is_optional(client: TestClient) -> None:
    body = register_body()
    del body["full_name"]

    response = client.post("/auth/register", json=body)

    assert response.status_code == 201
    assert response.json()["user"]["full_name"] is None


@pytest.mark.parametrize("email", [EMAIL, "PENGGUNA@GMAIL.COM", " pengguna@gmail.com "])
def test_register_duplicate_email_returns_409(
    client: TestClient,
    db: Session,
    email: str,
) -> None:
    response = client.post("/auth/register", json=register_body(email=email))

    assert response.status_code == 409
    assert response.json()["detail"] == "Email sudah terdaftar. Silakan masuk."
    assert db.query(User).count() == 1


def test_register_failed_duplicate_leaves_session_usable(
    client: TestClient,
    db: Session,
) -> None:
    client.post("/auth/register", json=register_body(email=EMAIL))

    response = client.post("/auth/register", json=register_body())

    assert response.status_code == 201
    assert db.query(User).count() == 2


@pytest.mark.parametrize("field", ["accepted_terms", "accepted_privacy"])
def test_register_requires_both_consents(client: TestClient, db: Session, field: str) -> None:
    response = client.post("/auth/register", json=register_body(**{field: False}))

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu."
    )
    assert db.query(User).count() == 1


def test_register_consent_is_checked_before_duplicate_email(client: TestClient) -> None:
    response = client.post(
        "/auth/register",
        json=register_body(email=EMAIL, accepted_terms=False),
    )
    assert response.status_code == 400


@pytest.mark.parametrize("value", ["yes", 1, None])
def test_register_consent_must_be_a_real_boolean(client: TestClient, value: object) -> None:
    response = client.post("/auth/register", json=register_body(accepted_terms=value))
    assert response.status_code == 422


@pytest.mark.parametrize(
    "overrides",
    [
        {"email": ""},
        {"email": "bukan-email"},
        {"password": ""},
        {"password": "1234567"},
        {"password": "a" * 129},
        {"full_name": ""},
        {"full_name": "   "},
        {"full_name": "a" * 256},
    ],
)
def test_register_validates_fields(
    client: TestClient,
    db: Session,
    overrides: dict[str, str],
) -> None:
    response = client.post("/auth/register", json=register_body(**overrides))

    assert response.status_code == 422
    assert db.query(User).count() == 1


@pytest.mark.parametrize("password", ["12345678", "a" * 128])
def test_register_accepts_password_length_limits(client: TestClient, password: str) -> None:
    response = client.post("/auth/register", json=register_body(password=password))
    assert response.status_code == 201


def test_openapi_documents_register_responses(client: TestClient) -> None:
    operation = client.get("/openapi.json").json()["paths"]["/auth/register"]["post"]
    assert {"201", "400", "409", "422"} <= set(operation["responses"])
