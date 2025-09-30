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


resource "openstack_compute_instance_v2" "test_vm" {
  name            = "terraform-vm"
  flavor_name     = "m1.tiny"
  image_name      = "cirros-0.6.3-x86_64-disk"
  security_groups = ["default"]

  network {
    name = "private"
  }
  provisioner "local-exec" {
    command = "echo The vm was correctly created"
  }

  provisioner "file" {
    source = "source_file.sh"
    destination = "terraform_provisionner.sh"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = ""
      script_path = "terraform_provisionner.sh"
    }
  }
}

data "openstack_compute_flavor_v2" "small" {
  vcpus = 1
  ram   = 512
  disk = 5
}

resource "openstack_networking_network_v2" "example_network" {
  name = "example-network"
}
resource "openstack_networking_subnet_v2" "example_subnet" {
  name = "example-subnet"
  network_id = openstack_networking_network_v2.example_network.id
  cidr = "192.0.0.0/16"
}

output "flavor-small" {
  value       = data.openstack_compute_flavor_v2.small.name
}

