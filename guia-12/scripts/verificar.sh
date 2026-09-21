#!/usr/bin/env bash
set -Eeuo pipefail
# Comprueba los archivos que forman el portfolio y su workflow.
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"; for f in portfolio/README.md portfolio/MATRIZ_PROYECTOS.md portfolio/docs/profile-readme.md portfolio/.github/workflows/portfolio-check.yml; do test -s "$B/$f"; done; grep -q 'DevOps Portfolio' "$B/portfolio/README.md"; echo 'Portfolio local verificado; repos externos no requeridos.'
