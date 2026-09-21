#!/usr/bin/env bash
set -Eeuo pipefail
BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; python3 -m venv "$BASE_DIR/.venv"; "$BASE_DIR/.venv/bin/pip" -q install -r "$BASE_DIR/backend/requirements-dev.txt"; chmod +x "$BASE_DIR/operaciones.sh"

