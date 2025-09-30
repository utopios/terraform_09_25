variable "instance_count" {
  description = "Nombre d'instances à créer"
  type        = number
  default     = 1
}

variable "name_prefix" {
  description = "Préfixe du nom des instances"
  type        = string
}

variable "flavor_name" {
  description = "Nom du flavor"
  type        = string
}

variable "image_name" {
  description = "Nom de l'image"
  type        = string
}

variable "network_id" {
  description = "ID du réseau"
  type        = string
}

variable "security_group_ids" {
  description = "Liste des IDs des groupes de sécurité"
  type        = list(string)
  default     = []
}

variable "metadata" {
  description = "Metadata pour les instances"
  type        = map(string)
  default     = {}
}

variable "create_volume" {
  description = "Créer un volume supplémentaire"
  type        = bool
  default     = false
}

variable "volume_size" {
  description = "Taille du volume en GB"
  type        = number
  default     = 10
}
