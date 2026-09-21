#!/bin/bash

# ============================================
# deploy.sh — Aplica todos los manifests en orden
# TP09 — Plan DevOps
# ============================================

set -euo pipefail

NAMESPACE="devops-portfolio"
MANIFEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/manifests"

log()  { echo "[$(date '+%H:%M:%S')] $1"; }
ok()   { echo "  [OK]   $1"; }
fail() { echo "  [FAIL] $1"; exit 1; }

log "=== Deploy Kubernetes — DevOps Portfolio ==="

# 1. Namespace
log "Aplicando namespace..."
kubectl apply -f "$MANIFEST_DIR/base/"
ok "Namespace listo"

# 2. Base de datos (primero porque backend depende de ella)
log "Aplicando base de datos..."
kubectl apply -f "$MANIFEST_DIR/db/"
log "Esperando que Postgres esté listo..."
kubectl rollout status deployment/postgres \
  -n "$NAMESPACE" --timeout=90s
ok "Postgres listo"

# 3. Backend
log "Aplicando backend..."
kubectl apply -f "$MANIFEST_DIR/backend/"
kubectl rollout status deployment/backend \
  -n "$NAMESPACE" --timeout=90s
ok "Backend listo"

# 4. Frontend
log "Aplicando frontend..."
kubectl apply -f "$MANIFEST_DIR/frontend/"
kubectl rollout status deployment/frontend \
  -n "$NAMESPACE" --timeout=60s
ok "Frontend listo"

# 5. Resumen
log ""
log "=== Estado final ==="
kubectl get all -n "$NAMESPACE"

log ""
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
log "App disponible en: http://$NODE_IP:30080"
