output "app_network_id" {
  description = "ID de la red principal de la app"
  value       = docker_network.app_network.id
}

output "app_network_name" {
  description = "Nombre de la red principal"
  value       = docker_network.app_network.name
}

output "monitoring_network_id" {
  description = "ID de la red de monitoreo"
  value       = docker_network.monitoring_network.id
}

output "monitoring_network_name" {
  description = "Nombre de la red de monitoreo"
  value       = docker_network.monitoring_network.name
}
