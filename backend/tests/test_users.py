"""Tests for the users router registration."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_users_router_status() -> None:
    response = client.get("/users/status")
    assert response.status_code == 200
    payload = response.json()
    assert payload["router"] == "users"
    assert payload["status"] == "registered"
