#!/usr/bin/env bash
# ============================================
# Despliega la Notes App integrada, el Ingress y el monitoreo
# en el laboratorio k3d local.
# ============================================

set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="notes-cluster"
CONTEXT="k3d-${CLUSTER_NAME}"
NAMESPACE="devops-portfolio"

"${PROJECT_DIR}/scripts/create-cluster.sh"
kubectl config use-context "${CONTEXT}"

# ── Construir e importar las imágenes al clúster k3d ──────
docker build -t notes-backend:tp14 "${PROJECT_DIR}/app/backend"
docker build -t notes-frontend:tp14 "${PROJECT_DIR}/app/frontend"
k3d image import -c "${CLUSTER_NAME}" notes-backend:tp14 notes-frontend:tp14

# ── Ingress controller (si no está instalado ya) ──────────
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx \
  --force-update >/dev/null
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.ingressClassResource.default=true \
  --wait --timeout 5m

# ── Chart de la app (TP10): postgres + backend + frontend + Ingress ──
# Sin --create-namespace: el chart ya define su propio namespace.yaml
# (ver README.md, sección "Notas").
helm upgrade --install mi-app "${PROJECT_DIR}/chart" \
  -f "${PROJECT_DIR}/values-local.yaml" \
  --wait --timeout 5m

# El tag local no cambia entre ejecuciones. Se reinician ambos Deployments
# para que los Pods carguen las imágenes recién importadas.
kubectl rollout restart deployment/backend deployment/frontend -n "${NAMESPACE}"

# ── Certificado TLS del Ingress ───────────────────────────
# El chart ya creó el namespace; el script valida el par y aplica el Secret.
"${PROJECT_DIR}/scripts/generate-tls-cert.sh"

kubectl rollout status deployment/backend -n "${NAMESPACE}" --timeout=180s
kubectl rollout status deployment/frontend -n "${NAMESPACE}" --timeout=180s

# ── Monitoreo (TP08): Prometheus/Grafana/NodeExporter/cAdvisor ───
# Todo en el namespace devops-portfolio, con RBAC propio (ServiceAccount +
# ClusterRole + ClusterRoleBinding) para que Prometheus descubra al backend
# por label (kubernetes_sd_configs), no por hostname fijo.
kubectl apply -f "${PROJECT_DIR}/monitoring-k8s-manifests.yaml"
kubectl rollout status deployment/prometheus -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/grafana -n "${NAMESPACE}" --timeout=120s
kubectl rollout status daemonset/node-exporter -n "${NAMESPACE}" --timeout=120s
kubectl rollout status daemonset/cadvisor -n "${NAMESPACE}" --timeout=120s

echo
echo "=== Pods ==="
kubectl get pods -n "${NAMESPACE}" -o wide
echo
echo "=== Ingress ==="
kubectl get ingress -n "${NAMESPACE}"
echo
echo "HTTPS de la app: https://devops-portfolio.local:18443/ (TLS termina en el Ingress)."
echo 'Probar HTTPS: curl --cacert certs/tls.crt --resolve devops-portfolio.local:18443:127.0.0.1 https://devops-portfolio.local:18443/health'
echo 'Comprobar restricción HTTP (esperado 308, sin -L): curl -o /dev/null -sS -w "%{http_code}\n" -H "Host: devops-portfolio.local" http://127.0.0.1:18080/health'
echo
echo "Prometheus y Grafana son Services ClusterIP (no se publican en el load balancer de k3d). Para acceder, en otra terminal:"
echo '  kubectl -n devops-portfolio port-forward svc/prometheus-service 19090:9090'
echo '  kubectl -n devops-portfolio port-forward svc/grafana-service 13000:3000    # admin / devops123'
