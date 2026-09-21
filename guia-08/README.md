# TP08 — Prometheus y Grafana

Agrega métricas a la Notes App y despliega Prometheus, Grafana, Node Exporter y cAdvisor con Docker Compose.

## Requisitos

- Docker con Docker Compose.
- Puertos 80, 3000 y 9090 libres.

## Ejecutar

Desde `guia-08/`:

```bash
cp .env.example .env
docker compose up -d --build
bash scripts/verificar-monitoreo.sh
```

Accesos:

- Notes App: `http://localhost`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000` (`admin` / `devops123`)

El dashboard incluye ocho paneles de solicitudes, latencia, errores, notas, CPU y memoria. Las reglas disponibles son `AppDown`, `HighCPU`, `HighErrorRate` y `DiskSpaceLow`.

Para generar datos de prueba:

```bash
bash scripts/generar-trafico.sh
```

Para detener el entorno:

```bash
docker compose down
```
