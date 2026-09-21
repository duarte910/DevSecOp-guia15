# TP15 — Semgrep como SAST sobre el proyecto de TP12

## Objetivo

En esta guía vas a agregar análisis estático de seguridad (SAST) al repositorio integrado de TP12. Semgrep revisará en una misma ejecución Python/Flask, los Dockerfiles, Terraform, Kubernetes y Helm.

También vas a generar un reporte JSON, publicarlo como artefacto de GitHub Actions, escribir un resumen, integrar opcionalmente SARIF con la pestaña **Security** y agregar un control estricto tipo **Andon Cord**.

## Punto de partida incluido

Este repositorio ya contiene la base necesaria hasta TP12:

```text
.
├── .github/workflows/cicd.yml       # pipeline anterior; no hay que borrarlo
├── devops-tp12/                     # aplicación integrada que se audita
│   ├── app/backend/                 # Python y Dockerfile
│   ├── app/frontend/                # Nginx y Dockerfile
│   ├── chart/                       # Helm
│   └── monitoring-k8s-manifests.yaml
├── guia-11/                         # Terraform
└── guia-06/ ... guia-12/            # antecedentes completos
```

El trabajo se hace desde la raíz del repositorio. No hace falta reconstruir los TP anteriores ni crear otra aplicación.

## Requisitos

- Git y una cuenta/repositorio en GitHub.
- Python 3 y soporte para entornos virtuales.
- Conexión a Internet para instalar Semgrep y descargar sus reglas.
- Helm, porque el workflow renderiza el chart antes de analizarlo.
- `jq` y `yamllint` para las comprobaciones locales.
- Docker y Terraform son recomendables para comprobar la base completa, pero no son necesarios para ejecutar Semgrep.

Comprobá el punto de partida:

```bash
pwd
test -f devops-tp12/app/backend/app.py
test -f devops-tp12/app/backend/Dockerfile
test -f devops-tp12/app/frontend/Dockerfile
test -d devops-tp12/chart/templates
test -f guia-11/main.tf
test -f .github/workflows/cicd.yml
```

## Paso 1 — Probar Semgrep localmente

Instalá Semgrep dentro de un entorno virtual para no mezclar sus dependencias con las del sistema:

```bash
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install semgrep
semgrep --version
```

Ejecutá el análisis automático desde la raíz:

```bash
semgrep scan --config=auto --exclude=.venv --exclude='**/.terraform/**' .
```

Semgrep descarga reglas del Registry la primera vez. Un hallazgo debe analizarse y documentarse; un error de análisis indica que algún archivo o regla no se pudo procesar.

## Paso 2 — Crear el workflow

Creá `.github/workflows/semgrep.yml` sin modificar ni eliminar `cicd.yml`:

```yaml
name: DevSecOps - Semgrep SAST Scan

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:

permissions:
  contents: read
  security-events: write

jobs:
  semgrep-scan:
    name: SAST Scan Multilenguaje
    runs-on: ubuntu-latest

    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Preparar Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Instalar Semgrep
        run: python3 -m pip install semgrep

      - name: Renderizar Helm para el análisis
        run: |
          mkdir -p .semgrep-tmp
          helm template tp15 devops-tp12/chart \
            -f devops-tp12/values-local.yaml \
            > .semgrep-tmp/helm-rendered.yaml

      - name: Ejecutar Semgrep y generar JSON
        run: |
          semgrep scan \
            --config=p/owasp-top-ten \
            --config=p/python \
            --config=p/dockerfile \
            --config=p/terraform \
            --config=p/kubernetes \
            --json --output=semgrep-results.json \
            devops-tp12/app \
            devops-tp12/monitoring-k8s-manifests.yaml \
            guia-11 .semgrep-tmp || true

      - name: Resumen de Auditoría SAST
        if: always()
        shell: bash
        run: |
          test -s semgrep-results.json || printf '{"results":[],"errors":[]}' > semgrep-results.json
          total=$(jq '.results | length' semgrep-results.json)
          errores=$(jq '[.results[] | select(.extra.severity == "ERROR")] | length' semgrep-results.json)
          warnings=$(jq '[.results[] | select(.extra.severity == "WARNING")] | length' semgrep-results.json)
          errores_scan=$(jq '.errors | length' semgrep-results.json)
          {
            echo "### Reporte de Análisis Estático SAST (Semgrep)"
            echo
            echo "| Capa auditada | Reglas aplicadas | Estado |"
            echo "|---|---|---|"
            echo "| Backend Python | OWASP Top 10 + Python | Completado |"
            echo "| Contenedores | Dockerfile | Completado |"
            echo "| IaC | Terraform | Completado |"
            echo "| Orquestación | Kubernetes + Helm/YAML | Completado |"
            echo
            echo "Hallazgos: **${total}**; ERROR: **${errores}**; WARNING: **${warnings}**."
            echo "Incidencias del analizador: **${errores_scan}**."
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Subir artefacto de resultados
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: semgrep-report
          path: semgrep-results.json
          retention-days: 7

      - name: Generar reporte SARIF
        run: |
          semgrep scan --config=auto \
            --sarif --output=semgrep.sarif \
            devops-tp12/app \
            devops-tp12/monitoring-k8s-manifests.yaml \
            guia-11 .semgrep-tmp || true

      - name: Cargar resultados a GitHub Code Scanning
        if: always() && hashFiles('semgrep.sarif') != ''
        continue-on-error: true
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: semgrep.sarif

      - name: Guard estricto de seguridad (Andon Cord)
        run: |
          semgrep scan --config=p/owasp-top-ten \
            --severity=ERROR --error \
            devops-tp12/app \
            devops-tp12/chart \
            devops-tp12/monitoring-k8s-manifests.yaml \
            guia-11
```

El workflow usa reglas para OWASP Top 10, Python, Dockerfile, Terraform y Kubernetes. Antes del análisis renderiza el chart de Helm para convertir sus templates en manifiestos YAML válidos.

## Paso 3 — Entender los dos niveles de exigencia

- El análisis informativo termina en `|| true`: genera evidencia aunque encuentre vulnerabilidades.
- El último paso no usa `|| true` y combina `--severity=ERROR --error`: si existe un hallazgo grave, el job falla y detiene la integración.

No agregues `continue-on-error` al Andon Cord. Si el guard falla, corregí el código o justificá un ajuste de regla; no ocultes el código de salida.

## Paso 4 — Validar antes de subir

```bash
yamllint -d relaxed .github/workflows/semgrep.yml

mkdir -p .semgrep-tmp
helm template tp15 devops-tp12/chart \
  -f devops-tp12/values-local.yaml \
  > .semgrep-tmp/helm-rendered.yaml

semgrep scan \
  --config=p/owasp-top-ten \
  --config=p/python \
  --config=p/dockerfile \
  --config=p/terraform \
  --config=p/kubernetes \
  --json --output=semgrep-results.json \
  devops-tp12/app \
  devops-tp12/monitoring-k8s-manifests.yaml \
  guia-11 .semgrep-tmp

python3 -m json.tool semgrep-results.json >/dev/null
jq '.results | length' semgrep-results.json
jq -r '.results[] | [.extra.severity, .check_id, .path] | @tsv' semgrep-results.json
```

El reporte local es generado y no se versiona.

## Paso 5 — Ejecutar en GitHub

```bash
git add .github/workflows/semgrep.yml
git commit -m "Agregar Semgrep SAST al pipeline"
git push origin develop
```

En GitHub verificá:

1. **Actions** → `DevSecOps - Semgrep SAST Scan`.
2. En el resumen, la tabla de las cuatro capas y la cantidad de hallazgos.
3. En **Artifacts**, `semgrep-report`, con retención de 7 días.
4. Si Code Scanning está habilitado, **Security** → **Code scanning alerts**.
5. Que el Andon Cord quede verde sin hallazgos `ERROR` y rojo si se introduce deliberadamente uno.

La carga SARIF puede no estar disponible en algunos repositorios privados. Por eso ese paso admite error; el JSON, el resumen, el artefacto y el Andon Cord siguen siendo obligatorios.

## Entrega sugerida

- `.github/workflows/semgrep.yml` versionado.
- Captura o enlace del run exitoso.
- `semgrep-report` descargado desde el run.
- Captura del `$GITHUB_STEP_SUMMARY`.
- Si se prueba el Andon Cord, evidencia del fallo controlado y luego un commit que retire la vulnerabilidad de prueba.

## Problemas frecuentes

| Problema | Causa probable | Solución |
|---|---|---|
| `semgrep: command not found` | El entorno virtual no está activo | Ejecutá `. .venv/bin/activate` |
| No se descargan reglas | Falta de red/proxy | Comprobá conectividad y repetí el scan |
| No aparece el artefacto | El JSON no se creó | Conservá `if: always()` y el JSON vacío de respaldo |
| SARIF falla | Code Scanning no habilitado/permisos | Revisá `security-events: write`; la carga es opcional |
| El workflow falla en el guard | Hay un hallazgo `ERROR` | Leé ruta/regla, corregí y volvé a ejecutar |
| Se analizaron miles de archivos | Se incluyó `.venv` o `.terraform` | Conservá ambos `--exclude` |

## Limpieza local

```bash
deactivate 2>/dev/null || true
rm -f semgrep-results.json semgrep.sarif
```

No borres el entorno virtual si pensás repetir la práctica; `.venv/` está ignorado por Git.
