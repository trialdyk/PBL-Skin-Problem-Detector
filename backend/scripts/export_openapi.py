"""Export the live FastAPI OpenAPI schema to backend/openapi.json.

Run from the backend/ directory (or any cwd; the script resolves the project root):

    python scripts/export_openapi.py

Agents and developers must regenerate this file whenever routers, schemas,
response models, or openapi_tags change. docs/api.md and human docs must follow
this JSON — not the other way around.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.main import app  # noqa: E402

OUT = ROOT / "openapi.json"


def main() -> None:
    schema = app.openapi()
    OUT.write_text(
        json.dumps(schema, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    paths = ", ".join(sorted(schema.get("paths", {})))
    print(f"Wrote {OUT.relative_to(ROOT)} ({len(schema.get('paths', {}))} paths: {paths})")


if __name__ == "__main__":
    main()
