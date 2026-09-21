#!/usr/bin/env bash
set -uo pipefail
NS="devops-portfolio"
ERRORS=0
ok() { printf '  [OK]   %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; ERRORS=$((ERRORS + 1)); }
need() { command -v "$1" >/dev/null 2>&1 || { fail "Falta la herramienta $1"; return 1; }; }
query() {
  local label="$1"; shift
  if ! QUERY_OUTPUT=$("$@" 2>&1); then fail "$label: la consulta falló"; return 1; fi
  if [ -z "${QUERY_OUTPUT//[[:space:]]/}" ]; then fail "$label: consulta exitosa, sin recursos"; return 1; fi
}

echo "=== Verificación Kubernetes — TP09 ==="
need kubectl || { echo "$ERRORS checks fallaron"; exit 1; }
need curl || { echo "$ERRORS checks fallaron"; exit 1; }

if query "Nodos" kubectl get nodes --no-headers; then
  while read -r name status _; do [ "$status" = Ready ] && ok "Nodo $name → $status" || fail "Nodo $name → $status"; done <<<"$QUERY_OUTPUT"
fi
if query "Pods" kubectl get pods -n "$NS" --no-headers; then
  while read -r name ready status _; do [ "$status" = Running ] && ok "$name → $status ($ready)" || fail "$name → $status"; done <<<"$QUERY_OUTPUT"
fi
if query "Deployments" kubectl get deployments -n "$NS" --no-headers; then
  while read -r name ready _ desired _; do [ "$ready" = "$desired/$desired" ] && ok "$name → $ready" || fail "$name → $ready (esperado $desired/$desired)"; done <<<"$QUERY_OUTPUT"
fi
if query "Services" kubectl get svc -n "$NS" --no-headers; then
  while read -r name type _ _ port _; do ok "$name → $type ($port)"; done <<<"$QUERY_OUTPUT"
fi
if query "PVC" kubectl get pvc -n "$NS" --no-headers; then
  while read -r name status _ size _; do [ "$status" = Bound ] && ok "$name → $status ($size)" || fail "$name → $status"; done <<<"$QUERY_OUTPUT"
fi
if NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' 2>/dev/null) && [ -n "$NODE_IP" ]; then
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$NODE_IP:30080/" 2>/dev/null) || CODE=000
  [ "$CODE" = 200 ] && ok "Healthcheck HTTP $CODE" || fail "Healthcheck HTTP $CODE"
else fail "No se pudo obtener la IP para el healthcheck"; fi
[ "$ERRORS" -eq 0 ] && { echo "Cluster OK — todos los checks pasaron"; exit 0; }
echo "$ERRORS checks fallaron"; exit 1
