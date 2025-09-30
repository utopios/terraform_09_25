# Création des volumes
resource "openstack_blockstorage_volume_v3" "volume" {
  count       = var.volume_count
  name        = "${var.name_prefix}-${count.index + 1}"
  size        = var.volume_size
  volume_type = var.volume_type != "" ? var.volume_type : null
  metadata    = var.metadata
}
