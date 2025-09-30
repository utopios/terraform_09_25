output "security_group_id" {
  description = "ID du groupe de sécurité"
  value       = openstack_networking_secgroup_v2.secgroup.id
}

output "security_group_name" {
  description = "Nom du groupe de sécurité"
  value       = openstack_networking_secgroup_v2.secgroup.name
}
