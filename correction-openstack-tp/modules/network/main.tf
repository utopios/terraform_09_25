# Création du réseau
resource "openstack_networking_network_v2" "network" {
  name           = var.network_name
  admin_state_up = true
}

# Création du sous-réseau
resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${var.network_name}-subnet"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
  enable_dhcp     = var.enable_dhcp
}

# Data source pour le réseau externe (conditionnel)
data "openstack_networking_network_v2" "external" {
  count = var.create_router ? 1 : 0
  name  = var.external_network_name
}

# Création du routeur (conditionnel)
resource "openstack_networking_router_v2" "router" {
  count               = var.create_router ? 1 : 0
  name                = "${var.network_name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external[0].id
}

# Interface entre le routeur et le sous-réseau (conditionnel)
resource "openstack_networking_router_interface_v2" "router_interface" {
  count     = var.create_router ? 1 : 0
  router_id = openstack_networking_router_v2.router[0].id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}
