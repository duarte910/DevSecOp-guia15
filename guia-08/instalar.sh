#!/usr/bin/env bash
set -Eeuo pipefail
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; command -v docker >/dev/null; [[ -f "$B/.env" ]] || cp "$B/.env.example" "$B/.env"; chmod +x "$B"/operaciones.sh "$B"/scripts/*.sh "$B"/backend/entrypoint.sh; (cd "$B" && COMPOSE_PROJECT_NAME=operaciones1-guia08 docker compose config -q)

