variable "project_name" { type = string }
variable "environment" { type = string }
variable "postgres_image" { type = string }
variable "backend_image" { type = string }
variable "frontend_image" { type = string }
variable "postgres_db" { type = string }
variable "postgres_password" {
  type      = string
  sensitive = true
}
variable "backend_port" { type = number }
variable "backend_replicas" { type = number }
variable "frontend_port" { type = number }
variable "app_network_name" { type = string }
variable "postgres_volume_name" { type = string }
