# ============================================
# outputs.tf — Valores de salida
# Visibles tras terraform apply
# ============================================

output "app_url" {
  description = "URL de la aplicación"
  value       = module.app.frontend_url
}

output "app_network" {
  description = "Nombre de la red Docker de la app"
  value       = module.network.app_network_name
}

output "monitoring_network" {
  description = "Nombre de la red Docker de monitoreo"
  value       = module.network.monitoring_network_name
}

output "postgres_volume" {
  description = "Nombre del volumen de Postgres"
  value       = module.storage.postgres_volume_name
}

output "backend_containers" {
  description = "IDs de los contenedores del backend"
  value       = module.app.backend_container_ids
}

output "infrastructure_summary" {
  description = "Resumen de la infraestructura creada"
  value = {
    environment = var.environment
    project     = var.project_name
    app_url     = module.app.frontend_url
    replicas    = var.backend_replicas
    managed_by  = "terraform"
  }
}
