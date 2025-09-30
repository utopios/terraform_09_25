output "volume_ids" {
  description = "Liste des IDs des volumes"
  value       = openstack_blockstorage_volume_v3.volume[*].id
}

output "volume_names" {
  description = "Liste des noms des volumes"
  value       = openstack_blockstorage_volume_v3.volume[*].name
}
