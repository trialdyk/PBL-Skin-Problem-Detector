"""Tests for the FastAPI application entry point."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_app_importable() -> None:
    assert app is not None
    assert app.title


def test_health_returns_ok() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["service"] == "dermascan-backend"


def test_unknown_route_returns_404() -> None:
    response = client.get("/this-route-does-not-exist")
    assert response.status_code == 404
