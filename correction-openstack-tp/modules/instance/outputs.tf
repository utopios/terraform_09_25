output "instance_ids" {
  description = "Liste des IDs des instances"
  value       = openstack_compute_instance_v2.instance[*].id
}

output "instance_ips" {
  description = "Liste des IPs privées des instances"
  value       = openstack_compute_instance_v2.instance[*].access_ip_v4
}

output "volume_ids" {
  description = "Liste des IDs des volumes (si créés)"
  value       = var.create_volume ? openstack_blockstorage_volume_v3.volume[*].id : []
}

output "instance_names" {
  description = "Liste des noms des instances"
  value       = openstack_compute_instance_v2.instance[*].name
}
