#!/usr/bin/env bash
set -Eeuo pipefail
BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; cd "$BASE_DIR"; export COMPOSE_PROJECT_NAME=operaciones1-guia06; [[ -f .env ]] || cp .env.example .env
if [[ ${OPERACIONES_GLOBAL:-0} == 1 ]]; then export FRONTEND_PORT=18006; else export FRONTEND_PORT=${FRONTEND_PORT:-80}; fi
port_free(){ ! ss -ltnH "sport = :$1" | grep -q .; }
case ${1:-} in iniciar) port_free "$FRONTEND_PORT" || docker compose ps --services --filter status=running | grep -q frontend || { echo "Puerto $FRONTEND_PORT ocupado; use FRONTEND_PORT=otro" >&2; ss -ltnp "sport = :$FRONTEND_PORT"; exit 1; }; docker compose up -d --build --wait;; detener) docker compose down;; reiniciar) "$BASE_DIR/operaciones.sh" detener; "$BASE_DIR/operaciones.sh" iniciar;; estado) docker compose ps;; verificar) docker compose config -q; "$BASE_DIR/scripts/verificar.sh" "http://127.0.0.1:$FRONTEND_PORT";; logs) docker compose logs --tail=100;; *) echo "Uso: $0 {iniciar|detener|reiniciar|estado|verificar|logs}" >&2; exit 64;; esac
