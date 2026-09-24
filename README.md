# TP15 — Semgrep como SAST sobre el proyecto de TP12

## Objetivo

En esta guía se agregará un análisis estático de seguridad (SAST) al repositorio integrado de TP12. Semgrep revisará en una misma ejecución Python/Flask, los Dockerfiles, Terraform, Kubernetes y Helm.

Adicionalmente se generará un reporte JSON que se publicará como artefacto de GitHub Actions, se escribirá un resumen, se integrará opcionalmente SARIF con la pestaña **Security** y se agregará un control estricto tipo **Andon Cord**.

## Punto de partida incluido

El punto de partida es el respositorio suministrado por la cátedra [Repositorio trabajo 15](https://github.com/operaciones2-unahur/trabajo-15)

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

El trabajo se realiza desde la raíz del repositorio. No es necesario reconstruir los TP anteriores ni crear otra aplicación.

## Requisitos

- Git y una cuenta/repositorio en GitHub.
- Python 3 y soporte para entornos virtuales.
- Conexión a Internet para instalar Semgrep y descargar sus reglas.
- Helm, porque el workflow renderiza el chart antes de analizarlo.
- `jq` y `yamllint` para las comprobaciones locales.
- Docker y Terraform son recomendables para comprobar la base completa, pero no son necesarios para ejecutar Semgrep.

Verificación del punto de partida:

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
<img width="1083" height="75" alt="image" src="https://github.com/user-attachments/assets/fe8fca3d-92d1-43a2-a2d5-cfc55bc67bf5" />

Ejecutá el análisis automático desde la raíz:

```bash
semgrep scan --config=auto --exclude=.venv --exclude='**/.terraform/**' .
```

Semgrep descarga reglas del Registry la primera vez. Un hallazgo debe analizarse y documentarse; un error de análisis indica que algún archivo o regla no se pudo procesar.

Se verifica que el escaneo de realiza de forma correcta.

## Paso 2 — Creación del workflow

Crear `.github/workflows/semgrep.yml` sin modificar ni eliminar `cicd.yml`:

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

No agregar `continue-on-error` al Andon Cord. Si el guard falla, se debe corregir el código o justificar un ajuste de regla; no se debe ocultar el código de salida.

En este caso, hemos incorporado el modo de bloqueo estricto. Un fallo grave detendrá la integración contínua. 

```bash
- name: Guard estricto de seguridad (Andon Cord)
        run: |
          semgrep scan --config=p/owasp-top-ten \
            --severity=ERROR --error \
            devops-tp12/app \
            devops-tp12/chart \
            devops-tp12/monitoring-k8s-manifests.yaml \
            guia-11
```

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

El reporte local es generado y no se versiona. Se verifica que no se han generados errors graves por lo cual el andon cord no detendrá el despliegue. 

```bash
(.venv) tduarte@DESK-MATI-01:~/Documentos/Operaciones-1-guia-hecha/guia-15$ python3 -m json.tool semgrep-results.json >/dev/null
jq '.results | length' semgrep-results.json
jq -r '.results[] | [.extra.severity, .check_id, .path] | @tsv' semgrep-results.json
20
WARNING python.flask.security.audit.app-run-param-config.avoid_app_run_with_bad_host    devops-tp12/app/backend/app.py
WARNING generic.nginx.security.request-host-used.request-host-used      devops-tp12/app/frontend/nginx.conf
INFO    yaml.kubernetes.security.run-as-non-root.run-as-non-root        devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.allow-privilege-escalation-no-securitycontext.allow-privilege-escalation-no-securitycontext    devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.writable-filesystem-container.writable-filesystem-container    devops-tp12/monitoring-k8s-manifests.yaml
INFO    yaml.kubernetes.security.run-as-non-root.run-as-non-root        devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.allow-privilege-escalation-no-securitycontext.allow-privilege-escalation-no-securitycontext    devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.writable-filesystem-container.writable-filesystem-container    devops-tp12/monitoring-k8s-manifests.yaml
INFO    yaml.kubernetes.security.run-as-non-root.run-as-non-root        devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.hostnetwork-pod.hostnetwork-pod        devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.hostpid-pod.hostpid-pod        devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.writable-filesystem-container.writable-filesystem-container    devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.allow-privilege-escalation.allow-privilege-escalation  devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.privileged-container.privileged-container      devops-tp12/monitoring-k8s-manifests.yaml
INFO    yaml.kubernetes.security.run-as-non-root.run-as-non-root        devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.writable-filesystem-container.writable-filesystem-container    devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.allow-privilege-escalation.allow-privilege-escalation  devops-tp12/monitoring-k8s-manifests.yaml
WARNING yaml.kubernetes.security.privileged-container.privileged-container      devops-tp12/monitoring-k8s-manifests.yaml
WARNING python.flask.security.audit.app-run-param-config.avoid_app_run_with_bad_host    guia-11/backend/app.py
WARNING generic.nginx.security.request-host-used.request-host-used      guia-11/frontend/nginx.conf

```



## Paso 5 — Ejecutar en GitHub

```bash
git add .github/workflows/semgrep.yml
git commit -m "Agregar Semgrep SAST al pipeline"
git push origin main
```

En GitHub verificá:

1. **Actions** → `DevSecOps - Semgrep SAST Scan`.

<img width="1659" height="530" alt="image" src="https://github.com/user-attachments/assets/e0f34fd2-a3fd-4289-82c1-6ece3e3618b3" />

2. En el resumen, la tabla de las cuatro capas y la cantidad de hallazgos.

<img width="775" height="785" alt="image" src="https://github.com/user-attachments/assets/789d064b-9e40-4972-a8ec-a71b5cd6589d" />
 
3. En **Artifacts**, `semgrep-report`, con retención de 7 días.

<img width="1554" height="224" alt="image" src="https://github.com/user-attachments/assets/54c36bcd-23bf-41f4-b377-9a6781a33279" />

4. **Security** → **Code scanning alerts**.

<img width="1755" height="875" alt="image" src="https://github.com/user-attachments/assets/dc7c0059-7542-4578-a0f8-33a088e76a65" />
   
5. Que el Andon Cord quede verde sin hallazgos `ERROR`

<img width="1022" height="868" alt="image" src="https://github.com/user-attachments/assets/b227e7fc-3735-4a36-a7b8-403fa00ae8df" />




