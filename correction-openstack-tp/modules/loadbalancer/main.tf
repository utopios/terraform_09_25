# Création du load balancer
resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
  name          = var.name
  vip_subnet_id = var.subnet_id
}

# Création du listener
resource "openstack_lb_listener_v2" "listener" {
  name            = "${var.name}-listener"
  protocol        = var.protocol
  protocol_port   = var.service_port
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
}

# Création du pool
resource "openstack_lb_pool_v2" "pool" {
  name        = "${var.name}-pool"
  protocol    = var.protocol
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener.id
}

# Création des members avec for_each
resource "openstack_lb_member_v2" "member" {
  for_each = toset(var.backend_instance_ips)

  pool_id       = openstack_lb_pool_v2.pool.id
  address       = each.value
  protocol_port = var.service_port
  subnet_id     = var.subnet_id
}

# Health monitor (conditionnel)
resource "openstack_lb_monitor_v2" "monitor" {
  count = var.enable_health_check ? 1 : 0

  pool_id     = openstack_lb_pool_v2.pool.id
  type        = var.protocol
  delay       = 5
  timeout     = 3
  max_retries = 3
  url_path    = var.protocol == "HTTP" ? "/" : null
}
