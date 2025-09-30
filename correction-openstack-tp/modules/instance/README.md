# Module Instance

Module Terraform réutilisable pour créer des instances de calcul avec volumes optionnels sur OpenStack.

## Description

Ce module crée :
- Des instances de calcul (avec count)
- Des volumes de stockage (optionnel)
- L'attachement des volumes aux instances (optionnel)

## Utilisation Basique

```hcl
module "web_servers" {
  source = "./modules/instance"
  
  instance_count     = 3
  name_prefix        = "web-server"
  flavor_name        = "m1.small"
  image_name         = "Ubuntu-20.04"
  network_id         = "network-uuid-here"
  security_group_ids = ["default"]
}
```

## Utilisation Avancée avec Volumes

```hcl
module "db_servers" {
  source = "./modules/instance"
  
  instance_count     = 2
  name_prefix        = "db-server"
  flavor_name        = "m1.medium"
  image_name         = "Ubuntu-20.04"
  network_id         = module.network.network_id
  security_group_ids = [module.sg.security_group_name]
  
  metadata = {
    Environment = "production"
    Role        = "database"
  }
  
  create_volume = true
  volume_size   = 100
}
```

## Variables

| Nom | Type | Description | Défaut | Requis |
|-----|------|-------------|--------|--------|
| instance_count | number | Nombre d'instances | 1 | Non |
| name_prefix | string | Préfixe du nom | - | Oui |
| flavor_name | string | Nom du flavor | - | Oui |
| image_name | string | Nom de l'image | - | Oui |
| network_id | string | ID du réseau | - | Oui |
| security_group_ids | list(string) | Liste des groupes de sécurité | [] | Non |
| metadata | map(string) | Tags/Metadata | {} | Non |
| create_volume | bool | Créer des volumes | false | Non |
| volume_size | number | Taille volume (GB) | 10 | Non |

## Outputs

| Nom | Description |
|-----|-------------|
| instance_ids | Liste des IDs des instances |
| instance_ips | Liste des IPs privées |
| volume_ids | Liste des IDs des volumes (si créés) |
| instance_names | Liste des noms des instances |

## Exemples

### Instance unique sans volume

```hcl
module "jumpbox" {
  source = "./modules/instance"
  
  instance_count = 1
  name_prefix    = "jumpbox"
  flavor_name    = "m1.tiny"
  image_name     = "Ubuntu-20.04"
  network_id     = var.network_id
}
```

### Cluster de 5 instances avec volumes

```hcl
module "app_cluster" {
  source = "./modules/instance"
  
  instance_count     = 5
  name_prefix        = "app-node"
  flavor_name        = "m1.large"
  image_name         = "CentOS-8"
  network_id         = module.network.network_id
  security_group_ids = ["app-sg"]
  
  metadata = {
    Cluster = "production"
    Type    = "application"
  }
  
  create_volume = true
  volume_size   = 50
}
```

### Instances avec plusieurs groupes de sécurité

```hcl
module "secured_instances" {
  source = "./modules/instance"
  
  instance_count = 2
  name_prefix    = "secure-node"
  flavor_name    = "m1.small"
  image_name     = "Ubuntu-20.04"
  network_id     = var.network_id
  security_group_ids = [
    module.web_sg.security_group_name,
    module.monitoring_sg.security_group_name
  ]
}
```

## Naming Convention

Les instances sont nommées avec le pattern : `{name_prefix}-{index}`

Exemples :
- `web-server-1`, `web-server-2`, `web-server-3`
- `db-server-1`, `db-server-2`

Les volumes suivent le même pattern : `{name_prefix}-volume-{index}`

## Notes

- Les volumes sont automatiquement attachés aux instances correspondantes
- L'index commence à 1 (pas 0) pour plus de lisibilité
- Les data sources récupèrent automatiquement le flavor et l'image
- Si `create_volume = false`, aucun volume n'est créé
