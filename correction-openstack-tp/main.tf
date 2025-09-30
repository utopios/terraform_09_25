provider "openstack" {
  user_name   = var.openstack_user_name
  password    = var.openstack_password
  auth_url    = var.openstack_auth_url
  region      = var.openstack_region
  tenant_name = var.openstack_tenant_name
}

# ========================================
# LOCALS - Configuration conditionnelle
# ========================================

locals {
  # Configuration par tier selon l'environnement
  web_config = {
    count  = var.environment == "prod" ? 2 : 1
    flavor = var.environment == "prod" ? "m1.medium" : "m1.small"
  }

  app_config = {
    count  = var.environment == "prod" ? 3 : 1
    flavor = var.environment == "prod" ? "m1.medium" : "m1.small"
  }

  db_config = {
    count         = var.environment == "prod" ? 2 : 1
    flavor        = var.environment == "prod" ? "m1.medium" : "m1.small"
    create_volume = var.environment == "prod" ? true : false
    volume_size   = 20
  }

  # Activer le load balancer seulement en prod
  enable_loadbalancer = var.environment == "prod" ? true : false

  # Créer des volumes de backup seulement en prod
  create_backup_volumes = var.environment == "prod" ? true : false

  # Configuration des réseaux
  networks_config = {
    web = {
      cidr          = "10.0.1.0/24"
      create_router = true
    }
    app = {
      cidr          = "10.0.2.0/24"
      create_router = false
    }
    db = {
      cidr          = "10.0.3.0/24"
      create_router = false
    }
  }

  # Configuration des groupes de sécurité
  security_groups_config = {
    web = {
      description = "Security group for web tier"
      rules = var.environment == "prod" ? {
        http = {
          port     = 80
          protocol = "tcp"
          cidr     = "0.0.0.0/0"
        }
        https = {
          port     = 443
          protocol = "tcp"
          cidr     = "0.0.0.0/0"
        }
        ssh = {
          port     = 22
          protocol = "tcp"
          cidr     = "0.0.0.0/0"
        }
      } : {
        http = {
          port     = 80
          protocol = "tcp"
          cidr     = "0.0.0.0/0"
        }
        ssh = {
          port     = 22
          protocol = "tcp"
          cidr     = "0.0.0.0/0"
        }
      }
    }
    app = {
      description = "Security group for application tier"
      rules = {
        app_port = {
          port     = 8080
          protocol = "tcp"
          cidr     = "10.0.0.0/16"
        }
        ssh = {
          port     = 22
          protocol = "tcp"
          cidr     = "0.0.0.0/0"
        }
      }
    }
    db = {
      description = "Security group for database tier"
      rules = {
        postgres = {
          port     = 5432
          protocol = "tcp"
          cidr     = "10.0.0.0/16"
        }
        ssh = {
          port     = 22
          protocol = "tcp"
          cidr     = "0.0.0.0/0"
        }
      }
    }
  }

  # Tags communs
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ========================================
# MODULES NETWORK
# ========================================

module "networks" {
  source   = "./modules/network"
  for_each = local.networks_config

  network_name          = "${var.project_name}-${each.key}-${var.environment}"
  subnet_cidr           = each.value.cidr
  create_router         = each.value.create_router
  external_network_name = var.external_network_name
}

# ========================================
# MODULES SECURITY GROUPS
# ========================================

module "security_groups" {
  source   = "./modules/security-group"
  for_each = local.security_groups_config

  name        = "${var.project_name}-${each.key}-${var.environment}"
  description = each.value.description
  rules       = each.value.rules
}

# ========================================
# MODULES INSTANCES - WEB TIER
# ========================================

module "web_instances" {
  source = "./modules/instance"

  instance_count = local.web_config.count
  name_prefix    = "${var.project_name}-web-${var.environment}"
  flavor_name    = local.web_config.flavor
  image_name     = var.image_name
  network_id     = module.networks["web"].network_id
  security_group_ids = [
    module.security_groups["web"].security_group_name
  ]

  metadata = merge(local.common_tags, {
    Tier = "web"
    Role = "nginx"
  })

  create_volume = false
}

# ========================================
# MODULES INSTANCES - APP TIER
# ========================================

module "app_instances" {
  source = "./modules/instance"

  instance_count = local.app_config.count
  name_prefix    = "${var.project_name}-app-${var.environment}"
  flavor_name    = local.app_config.flavor
  image_name     = var.image_name
  network_id     = module.networks["app"].network_id
  security_group_ids = [
    module.security_groups["app"].security_group_name
  ]

  metadata = merge(local.common_tags, {
    Tier = "application"
    Role = "backend"
  })

  create_volume = false
}

# ========================================
# MODULES INSTANCES - DATABASE TIER
# ========================================

module "db_instances" {
  source = "./modules/instance"

  instance_count = local.db_config.count
  name_prefix    = "${var.project_name}-db-${var.environment}"
  flavor_name    = local.db_config.flavor
  image_name     = var.image_name
  network_id     = module.networks["db"].network_id
  security_group_ids = [
    module.security_groups["db"].security_group_name
  ]

  metadata = merge(local.common_tags, {
    Tier = "database"
    Role = "postgresql"
  })

  create_volume = local.db_config.create_volume
  volume_size   = local.db_config.volume_size
}

# ========================================
# MODULES LOAD BALANCER (conditionnel - prod uniquement)
# ========================================

module "loadbalancer" {
  count  = local.enable_loadbalancer ? 1 : 0
  source = "./modules/loadbalancer"

  name                   = "${var.project_name}-lb-${var.environment}"
  subnet_id              = module.networks["web"].subnet_id
  backend_instance_ids   = module.web_instances.instance_ids
  backend_instance_ips   = module.web_instances.instance_ips
  service_port           = 80
  protocol               = "HTTP"
  enable_health_check    = true
}

# ========================================
# MODULES VOLUMES BACKUP (conditionnel - prod uniquement)
# ========================================

module "backup_volumes" {
  count  = local.create_backup_volumes ? 1 : 0
  source = "./modules/volume"

  volume_count = local.db_config.count
  name_prefix  = "${var.project_name}-db-backup-${var.environment}"
  volume_size  = 50

  metadata = merge(local.common_tags, {
    Purpose = "backup"
    Tier    = "database"
  })
}
