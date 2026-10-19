#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

PORT="${PORT:-8000}"

# Prefer project virtualenv over system Python (avoids Python 3.14 / missing deps).
if [[ -x "${ROOT_DIR}/.venv/Scripts/python.exe" ]]; then
  PYTHON="${ROOT_DIR}/.venv/Scripts/python.exe"
elif [[ -x "${ROOT_DIR}/.venv/bin/python" ]]; then
  PYTHON="${ROOT_DIR}/.venv/bin/python"
elif command -v python >/dev/null 2>&1; then
  PYTHON="python"
else
  PYTHON="python3"
fi

exec "${PYTHON}" -m uvicorn app.main:app --reload --host 127.0.0.1 --port "${PORT}"
