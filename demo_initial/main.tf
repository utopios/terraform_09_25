# Provider => à l'intérieur du bloc terraform (configuration) 

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.0"
        }
    }
}

##Variables

variable "var-1" {
    type = string
    description = "var-1 type string"
    default = "default val of var 1"
}

# Resources
# .....

resource "null_resource" "name-resource1" {
  ### propriétés
#   attribut1 = var.var-1
#   attribut2 = var.var-2
}

# OUTPUT
####

output "value-of-var-1" {
  value = var.var-1
}

output "value-of-var-2" {
  value = var.var-2
}