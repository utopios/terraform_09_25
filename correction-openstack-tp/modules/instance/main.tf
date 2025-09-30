# Data sources pour flavor et image
data "openstack_compute_flavor_v2" "flavor" {
  name = var.flavor_name
}

data "openstack_images_image_v2" "image" {
  name        = var.image_name
  most_recent = true
}

# Création des instances
resource "openstack_compute_instance_v2" "instance" {
  count           = var.instance_count
  name            = "${var.name_prefix}-${count.index + 1}"
  flavor_id       = data.openstack_compute_flavor_v2.flavor.id
  image_id        = data.openstack_images_image_v2.image.id
  security_groups = var.security_group_ids

  metadata = var.metadata

  network {
    uuid = var.network_id
  }
}

# Création des volumes (conditionnel)
resource "openstack_blockstorage_volume_v3" "volume" {
  count = var.create_volume ? var.instance_count : 0
  name  = "${var.name_prefix}-volume-${count.index + 1}"
  size  = var.volume_size
}

# Attachement des volumes (conditionnel)
resource "openstack_compute_volume_attach_v2" "attachments" {
  count       = var.create_volume ? var.instance_count : 0
  instance_id = openstack_compute_instance_v2.instance[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.volume[count.index].id
}
