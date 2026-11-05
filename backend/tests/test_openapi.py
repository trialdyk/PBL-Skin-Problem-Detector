"""Ensure the committed OpenAPI snapshot stays in sync with the running app."""

from __future__ import annotations

import json
from pathlib import Path

from app.main import app

OPENAPI_PATH = Path(__file__).resolve().parents[1] / "openapi.json"


def test_committed_openapi_matches_app() -> None:
    assert OPENAPI_PATH.is_file(), (
        "Missing backend/openapi.json. Run: python scripts/export_openapi.py"
    )
    committed = json.loads(OPENAPI_PATH.read_text(encoding="utf-8"))
    live = app.openapi()
    assert committed == live, (
        "backend/openapi.json is stale. After changing routers/schemas/"
        "openapi_tags, run: python scripts/export_openapi.py"
    )
