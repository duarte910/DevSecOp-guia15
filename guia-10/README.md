# TP10 — Helm e Ingress

Empaqueta la Notes App de TP09 como un chart de Helm con Ingress y HPA opcional.

## Requisitos

- Kubernetes, `kubectl` y Helm.
- Un Ingress Controller.
- Imágenes del backend y frontend disponibles.

Reemplazá `TU_USUARIO` en `devops-portfolio/values.yaml` antes de instalar.

## Validar e instalar

Desde `guia-10/`:

```bash
helm lint devops-portfolio -f values-dev.yaml
helm template mi-app devops-portfolio -f values-dev.yaml
helm install mi-app devops-portfolio -f values-dev.yaml
kubectl get all,ingress,pvc -n devops-portfolio
```

Rutas del Ingress:

- `/` → frontend.
- `/api` → backend.
- `/health` → backend.

Operaciones posteriores:

```bash
helm upgrade mi-app devops-portfolio -f values-dev.yaml
helm rollback mi-app 1
helm uninstall mi-app
```

El chart crea el namespace mediante una plantilla; no agregues `--create-namespace`.
