# Provider => à l'intérieur du bloc terraform (configuration) 

terraform {
    required_providers {
        # aws = {
        #     source = "hashicorp/aws"
        #     version = "5.0"
        # }
    }
}

##Variables

variable "var-1" {
    type = string
    description = "var-1 type string"
    default = "default val of var 1"
    sensitive = true
}

locals {
  local-var = upper(var.var-1)
}

# Resources
# .....

resource "null_resource" "name-resource1" {
  ### propriétés
#   attribut1 = var.var-1
#   attribut2 = var.var-2
}

resource "null_resource" "resource2" {  
  #attribut2 = null_resource.name-resource1.id
}

resource "null_resource" "resource3" {
  depends_on = [ null_resource.name-resource1, null_resource.resource2 ]

  lifecycle {
    # prevent_destroy = true
    # create_before_destroy = true
    # ignore_changes = [ null_resource.resource3.id ]
    # replace_triggered_by = [ null_resource.name-resource1 ]
  }
}

# OUTPUT
####

output "value-of-var-1" {
  value = var.var-1
}

output "value-of-var-2" {
  value = var.var-2
}

output "output-local-var" {
  value = local.local-var
}

variable "list_of_strings" {
  description = "A list of strings"
  type        = list(string)
  default     = ["apple", "banana", "cherry"]
}
output "lengths_of_strings" {
  value = [for s in var.list_of_strings : length(s)]
}

