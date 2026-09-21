output "postgres_volume_name" {
  value = docker_volume.postgres_data.name
}

output "grafana_volume_name" {
  value = docker_volume.grafana_data.name
}

output "prometheus_volume_name" {
  value = docker_volume.prometheus_data.name
}
