# TP06 — Docker Compose: Notes App

Aplicación con frontend Nginx, API Flask/Gunicorn y PostgreSQL.

## Requisito

- Docker con Docker Compose.

## Ejecutar

Desde `guia-06/`:

```bash
cp .env.example .env
docker compose up -d --build
./scripts/verificar.sh
```

La aplicación queda disponible en `http://localhost`. Para probarla:

```bash
curl http://localhost/health
curl http://localhost/api/notes
curl -X POST http://localhost/api/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"Primera nota","content":"Docker Compose funciona"}'
```

Para detenerla y borrar sus volúmenes:

```bash
docker compose down -v
```

`docker-compose.override.yml` habilita el desarrollo local y publica PostgreSQL en el host. Para omitirlo, usá `docker compose -f docker-compose.yml up -d --build`.
