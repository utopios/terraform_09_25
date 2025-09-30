output "network_id" {
  description = "ID du réseau créé"
  value       = openstack_networking_network_v2.network.id
}

output "subnet_id" {
  description = "ID du sous-réseau créé"
  value       = openstack_networking_subnet_v2.subnet.id
}

output "subnet_cidr" {
  description = "CIDR du sous-réseau"
  value       = openstack_networking_subnet_v2.subnet.cidr
}

output "network_name" {
  description = "Nom du réseau"
  value       = openstack_networking_network_v2.network.name
}
