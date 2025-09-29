# Workshop Terraform 1

### Objectifs du workshop

- Maîtriser les concepts fondamentaux de Terraform

- Comprendre HCL (HashiCorp Configuration Language)

- Gérer le state et le cycle de vie des ressources

- Créer des modules réutilisables

- Appliquer les bonnes pratiques



### Prérequis

- Terraform 1.5+ installé

- Un éditeur de code (VS Code recommandé)

- Terminal/ligne de commande



### Structure du workshop

```

terraform-workshop/

├── module1-bases/

├── module2-structures/

├── module3-fonctions/

```



### Installation rapide

```bash

# Vérifier Terraform

terraform version



# Créer la structure

mkdir -p terraform-workshop/{module1-bases,module2-structures,module3-fonctions}

cd terraform-workshop

```



---



## Module 1 : Les Bases du HCL



### Théorie



**Terraform** utilise un langage déclaratif (HCL) pour définir l'infrastructure. Les concepts clés :

- **Resources** : Composants d'infrastructure à créer

- **Variables** : Paramètres configurables

- **Outputs** : Valeurs à exposer

- **Providers** : Plugins pour interagir avec des APIs



### Exercice 1.1 : Premier fichier Terraform



```bash

cd module1-bases

mkdir exercice1.1

cd exercice1.1

```



Créez **main.tf** :

```hcl

# Configuration Terraform

terraform {

  required_version = ">= 1.5"

  required_providers {

    random = {

      source  = "hashicorp/random"

      version = "~> 3.5"

    }

    local = {

      source  = "hashicorp/local"

      version = "~> 2.4"

    }

  }

}



# Génération d'un ID aléatoire

resource "random_string" "server_id" {

  length  = 8

  special = false

  upper   = false

}



# Création d'un fichier local

resource "local_file" "greeting" {

  filename = "${path.module}/hello.txt"

  content  = "Hello from Terraform! Server ID: ${random_string.server_id.result}"

}



# Output pour afficher l'ID

output "server_id" {

  value       = random_string.server_id.result

  description = "L'identifiant unique du serveur"

}



output "file_path" {

  value = local_file.greeting.filename

}

```



**Exécution** :

```bash

# Initialiser Terraform

terraform init



# Voir le plan d'exécution

terraform plan



# Appliquer les changements

terraform apply



# Vérifier le fichier créé

cat hello.txt



# Afficher les outputs

terraform output



# Nettoyer

terraform destroy

```



### Exercice 1.2 : Variables et types de données



Créez **variables.tf** :

```hcl

variable "environment" {

  type        = string

  description = "Environnement de déploiement (dev, staging, prod)"

  default     = "dev"

  

  validation {

    condition     = contains(["dev", "staging", "prod"], var.environment)

    error_message = "L'environnement doit être dev, staging ou prod."

  }

}



variable "server_count" {

  type        = number

  description = "Nombre de serveurs à créer"

  default     = 3

  

  validation {

    condition     = var.server_count > 0 && var.server_count <= 10

    error_message = "Le nombre de serveurs doit être entre 1 et 10."

  }

}



variable "server_config" {

  type = object({

    cpu    = number

    memory = number

    disk   = number

  })

  description = "Configuration matérielle du serveur"

  default = {

    cpu    = 2

    memory = 4096

    disk   = 50

  }

}



variable "tags" {

  type = map(string)

  description = "Tags à appliquer aux ressources"

  default = {

    team    = "devops"

    project = "workshop"

    managed = "terraform"

  }

}



variable "allowed_ports" {

  type        = list(number)

  description = "Liste des ports autorisés"

  default     = [80, 443, 8080]

}



variable "enable_backup" {

  type        = bool

  description = "Activer les sauvegardes"

  default     = true

}

```



Créez **main.tf** :

```hcl

terraform {

  required_version = ">= 1.5"

  required_providers {

    local = {

      source  = "hashicorp/local"

      version = "~> 2.4"

    }

  }

}



# Fichier de configuration principal

resource "local_file" "config" {

  filename = "${path.module}/config-${var.environment}.json"

  content = jsonencode({

    environment = var.environment

    servers     = var.server_count

    config      = var.server_config

    tags        = var.tags

    ports       = var.allowed_ports

    backup      = var.enable_backup

    timestamp   = timestamp()

  })

}



# Fichier de configuration lisible

resource "local_file" "config_readable" {

  filename = "${path.module}/config-${var.environment}.txt"

  content  = <<-EOT

    ====================================

    CONFIGURATION ${upper(var.environment)}

    ====================================

    

    Nombre de serveurs: ${var.server_count}

    

    Configuration matérielle:

      - CPU: ${var.server_config.cpu} cores

      - RAM: ${var.server_config.memory} MB

      - Disque: ${var.server_config.disk} GB

    

    Ports autorisés: ${join(", ", var.allowed_ports)}

    

    Backup activé: ${var.enable_backup ? "Oui" : "Non"}

    

    Tags:

    ${join("\n", [for k, v in var.tags : "  - ${k}: ${v}"])}

    

    ====================================

  EOT

}

```



Créez **outputs.tf** :

```hcl

output "environment" {

  value = var.environment

}



output "total_cpu" {

  value       = var.server_count * var.server_config.cpu

  description = "Total de CPU alloués"

}



output "total_memory_gb" {

  value       = (var.server_count * var.server_config.memory) / 1024

  description = "Total de mémoire en GB"

}



output "config_summary" {

  value = {

    env     = var.environment

    servers = var.server_count

    backup  = var.enable_backup

  }

}

```



Créez **terraform.tfvars** :

```hcl

environment  = "staging"

server_count = 5



server_config = {

  cpu    = 4

  memory = 8192

  disk   = 100

}



tags = {

  team        = "platform"

  project     = "infrastructure"

  managed     = "terraform"

  cost_center = "engineering"

}



allowed_ports = [22, 80, 443, 3000, 8080]

enable_backup = true

```



**Exécution** :

```bash

cd ../exercice1.2



# Appliquer avec les valeurs par défaut

terraform init

terraform plan -var-file=terraform.tfvars

terraform apply -var-file=terraform.tfvars



# Vérifier les fichiers créés

cat config-dev.json

cat config-dev.txt



# Appliquer avec terraform.tfvars

terraform apply



# Appliquer avec des variables en ligne

terraform apply -var-file=terraform.tfvars -var="environment=prod" -var="server_count=10"



# Vérifier les outputs

terraform output

terraform output total_cpu

terraform output -json config_summary

```





---



## Module 2 : Structures de Contrôle



### Théorie



Terraform propose plusieurs mécanismes pour créer plusieurs ressources :

- **count** : Créer N instances identiques (utilise un index numérique)

- **for_each** : Créer des instances basées sur un map ou set (utilise des clés)

- **Conditions** : Créer ou non une ressource selon une condition



### Exercice 2.1 : Count - Boucles simples



```bash

cd ../../module2-structures

mkdir exercice2.1

cd exercice2.1

```



**variables.tf** :

```hcl

variable "server_count" {

  type    = number

  default = 5

}



variable "environment" {

  type    = string

  default = "dev"

}

```



**main.tf** :

```hcl

terraform {

  required_version = ">= 1.5"

  required_providers {

    random = {

      source  = "hashicorp/random"

      version = "~> 3.5"

    }

    local = {

      source  = "hashicorp/local"

      version = "~> 2.4"

    }

  }

}



# Génération d'UUID pour chaque serveur

resource "random_uuid" "server_ids" {

  count = var.server_count

}



# Génération de mots de passe

resource "random_password" "server_passwords" {

  count   = var.server_count

  length  = 16

  special = true

}



# Création d'un fichier par serveur

resource "local_file" "servers" {

  count    = var.server_count

  filename = "${path.module}/servers/server-${count.index}.json"

  content = jsonencode({

    id       = random_uuid.server_ids[count.index].result

    name     = "server-${count.index}"

    hostname = "${var.environment}-server-${count.index}"

    index    = count.index

    password = random_password.server_passwords[count.index].result

    created  = timestamp()

  })

}



# Fichier d'inventaire

resource "local_file" "inventory" {

  filename = "${path.module}/inventory.txt"

  content  = <<-EOT

    ===== INVENTAIRE DES SERVEURS =====

    Environnement: ${var.environment}

    Total: ${var.server_count} serveurs

    

    ${join("\n", [for i in range(var.server_count) : "- server-${i}: ${random_uuid.server_ids[i].result}"])}

    

    ===================================

  EOT

}

```



**outputs.tf** :

```hcl

output "all_server_ids" {

  value       = random_uuid.server_ids[*].result

  description = "Liste de tous les IDs de serveurs"

}



output "first_server_id" {

  value = random_uuid.server_ids[0].result

}



output "last_server_id" {

  value = random_uuid.server_ids[var.server_count - 1].result

}



output "server_count" {

  value = length(random_uuid.server_ids)

}

```



**Exécution** :

```bash

mkdir servers

terraform init

terraform apply



# Lister les fichiers créés

ls servers/

cat servers/server-0.json



# Voir l'inventaire

cat inventory.txt



# Modifier le nombre de serveurs

terraform apply -var="server_count=3"

terraform apply -var="server_count=7"

```



### Exercice 2.2 : For_each - Boucles avec maps



```bash

cd ../

mkdir exercice2.2

cd exercice2.2

```



**variables.tf** :

```hcl

variable "servers" {

  type = map(object({

    role     = string

    size     = string

    replicas = number

  }))

  description = "Configuration des serveurs"

  default = {

    web = {

      role     = "frontend"

      size     = "small"

      replicas = 2

    }

    api = {

      role     = "backend"

      size     = "medium"

      replicas = 3

    }

    db = {

      role     = "database"

      size     = "large"

      replicas = 1

    }

    cache = {

      role     = "cache"

      size     = "small"

      replicas = 2

    }

  }

}

```



**main.tf** :

```hcl

terraform {

  required_version = ">= 1.5"

  required_providers {

    random = {

      source  = "hashicorp/random"

      version = "~> 3.5"

    }

    local = {

      source  = "hashicorp/local"

      version = "~> 2.4"

    }

  }

}



# Génération de mots de passe pour chaque type de serveur

resource "random_password" "server_passwords" {

  for_each = var.servers

  

  length  = 20

  special = true

}



# UUID pour chaque serveur

resource "random_uuid" "server_uuids" {

  for_each = var.servers

}



# Configuration pour chaque type de serveur

resource "local_file" "server_configs" {

  for_each = var.servers

  

  filename = "${path.module}/configs/${each.key}-config.json"

  content = jsonencode({

    server_type = each.key

    uuid        = random_uuid.server_uuids[each.key].result

    role        = each.value.role

    size        = each.value.size

    replicas    = each.value.replicas

    password    = random_password.server_passwords[each.key].result

    created_at  = timestamp()

  })

}



# Documentation pour chaque serveur

resource "local_file" "server_docs" {

  for_each = var.servers

  

  filename = "${path.module}/docs/${each.key}-README.md"

  content  = <<-EOT

    # Serveur ${upper(each.key)}

    

    ## Informations générales

    - Type: ${each.key}

    - Rôle: ${each.value.role}

    - Taille: ${each.value.size}

    - Réplicas: ${each.value.replicas}

    - UUID: ${random_uuid.server_uuids[each.key].result}

    

    ## Accès

    Password stocké dans le fichier de configuration sécurisé.

    

    ## Configuration

    Voir configs/${each.key}-config.json pour les détails complets.

  EOT

}



# Fichier récapitulatif

locals {

  total_replicas = sum([for s in var.servers : s.replicas])

}



resource "local_file" "summary" {

  filename = "${path.module}/SUMMARY.md"

  content  = <<-EOT

    # Résumé de l'infrastructure

    

    ## Statistiques

    - Types de serveurs: ${length(var.servers)}

    - Total de réplicas: ${local.total_replicas}

    

    ## Serveurs par rôle

    ${join("\n", [for k, v in var.servers : "- ${k} (${v.role}): ${v.replicas} réplicas - ${v.size}"])}

    

    ## Distribution par rôle

    ${join("\n", distinct([for k, v in var.servers : "- ${v.role}: ${join(", ", [for k2, v2 in var.servers : k2 if v2.role == v.role])}"]))}

  EOT

}

```



**outputs.tf** :

```hcl

output "server_roles" {

  value = { for k, v in var.servers : k => v.role }

}



output "server_uuids" {

  value = { for k, v in random_uuid.server_uuids : k => v.result }

}



output "total_replicas" {

  value = sum([for s in var.servers : s.replicas])

}



output "servers_by_size" {

  value = {

    for size in distinct([for s in var.servers : s.size]) :

    size => [for k, v in var.servers : k if v.size == size]

  }

}



output "backend_servers" {

  value = [for k, v in var.servers : k if v.role == "backend"]

}

```



**Exécution** :

```bash

mkdir -p configs docs

terraform init

terraform apply



# Explorer les fichiers créés

ls configs/

cat configs/web-config.json

cat docs/api-README.md

cat SUMMARY.md



# Voir les outputs

terraform output

terraform output -json servers_by_size

```



### Exercice 2.3 : Conditions



```bash

cd ../

mkdir exercice2.3

cd exercice2.3

```



**variables.tf** :

```hcl

variable "environment" {

  type    = string

  default = "dev"

}



variable "enable_monitoring" {

  type    = bool

  default = true

}



variable "enable_backup" {

  type    = bool

  default = false

}



variable "enable_logging" {

  type    = bool

  default = true

}



variable "enable_alerts" {

  type    = bool

  default = false

}

```



**main.tf** :

```hcl

terraform {

  required_version = ">= 1.5"

  required_providers {

    local = {

      source  = "hashicorp/local"

      version = "~> 2.4"

    }

    random = {

      source  = "hashicorp/random"

      version = "~> 3.5"

    }

  }

}



# Monitoring - créé seulement si activé

resource "local_file" "monitoring_config" {

  count = var.enable_monitoring ? 1 : 0

  

  filename = "${path.module}/monitoring.conf"

  content  = <<-EOT

    [monitoring]

    enabled = true

    interval = ${var.environment == "prod" ? "30s" : "60s"}

    retention = ${var.environment == "prod" ? "90d" : "30d"}

  EOT

}



# Backup - créé seulement si activé

resource "local_file" "backup_config" {

  count = var.enable_backup ? 1 : 0

  

  filename = "${path.module}/backup.conf"

  content  = <<-EOT

    [backup]

    enabled = true

    frequency = ${var.environment == "prod" ? "hourly" : "daily"}

    retention = ${var.environment == "prod" ? 30 : 7}

  EOT

}



# Logging - créé seulement si activé

resource "local_file" "logging_config" {

  count = var.enable_logging ? 1 : 0

  

  filename = "${path.module}/logging.conf"

  content  = <<-EOT

    [logging]

    enabled = true

    level = ${var.environment == "prod" ? "warn" : "debug"}

    output = ${var.environment == "prod" ? "syslog" : "stdout"}

  EOT

}



# Alerts - créé seulement si activé ET en production

resource "local_file" "alerts_config" {

  count = var.enable_alerts && var.environment == "prod" ? 1 : 0

  

  filename = "${path.module}/alerts.conf"

  content  = <<-EOT

    [alerts]

    enabled = true

    email = ops@company.com

    slack = #production-alerts

  EOT

}



# Configuration principale avec logique conditionnelle

locals {

  is_production  = var.environment == "prod"

  is_development = var.environment == "dev"

  

  deployment_mode = local.is_production ? "PRODUCTION" : (

    local.is_development ? "DEVELOPMENT" : "STAGING"

  )

  

  max_connections = local.is_production ? 1000 : (

    local.is_development ? 10 : 100

  )

  

  cache_enabled = local.is_production || var.environment == "staging"

  

  features = {

    monitoring = var.enable_monitoring

    backup     = var.enable_backup

    logging    = var.enable_logging

    alerts     = var.enable_alerts && local.is_production

    cache      = local.cache_enabled

  }

}





resource "local_file" "main_config" {

  filename = "${path.module}/config.yaml"

  content  = <<-EOT

    environment: ${var.environment}

    mode: ${local.deployment_mode}

    

    performance:

      max_connections: ${local.max_connections}

      cache_enabled: ${local.cache_enabled}

    

    features:

      monitoring: ${local.features.monitoring}

      backup: ${local.features.backup}

      logging: ${local.features.logging}

      alerts: ${local.features.alerts}

      cache: ${local.features.cache}

    

    security:

      strict_mode: ${local.is_production}

      debug_mode: ${local.is_development}

  EOT

}



# Fichier de statut des features

resource "local_file" "feature_status" {

  filename = "${path.module}/FEATURES.md"

  content  = <<-EOT

    # État des fonctionnalités - ${upper(var.environment)}

    

    ## Fonctionnalités activées

    ${join("\n", [for k, v in local.features : "- ${k}: ${v ? "ACTIVÉ" : "DÉSACTIVÉ"}" if v])}

    

    ## Fonctionnalités désactivées

    ${join("\n", [for k, v in local.features : "- ${k}: ${v ? "ACTIVÉ" : "DÉSACTIVÉ"}" if !v])}

    

    ## Mode de déploiement

    ${local.deployment_mode}

    

    ## Configuration de performance

    - Connexions max: ${local.max_connections}

    - Cache: ${local.cache_enabled ? "Activé" : "Désactivé"}

  EOT

}

```



**outputs.tf** :

```hcl

output "deployment_mode" {

  value = local.deployment_mode

}



output "features_enabled" {

  value = {

    for k, v in local.features : k => v if v

  }

}



output "config_files_created" {

  value = concat(

    var.enable_monitoring ? ["monitoring.conf"] : [],

    var.enable_backup ? ["backup.conf"] : [],

    var.enable_logging ? ["logging.conf"] : [],

    var.enable_alerts && var.environment == "prod" ? ["alerts.conf"] : [],

    ["config.yaml", "FEATURES.md"]

  )

}

```



**Exécution** :

```bash

terraform init



# Test en dev (monitoring activé, backup non)

terraform apply -var="environment=dev"

ls *.conf



# Test en prod (toutes les features activées)

terraform apply \

  -var="environment=prod" \

  -var="enable_monitoring=true" \

  -var="enable_backup=true" \

  -var="enable_logging=true" \

  -var="enable_alerts=true"

  

ls *.conf

cat config.yaml

cat FEATURES.md



# Test sans monitoring

terraform apply -var="enable_monitoring=false"

```







---



## Module 3 : Fonctions Terraform



### Théorie



Terraform inclut de nombreuses fonctions built-in pour manipuler :

- **Strings** : upper, lower, trim, format, regex

- **Collections** : concat, merge, flatten, distinct

- **Numeric** : min, max, ceil, floor

- **Date/Time** : timestamp, formatdate

- **Encoding** : jsonencode, yamlencode, base64encode

- **Filesystem** : file, fileexists, templatefile



### Exercice 3.1 : Manipulation de données



```bash

cd ../../module3-fonctions

mkdir exercice3.1

cd exercice3.1

```



**variables.tf** :

```hcl

variable "environment" {

  type    = string

  default = "development"

}



variable "team_members" {

  type = list(string)

  default = [

    "alice@company.com",

    "bob@company.com",

    "charlie@company.com"

  ]

}



variable "base_config" {

  type = map(string)

  default = {

    region  = "eu-west-1"

    project = "workshop"

  }

}



variable "additional_config" {

  type = map(string)

  default = {

    team        = "platform"

    cost_center = "engineering"

  }

}



variable "allowed_ports" {

  type = list(number)

  default = [22, 80, 443]

}



variable "extra_ports" {

  type = list(number)

  default = [8080, 8443, 3000]

}

```



**main.tf** :

```hcl

terraform {

  required_version = ">= 1.5"

  required_providers {

    local = {

      source  = "hashicorp/local"

      version = "~> 2.4"

    }

  }

}



# ========== STRING FUNCTIONS ==========

locals {

  # Transformations de strings

  env_upper       = upper(var.environment)

  env_lower       = lower(var.environment)

  env_title       = title(var.environment)

  

  # Formatage

  formatted_name  = format("app-%s-%03d", var.environment, 42)

  padded_id       = format("%05d", 123)

  

  # Extraction et manipulation

  env_short       = substr(var.environment, 0, 3)

  env_trimmed     = trimspace("  ${var.environment}  ")

  

  # Remplacement

  env_sanitized   = replace(var.environment, "-", "_")

  

  # Join et split

  emails_joined   = join(", ", var.team_members)

  emails_list     = split("@", var.team_members[0])

  

  # Regex

  is_prod         = can(regex("^prod", var.environment))

}



# ========== COLLECTION FUNCTIONS ==========

locals {

  # Concatenation

  all_ports = concat(var.allowed_ports, var.extra_ports)

  

  # Distinct (supprimer les doublons)

  unique_ports = distinct(concat(var.allowed_ports, var.extra_ports, [80, 443]))

  

  # Merge de maps

  full_config = merge(var.base_config, var.additional_config, {

    environment = var.environment

    timestamp   = timestamp()

  })

  

  # Flatten (aplatir les listes imbriquées)

  nested_list = [[1, 2], [3, 4], [5, 6]]

  flat_list   = flatten(local.nested_list)

  

  # Slice (extraire une portion)

  first_two_members = slice(var.team_members, 0, 2)

  

  # Contains

  has_port_80 = contains(var.allowed_ports, 80)

  has_port_99 = contains(var.allowed_ports, 99)

  

  # Element (accès circulaire)

  first_member    = element(var.team_members, 0)

  wrapped_member  = element(var.team_members, 10) # Retourne l'index 10 % length

  

  # Reverse

  reversed_ports = reverse(var.allowed_ports)

  

  # Sort

  sorted_ports = sort(local.all_ports)

  

  # Keys et values

  config_keys   = keys(local.full_config)

  config_values = values(local.full_config)

  

  # Zipmap (créer un map à partir de deux listes)

  roles    = ["alice", "bob", "charlie"]

  titles   = ["Lead", "Developer", "DevOps"]

  role_map = zipmap(local.roles, local.titles)

}



# ========== NUMERIC FUNCTIONS ==========

locals {

  # Min et Max

  min_port = min(var.allowed_ports...)

  max_port = max(var.allowed_ports...)

  

  # Ceil, floor, round

  price       = 19.99

  price_ceil  = ceil(local.price)

  price_floor = floor(local.price)

  

  # Abs (valeur absolue)

  absolute = abs(-42)

  

  # Pow (puissance)

  squared = pow(5, 2)

  

  # Sum (somme via boucle)

  total_ports = length(local.all_ports)

}



# ========== DATE/TIME FUNCTIONS ==========

locals {

  # Timestamp actuel

  current_time = timestamp()

  

  # Formatage de dates

  formatted_date = formatdate("DD-MM-YYYY", local.current_time)

  formatted_time = formatdate("hh:mm:ss", local.current_time)

  formatted_full = formatdate("YYYY-MM-DD'T'hh:mm:ssZZZ", local.current_time)

  

  # Date ISO

  iso_date = formatdate("YYYY-MM-DD", local.current_time)

}



# ========== ENCODING FUNCTIONS ==========

locals {

  # JSON encoding

  json_config = jsonencode({

    environment = var.environment

    config      = local.full_config

    ports       = local.unique_ports

  })

  

  # YAML encoding

  yaml_config = yamlencode({

    environment = var.environment

    config      = local.full_config

  })

  

  # Base64

  secret         = "my-secret-password"

  encoded_secret = base64encode(local.secret)

  decoded_secret = base64decode(local.encoded_secret)

}



# ========== TYPE CONVERSION ==========

locals {

  # tostring, tonumber, tobool

  number_str = tostring(123)

  str_number = tonumber("456")

  bool_value = tobool("true")

  

  # tolist, tomap, toset

  ports_list = tolist(toset(local.all_ports))

  ports_set  = toset(local.all_ports)

  config_map = tomap(var.base_config)

}



# Fichier de démonstration de toutes les fonctions

resource "local_file" "functions_demo" {

  filename = "${path.module}/functions-output.json"

  content = jsonencode({

    string_functions = {

      upper          = local.env_upper

      lower          = local.env_lower

      title          = local.env_title

      formatted_name = local.formatted_name

      padded_id      = local.padded_id

      short          = local.env_short

      sanitized      = local.env_sanitized

      emails_joined  = local.emails_joined

      is_prod        = local.is_prod

    }

    

    collection_functions = {

      all_ports         = local.all_ports

      unique_ports      = local.unique_ports

      flat_list         = local.flat_list

      first_two_members = local.first_two_members

      has_port_80       = local.has_port_80

      has_port_99       = local.has_port_99

      reversed_ports    = local.reversed_ports

      sorted_ports      = local.sorted_ports

      role_map          = local.role_map

    }

    

    numeric_functions = {

      min_port    = local.min_port

      max_port    = local.max_port

      price_ceil  = local.price_ceil

      price_floor = local.price_floor

      absolute    = local.absolute

      squared     = local.squared

      total_ports = local.total_ports

    }

    

    datetime_functions = {

      current_time   = local.current_time

      formatted_date = local.formatted_date

      formatted_time = local.formatted_time

      iso_date       = local.iso_date

    }

    

    encoding_functions = {

      json_sample    = local.json_config

      encoded_secret = local.encoded_secret

    }

  })

}



# Fichier texte lisible

resource "local_file" "functions_readable" {

  filename = "${path.module}/functions-output.txt"

  content  = <<-EOT

    ====================================

    DÉMONSTRATION DES FONCTIONS TERRAFORM

    ====================================

    

    # STRING FUNCTIONS

    Environnement original: ${var.environment}

    Upper: ${local.env_upper}

    Lower: ${local.env_lower}

    Title: ${local.env_title}

    Formatted: ${local.formatted_name}

    Short (3 chars): ${local.env_short}

    

    # COLLECTION FUNCTIONS

    Ports combinés: ${join(", ", local.all_ports)}

    Ports uniques: ${join(", ", local.unique_ports)}

    Ports triés: ${join(", ", local.sorted_ports)}

    Min port: ${local.min_port}

    Max port: ${local.max_port}

    

    # DATE/TIME

    Timestamp: ${local.current_time}

    Date formatée: ${local.formatted_date}

    Heure formatée: ${local.formatted_time}

    

    # MEMBERS

    ${join("\n", [for email in var.team_members : "- ${email}"])}

    

    ====================================

  EOT

}

```



**outputs.tf** :

```hcl

output "string_operations" {

  value = {

    upper     = local.env_upper

    lower     = local.env_lower

    formatted = local.formatted_name

  }

}



output "collection_operations" {

  value = {

    total_ports  = length(local.all_ports)

    unique_ports = length(local.unique_ports)

    min_port     = local.min_port

    max_port     = local.max_port

  }

}



output "datetime_info" {

  value = {

    timestamp = local.current_time

    date      = local.formatted_date

  }

}

```



**Exécution** :

```bash

terraform init

terraform apply



# Examiner les résultats

cat functions-output.json | jq

cat functions-output.txt

```



### Exercice 3.2 : Templatefile



```bash

cd ../

mkdir exercice3.2

cd exercice3.2

```



Créez **server-config.tpl** :

```

====================================

APPLICATION: ${app_name}

ENVIRONMENT: ${environment}

====================================



SERVERS CONFIGURATION

---------------------

%{ for server in servers ~}

Server: ${server.name}

  - Role: ${server.role}

  - Size: ${server.size}

  - Status: ${server.enabled ? "ENABLED" : "DISABLED"}

%{ endfor ~}



NETWORK SETTINGS

----------------

Allowed Ports: ${join(", ", ports)}



TAGS

----

%{ for key, value in tags ~}

${key} = ${value}

%{ endfor ~}



FEATURES

--------

%{ if monitoring_enabled ~}

- Monitoring: ACTIVE (interval: ${monitoring_interval})

%{ else ~}

- Monitoring: INACTIVE

%{ endif ~}

%{ if backup_enabled ~}

- Backup: ACTIVE (retention: ${backup_retention} days)

%{ else ~}

- Backup: INACTIVE

%{ endif ~}



DATABASE CONNECTIONS

--------------------

%{ for db in databases ~}

${db.name}:

  host: ${db.host}

  port: ${db.port}

  database: ${db.name}

%{ endfor ~}



====================================

Generated: ${timestamp}

====================================

```



Créez **nginx-config.tpl** :

```

# NGINX Configuration

# Generated by Terraform



upstream backend {

%{ for server in backend_servers ~}

    server ${server.ip}:${server.port} weight=${server.weight};

%{ endfor ~}

}



server {

    listen ${listen_port};

    server_name ${server_name};



%{ if ssl_enabled ~}

    ssl_certificate /etc/nginx/ssl/${ssl_cert};

    ssl_certificate_key /etc/nginx/ssl/${ssl_key};

%{ endif ~}



    location / {

        proxy_pass http://backend;

        proxy_set_header Host $host;

        proxy_set_header X-Real-IP $remote_addr;

        

%{ if enable_caching ~}

        proxy_cache ${cache_zone};

        proxy_cache_valid 200 ${cache_ttl}m;

%{ endif ~}

    }



%{ for location in custom_locations ~}

    location ${location.path} {

        ${location.config}

    }

%{ endfor ~}

}

```



Créez **variables.tf** :

```hcl

variable "app_name" {

  type    = string

  default = "MyApplication"

}



variable "environment" {

  type    = string

  default = "production"

}



variable "monitoring_enabled" {

  type    = bool

  default = true

}



variable "backup_enabled" {

  type    = bool

  default = true

}

```



Créez **main.tf** :

```hcl

terraform {

  required_version = ">= 1.5"

  required_providers {

    local = {

      source  = "hashicorp/local"

      version = "~> 2.4"

    }

  }

}



locals {

  servers = [

    {

      name    = "web-01"

      role    = "frontend"

      size    = "medium"

      enabled = true

    },

    {

      name    = "web-02"

      role    = "frontend"

      size    = "medium"

      enabled = true

    },

    {

      name    = "api-01"

      role    = "backend"

      size    = "large"

      enabled = true

    },

    {

      name    = "worker-01"

      role    = "worker"

      size    = "small"

      enabled = false

    }

  ]



  databases = [

    {

      name = "postgres"

      host = "db-primary.internal"

      port = 5432

    },

    {

      name = "redis"

      host = "cache.internal"

      port = 6379

    }

  ]



  tags = {

    environment = var.environment

    team        = "platform"

    managed_by  = "terraform"

    cost_center = "engineering"

  }



  backend_servers = [

    { ip = "10.0.1.10", port = 8080, weight = 5 },

    { ip = "10.0.1.11", port = 8080, weight = 5 },

    { ip = "10.0.1.12", port = 8080, weight = 3 }

  ]



  custom_locations = [

    {

      path   = "/api"

      config = "proxy_pass http://api-backend;"

    },

    {

      path   = "/static"

      config = "alias /var/www/static;"

    }

  ]

}



# Utilisation du templatefile pour la configuration serveur

resource "local_file" "server_config" {

  filename = "${path.module}/generated-server-config.txt"

  content = templatefile("${path.module}/server-config.tpl", {

    app_name           = var.app_name

    environment        = var.environment

    servers            = local.servers

    ports              = [80, 443, 8080, 3000]

    tags               = local.tags

    monitoring_enabled = var.monitoring_enabled

    monitoring_interval = var.monitoring_enabled ? "30s" : "0s"

    backup_enabled     = var.backup_enabled

    backup_retention   = var.backup_enabled ? 30 : 0

    databases          = local.databases

    timestamp          = timestamp()

  })

}



# Utilisation du templatefile pour NGINX

resource "local_file" "nginx_config" {

  filename = "${path.module}/generated-nginx.conf"

  content = templatefile("${path.module}/nginx-config.tpl", {

    backend_servers  = local.backend_servers

    listen_port      = var.environment == "prod" ? 443 : 80

    server_name      = "${var.app_name}.example.com"

    ssl_enabled      = var.environment == "prod"

    ssl_cert         = "cert.pem"

    ssl_key          = "key.pem"

    enable_caching   = var.environment == "prod"

    cache_zone       = "app_cache"

    cache_ttl        = 60

    custom_locations = local.custom_locations

  })

}



# Configuration YAML générée dynamiquement

resource "local_file" "yaml_config" {

  filename = "${path.module}/config.yaml"

  content = yamlencode({

    application = var.app_name

    environment = var.environment

    servers     = local.servers

    databases   = local.databases

    features = {

      monitoring = var.monitoring_enabled

      backup     = var.backup_enabled

    }

    network = {

      ports = [80, 443, 8080, 3000]

    }

    metadata = {

      generated_at = timestamp()

      tags         = local.tags

    }

  })

}

```



**outputs.tf** :

```hcl

output "config_files_created" {

  value = [

    local_file.server_config.filename,

    local_file.nginx_config.filename,

    local_file.yaml_config.filename

  ]

}



output "active_servers" {

  value = [for s in local.servers : s.name if s.enabled]

}



output "backend_endpoints" {

  value = [for s in local.backend_servers : "${s.ip}:${s.port}"]

}

```



**Exécution** :

```bash

terraform init

terraform apply



# Examiner les fichiers générés

cat generated-server-config.txt

cat generated-nginx.conf

cat config.yaml



# Tester avec différents environnements

terraform apply -var="environment=dev" -var="monitoring_enabled=false"

cat generated-nginx.conf

```



