# Workshop 2 Terraform OpenStack

---

### Structure du workshop
```
terraform-openstack-workshop/
├── module1-base/
├── module2-compute/
├── module3-network/
```

### Préparation de l'environnement

Créez **clouds.yaml** :
```yaml
clouds:
  workshop-dev:
    auth:
      auth_url: http://127.0.0.1/identity
      username: "your-username"
      password: "your-password"
      project_name: "workshop-dev"
      project_domain_name: "Default"
      user_domain_name: "Default"
    region_name: "RegionOne"
    interface: "public"
    identity_api_version: 3

  workshop-staging:
    auth:
      auth_url: https://openstack.example.com:5000/v3
      username: "your-username"
      password: "your-password"
      project_name: "workshop-staging"
      project_domain_name: "Default"
      user_domain_name: "Default"
    region_name: "RegionOne"
    interface: "public"
    identity_api_version: 3

  workshop-prod:
    auth:
      auth_url: https://openstack.example.com:5000/v3
      username: "your-username"
      password: "your-password"
      project_name: "workshop-prod"
      project_domain_name: "Default"
      user_domain_name: "Default"
    region_name: "RegionOne"
    interface: "public"
    identity_api_version: 3
```

---

## Module 1 : Configuration de Base et Authentification

### Objectif
Configurer le provider OpenStack de manière portable et découvrir les ressources disponibles.

### Exercice 1.1 : Configuration du provider avec cloud.yaml

```bash
mkdir -p terraform-openstack-workshop/module1-base/exercice1.1
cd terraform-openstack-workshop/module1-base/exercice1.1
```

Créez **versions.tf** :
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}
```

Créez **provider.tf** :
```hcl
# BONNE PRATIQUE : Configuration du provider avec cloud.yaml
# Permet de changer facilement d'environnement
provider "openstack" {
  cloud = var.cloud_name  # Référence au clouds.yaml
}

# Alternative pour configuration directe (moins portable)
# provider "openstack" {
#   auth_url    = var.auth_url
#   user_name   = var.username
#   password    = var.password
#   tenant_name = var.project_name
#   domain_name = var.domain_name
#   region      = var.region
# }
```

Créez **variables.tf** :
```hcl
variable "cloud_name" {
  type        = string
  description = "Nom du cloud dans clouds.yaml"
  default     = "workshop-dev"
}

variable "environment" {
  type        = string
  description = "Environnement (dev, staging, prod)"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment doit être dev, staging ou prod."
  }
}

variable "project_name" {
  type        = string
  description = "Nom du projet pour le naming"
  default     = "workshop"
}
```

Créez **locals.tf** :
```hcl
# BONNE PRATIQUE : Centraliser les conventions de nommage
locals {
  # Convention de nommage standardisée
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Tags communs à toutes les ressources
  common_tags = {
    Environment  = var.environment
    Project      = var.project_name
    ManagedBy    = "terraform"
    Owner        = "platform-team"
    CreatedAt    = timestamp()
  }
  
  # Convertir les tags en metadata OpenStack
  common_metadata = {
    for k, v in local.common_tags : 
    lower(k) => tostring(v)
  }
}
```

Créez **main.tf** :
```hcl
# DATA SOURCE : Découvrir automatiquement les images disponibles
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04"
  most_recent = true
}

data "openstack_images_image_v2" "centos" {
  name        = "CentOS Stream 9"
  most_recent = true
}

# DATA SOURCE : Découvrir les flavors disponibles
data "openstack_compute_flavor_v2" "small" {
  name = "m1.small"
}

data "openstack_compute_flavor_v2" "medium" {
  name = "m1.medium"
}

data "openstack_compute_flavor_v2" "large" {
  name = "m1.large"
}

# DATA SOURCE : Découvrir les réseaux existants
data "openstack_networking_network_v2" "external" {
  name     = "external"
  external = true
}

# Créer un fichier de rapport des ressources disponibles
resource "local_file" "resource_inventory" {
  filename = "${path.module}/openstack-inventory.yaml"
  content = yamlencode({
    cloud       = var.cloud_name
    environment = var.environment
    discovery = {
      images = {
        ubuntu = {
          id   = data.openstack_images_image_v2.ubuntu.id
          name = data.openstack_images_image_v2.ubuntu.name
          size = data.openstack_images_image_v2.ubuntu.size_bytes
        }
        centos = {
          id   = data.openstack_images_image_v2.centos.id
          name = data.openstack_images_image_v2.centos.name
          size = data.openstack_images_image_v2.centos.size_bytes
        }
      }
      flavors = {
        small = {
          id    = data.openstack_compute_flavor_v2.small.id
          vcpus = data.openstack_compute_flavor_v2.small.vcpus
          ram   = data.openstack_compute_flavor_v2.small.ram
          disk  = data.openstack_compute_flavor_v2.small.disk
        }
        medium = {
          id    = data.openstack_compute_flavor_v2.medium.id
          vcpus = data.openstack_compute_flavor_v2.medium.vcpus
          ram   = data.openstack_compute_flavor_v2.medium.ram
          disk  = data.openstack_compute_flavor_v2.medium.disk
        }
        large = {
          id    = data.openstack_compute_flavor_v2.large.id
          vcpus = data.openstack_compute_flavor_v2.large.vcpus
          ram   = data.openstack_compute_flavor_v2.large.ram
          disk  = data.openstack_compute_flavor_v2.large.disk
        }
      }
      networks = {
        external = {
          id     = data.openstack_networking_network_v2.external.id
          name   = data.openstack_networking_network_v2.external.name
          subnets = data.openstack_networking_network_v2.external.all_subnets
        }
      }
    }
    naming_convention = {
      prefix = local.name_prefix
      example = "${local.name_prefix}-resource-name"
    }
    tags = local.common_tags
  })
}
```

Créez **outputs.tf** :
```hcl
output "cloud_config" {
  value = {
    cloud       = var.cloud_name
    environment = var.environment
    name_prefix = local.name_prefix
  }
  description = "Configuration du cloud"
}

output "available_images" {
  value = {
    ubuntu = {
      id   = data.openstack_images_image_v2.ubuntu.id
      name = data.openstack_images_image_v2.ubuntu.name
    }
    centos = {
      id   = data.openstack_images_image_v2.centos.id
      name = data.openstack_images_image_v2.centos.name
    }
  }
  description = "Images disponibles"
}

output "available_flavors" {
  value = {
    small  = data.openstack_compute_flavor_v2.small.name
    medium = data.openstack_compute_flavor_v2.medium.name
    large  = data.openstack_compute_flavor_v2.large.name
  }
  description = "Flavors disponibles"
}

output "external_network" {
  value = {
    id   = data.openstack_networking_network_v2.external.id
    name = data.openstack_networking_network_v2.external.name
  }
  description = "Réseau externe"
}

output "naming_convention" {
  value = {
    prefix  = local.name_prefix
    example = "${local.name_prefix}-vm-web"
  }
  description = "Convention de nommage utilisée"
}

output "common_tags" {
  value       = local.common_tags
  description = "Tags communs appliqués à toutes les ressources"
}
```

Créez **terraform.tfvars** :
```hcl
cloud_name   = "workshop-dev"
environment  = "dev"
project_name = "workshop"
```

**Exécution** :
```bash
# Initialiser
terraform init

# Vérifier la découverte des ressources
terraform plan

# Appliquer
terraform apply

# Examiner l'inventaire
cat openstack-inventory.yaml

# Voir les outputs
terraform output
terraform output available_images
terraform output naming_convention

# Tester avec un autre environnement
terraform apply -var="cloud_name=workshop-staging" -var="environment=staging"
```

### Exercice 1.2 : Configuration portable multi-régions

```bash
cd ../
mkdir exercice1.2
cd exercice1.2
```

Créez **versions.tf** :
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}
```

Créez **variables.tf** :
```hcl
variable "cloud_name" {
  type        = string
  description = "Nom du cloud dans clouds.yaml"
  default     = "workshop-dev"
}

variable "region" {
  type        = string
  description = "Région OpenStack"
  default     = "RegionOne"
}

variable "environment" {
  type        = string
  description = "Environnement"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Nom du projet"
  default     = "workshop"
}

# BONNE PRATIQUE : Configuration par région
variable "region_config" {
  type = map(object({
    availability_zones = list(string)
    dns_servers        = list(string)
    ntp_servers        = list(string)
  }))
  description = "Configuration spécifique par région"
  default = {
    RegionOne = {
      availability_zones = ["nova"]
      dns_servers        = ["8.8.8.8", "8.8.4.4"]
      ntp_servers        = ["ntp.ubuntu.com"]
    }
    RegionTwo = {
      availability_zones = ["az1", "az2"]
      dns_servers        = ["1.1.1.1", "1.0.0.1"]
      ntp_servers        = ["time.cloudflare.com"]
    }
  }
}

# BONNE PRATIQUE : Mapping des noms d'images par région
variable "image_mapping" {
  type = map(map(string))
  description = "Mapping des images par région et OS"
  default = {
    RegionOne = {
      ubuntu = "Ubuntu 22.04"
      centos = "CentOS Stream 9"
      debian = "Debian 12"
    }
    RegionTwo = {
      ubuntu = "ubuntu-22.04-x86_64"
      centos = "centos-stream-9-x86_64"
      debian = "debian-12-x86_64"
    }
  }
}

# BONNE PRATIQUE : Mapping des flavors par région
variable "flavor_mapping" {
  type = map(map(string))
  description = "Mapping des flavors par région et taille"
  default = {
    RegionOne = {
      small  = "m1.small"
      medium = "m1.medium"
      large  = "m1.large"
    }
    RegionTwo = {
      small  = "t2.small"
      medium = "t2.medium"
      large  = "t2.large"
    }
  }
}
```

Créez **provider.tf** :
```hcl
provider "openstack" {
  cloud  = var.cloud_name
  region = var.region
}
```

Créez **locals.tf** :
```hcl
locals {
  # Configuration active basée sur la région
  current_region_config = lookup(
    var.region_config, 
    var.region, 
    var.region_config["RegionOne"]
  )
  
  # Mapping des images pour la région courante
  current_image_mapping = lookup(
    var.image_mapping,
    var.region,
    var.image_mapping["RegionOne"]
  )
  
  # Mapping des flavors pour la région courante
  current_flavor_mapping = lookup(
    var.flavor_mapping,
    var.region,
    var.flavor_mapping["RegionOne"]
  )
  
  # Convention de nommage incluant la région
  name_prefix = "${var.project_name}-${var.environment}-${var.region}"
  
  # Tags standardisés
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Region      = var.region
    ManagedBy   = "terraform"
  }
  
  common_metadata = {
    for k, v in local.common_tags : 
    lower(k) => tostring(v)
  }
}
```

Créez **main.tf** :
```hcl
# Découvrir les images avec mapping portable
data "openstack_images_image_v2" "ubuntu" {
  name        = local.current_image_mapping["ubuntu"]
  most_recent = true
}

data "openstack_images_image_v2" "centos" {
  name        = local.current_image_mapping["centos"]
  most_recent = true
}

# Découvrir les flavors avec mapping portable
data "openstack_compute_flavor_v2" "small" {
  name = local.current_flavor_mapping["small"]
}

data "openstack_compute_flavor_v2" "medium" {
  name = local.current_flavor_mapping["medium"]
}

# Réseau externe
data "openstack_networking_network_v2" "external" {
  external = true
}

# Créer un rapport de configuration
resource "local_file" "region_config" {
  filename = "${path.module}/region-${var.region}-config.yaml"
  content = yamlencode({
    cloud  = var.cloud_name
    region = var.region
    environment = var.environment
    
    configuration = {
      availability_zones = local.current_region_config.availability_zones
      dns_servers        = local.current_region_config.dns_servers
      ntp_servers        = local.current_region_config.ntp_servers
    }
    
    resources = {
      images = {
        ubuntu = {
          mapped_name = local.current_image_mapping["ubuntu"]
          id          = data.openstack_images_image_v2.ubuntu.id
          actual_name = data.openstack_images_image_v2.ubuntu.name
        }
        centos = {
          mapped_name = local.current_image_mapping["centos"]
          id          = data.openstack_images_image_v2.centos.id
          actual_name = data.openstack_images_image_v2.centos.name
        }
      }
      
      flavors = {
        small = {
          mapped_name = local.current_flavor_mapping["small"]
          id          = data.openstack_compute_flavor_v2.small.id
          vcpus       = data.openstack_compute_flavor_v2.small.vcpus
          ram_mb      = data.openstack_compute_flavor_v2.small.ram
        }
        medium = {
          mapped_name = local.current_flavor_mapping["medium"]
          id          = data.openstack_compute_flavor_v2.medium.id
          vcpus       = data.openstack_compute_flavor_v2.medium.vcpus
          ram_mb      = data.openstack_compute_flavor_v2.medium.ram
        }
      }
      
      network = {
        external = {
          id   = data.openstack_networking_network_v2.external.id
          name = data.openstack_networking_network_v2.external.name
        }
      }
    }
    
    naming = {
      prefix  = local.name_prefix
      pattern = "${local.name_prefix}-<resource>-<name>"
    }
    
    tags = local.common_tags
  })
}
```

Créez **outputs.tf** :
```hcl
output "region_info" {
  value = {
    cloud              = var.cloud_name
    region             = var.region
    environment        = var.environment
    availability_zones = local.current_region_config.availability_zones
  }
}

output "portable_image_ids" {
  value = {
    ubuntu = data.openstack_images_image_v2.ubuntu.id
    centos = data.openstack_images_image_v2.centos.id
  }
  description = "IDs d'images résolus dynamiquement"
}

output "portable_flavor_ids" {
  value = {
    small  = data.openstack_compute_flavor_v2.small.id
    medium = data.openstack_compute_flavor_v2.medium.id
  }
  description = "IDs de flavors résolus dynamiquement"
}

output "naming_convention" {
  value = {
    prefix = local.name_prefix
    example = "${local.name_prefix}-vm-web-01"
  }
}
```

**Exécution** :
```bash
terraform init

# Test RegionOne
terraform apply -var="region=RegionOne"
cat region-RegionOne-config.yaml

# Test RegionTwo (si disponible)
terraform apply -var="region=RegionTwo"
cat region-RegionTwo-config.yaml

# Comparer les configurations
diff region-RegionOne-config.yaml region-RegionTwo-config.yaml
```

### Points clés du Module 1
- Utilisation de clouds.yaml pour la portabilité
- Data sources pour découvrir dynamiquement les ressources
- Mapping des noms d'images et flavors par région
- Convention de nommage standardisée
- Tags et metadata communs
- Configuration par région/environnement

---

## Module 2 : Compute et Stockage Portable

### Objectif
Créer des instances et volumes de manière portable avec abstraction des spécificités OpenStack.

### Exercice 2.1 : Instance compute portable

```bash
cd ../../module2-compute
mkdir exercice2.1
cd exercice2.1
```

Créez **versions.tf** :
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
```

Créez **variables.tf** :
```hcl
variable "cloud_name" {
  type    = string
  default = "workshop-dev"
}

variable "region" {
  type    = string
  default = "RegionOne"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "workshop"
}

# BONNE PRATIQUE : Tailles abstraites indépendantes du cloud
variable "instance_size" {
  type        = string
  description = "Taille abstraite de l'instance (small, medium, large)"
  default     = "small"
  
  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.instance_size)
    error_message = "La taille doit être small, medium, large ou xlarge."
  }
}

# BONNE PRATIQUE : OS abstrait
variable "operating_system" {
  type        = string
  description = "Système d'exploitation (ubuntu, centos, debian)"
  default     = "ubuntu"
  
  validation {
    condition     = contains(["ubuntu", "centos", "debian"], var.operating_system)
    error_message = "OS doit être ubuntu, centos ou debian."
  }
}

# BONNE PRATIQUE : Configuration d'instance abstraite
variable "instance_config" {
  type = object({
    name                = string
    size                = string
    os                  = string
    availability_zone   = optional(string, null)
    enable_floating_ip  = optional(bool, false)
    security_groups     = optional(list(string), [])
    user_data           = optional(string, null)
  })
  description = "Configuration abstraite de l'instance"
  default = {
    name    = "web-server"
    size    = "small"
    os      = "ubuntu"
  }
}

# Mapping OpenStack-spécifique (externalisable dans un fichier séparé)
variable "openstack_flavor_mapping" {
  type = map(map(string))
  default = {
    RegionOne = {
      small  = "m1.small"
      medium = "m1.medium"
      large  = "m1.large"
      xlarge = "m1.xlarge"
    }
  }
}

variable "openstack_image_mapping" {
  type = map(map(string))
  default = {
    RegionOne = {
      ubuntu = "Ubuntu 22.04"
      centos = "CentOS Stream 9"
      debian = "Debian 12"
    }
  }
}
```

Créez **provider.tf** :
```hcl
provider "openstack" {
  cloud  = var.cloud_name
  region = var.region
}
```

Créez **locals.tf** :
```hcl
locals {
  # Résolution du flavor basé sur la taille abstraite
  flavor_name = lookup(
    lookup(var.openstack_flavor_mapping, var.region, {}),
    var.instance_config.size,
    "m1.small"  # Fallback
  )
  
  # Résolution de l'image basée sur l'OS abstrait
  image_name = lookup(
    lookup(var.openstack_image_mapping, var.region, {}),
    var.instance_config.os,
    "Ubuntu 22.04"  # Fallback
  )
  
  # Convention de nommage
  name_prefix = "${var.project_name}-${var.environment}"
  instance_name = "${local.name_prefix}-${var.instance_config.name}"
  
  # Metadata standardisée (portable)
  common_metadata = {
    environment    = var.environment
    project        = var.project_name
    managed_by     = "terraform"
    instance_size  = var.instance_config.size
    operating_system = var.instance_config.os
    created_at     = timestamp()
  }
  
  # User data avec cloud-init (portable multi-cloud)
  default_user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - curl
      - wget
      - git
      - htop
    
    write_files:
      - path: /etc/environment-info
        content: |
          ENVIRONMENT=${var.environment}
          PROJECT=${var.project_name}
          INSTANCE_NAME=${local.instance_name}
          CLOUD_PROVIDER=openstack
          MANAGED_BY=terraform
    
    runcmd:
      - echo "Instance ${local.instance_name} initialized" > /var/log/terraform-init.log
      - echo "Environment: ${var.environment}" >> /var/log/terraform-init.log
  EOF
  
  user_data = coalesce(var.instance_config.user_data, local.default_user_data)
}
```

Créez **network.tf** :
```hcl
# Réseau externe
data "openstack_networking_network_v2" "external" {
  external = true
}

# Créer un réseau privé
resource "openstack_networking_network_v2" "private" {
  name           = "${local.name_prefix}-network"
  admin_state_up = true
}

# Sous-réseau
resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${local.name_prefix}-subnet"
  network_id      = openstack_networking_network_v2.private.id
  cidr            = "192.168.100.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  
  allocation_pool {
    start = "192.168.100.10"
    end   = "192.168.100.250"
  }
}

# Routeur
resource "openstack_networking_router_v2" "router" {
  name                = "${local.name_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Interface du routeur
resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}
```

Créez **security.tf** :
```hcl
# Security group par défaut
resource "openstack_compute_secgroup_v2" "default" {
  name        = "${local.name_prefix}-default-sg"
  description = "Security group par défaut pour ${var.environment}"
  
  # SSH
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  
  # ICMP (ping)
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
  
  # Outbound
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}

# Keypair pour SSH
resource "openstack_compute_keypair_v2" "keypair" {
  name = "${local.name_prefix}-keypair"
}

# Sauvegarder la clé privée localement
resource "local_sensitive_file" "private_key" {
  content         = openstack_compute_keypair_v2.keypair.private_key
  filename        = "${path.module}/${local.name_prefix}-key.pem"
  file_permission = "0600"
}
```

Créez **compute.tf** :
```hcl
# Data sources pour les ressources OpenStack
data "openstack_compute_flavor_v2" "instance" {
  name = local.flavor_name
}

data "openstack_images_image_v2" "instance" {
  name        = local.image_name
  most_recent = true
}

# RESSOURCE PRINCIPALE : Instance compute portable
resource "openstack_compute_instance_v2" "instance" {
  name              = local.instance_name
  flavor_id         = data.openstack_compute_flavor_v2.instance.id
  image_id          = data.openstack_images_image_v2.instance.id
  key_pair          = openstack_compute_keypair_v2.keypair.name
  availability_zone = var.instance_config.availability_zone
  user_data         = local.user_data
  
  # Métadonnées portables
  metadata = local.common_metadata
  
  # Security groups
  security_groups = concat(
    [openstack_compute_secgroup_v2.default.name],
    var.instance_config.security_groups
  )
  
  # Réseau
  network {
    uuid = openstack_networking_network_v2.private.id
  }
  
  # BONNE PRATIQUE : Lifecycle pour éviter les interruptions
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      user_data,  # Ignorer les changements de user_data après création
    ]
  }
  
  # Tags via metadata (OpenStack-specific mais portable)
  tags = [
    "${var.environment}",
    "${var.project_name}",
    "managed-by-terraform",
  ]
}

# Floating IP (optionnelle)
resource "openstack_networking_floatingip_v2" "instance" {
  count = var.instance_config.enable_floating_ip ? 1 : 0
  
  pool = data.openstack_networking_network_v2.external.name
}

# Association Floating IP
resource "openstack_compute_floatingip_associate_v2" "instance" {
  count = var.instance_config.enable_floating_ip ? 1 : 0
  
  floating_ip = openstack_networking_floatingip_v2.instance[0].address
  instance_id = openstack_compute_instance_v2.instance.id
}
```

Créez **outputs.tf** :
```hcl
# BONNE PRATIQUE : Outputs standardisés et portables
output "instance" {
  value = {
    id              = openstack_compute_instance_v2.instance.id
    name            = openstack_compute_instance_v2.instance.name
    private_ip      = openstack_compute_instance_v2.instance.access_ip_v4
    public_ip       = var.instance_config.enable_floating_ip ? openstack_networking_floatingip_v2.instance[0].address : null
    size            = var.instance_config.size
    os              = var.instance_config.os
    status          = openstack_compute_instance_v2.instance.power_state
  }
  description = "Informations de l'instance (format portable)"
}

output "connection_info" {
  value = {
    ssh_command = var.instance_config.enable_floating_ip ? "ssh -i ${local.name_prefix}-key.pem ubuntu@${openstack_networking_floatingip_v2.instance[0].address}" : "ssh -i ${local.name_prefix}-key.pem ubuntu@${openstack_compute_instance_v2.instance.access_ip_v4}"
    private_key = "${path.module}/${local.name_prefix}-key.pem"
  }
  description = "Informations de connexion SSH"
  sensitive   = true
}

output "network_info" {
  value = {
    private_network = {
      id         = openstack_networking_network_v2.private.id
      name       = openstack_networking_network_v2.private.name
      cidr       = openstack_networking_subnet_v2.subnet.cidr
    }
    private_ip = openstack_compute_instance_v2.instance.access_ip_v4
    public_ip  = var.instance_config.enable_floating_ip ? openstack_networking_floatingip_v2.instance[0].address : null
  }
  description = "Informations réseau"
}

output "openstack_mapping" {
  value = {
    requested_size  = var.instance_config.size
    actual_flavor   = local.flavor_name
    flavor_id       = data.openstack_compute_flavor_v2.instance.id
    requested_os    = var.instance_config.os
    actual_image    = local.image_name
    image_id        = data.openstack_images_image_v2.instance.id
  }
  description = "Mapping entre configuration abstraite et ressources OpenStack"
}
```

Créez **terraform.tfvars** :
```hcl
cloud_name   = "workshop-dev"
region       = "RegionOne"
environment  = "dev"
project_name = "workshop"

instance_config = {
  name               = "web-server-01"
  size               = "small"
  os                 = "ubuntu"
  enable_floating_ip = true
}
```

**Exécution** :
```bash
terraform init
terraform plan
terraform apply

# Voir les informations de l'instance
terraform output instance
terraform output network_info
terraform output openstack_mapping

# Se connecter à l'instance
terraform output -raw connection_info

# Test de portabilité : changer de taille
terraform apply -var='instance_config={name="web-server-01",size="medium",os="ubuntu",enable_floating_ip=true}'

# Test de portabilité : changer d'OS
terraform apply -var='instance_config={name="web-server-01",size="small",os="centos",enable_floating_ip=true}'
```

### Exercice 2.2 : Volumes persistants portables

```bash
cd ../
mkdir exercice2.2
cd exercice2.2
```

Créez **versions.tf** et **provider.tf** (identiques à l'exercice précédent)

Créez **variables.tf** :
```hcl
variable "cloud_name" {
  type    = string
  default = "workshop-dev"
}

variable "region" {
  type    = string
  default = "RegionOne"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "workshop"
}

# BONNE PRATIQUE : Configuration de volume abstraite
variable "volumes" {
  type = map(object({
    size_gb     = number
    type        = optional(string, "standard")  # standard, ssd, high-performance
    description = optional(string, "")
    bootable    = optional(bool, false)
  }))
  description = "Configuration des volumes de stockage"
  default = {
    data = {
      size_gb     = 50
      type        = "standard"
      description = "Volume de données"
    }
    backup = {
      size_gb     = 100
      type        = "standard"
      description = "Volume de backup"
    }
  }
}

# Mapping des types de volumes OpenStack
variable "openstack_volume_type_mapping" {
  type = map(string)
  description = "Mapping des types de volumes abstraits vers types OpenStack"
  default = {
    standard         = "lvmdriver-1"
    ssd              = "ssd"
    high-performance = "high-performance"
  }
}

variable "instance_config" {
  type = object({
    name = string
    size = string
    os   = string
  })
  default = {
    name = "storage-server"
    size = "medium"
    os   = "ubuntu"
  }
}
```

Créez **locals.tf** :
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Résolution des types de volumes
  volume_configs = {
    for name, config in var.volumes : name => {
      name        = "${local.name_prefix}-volume-${name}"
      size        = config.size_gb
      type        = lookup(var.openstack_volume_type_mapping, config.type, "lvmdriver-1")
      description = config.description
      bootable    = config.bootable
    }
  }
  
  common_metadata = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
    created_at  = timestamp()
  }
  
  # Configuration de l'instance
  flavor_mapping = {
    small  = "m1.small"
    medium = "m1.medium"
    large  = "m1.large"
  }
  
  image_mapping = {
    ubuntu = "Ubuntu 22.04"
    centos = "CentOS Stream 9"
  }
  
  flavor_name = lookup(local.flavor_mapping, var.instance_config.size, "m1.small")
  image_name  = lookup(local.image_mapping, var.instance_config.os, "Ubuntu 22.04")
}
```

Créez **network.tf** :
```hcl
data "openstack_networking_network_v2" "external" {
  external = true
}

resource "openstack_networking_network_v2" "private" {
  name           = "${local.name_prefix}-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${local.name_prefix}-subnet"
  network_id      = openstack_networking_network_v2.private.id
  cidr            = "192.168.200.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_networking_router_v2" "router" {
  name                = "${local.name_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}
```

Créez **security.tf** :
```hcl
resource "openstack_compute_secgroup_v2" "default" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for storage server"
  
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_keypair_v2" "keypair" {
  name = "${local.name_prefix}-keypair"
}

resource "local_sensitive_file" "private_key" {
  content         = openstack_compute_keypair_v2.keypair.private_key
  filename        = "${path.module}/${local.name_prefix}-key.pem"
  file_permission = "0600"
}
```

Créez **volumes.tf** :
```hcl
# BONNE PRATIQUE : Créer des volumes portables avec for_each
resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each = local.volume_configs
  
  name        = each.value.name
  description = each.value.description
  size        = each.value.size
  volume_type = each.value.type
  
  # Métadonnées portables
  metadata = merge(
    local.common_metadata,
    {
      volume_name = each.key
      volume_type = each.value.type
      purpose     = each.value.description
    }
  )
  
  # BONNE PRATIQUE : Activer la protection contre la suppression en prod
  lifecycle {
    prevent_destroy = false  # Mettre à true en production
  }
}

# Snapshots automatiques (optionnel)
resource "openstack_blockstorage_volume_v3" "snapshot_volumes" {
  for_each = {
    for name, config in var.volumes : name => config
    if config.type == "ssd"  # Seulement pour les volumes SSD
  }
  
  name        = "${local.name_prefix}-snapshot-${each.key}"
  description = "Snapshot volume for ${each.key}"
  size        = each.value.size_gb
  volume_type = lookup(var.openstack_volume_type_mapping, each.value.type, "lvmdriver-1")
  
  metadata = merge(
    local.common_metadata,
    {
      snapshot_source = each.key
      backup_enabled  = "true"
    }
  )
}
```

Créez **compute.tf** :
```hcl
data "openstack_compute_flavor_v2" "instance" {
  name = local.flavor_name
}

data "openstack_images_image_v2" "instance" {
  name        = local.image_name
  most_recent = true
}

# Instance avec volumes attachés
resource "openstack_compute_instance_v2" "storage_server" {
  name            = "${local.name_prefix}-${var.instance_config.name}"
  flavor_id       = data.openstack_compute_flavor_v2.instance.id
  image_id        = data.openstack_images_image_v2.instance.id
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_compute_secgroup_v2.default.name]
  
  metadata = local.common_metadata
  
  network {
    uuid = openstack_networking_network_v2.private.id
  }
  
  # User data pour monter automatiquement les volumes
  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - lvm2
      - xfsprogs
    
    write_files:
      - path: /etc/volume-info.yaml
        content: |
          volumes:
    ${indent(10, yamlencode({
      for name, vol in openstack_blockstorage_volume_v3.volumes :
      name => {
        id   = vol.id
        size = vol.size
        type = vol.volume_type
      }
    }))}
    
    runcmd:
      - echo "Storage server ${var.instance_config.name} initialized" > /var/log/storage-init.log
  EOF
}

# BONNE PRATIQUE : Attachement de volumes avec ordre contrôlé
resource "openstack_compute_volume_attach_v2" "attachments" {
  for_each = openstack_blockstorage_volume_v3.volumes
  
  instance_id = openstack_compute_instance_v2.storage_server.id
  volume_id   = each.value.id
  
  # L'instance doit exister avant d'attacher les volumes
  depends_on = [openstack_compute_instance_v2.storage_server]
}

# Floating IP
resource "openstack_networking_floatingip_v2" "storage_server" {
  pool = data.openstack_networking_network_v2.external.name
}

resource "openstack_compute_floatingip_associate_v2" "storage_server" {
  floating_ip = openstack_networking_floatingip_v2.storage_server.address
  instance_id = openstack_compute_instance_v2.storage_server.id
}
```

Créez **outputs.tf** :
```hcl
output "instance" {
  value = {
    id         = openstack_compute_instance_v2.storage_server.id
    name       = openstack_compute_instance_v2.storage_server.name
    private_ip = openstack_compute_instance_v2.storage_server.access_ip_v4
    public_ip  = openstack_networking_floatingip_v2.storage_server.address
  }
  description = "Informations de l'instance de stockage"
}

output "volumes" {
  value = {
    for name, vol in openstack_blockstorage_volume_v3.volumes : name => {
      id          = vol.id
      name        = vol.name
      size_gb     = vol.size
      type        = vol.volume_type
      status      = vol.attachment[0].device
      attached_to = vol.attachment[0].instance_id
    }
  }
  description = "Informations des volumes (format portable)"
}

output "storage_summary" {
  value = {
    total_storage_gb = sum([for v in var.volumes : v.size_gb])
    volume_count     = length(var.volumes)
    volumes_by_type = {
      for type in distinct([for v in var.volumes : v.type]) :
      type => [for name, v in var.volumes : name if v.type == type]
    }
  }
  description = "Résumé du stockage"
}

output "connection_info" {
  value = {
    ssh_command = "ssh -i ${local.name_prefix}-key.pem ubuntu@${openstack_networking_floatingip_v2.storage_server.address}"
    check_volumes = "ssh -i ${local.name_prefix}-key.pem ubuntu@${openstack_networking_floatingip_v2.storage_server.address} 'lsblk'"
  }
  description = "Commandes de connexion et vérification"
}

output "volume_configuration" {
  value = {
    for name, config in local.volume_configs : name => {
      requested_type = [for k, v in var.volumes : v.type if k == name][0]
      openstack_type = config.type
      size_gb        = config.size
    }
  }
  description = "Mapping de configuration des volumes"
}
```

Créez **terraform.tfvars** :
```hcl
cloud_name   = "workshop-dev"
environment  = "dev"
project_name = "workshop"

instance_config = {
  name = "storage-server-01"
  size = "medium"
  os   = "ubuntu"
}

volumes = {
  data = {
    size_gb     = 50
    type        = "standard"
    description = "Volume de données applicatives"
  }
  logs = {
    size_gb     = 20
    type        = "standard"
    description = "Volume de logs"
  }
  backup = {
    size_gb     = 100
    type        = "standard"
    description = "Volume de backup"
  }
  cache = {
    size_gb     = 30
    type        = "ssd"
    description = "Volume de cache haute performance"
  }
}
```

**Exécution** :
```bash
terraform init
terraform plan
terraform apply

# Vérifier les volumes
terraform output volumes
terraform output storage_summary
terraform output volume_configuration

# Se connecter et vérifier les volumes attachés
SSH_CMD=$(terraform output -raw connection_info | grep ssh_command | cut -d'"' -f2)
eval $SSH_CMD "lsblk"

# Tester la portabilité : ajouter un nouveau volume
cat >> terraform.tfvars <<EOF

volumes = {
  data = {
    size_gb     = 50
    type        = "standard"
    description = "Volume de données applicatives"
  }
  logs = {
    size_gb     = 20
    type        = "standard"
    description = "Volume de logs"
  }
  backup = {
    size_gb     = 100
    type        = "standard"
    description = "Volume de backup"
  }
  cache = {
    size_gb     = 30
    type        = "ssd"
    description = "Volume de cache haute performance"
  }
  archive = {
    size_gb     = 200
    type        = "standard"
    description = "Volume d'archives"
  }
}
EOF

terraform apply
```

---

## Module 3 : Réseau et Sécurité Modulaire

### Objectif
Créer une architecture réseau portable avec VPC, subnets, routing et sécurité.

### Exercice 3.1 : VPC et subnets portables

```bash
cd ../../module3-network
mkdir exercice3.1
cd exercice3.1
```

Créez **versions.tf** :
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}
```

Créez **variables.tf** :
```hcl
variable "cloud_name" {
  type    = string
  default = "workshop-dev"
}

variable "region" {
  type    = string
  default = "RegionOne"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "workshop"
}

# BONNE PRATIQUE : Configuration réseau abstraite et portable
variable "network_config" {
  type = object({
    vpc_cidr = string
    subnets = map(object({
      cidr              = string
      type              = string  # public, private, database
      availability_zone = optional(string, null)
    }))
    enable_nat        = optional(bool, true)
    enable_vpn        = optional(bool, false)
    dns_servers       = optional(list(string), ["8.8.8.8", "8.8.4.4"])
  })
  description = "Configuration réseau portable"
  default = {
    vpc_cidr = "10.0.0.0/16"
    subnets = {
      public = {
        cidr = "10.0.1.0/24"
        type = "public"
      }
      private = {
        cidr = "10.0.2.0/24"
        type = "private"
      }
      database = {
        cidr = "10.0.3.0/24"
        type = "database"
      }
    }
    enable_nat = true
  }
}
```

Créez **provider.tf** :
```hcl
provider "openstack" {
  cloud  = var.cloud_name
  region = var.region
}
```

Créez **locals.tf** :
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Métadonnées standardisées
  common_tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
    vpc_cidr    = var.network_config.vpc_cidr
  }
  
  # Séparer les subnets par type
  public_subnets = {
    for name, config in var.network_config.subnets :
    name => config if config.type == "public"
  }
  
  private_subnets = {
    for name, config in var.network_config.subnets :
    name => config if config.type == "private"
  }
  
  database_subnets = {
    for name, config in var.network_config.subnets :
    name => config if config.type == "database"
  }
}
```

Créez **network.tf** :
```hcl
# Réseau externe (data source)
data "openstack_networking_network_v2" "external" {
  external = true
}

# RESSOURCE PRINCIPALE : Réseau privé (VPC équivalent)
resource "openstack_networking_network_v2" "vpc" {
  name           = "${local.name_prefix}-vpc"
  admin_state_up = true
  
  # Metadata
  tags = [
    var.environment,
    var.project_name,
    "vpc",
  ]
}

# BONNE PRATIQUE : Créer des subnets avec for_each pour la flexibilité
resource "openstack_networking_subnet_v2" "subnets" {
  for_each = var.network_config.subnets
  
  name            = "${local.name_prefix}-subnet-${each.key}"
  network_id      = openstack_networking_network_v2.vpc.id
  cidr            = each.value.cidr
  ip_version      = 4
  dns_nameservers = var.network_config.dns_servers
  
  # Plage d'allocation (réserver les 10 premières IPs)
  allocation_pool {
    start = cidrhost(each.value.cidr, 10)
    end   = cidrhost(each.value.cidr, -2)
  }
  
  # Gateway (première IP utilisable)
  gateway_ip = cidrhost(each.value.cidr, 1)
  
  # Metadata via tags
  tags = [
    each.value.type,
    each.key,
    var.environment,
  ]
}

# Routeur pour accès externe
resource "openstack_networking_router_v2" "router" {
  name                = "${local.name_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
  
  tags = [
    "router",
    var.environment,
  ]
}

# BONNE PRATIQUE : Attacher seulement les subnets publics au routeur
resource "openstack_networking_router_interface_v2" "public_interfaces" {
  for_each = local.public_subnets
  
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnets[each.key].id
}

# Pour les subnets privés, créer des routes conditionnelles
resource "openstack_networking_router_interface_v2" "private_interfaces" {
  for_each = var.network_config.enable_nat ? local.private_subnets : {}
  
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnets[each.key].id
}
```

Créez **outputs.tf** :
```hcl
# BONNE PRATIQUE : Outputs structurés et portables
output "vpc" {
  value = {
    id   = openstack_networking_network_v2.vpc.id
    name = openstack_networking_network_v2.vpc.name
    cidr = var.network_config.vpc_cidr
  }
  description = "Informations du VPC"
}

output "subnets" {
  value = {
    for name, subnet in openstack_networking_subnet_v2.subnets : name => {
      id                = subnet.id
      name              = subnet.name
      cidr              = subnet.cidr
      type              = var.network_config.subnets[name].type
      gateway_ip        = subnet.gateway_ip
      dns_nameservers   = subnet.dns_nameservers
      allocation_start  = subnet.allocation_pool[0].start
      allocation_end    = subnet.allocation_pool[0].end
    }
  }
  description = "Informations des subnets (format portable)"
}

output "subnets_by_type" {
  value = {
    public   = {for k, v in local.public_subnets : k => openstack_networking_subnet_v2.subnets[k].id}
    private  = {for k, v in local.private_subnets : k => openstack_networking_subnet_v2.subnets[k].id}
    database = {for k, v in local.database_subnets : k => openstack_networking_subnet_v2.subnets[k].id}
  }
  description = "Subnets groupés par type"
}

output "router" {
  value = {
    id          = openstack_networking_router_v2.router.id
    name        = openstack_networking_router_v2.router.name
    external_id = openstack_networking_router_v2.router.external_network_id
  }
  description = "Informations du routeur"
}

output "network_topology" {
  value = {
    vpc_cidr         = var.network_config.vpc_cidr
    subnet_count     = length(var.network_config.subnets)
    public_subnets   = length(local.public_subnets)
    private_subnets  = length(local.private_subnets)
    database_subnets = length(local.database_subnets)
    nat_enabled      = var.network_config.enable_nat
  }
  description = "Topologie réseau"
}
```

Créez **terraform.tfvars** :
```hcl
cloud_name   = "workshop-dev"
environment  = "dev"
project_name = "workshop"

network_config = {
  vpc_cidr = "10.0.0.0/16"
  subnets = {
    public-az1 = {
      cidr              = "10.0.1.0/24"
      type              = "public"
      availability_zone = "nova"
    }
    public-az2 = {
      cidr              = "10.0.2.0/24"
      type              = "public"
      availability_zone = "nova"
    }
    private-app = {
      cidr = "10.0.10.0/24"
      type = "private"
    }
    private-worker = {
      cidr = "10.0.11.0/24"
      type = "private"
    }
    database-primary = {
      cidr = "10.0.20.0/24"
      type = "database"
    }
    database-replica = {
      cidr = "10.0.21.0/24"
      type = "database"
    }
  }
  enable_nat  = true
  dns_servers = ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
}
```

**Exécution** :
```bash
terraform init
terraform plan
terraform apply

# Vérifier la topologie
terraform output network_topology
terraform output subnets_by_type
terraform output -json subnets | jq

# Visualiser l'architecture
cat > network-diagram.txt <<EOF
VPC: $(terraform output -json vpc | jq -r '.cidr')
├── Public Subnets (Internet Gateway attached)
$(terraform output -json subnets_by_type | jq -r '.public | keys[]' | while read subnet; do echo "│   ├── $subnet"; done)
├── Private Subnets (NAT Gateway)
$(terraform output -json subnets_by_type | jq -r '.private | keys[]' | while read subnet; do echo "│   ├── $subnet"; done)
└── Database Subnets (Isolated)
$(terraform output -json subnets_by_type | jq -r '.database | keys[]' | while read subnet; do echo "    ├── $subnet"; done)
EOF

cat network-diagram.txt
```

### Exercice 3.2 : Security Groups portables

```bash
cd ../
mkdir exercice3.2
cd exercice3.2
```

Créez **versions.tf**, **provider.tf** (identiques)

Créez **variables.tf** :
```hcl
variable "cloud_name" {
  type    = string
  default = "workshop-dev"
}

variable "region" {
  type    = string
  default = "RegionOne"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "workshop"
}

# BONNE PRATIQUE : Définition abstraite des security groups
variable "security_groups" {
  type = map(object({
    description = string
    ingress = list(object({
      protocol    = string
      from_port   = number
      to_port     = number
      cidr_blocks = list(string)
      description = string
    }))
    egress = optional(list(object({
      protocol    = string
      from_port   = number
      to_port     = number
      cidr_blocks = list(string)
      description = string
    })), [])
  }))
  description = "Configuration des security groups (format portable)"
  default = {
    web = {
      description = "Security group pour serveurs web"
      ingress = [
        {
          protocol    = "tcp"
          from_port   = 80
          to_port     = 80
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from anywhere"
        },
        {
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from anywhere"
        },
        {
          protocol    = "tcp"
          from_port   = 22
          to_port     = 22
          cidr_blocks = ["0.0.0.0/0"]
          description = "SSH from anywhere"
        }
      ]
      egress = [
        {
          protocol    = "tcp"
          from_port   = 0
          to_port     = 65535
          cidr_blocks = ["0.0.0.0/0"]
          description = "All TCP outbound"
        }
      ]
    }
    
    app = {
      description = "Security group pour serveurs applicatifs"
      ingress = [
        {
          protocol    = "tcp"
          from_port   = 8080
          to_port     = 8080
          cidr_blocks = ["10.0.0.0/16"]
          description = "Application port from VPC"
        },
        {
          protocol    = "tcp"
          from_port   = 22
          to_port     = 22
          cidr_blocks = ["10.0.0.0/16"]
          description = "SSH from VPC"
        }
      ]
      egress = []
    }
    
    database = {
      description = "Security group pour bases de données"
      ingress = [
        {
          protocol    = "tcp"
          from_port   = 3306
          to_port     = 3306
          cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
          description = "MySQL from app subnets"
        },
        {
          protocol    = "tcp"
          from_port   = 5432
          to_port     = 5432
          cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
          description = "PostgreSQL from app subnets"
        }
      ]
      egress = []
    }
  }
}

# Configuration pour les règles communes
variable "allow_icmp" {
  type        = bool
  description = "Autoriser ICMP (ping) pour tous les security groups"
  default     = true
}

variable "management_cidr" {
  type        = string
  description = "CIDR pour accès management/bastion"
  default     = "0.0.0.0/0"
}
```

Créez **locals.tf** :
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Métadonnées communes
  common_metadata = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
  
  # BONNE PRATIQUE : Ajouter des règles ICMP automatiquement si activé
  security_groups_with_icmp = {
    for sg_name, sg_config in var.security_groups : sg_name => {
      description = sg_config.description
      ingress = concat(
        sg_config.ingress,
        var.allow_icmp ? [{
          protocol    = "icmp"
          from_port   = -1
          to_port     = -1
          cidr_blocks = ["0.0.0.0/0"]
          description = "ICMP from anywhere"
        }] : []
      )
      egress = sg_config.egress
    }
  }
  
  # BONNE PRATIQUE : Générer des règles de sortie par défaut si non spécifiées
  security_groups_final = {
    for sg_name, sg_config in local.security_groups_with_icmp : sg_name => {
      description = sg_config.description
      ingress     = sg_config.ingress
      egress = length(sg_config.egress) > 0 ? sg_config.egress : [
        {
          protocol    = "tcp"
          from_port   = 0
          to_port     = 65535
          cidr_blocks = ["0.0.0.0/0"]
          description = "All TCP outbound (default)"
        },
        {
          protocol    = "udp"
          from_port   = 0
          to_port     = 65535
          cidr_blocks = ["0.0.0.0/0"]
          description = "All UDP outbound (default)"
        }
      ]
    }
  }
}
```

Créez **security-groups.tf** :
```hcl
# BONNE PRATIQUE : Créer les security groups avec for_each
resource "openstack_compute_secgroup_v2" "groups" {
  for_each = local.security_groups_final
  
  name        = "${local.name_prefix}-sg-${each.key}"
  description = each.value.description
}

# BONNE PRATIQUE : Créer les règles d'ingress séparément pour plus de flexibilité
resource "openstack_compute_secgroup_v2" "ingress_rules" {
  for_each = {
    for pair in flatten([
      for sg_name, sg_config in local.security_groups_final : [
        for idx, rule in sg_config.ingress : {
          sg_name     = sg_name
          rule_key    = "${sg_name}-ingress-${idx}"
          protocol    = rule.protocol
          from_port   = rule.from_port
          to_port     = rule.to_port
          cidr_blocks = rule.cidr_blocks
          description = rule.description
        }
      ]
    ]) : pair.rule_key => pair
  }
  
  name        = "${local.name_prefix}-sg-${each.value.sg_name}"
  description = openstack_compute_secgroup_v2.groups[each.value.sg_name].description
  
  # Règle d'ingress
  dynamic "rule" {
    for_each = each.value.cidr_blocks
    content {
      from_port   = each.value.from_port
      to_port     = each.value.to_port
      ip_protocol = each.value.protocol
      cidr        = rule.value
    }
  }
  
  depends_on = [openstack_compute_secgroup_v2.groups]
}

# BONNE PRATIQUE : Créer les règles d'egress séparément
resource "openstack_compute_secgroup_v2" "egress_rules" {
  for_each = {
    for pair in flatten([
      for sg_name, sg_config in local.security_groups_final : [
        for idx, rule in sg_config.egress : {
          sg_name     = sg_name
          rule_key    = "${sg_name}-egress-${idx}"
          protocol    = rule.protocol
          from_port   = rule.from_port
          to_port     = rule.to_port
          cidr_blocks = rule.cidr_blocks
          description = rule.description
        }
      ]
    ]) : pair.rule_key => pair
  }
  
  name        = "${local.name_prefix}-sg-${each.value.sg_name}"
  description = openstack_compute_secgroup_v2.groups[each.value.sg_name].description
  
  # Règle d'egress
  dynamic "rule" {
    for_each = each.value.cidr_blocks
    content {
      from_port   = each.value.from_port
      to_port     = each.value.to_port
      ip_protocol = each.value.protocol
      cidr        = rule.value
    }
  }
  
  depends_on = [openstack_compute_secgroup_v2.groups]
}

# Security group bastion/management séparé
resource "openstack_compute_secgroup_v2" "bastion" {
  name        = "${local.name_prefix}-sg-bastion"
  description = "Security group pour bastion/jump host"
  
  # SSH depuis management CIDR
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = var.management_cidr
  }
  
  # ICMP
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
  
  # Egress
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}
```

Créez **outputs.tf** :
```hcl
# BONNE PRATIQUE : Outputs structurés pour réutilisation
output "security_groups" {
  value = {
    for sg_name, sg in openstack_compute_secgroup_v2.groups : sg_name => {
      id          = sg.id
      name        = sg.name
      description = sg.description
    }
  }
  description = "Security groups créés (format portable)"
}

output "security_group_ids" {
  value = {
    for sg_name, sg in openstack_compute_secgroup_v2.groups : sg_name => sg.id
  }
  description = "Mapping nom => ID des security groups"
}

output "security_group_names" {
  value = {
    for sg_name, sg in openstack_compute_secgroup_v2.groups : sg_name => sg.name
  }
  description = "Mapping nom => nom complet des security groups"
}

output "bastion_security_group" {
  value = {
    id   = openstack_compute_secgroup_v2.bastion.id
    name = openstack_compute_secgroup_v2.bastion.name
  }
  description = "Security group bastion"
}

output "security_rules_summary" {
  value = {
    for sg_name, sg_config in var.security_groups : sg_name => {
      ingress_rules_count = length(sg_config.ingress)
      egress_rules_count  = length(sg_config.egress)
      ingress_rules = [
        for rule in sg_config.ingress : 
        "${rule.protocol}:${rule.from_port}-${rule.to_port} from ${join(",", rule.cidr_blocks)}"
      ]
    }
  }
  description = "Résumé des règles de sécurité"
}

# BONNE PRATIQUE : Output pour faciliter les références
output "sg_references" {
  value = {
    web      = openstack_compute_secgroup_v2.groups["web"].name
    app      = openstack_compute_secgroup_v2.groups["app"].name
    database = openstack_compute_secgroup_v2.groups["database"].name
    bastion  = openstack_compute_secgroup_v2.bastion.name
  }
  description = "Références rapides aux security groups"
}
```

Créez **documentation.tf** :
```hcl
# Générer une documentation des security groups
resource "local_file" "security_documentation" {
  filename = "${path.module}/SECURITY-GROUPS.md"
  content  = <<-EOT
    # Security Groups Configuration
    
    Environment: **${var.environment}**
    Project: **${var.project_name}**
    Generated: ${timestamp()}
    
    ## Security Groups Overview
    
    ${join("\n\n", [
      for sg_name, sg_config in var.security_groups :
      <<-SG
      ### ${upper(sg_name)} Security Group
      
      **Name**: ${local.name_prefix}-sg-${sg_name}
      **Description**: ${sg_config.description}
      **ID**: ${openstack_compute_secgroup_v2.groups[sg_name].id}
      
      #### Ingress Rules
      ${join("\n", [
        for rule in sg_config.ingress :
        "- **${rule.protocol}** port ${rule.from_port}${rule.from_port != rule.to_port ? "-${rule.to_port}" : ""} from ${join(", ", rule.cidr_blocks)} - ${rule.description}"
      ])}
      
      #### Egress Rules
      ${length(sg_config.egress) > 0 ? join("\n", [
        for rule in sg_config.egress :
        "- **${rule.protocol}** port ${rule.from_port}${rule.from_port != rule.to_port ? "-${rule.to_port}" : ""} to ${join(", ", rule.cidr_blocks)} - ${rule.description}"
      ]) : "- All outbound traffic allowed (default)"}
      SG
    ])}
    
    ## Bastion Security Group
    
    **Name**: ${local.name_prefix}-sg-bastion
    **ID**: ${openstack_compute_secgroup_v2.bastion.id}
    
    - SSH (22) from ${var.management_cidr}
    - ICMP from anywhere
    - All outbound traffic
    
    ## Usage Examples
    
    ### Terraform
    ```hcl
    # Référencer un security group
    security_groups = [
      "${openstack_compute_secgroup_v2.groups["web"].name}",
      "${openstack_compute_secgroup_v2.bastion.name}"
    ]
    ```
    
    ### OpenStack CLI
    ```bash
    # Lister les security groups
    openstack security group list --project ${var.project_name}
    
    # Voir les règles d'un security group
    openstack security group show ${openstack_compute_secgroup_v2.groups["web"].name}
    ```
  EOT
}

# Générer un fichier de configuration pour les tests
resource "local_file" "security_test_config" {
  filename = "${path.module}/security-test.yaml"
  content = yamlencode({
    security_groups = {
      for sg_name, sg in openstack_compute_secgroup_v2.groups : sg_name => {
        id   = sg.id
        name = sg.name
        ingress_rules = [
          for rule in var.security_groups[sg_name].ingress : {
            protocol = rule.protocol
            ports    = "${rule.from_port}:${rule.to_port}"
            sources  = rule.cidr_blocks
          }
        ]
      }
    }
    bastion = {
      id   = openstack_compute_secgroup_v2.bastion.id
      name = openstack_compute_secgroup_v2.bastion.name
    }
  })
}
```

Créez **terraform.tfvars** :
```hcl
cloud_name   = "workshop-dev"
environment  = "dev"
project_name = "workshop"

allow_icmp        = true
management_cidr   = "203.0.113.0/24"  # Remplacer par votre IP publique

security_groups = {
  web = {
    description = "Security group pour serveurs web publics"
    ingress = [
      {
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP depuis Internet"
      },
      {
        protocol    = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS depuis Internet"
      },
      {
        protocol    = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_blocks = ["10.0.0.0/16"]
        description = "SSH depuis VPC uniquement"
      }
    ]
    egress = [
      {
        protocol    = "tcp"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = ["0.0.0.0/0"]
        description = "Tout trafic sortant TCP"
      },
      {
        protocol    = "udp"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = ["0.0.0.0/0"]
        description = "Tout trafic sortant UDP"
      }
    ]
  }
  
  app = {
    description = "Security group pour serveurs applicatifs privés"
    ingress = [
      {
        protocol    = "tcp"
        from_port   = 8080
        to_port     = 8080
        cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
        description = "Application port depuis subnets publics"
      },
      {
        protocol    = "tcp"
        from_port   = 8443
        to_port     = 8443
        cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
        description = "Application port HTTPS depuis subnets publics"
      },
      {
        protocol    = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_blocks = ["10.0.0.0/16"]
        description = "SSH depuis VPC"
      }
    ]
    egress = []  # Utilise les règles par défaut
  }
  
  database = {
    description = "Security group pour bases de données"
    ingress = [
      {
        protocol    = "tcp"
        from_port   = 3306
        to_port     = 3306
        cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
        description = "MySQL depuis subnets applicatifs"
      },
      {
        protocol    = "tcp"
        from_port   = 5432
        to_port     = 5432
        cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
        description = "PostgreSQL depuis subnets applicatifs"
      },
      {
        protocol    = "tcp"
        from_port   = 6379
        to_port     = 6379
        cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
        description = "Redis depuis subnets applicatifs"
      },
      {
        protocol    = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_blocks = ["10.0.0.0/16"]
        description = "SSH depuis VPC"
      }
    ]
    egress = []
  }
  
  cache = {
    description = "Security group pour cache (Redis, Memcached)"
    ingress = [
      {
        protocol    = "tcp"
        from_port   = 6379
        to_port     = 6379
        cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
        description = "Redis depuis app subnets"
      },
      {
        protocol    = "tcp"
        from_port   = 11211
        to_port     = 11211
        cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
        description = "Memcached depuis app subnets"
      }
    ]
    egress = []
  }
}
```

**Exécution** :
```bash
terraform init
terraform plan
terraform apply

# Examiner les security groups créés
terraform output security_groups
terraform output security_rules_summary
terraform output sg_references

# Lire la documentation générée
cat SECURITY-GROUPS.md

# Voir la configuration de test
cat security-test.yaml

```
