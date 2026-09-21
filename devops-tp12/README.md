# Base integrada TP12 — Notes App

Esta es la aplicación integrada hasta TP12 que se audita con Semgrep en TP15. Incluye frontend, backend, PostgreSQL, Helm, Ingress, TLS y monitoreo de Kubernetes.

## Arquitectura

- `/` → frontend Nginx.
- `/api` y `/health` → backend Flask.
- Backend → PostgreSQL mediante la red interna del clúster.
- Prometheus consulta al backend, Node Exporter, cAdvisor y API Server.
- Grafana usa Prometheus como datasource.
- TLS termina en el Ingress.

## Desplegar

Desde `devops-tp12/`, comprobá primero que estás usando el laboratorio correcto:

```bash
kubectl config current-context
k3d cluster list
docker context show
```

El contexto esperado es `k3d-notes-cluster`. Si aparece otro, no continúes.

```bash
./scripts/deploy.sh
```

El script crea o reutiliza el clúster, construye las imágenes, instala el chart y aplica `monitoring-k8s-manifests.yaml`.

Para aplicar solamente el monitoreo:

```bash
kubectl apply -f monitoring-k8s-manifests.yaml
kubectl get all -n devops-portfolio -l component=monitoring
kubectl get configmap,pvc,serviceaccount -n devops-portfolio
```

## Comprobar HTTPS

```bash
curl --cacert certs/tls.crt \
  --resolve devops-portfolio.local:18443:127.0.0.1 \
  https://devops-portfolio.local:18443/health
```

No uses `-k`: desactiva la validación del certificado. Para el navegador, agregá `127.0.0.1 devops-portfolio.local` a `/etc/hosts` y abrí `https://devops-portfolio.local:18443/`.

Si un clúster existente no publica el puerto 18443, usá otra terminal:

```bash
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 18444:443
```

Luego repetí el `curl` usando el puerto `18444` tanto en `--resolve` como en la URL.

## Comprobar la aplicación

```bash
curl --cacert certs/tls.crt --resolve devops-portfolio.local:18443:127.0.0.1 https://devops-portfolio.local:18443/api/notes
curl --cacert certs/tls.crt --resolve devops-portfolio.local:18443:127.0.0.1 -H 'Content-Type: application/json' -d '{"title":"prueba","content":"TP15"}' https://devops-portfolio.local:18443/api/notes
```

La API permite listar, crear y eliminar notas. Una creación sin `title` debe responder HTTP 400.

## Validaciones locales

```bash
helm lint chart -f values-local.yaml
helm template mi-app chart -f values-local.yaml >/tmp/devops-tp12-rendered.yaml
python3 -m pytest app/backend/tests -v
bash -n scripts/*.sh
```

Los certificados se generan localmente dentro de `certs/`. Esa carpeta está ignorada y no debe subirse a Git.
