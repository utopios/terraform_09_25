
resource "openstack_images_image_v2" "ubuntu_image" {
  name             = "${var.project_name}-ubuntu-22-04"
  image_source_url = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"
  #web_download     = true
  verify_checksum  = true
  
  properties = {
    os_type    = "linux"
    os_distro  = "ubuntu"
    os_version = "22.04"
  }
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "${var.project_name}-ubuntu-22-04"
  most_recent = true
  depends_on = [openstack_images_image_v2.ubuntu_image]
}

# data "openstack_images_image_v2" "centos" {
#   name        = "CentOS Stream 9"
#   most_recent = true
# }

# # DATA SOURCE : Découvrir les flavors disponibles
# data "openstack_compute_flavor_v2" "small" {
#   name = "m1.small"
# }

# data "openstack_compute_flavor_v2" "medium" {
#   name = "m1.medium"
# }

# data "openstack_compute_flavor_v2" "large" {
#   name = "m1.large"
# }

# # DATA SOURCE : Découvrir les réseaux existants
# data "openstack_networking_network_v2" "external" {
#   name     = "external"
#   external = true
# }
