"""End-to-end coverage for every path in ``backend/openapi.json``.

Run (from ``backend/``)::

    pytest tests/test_api_suite.py -v
    pytest -v                       # whole suite
"""

from __future__ import annotations

import io
import json
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.core.config import get_settings
from app.main import app
from app.models import User
from app.services import ml_service
from tests.conftest import DEMO_EMAIL, DEMO_PASSWORD, UNAUTHORIZED_DETAIL

OPENAPI_PATH = Path(__file__).resolve().parents[1] / "openapi.json"

# All routes currently documented — keep this list in sync with OpenAPI.
EXPECTED_PATHS = {
    "/auth/login",
    "/auth/register",
    "/auth/verify-email",
    "/auth/resend-verification",
    "/auth/google",
    "/users/status",
    "/items/status",
    "/ml/predict",
    "/health",
}

PROTECTED_PATHS = ("/users/status", "/items/status", "/ml/predict")


def _png(color: tuple[int, int, int] = (214, 176, 160), size: int = 32) -> bytes:
    """Tiny RGB PNG for multipart uploads (needs Pillow)."""
    Image = pytest.importorskip("PIL.Image", reason="install requirements-ml.txt for ML upload tests")
    buffer = io.BytesIO()
    Image.new("RGB", (size, size), color).save(buffer, format="PNG")
    return buffer.getvalue()


def login_body(**overrides: object) -> dict[str, object]:
    return {
        "email": DEMO_EMAIL,
        "password": DEMO_PASSWORD,
        "accepted_terms": True,
        "accepted_privacy": True,
        **overrides,
    }


def register_body(**overrides: object) -> dict[str, object]:
    return {
        "full_name": "Budi Santoso",
        "email": "budi@gmail.com",
        "password": "rahasia123",
        "accepted_terms": True,
        "accepted_privacy": True,
        **overrides,
    }


# ---------------------------------------------------------------------------
# Contract: OpenAPI lists every route we test below
# ---------------------------------------------------------------------------


def test_openapi_lists_all_current_api_paths() -> None:
    committed = json.loads(OPENAPI_PATH.read_text(encoding="utf-8"))
    live = app.openapi()
    assert set(committed["paths"]) == EXPECTED_PATHS
    assert set(live["paths"]) == EXPECTED_PATHS


# ---------------------------------------------------------------------------
# GET /health — public
# ---------------------------------------------------------------------------


def test_health_ok(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "dermascan-backend"}


# ---------------------------------------------------------------------------
# POST /auth/login — public
# ---------------------------------------------------------------------------


def test_login_success(client: TestClient) -> None:
    response = client.post("/auth/login", json=login_body())
    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["user"]["email"] == DEMO_EMAIL
    assert body["access_token"]
    assert body["expires_in"] == get_settings().jwt_expire_minutes * 60


def test_login_wrong_password(client: TestClient) -> None:
    response = client.post("/auth/login", json=login_body(password="salah"))
    assert response.status_code == 401
    assert response.json()["detail"] == "Email atau kata sandi salah. Periksa kembali."


def test_login_missing_consent(client: TestClient) -> None:
    response = client.post("/auth/login", json=login_body(accepted_terms=False))
    assert response.status_code == 400


def test_login_invalid_body(client: TestClient) -> None:
    response = client.post("/auth/login", json=login_body(email="bukan-email"))
    assert response.status_code == 422


# ---------------------------------------------------------------------------
# POST /auth/register — public
# ---------------------------------------------------------------------------


def test_register_success(client: TestClient, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("app.services.email_service.send_verification_code", lambda *a, **k: None)
    response = client.post("/auth/register", json=register_body())
    assert response.status_code == 201
    body = response.json()
    assert body["email"] == "budi@gmail.com"
    assert "access_token" not in body
    assert body["expires_in"] > 0


def test_register_duplicate_email(client: TestClient) -> None:
    response = client.post("/auth/register", json=register_body(email=DEMO_EMAIL))
    assert response.status_code == 409
    assert "sudah terdaftar" in response.json()["detail"]


def test_register_missing_consent(client: TestClient) -> None:
    response = client.post("/auth/register", json=register_body(accepted_privacy=False))
    assert response.status_code == 400


def test_register_short_password(client: TestClient) -> None:
    response = client.post("/auth/register", json=register_body(password="1234567"))
    assert response.status_code == 422


# ---------------------------------------------------------------------------
# POST /auth/google — public (Google verify mocked)
# ---------------------------------------------------------------------------


def test_google_login_success(client: TestClient) -> None:
    claims = {
        "sub": "google-sub-suite",
        "email": "google.user@gmail.com",
        "email_verified": True,
        "name": "Google User",
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
    assert response.json()["user"]["email"] == "google.user@gmail.com"
    assert response.json()["access_token"]


def test_google_login_missing_consent(client: TestClient) -> None:
    response = client.post(
        "/auth/google",
        json={
            "id_token": "header.payload.signature-long-enough",
            "accepted_terms": False,
            "accepted_privacy": True,
        },
    )
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# Protected routes — auth matrix
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("path", PROTECTED_PATHS)
def test_protected_routes_require_bearer(client: TestClient, path: str) -> None:
    if path == "/ml/predict":
        # Auth runs before image decode — any bytes are fine here.
        response = client.post(
            path,
            files=[("files", ("a.png", b"not-an-image", "image/png"))],
        )
    else:
        response = client.get(path)

    assert response.status_code == 401
    assert response.json()["detail"] == UNAUTHORIZED_DETAIL
    assert response.headers.get("www-authenticate") == "Bearer"


@pytest.mark.parametrize("path", ("/users/status", "/items/status"))
def test_protected_get_rejects_bad_token(client: TestClient, path: str) -> None:
    response = client.get(path, headers={"Authorization": "Bearer bukan.jwt.valid"})
    assert response.status_code == 401


def test_users_status_ok(client: TestClient, auth_header: dict[str, str]) -> None:
    response = client.get("/users/status", headers=auth_header)
    assert response.status_code == 200
    payload = response.json()
    assert payload["router"] == "users"
    assert payload["status"] == "registered"


def test_items_status_ok(client: TestClient, auth_header: dict[str, str]) -> None:
    response = client.get("/items/status", headers=auth_header)
    assert response.status_code == 200
    payload = response.json()
    assert payload["router"] == "items"
    assert payload["status"] == "registered"


def test_users_status_rejects_inactive_user(
    client: TestClient,
    demo_user: User,
    auth_header: dict[str, str],
) -> None:
    demo_user.is_active = False
    # session is the same as fixture db via identity map; flush through query
    from sqlalchemy.orm import object_session

    session = object_session(demo_user)
    assert session is not None
    session.commit()

    response = client.get("/users/status", headers=auth_header)
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# POST /ml/predict — protected
# ---------------------------------------------------------------------------


def test_ml_predict_requires_auth(client: TestClient) -> None:
    response = client.post(
        "/ml/predict",
        files=[("files", ("front.png", b"x", "image/png"))],
    )
    assert response.status_code == 401


def test_ml_predict_rejects_four_files(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    photo = _png()
    files = [("files", (f"p{i}.png", photo, "image/png")) for i in range(4)]
    response = client.post("/ml/predict", files=files, headers=auth_header)
    assert response.status_code == 400


def test_ml_predict_returns_503_when_model_missing(
    client: TestClient,
    auth_header: dict[str, str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def boom() -> None:
        raise ml_service.ModelUnavailableError("no model")

    monkeypatch.setattr(ml_service, "_load_interpreter", boom)
    response = client.post(
        "/ml/predict",
        files=[("files", ("front.png", _png(), "image/png"))],
        headers=auth_header,
    )
    assert response.status_code == 503


# ---------------------------------------------------------------------------
# Happy-path chain: register → login → use token on protected GETs
# ---------------------------------------------------------------------------


def test_full_auth_flow_then_protected_calls(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    codes: list[str] = []
    monkeypatch.setattr(
        "app.services.email_service.send_verification_code",
        lambda to, code, settings=None: codes.append(code),
    )
    registered = client.post(
        "/auth/register",
        json=register_body(email="flow@gmail.com", password="password1"),
    )
    assert registered.status_code == 201
    assert codes

    verified = client.post(
        "/auth/verify-email",
        json={"email": "flow@gmail.com", "code": codes[-1]},
    )
    assert verified.status_code == 200
    token = verified.json()["access_token"]

    login = client.post(
        "/auth/login",
        json=login_body(email="flow@gmail.com", password="password1"),
    )
    assert login.status_code == 200

    headers = {"Authorization": f"Bearer {token}"}
    assert client.get("/users/status", headers=headers).status_code == 200
    assert client.get("/items/status", headers=headers).status_code == 200
    assert client.get("/health").status_code == 200
