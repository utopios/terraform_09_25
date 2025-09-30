output "environment" {
  description = "Environnement déployé"
  value       = var.environment
}

output "project_name" {
  description = "Nom du projet"
  value       = var.project_name
}

# ========================================
# OUTPUTS RÉSEAUX
# ========================================

output "networks_info" {
  description = "Informations sur les réseaux créés"
  value = {
    for tier, network in module.networks : tier => {
      network_id   = network.network_id
      subnet_id    = network.subnet_id
      subnet_cidr  = network.subnet_cidr
      network_name = network.network_name
    }
  }
}

# ========================================
# OUTPUTS SECURITY GROUPS
# ========================================

output "security_groups" {
  description = "Groupes de sécurité créés"
  value = {
    for tier, sg in module.security_groups : tier => {
      id   = sg.security_group_id
      name = sg.security_group_name
    }
  }
}

# ========================================
# OUTPUTS WEB TIER
# ========================================

output "web_tier" {
  description = "Informations sur les instances web"
  value = {
    instance_count = local.web_config.count
    flavor         = local.web_config.flavor
    instance_ids   = module.web_instances.instance_ids
    instance_names = module.web_instances.instance_names
    instance_ips   = module.web_instances.instance_ips
  }
}

# ========================================
# OUTPUTS APP TIER
# ========================================

output "app_tier" {
  description = "Informations sur les instances application"
  value = {
    instance_count = local.app_config.count
    flavor         = local.app_config.flavor
    instance_ids   = module.app_instances.instance_ids
    instance_names = module.app_instances.instance_names
    instance_ips   = module.app_instances.instance_ips
  }
}

# ========================================
# OUTPUTS DATABASE TIER
# ========================================

output "db_tier" {
  description = "Informations sur les instances database"
  value = {
    instance_count = local.db_config.count
    flavor         = local.db_config.flavor
    instance_ids   = module.db_instances.instance_ids
    instance_names = module.db_instances.instance_names
    instance_ips   = module.db_instances.instance_ips
    volume_ids     = module.db_instances.volume_ids
  }
}

# ========================================
# OUTPUTS LOAD BALANCER
# ========================================

output "loadbalancer_info" {
  description = "Informations sur le load balancer (si créé)"
  value = local.enable_loadbalancer ? {
    id          = module.loadbalancer[0].loadbalancer_id
    name        = module.loadbalancer[0].loadbalancer_name
    vip_address = module.loadbalancer[0].loadbalancer_vip_address
  } : null
}

# ========================================
# OUTPUTS BACKUP VOLUMES
# ========================================

output "backup_volumes_info" {
  description = "Informations sur les volumes de backup (si créés)"
  value = local.create_backup_volumes ? {
    volume_ids   = module.backup_volumes[0].volume_ids
    volume_names = module.backup_volumes[0].volume_names
  } : null
}

# ========================================
# RÉSUMÉ DE LA CONFIGURATION
# ========================================

output "deployment_summary" {
  description = "Résumé du déploiement"
  value = {
    environment           = var.environment
    total_instances       = local.web_config.count + local.app_config.count + local.db_config.count
    web_instances         = local.web_config.count
    app_instances         = local.app_config.count
    db_instances          = local.db_config.count
    loadbalancer_enabled  = local.enable_loadbalancer
    backup_volumes_count  = local.create_backup_volumes ? local.db_config.count : 0
    networks_created      = length(keys(module.networks))
    security_groups_created = length(keys(module.security_groups))
  }
}
