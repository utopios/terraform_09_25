# Création du groupe de sécurité
resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = var.name
  description = var.description
}

# Création des règles avec for_each
resource "openstack_networking_secgroup_rule_v2" "rules" {
  for_each = var.rules

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = each.value.port
  port_range_max    = each.value.port
  remote_ip_prefix  = each.value.cidr
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}
