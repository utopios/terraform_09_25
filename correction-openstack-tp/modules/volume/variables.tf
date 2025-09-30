variable "volume_count" {
  description = "Nombre de volumes à créer"
  type        = number
  default     = 1
}

variable "name_prefix" {
  description = "Préfixe du nom des volumes"
  type        = string
}

variable "volume_size" {
  description = "Taille du volume en GB"
  type        = number
}

variable "volume_type" {
  description = "Type de volume"
  type        = string
  default     = ""
}

variable "metadata" {
  description = "Metadata pour les volumes"
  type        = map(string)
  default     = {}
}
