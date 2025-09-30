# Module Security Group

Module Terraform réutilisable pour créer des groupes de sécurité avec règles dynamiques sur OpenStack.

## Description

Ce module crée :
- Un groupe de sécurité
- Des règles d'entrée (ingress) dynamiques basées sur une map

## Utilisation

```hcl
module "web_sg" {
  source = "./modules/security-group"
  
  name        = "web-security-group"
  description = "Security group for web servers"
  
  rules = {
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
      cidr     = "10.0.0.0/8"
    }
  }
}
```

## Variables

| Nom | Type | Description | Défaut | Requis |
|-----|------|-------------|--------|--------|
| name | string | Nom du groupe de sécurité | - | Oui |
| description | string | Description | - | Oui |
| rules | map(object) | Map des règles | {} | Non |

### Structure de la map rules

```hcl
rules = {
  "nom_regle" = {
    port     = 80        # Port (number)
    protocol = "tcp"     # Protocole (string)
    cidr     = "0.0.0.0/0"  # CIDR source (string)
  }
}
```

## Outputs

| Nom | Description |
|-----|-------------|
| security_group_id | ID du groupe de sécurité |
| security_group_name | Nom du groupe de sécurité |

## Exemples

### Groupe de sécurité pour base de données

```hcl
module "db_sg" {
  source = "./modules/security-group"
  
  name        = "database-sg"
  description = "Security group for PostgreSQL"
  
  rules = {
    postgres = {
      port     = 5432
      protocol = "tcp"
      cidr     = "10.0.0.0/16"
    }
    ssh = {
      port     = 22
      protocol = "tcp"
      cidr     = "192.168.1.0/24"
    }
  }
}
```

### Groupe de sécurité sans règles (règles ajoutées plus tard)

```hcl
module "empty_sg" {
  source = "./modules/security-group"
  
  name        = "empty-sg"
  description = "Empty security group"
  rules       = {}
}
```

## Notes

- Toutes les règles créées sont de type **ingress** (entrée)
- Le protocole peut être : tcp, udp, icmp
- Pour autoriser tout le trafic : cidr = "0.0.0.0/0"
- Pour restreindre à un réseau : cidr = "10.0.0.0/16"
