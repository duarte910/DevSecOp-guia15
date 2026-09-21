# Backend heredado del pipeline

Esta carpeta conserva la aplicación usada en los jobs `lint`, `test` y `build-push` del pipeline anterior. Se mantiene porque TP14 agrega el análisis de amenazas al workflow existente; no reemplaza sus etapas.

La aplicación que se modela y se despliega en TP14 está en `../devops-tp12/`. Para realizar la guía, volvé al [`README.md`](../README.md) de la raíz.

## Prueba local

Desde esta carpeta:

```bash
cp .env.example .env
docker compose config --quiet
docker compose up -d --build
curl http://localhost/health
```

Para ejecutar los tests sin Compose:

```bash
cd backend
python3 -m pip install -r requirements.txt
python3 -m pytest tests -v --cov=. --cov-report=term-missing
```

El workflow se encuentra en `../.github/workflows/cicd.yml`. La publicación en Docker Hub requiere los Secrets `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`. No hay un despliegue remoto configurado.
