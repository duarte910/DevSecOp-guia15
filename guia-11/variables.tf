# ============================================
# variables.tf — Declaración de variables
# ============================================

variable "environment" {
  description = "Entorno de deployment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El entorno debe ser dev, staging o prod."
  }
}

variable "project_name" {
  description = "Nombre del proyecto (prefijo para todos los recursos)"
  type        = string
  default     = "devops-portfolio"
}

# ── Base de datos ─────────────────────────────────────────
variable "postgres_image" {
  description = "Imagen de Postgres"
  type        = string
  default     = "postgres:16-alpine"
}

variable "postgres_password" {
  description = "Contraseña de Postgres"
  type        = string
  sensitive   = true # no se muestra en logs ni en plan
  default     = "devops123"
}

variable "postgres_db" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "notesdb"
}

# ── Backend ───────────────────────────────────────────────
variable "backend_image" {
  description = "Imagen del backend Flask"
  type        = string
  default     = "python:3.12-slim"
}

variable "backend_port" {
  description = "Puerto del backend"
  type        = number
  default     = 5000
}

variable "backend_replicas" {
  description = "Número de contenedores del backend"
  type        = number
  default     = 1

  validation {
    condition     = var.backend_replicas >= 1 && var.backend_replicas <= 5
    error_message = "Las réplicas deben estar entre 1 y 5."
  }
}

# ── Frontend ──────────────────────────────────────────────
variable "frontend_image" {
  description = "Imagen del frontend Nginx"
  type        = string
  default     = "nginx:alpine"
}

variable "frontend_port" {
  description = "Puerto expuesto del frontend en el host"
  type        = number
  default     = 8080
}

# ── Networking ────────────────────────────────────────────
variable "network_subnet" {
  description = "Subnet de la red principal de la app"
  type        = string
  default     = "172.20.0.0/16"
}

variable "monitoring_subnet" {
  description = "Subnet de la red de monitoreo"
  type        = string
  default     = "172.21.0.0/16"
}
