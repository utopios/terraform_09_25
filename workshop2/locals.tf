locals {
  # Convention de nommage standardisée
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Tags communs à toutes les ressources
  common_tags = {
    Environment  = var.environment
    Project      = var.project_name
    ManagedBy    = "terraform"
    Owner        = "platform-team"
    CreatedAt    = timestamp()
  }
  
  # Convertir les tags en metadata OpenStack
  common_metadata = {
    for k, v in local.common_tags : 
    lower(k) => tostring(v)
  }
}