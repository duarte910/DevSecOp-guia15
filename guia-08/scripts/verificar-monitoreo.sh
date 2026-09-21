#!/bin/bash

set -uo pipefail
ERRORS=0
ok()   { echo "  [OK]   $1"; }
fail() { echo "  [FAIL] $1"; ERRORS=$((ERRORS+1)); }

echo "=== Verificación del stack de monitoreo ==="
echo ""

echo "--- Servicios ---"
for svc in notes-backend prometheus grafana node-exporter cadvisor; do
    ST=$(docker inspect --format='{{.State.Status}}' "$svc" 2>/dev/null || echo "no encontrado")
    [ "$ST" = "running" ] && ok "$svc" || fail "$svc → $ST"
done

echo ""
echo "--- Endpoints ---"
for url in \
    "http://localhost:9090/-/healthy Prometheus" \
    "http://localhost:3000/api/health Grafana" \
    "http://localhost:9100/metrics Node-Exporter"; do
    TARGET=$(echo $url | awk '{print $1}')
    NAME=$(echo $url | awk '{print $2}')
    CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$TARGET" 2>/dev/null || echo "000")
    [ "$CODE" = "200" ] && ok "$NAME → HTTP $CODE" || fail "$NAME → HTTP $CODE"
done

echo ""
echo "--- Targets en Prometheus ---"
python3 - << 'PYEOF'
import urllib.request, json
try:
    with urllib.request.urlopen("http://localhost:9090/api/v1/targets", timeout=5) as r:
        data = json.loads(r.read())
    for t in data["data"]["activeTargets"]:
        job  = t["labels"].get("job","?")
        health = t["health"]
        icon = "[OK]  " if health == "up" else "[FAIL]"
        print(f"  {icon} {job} → {health}")
except Exception as e:
    print(f"  [FAIL] No se pudo consultar Prometheus: {e}")
PYEOF

echo ""
[ "$ERRORS" -eq 0 ] && echo "Stack de monitoreo OK" || echo "$ERRORS servicios con problemas"
