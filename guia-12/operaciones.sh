#!/usr/bin/env bash
set -Eeuo pipefail
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; r="$B/resultado/ultimo.log"; mkdir -p "$(dirname "$r")"; case ${1:-} in iniciar|verificar|reiniciar) "$B/scripts/verificar.sh" | tee "$r";; detener) echo 'Guía 12: no existen servicios permanentes.';; estado) find "$B/portfolio" -type f -printf '%P\n' | sort;; logs) test -f "$r" && cat "$r" || echo 'Sin reporte';; *) exit 64;; esac

