#!/usr/bin/env bash
set -Eeuo pipefail
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; command -v terraform >/dev/null; command -v docker >/dev/null; chmod +x "$B/operaciones.sh" "$B/backend/entrypoint.sh"; cd "$B"; terraform fmt -recursive; terraform init -input=false; terraform validate

