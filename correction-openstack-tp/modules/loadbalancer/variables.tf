variable "name" {
  description = "Nom du load balancer"
  type        = string
}

variable "subnet_id" {
  description = "ID du sous-réseau"
  type        = string
}

variable "backend_instance_ids" {
  description = "Liste des IDs des instances backend"
  type        = list(string)
}

variable "backend_instance_ips" {
  description = "Liste des IPs des instances backend"
  type        = list(string)
}

variable "service_port" {
  description = "Port du service"
  type        = number
  default     = 80
}

variable "protocol" {
  description = "Protocole (HTTP, HTTPS, TCP)"
  type        = string
  default     = "HTTP"
}

variable "enable_health_check" {
  description = "Activer le health check"
  type        = bool
  default     = true
}
