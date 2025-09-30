variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "L'environnement doit être 'dev' ou 'prod'."
  }
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "multi-tier-app"
}

variable "openstack_user_name" {
  description = "Nom d'utilisateur OpenStack"
  type        = string
}

variable "openstack_password" {
  description = "Mot de passe OpenStack"
  type        = string
  sensitive   = true
}

variable "openstack_auth_url" {
  description = "URL d'authentification OpenStack"
  type        = string
}

variable "openstack_region" {
  description = "Région OpenStack"
  type        = string
  default     = "RegionOne"
}

variable "openstack_tenant_name" {
  description = "Nom du tenant/project OpenStack"
  type        = string
}

variable "image_name" {
  description = "Nom de l'image à utiliser"
  type        = string
  default     = "Ubuntu-20.04"
}

variable "external_network_name" {
  description = "Nom du réseau externe pour les IP flottantes"
  type        = string
  default     = "public"
}
