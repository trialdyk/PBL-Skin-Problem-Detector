"""Tests for scan history persistence endpoints."""

from __future__ import annotations

import io
import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password
from app.models import User
from app.services import history_service

TINY_PNG = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f"
    b"\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82"
)


@pytest.fixture
def history_dir(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    monkeypatch.setenv("HISTORY_UPLOAD_DIR", str(tmp_path / "uploads"))
    from app.core.config import get_settings

    get_settings.cache_clear()
    yield tmp_path / "uploads"
    get_settings.cache_clear()


def _auth_for(db: Session, email: str = "other@example.com") -> dict[str, str]:
    user = User(
        email=email,
        password_hash=hash_password("password123"),
        full_name="Other",
        email_verified=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"Authorization": f"Bearer {create_access_token(str(user.id))}"}


def _create_payload() -> dict:
    interview = {
        "gender": "female",
        "age": 21,
        "uses_sunscreen": True,
        "skin_type": "combination",
        "unhealthy_food_often": False,
        "skipped": False,
    }
    return {
        "grade": "2",
        "grade_label": "Ringan",
        "model_id": "dermascan-custom-cnn-v1",
        "result_source": "ml",
        "top_label": "IGA2",
        "interview": json.dumps(interview),
        "aggregate": json.dumps({"grade": 2, "predictions": [0.1, 0.2, 0.5, 0.15, 0.05]}),
    }


def _files() -> dict:
    return {
        "front": ("front.png", io.BytesIO(TINY_PNG), "image/png"),
        "left": ("left.png", io.BytesIO(TINY_PNG), "image/png"),
        "right": ("right.png", io.BytesIO(TINY_PNG), "image/png"),
    }


def test_history_requires_auth(client: TestClient) -> None:
    response = client.get("/history")
    assert response.status_code == 401


def test_create_list_detail_photo_delete(
    client: TestClient,
    auth_header: dict[str, str],
    history_dir: Path,
) -> None:
    created = client.post(
        "/history",
        headers=auth_header,
        data=_create_payload(),
        files=_files(),
    )
    assert created.status_code == 201, created.text
    body = created.json()
    history_id = body["id"]
    assert body["grade"] == 2
    assert body["recommendation"]["status"] == "pending"
    assert body["photos"]["front"] == f"/history/{history_id}/photos/front"
    assert body["interview"]["age"] == 21

    listed = client.get("/history", headers=auth_header)
    assert listed.status_code == 200
    payload = listed.json()
    assert payload["total"] == 1
    assert payload["items"][0]["id"] == history_id

    detail = client.get(f"/history/{history_id}", headers=auth_header)
    assert detail.status_code == 200
    assert detail.json()["aggregate"]["grade"] == 2

    photo = client.get(f"/history/{history_id}/photos/front", headers=auth_header)
    assert photo.status_code == 200
    assert photo.content.startswith(b"\x89PNG")

    deleted = client.delete(f"/history/{history_id}", headers=auth_header)
    assert deleted.status_code == 200
    assert deleted.json()["deleted"] is True

    missing = client.get(f"/history/{history_id}", headers=auth_header)
    assert missing.status_code == 404


def test_history_ownership(
    client: TestClient,
    auth_header: dict[str, str],
    db: Session,
    history_dir: Path,
) -> None:
    created = client.post(
        "/history",
        headers=auth_header,
        data=_create_payload(),
        files=_files(),
    )
    history_id = created.json()["id"]
    other = _auth_for(db)

    assert client.get(f"/history/{history_id}", headers=other).status_code == 404
    assert client.get(f"/history/{history_id}/photos/left", headers=other).status_code == 404
    assert client.delete(f"/history/{history_id}", headers=other).status_code == 404


def test_create_rejects_bad_source(
    client: TestClient,
    auth_header: dict[str, str],
    history_dir: Path,
) -> None:
    data = _create_payload()
    data["result_source"] = "magic"
    response = client.post("/history", headers=auth_header, data=data, files=_files())
    assert response.status_code == 400
