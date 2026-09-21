#!/usr/bin/env bash
set -Eeuo pipefail
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; chmod +x "$B/operaciones.sh" "$B/scripts/verificar.sh"; "$B/scripts/verificar.sh"

