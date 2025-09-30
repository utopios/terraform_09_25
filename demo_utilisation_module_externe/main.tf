terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}

provider "openstack" {
  auth_url    = var.auth_url
  user_name   = var.user_name
  password    = var.password
  tenant_name = var.tenant_name
  region      = "RegionOne"
  domain_name = "Default"
}

variable "auth_url" {
  type = string
  description = "auth url"
  # sensitive = true
}
variable "user_name" {}
variable "password" {}
variable "tenant_name" {}

module "network" {
    source = "git::https://github.com/utopios/terraform_network_module.git"
    network_name = "network_demo"
    subnet_name = "sub_net_demo"
    cidr = "10.0.1.0/24"
    user_name = var.user_name
    password = var.password
    tenant_name = var.tenant_name
    auth_url = var.auth_url
}

output "network_output" {
    value = {
        network_id = module.network.network_id
        subnet_id = module.network.subnet_id
    }
}