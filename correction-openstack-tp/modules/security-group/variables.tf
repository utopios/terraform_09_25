variable "name" {
  description = "Nom du groupe de sécurité"
  type        = string
}

variable "description" {
  description = "Description du groupe de sécurité"
  type        = string
}

variable "rules" {
  description = "Map des règles de sécurité"
  type = map(object({
    port     = number
    protocol = string
    cidr     = string
  }))
  default = {}
}
