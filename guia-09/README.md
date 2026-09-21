# TP09 — Notes App en Kubernetes

Despliega PostgreSQL, backend y frontend en el namespace `devops-portfolio` mediante Deployments, Services, ConfigMap, Secret y PVC.

## Requisitos

- Un clúster Kubernetes accesible con `kubectl`.
- Imágenes del backend y frontend disponibles.

Antes de desplegar, reemplazá `TU_USUARIO` en los manifiestos por tu usuario de Docker Hub.

## Desplegar y verificar

Desde `guia-09/`:

```bash
bash scripts/deploy.sh
bash scripts/verificar.sh
kubectl get all,pvc,configmap,secret -n devops-portfolio
```

La aplicación se expone mediante el NodePort `30080`.

Comandos útiles:

```bash
kubectl logs -l app=backend -n devops-portfolio --tail=100
kubectl scale deployment backend --replicas=3 -n devops-portfolio
kubectl rollout undo deployment/backend -n devops-portfolio
```

Las credenciales incluidas son valores de laboratorio, no secretos reales.
