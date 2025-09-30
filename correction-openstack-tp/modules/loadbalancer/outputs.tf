output "loadbalancer_id" {
  description = "ID du load balancer"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.id
}

output "loadbalancer_vip_address" {
  description = "Adresse VIP du load balancer"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.vip_address
}

output "loadbalancer_name" {
  description = "Nom du load balancer"
  value       = openstack_lb_loadbalancer_v2.loadbalancer.name
}
