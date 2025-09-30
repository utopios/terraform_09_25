variable "cloud_name" {
  type        = string
  description = "Nom du cloud dans clouds.yaml"
  default     = "openstack"
}

variable "environment" {
  type        = string
  description = "Environnement (dev, staging, prod)"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment doit être dev, staging ou prod."
  }
}

variable "project_name" {
  type        = string
  description = "Nom du projet pour le naming"
  default     = "admin"
}