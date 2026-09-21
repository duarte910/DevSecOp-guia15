#!/usr/bin/env bash
set -Eeuo pipefail
BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; command -v docker >/dev/null || { echo 'Falta Docker' >&2; exit 69; }; docker compose version >/dev/null; [[ -f "$BASE_DIR/.env" ]] || cp "$BASE_DIR/.env.example" "$BASE_DIR/.env"; chmod +x "$BASE_DIR"/operaciones.sh "$BASE_DIR"/scripts/*.sh "$BASE_DIR"/backend/entrypoint.sh; (cd "$BASE_DIR" && COMPOSE_PROJECT_NAME=operaciones1-guia06 docker compose config -q)

