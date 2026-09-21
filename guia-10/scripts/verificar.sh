#!/usr/bin/env bash
set -uo pipefail
NS="devops-portfolio"; RELEASE="${RELEASE:-mi-app}"; ERRORS=0
ok() { printf '  [OK]   %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; ERRORS=$((ERRORS + 1)); }
need() { command -v "$1" >/dev/null 2>&1 || { fail "Falta la herramienta $1"; return 1; }; }
query() { local label="$1"; shift; if ! QUERY_OUTPUT=$("$@" 2>&1); then fail "$label: la consulta falló"; return 1; fi; if [ -z "${QUERY_OUTPUT//[[:space:]]/}" ]; then fail "$label: consulta exitosa, sin recursos"; return 1; fi; }

echo "=== Verificación Helm + Ingress — TP10 ==="
for tool in helm kubectl curl; do need "$tool" || { echo "$ERRORS checks fallaron"; exit 1; }; done
if STATUS=$(helm status "$RELEASE" 2>/dev/null | awk '/STATUS/{print $2}') && [ -n "$STATUS" ]; then [ "$STATUS" = deployed ] && ok "Release $RELEASE → $STATUS" || fail "Release $RELEASE → $STATUS"; else fail "Release $RELEASE no encontrado"; fi
if query "Pods" kubectl get pods -n "$NS" --no-headers; then while read -r name ready status _; do [ "$status" = Running ] && ok "$name → $status ($ready)" || fail "$name → $status"; done <<<"$QUERY_OUTPUT"; fi
if query "Ingress" kubectl get ingress -n "$NS" --no-headers; then while read -r name _ host _; do ok "$name → host: $host"; done <<<"$QUERY_OUTPUT"; fi
INGRESS_URL="${INGRESS_URL:-http://127.0.0.1:${K3D_INGRESS_PORT:-8090}}"; INGRESS_HOST="${INGRESS_HOST:-devops-portfolio.dev}"
for path in / /health /api/notes; do CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "Host: $INGRESS_HOST" --max-time 5 "$INGRESS_URL$path" 2>/dev/null) || CODE=000; [ "$CODE" = 200 ] && ok "$path → HTTP $CODE" || fail "$path → HTTP $CODE"; done
[ "$ERRORS" -eq 0 ] && { echo "TP 10 OK"; exit 0; }; echo "$ERRORS checks fallaron"; exit 1
