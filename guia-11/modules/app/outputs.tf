output "postgres_container_id" {
  value = docker_container.postgres.id
}

output "backend_container_ids" {
  value = [for c in docker_container.backend : c.id]
}

output "frontend_container_id" {
  value = docker_container.frontend.id
}

output "frontend_url" {
  value = "http://localhost:${var.frontend_port}"
}
