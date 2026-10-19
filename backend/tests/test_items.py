"""Tests for the items router registration."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_items_router_status() -> None:
    response = client.get("/items/status")
    assert response.status_code == 200
    payload = response.json()
    assert payload["router"] == "items"
    assert payload["status"] == "registered"
