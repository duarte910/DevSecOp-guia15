#!/bin/bash

set -uo pipefail
ERRORS=0
ok()   { echo "  [OK]   $1"; }
fail() { echo "  [FAIL] $1"; ERRORS=$((ERRORS+1)); }

echo "=== Verificación Terraform — TP11 ==="
echo ""

echo "--- Terraform state ---"
if terraform state list 2>/dev/null | grep -q "module"; then
    COUNT=$(terraform state list 2>/dev/null | wc -l)
    ok "$COUNT recursos en el state"
else
    fail "State vacío o no inicializado"
fi

echo ""
echo "--- Redes Docker (creadas por Terraform) ---"
for net in app monitoring; do
    NAME=$(docker network ls --filter "label=managed-by=terraform" \
      --filter "label=environment=dev" \
      --format "{{.Name}}" | grep $net || echo "")
    [ -n "$NAME" ] && ok "Red $net → $NAME" || fail "Red $net no encontrada"
done

echo ""
echo "--- Volúmenes Docker ---"
for vol in postgres grafana prometheus; do
    NAME=$(docker volume ls --filter "label=managed-by=terraform" \
      --format "{{.Name}}" | grep $vol || echo "")
    [ -n "$NAME" ] && ok "Volumen $vol → $NAME" || fail "Volumen $vol no encontrado"
done

echo ""
echo "--- Contenedores ---"
for svc in postgres backend frontend; do
    NAME=$(docker ps --filter "label=managed-by=terraform" \
      --filter "status=running" \
      --format "{{.Names}}" | grep $svc || echo "")
    [ -n "$NAME" ] && ok "Contenedor $svc → running" || fail "Contenedor $svc no está running"
done

echo ""
echo "--- Outputs de Terraform ---"
APP_URL=$(terraform output -raw app_url 2>/dev/null || echo "")
[ -n "$APP_URL" ] && ok "app_url → $APP_URL" || fail "Output app_url no disponible"

echo ""
# Devuelve un código distinto de cero si alguna comprobación falló.
if [ "$ERRORS" -eq 0 ]; then
    echo "Infraestructura OK"
    exit 0
else
    echo "$ERRORS recursos con problemas"
    exit 1
fi
