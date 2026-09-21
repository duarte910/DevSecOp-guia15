# ============================================
# main.tf — Orquestación de módulos
# TP 11 — Plan DevOps
# ============================================

# ── Módulo de redes ───────────────────────────────────────
module "network" {
  source = "./modules/network"

  project_name      = var.project_name
  environment       = var.environment
  app_subnet        = var.network_subnet
  monitoring_subnet = var.monitoring_subnet
}

# ── Módulo de almacenamiento ──────────────────────────────
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

# ── Módulo de la app ──────────────────────────────────────
# Depende de network y storage
module "app" {
  source = "./modules/app"

  project_name      = var.project_name
  environment       = var.environment
  postgres_image    = var.postgres_image
  backend_image     = var.backend_image
  frontend_image    = var.frontend_image
  postgres_db       = var.postgres_db
  postgres_password = var.postgres_password
  backend_port      = var.backend_port
  backend_replicas  = var.backend_replicas
  frontend_port     = var.frontend_port

  # Outputs del módulo network usados como inputs del módulo app
  app_network_name     = module.network.app_network_name
  postgres_volume_name = module.storage.postgres_volume_name
}
