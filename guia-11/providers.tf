# ============================================
# providers.tf — Configuración del provider
# TP11 — Plan DevOps Operaciones1
# ============================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # En producción el state va en S3, GCS o Terraform Cloud
  # Para este ejercicio usamos local
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {
  # Conecta al Docker daemon local via socket
  host = "unix:///var/run/docker.sock"
}
