variable "project_name" { type = string }
variable "environment" { type = string }
variable "app_subnet" {
  type    = string
  default = "172.20.0.0/16"
}
variable "monitoring_subnet" {
  type    = string
  default = "172.21.0.0/16"
}
