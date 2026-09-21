#!/bin/bash

# ============================================
# healthcheck.sh — Verifica el stack completo
# ============================================

set -uo pipefail
BASE_URL="${1:-http://localhost}"

ok()   { echo "  [OK]   $1"; }
fail() { echo "  [FAIL] $1"; ERRORS=$((ERRORS+1)); }
ERRORS=0

echo "=== Healthcheck del stack Docker Compose ==="
echo ""

echo "--- Servicios Docker ---"
for svc in notes-db notes-backend notes-frontend; do
    STATUS=$(docker inspect --format='{{.State.Status}}' "$svc" 2>/dev/null || echo "no encontrado")
    if [ "$STATUS" = "running" ]; then
        ok "$svc → running"
    else
        fail "$svc → $STATUS"
    fi
done

echo ""
echo "--- Endpoints HTTP ---"

HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$BASE_URL/health" 2>/dev/null || echo "000")
[ "$HTTP" = "200" ] && ok "GET /health → $HTTP" || fail "GET /health → $HTTP"

HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$BASE_URL/api/notes" 2>/dev/null || echo "000")
[ "$HTTP" = "200" ] && ok "GET /api/notes → $HTTP" || fail "GET /api/notes → $HTTP"

HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$BASE_URL/" 2>/dev/null || echo "000")
[ "$HTTP" = "200" ] && ok "GET / (frontend) → $HTTP" || fail "GET / (frontend) → $HTTP"

echo ""
echo "--- DB desde backend ---"
DB_STATUS=$(curl -s "$BASE_URL/health" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('db','?'))" 2>/dev/null || echo "?")
[ "$DB_STATUS" = "connected" ] && ok "Postgres → $DB_STATUS" || fail "Postgres → $DB_STATUS"

echo ""
[ "$ERRORS" -eq 0 ] && echo "Stack OK — todos los checks pasaron" || echo "$ERRORS checks fallaron"
