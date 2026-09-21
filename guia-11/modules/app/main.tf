# ============================================
# modules/app/main.tf
# Crea los contenedores Docker de la app
# ============================================

# ── Imágenes (pull desde registry) ───────────────────────
resource "docker_image" "postgres" {
  name         = var.postgres_image
  keep_locally = true # no borrar la imagen al destroy
}

resource "docker_image" "backend" {
  name         = var.backend_image
  keep_locally = true
}

resource "docker_image" "frontend" {
  name         = var.frontend_image
  keep_locally = true
}

# ── Contenedor Postgres ───────────────────────────────────
resource "docker_container" "postgres" {
  name  = "${var.project_name}-postgres-${var.environment}"
  image = docker_image.postgres.image_id

  restart = "unless-stopped"

  env = [
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ]

  # Montar el volumen persistente
  volumes {
    volume_name    = var.postgres_volume_name
    container_path = "/var/lib/postgresql/data"
  }

  # Conectar a la red de la app
  networks_advanced {
    name    = var.app_network_name
    aliases = ["postgres"] # hostname dentro de la red
  }

  # Healthcheck interno
  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U postgres"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "20s"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "environment"
    value = var.environment
  }
  labels {
    label = "managed-by"
    value = "terraform"
  }
}

# ── Contenedor Backend ────────────────────────────────────
resource "docker_container" "backend" {
  count = var.backend_replicas
  name  = "${var.project_name}-backend-${var.environment}-${count.index}"
  image = docker_image.backend.image_id

  restart = "unless-stopped"

  # El backend depende de Postgres
  depends_on = [docker_container.postgres]

  env = [
    "DB_HOST=postgres",
    "DB_PORT=5432",
    "DB_NAME=${var.postgres_db}",
    "DB_USER=postgres",
    "DB_PASSWORD=${var.postgres_password}",
    "APP_ENV=${var.environment}",
    "PORT=${var.backend_port}",
  ]

  # Solo exponer el puerto del primer contenedor al host
  dynamic "ports" {
    for_each = count.index == 0 ? [1] : []
    content {
      internal = var.backend_port
      external = var.backend_port
    }
  }

  networks_advanced {
    name    = var.app_network_name
    aliases = ["backend-${count.index}"]
  }

  healthcheck {
    # La imagen ya incluye Python; se usa urllib para consultar /health
    # sin agregar curl al contenedor.
    test         = ["CMD-SHELL", "python3 -c \"import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:${var.backend_port}/health', timeout=3).status==200 else 1)\" || exit 1"]
    interval     = "15s"
    timeout      = "5s"
    retries      = 3
    start_period = "30s"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "environment"
    value = var.environment
  }
  labels {
    label = "managed-by"
    value = "terraform"
  }
  labels {
    label = "replica"
    value = tostring(count.index)
  }
}

# ── Contenedor Frontend ───────────────────────────────────
resource "docker_container" "frontend" {
  name  = "${var.project_name}-frontend-${var.environment}"
  image = docker_image.frontend.image_id

  restart = "unless-stopped"

  depends_on = [docker_container.backend]

  ports {
    internal = 80
    external = var.frontend_port
  }

  networks_advanced {
    name    = var.app_network_name
    aliases = ["frontend"]
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget -q --spider http://localhost/ || exit 1"]
    interval     = "15s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "environment"
    value = var.environment
  }
  labels {
    label = "managed-by"
    value = "terraform"
  }
}
