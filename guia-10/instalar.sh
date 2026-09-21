#!/usr/bin/env bash
set -Eeuo pipefail
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; for c in docker k3d kubectl helm jq; do command -v "$c" >/dev/null; done; chmod +x "$B/operaciones.sh" "$B/scripts/verificar.sh" "$B/backend/entrypoint.sh"; helm lint "$B/devops-portfolio"; helm template operaciones1-guia10 "$B/devops-portfolio" -f "$B/values-dev.yaml" >/dev/null
