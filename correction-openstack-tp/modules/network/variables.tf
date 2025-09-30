variable "network_name" {
  description = "Nom du réseau"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR du sous-réseau"
  type        = string
}

variable "dns_nameservers" {
  description = "Liste des serveurs DNS"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "enable_dhcp" {
  description = "Activer DHCP"
  type        = bool
  default     = true
}

variable "create_router" {
  description = "Créer un routeur pour ce réseau"
  type        = bool
  default     = false
}

variable "external_network_name" {
  description = "Nom du réseau externe (requis si create_router = true)"
  type        = string
  default     = ""
}
