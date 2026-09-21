#!/usr/bin/env bash

set -Eeuo pipefail

CLUSTER_NAME="notes-cluster"

if k3d cluster list --no-headers | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  printf 'El clúster %s ya existe; no se recrea.\n' "${CLUSTER_NAME}"
  kubectl config use-context "k3d-${CLUSTER_NAME}"
  BINDINGS="$(docker inspect "k3d-${CLUSTER_NAME}-serverlb" --format '{{json .HostConfig.PortBindings}}' 2>/dev/null || true)"
  if [[ "${BINDINGS}" != *'18443'* ]]; then
    printf 'ADVERTENCIA: el clúster existente no publica 18443; no se modifica.\n' >&2
    printf 'Usá: kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 18444:443\n' >&2
  else
    printf 'Mapeo HTTPS 18443 verificado en el load balancer de k3d.\n'
  fi
  exit 0
fi

# El Ingress usa 18080 para HTTP y 18443 para HTTPS. Grafana y Prometheus
# se consultan mediante port-forward, como indica devops-tp12/README.md.
for port in 18080 18443; do
  if ss -ltnH "sport = :${port}" | grep -q .; then
    printf 'ERROR: el puerto %s está ocupado. No se crea el clúster.\n' "${port}" >&2
    ss -ltnp "sport = :${port}" >&2 || true
    exit 1
  fi
done

k3d cluster create "${CLUSTER_NAME}" \
  --servers 1 \
  --agents 2 \
  --k3s-arg '--disable=traefik@server:*' \
  -p '127.0.0.1:18080:80@loadbalancer' \
  -p '127.0.0.1:18443:443@loadbalancer' \
  --wait

kubectl config use-context "k3d-${CLUSTER_NAME}"
kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl get nodes -o wide
