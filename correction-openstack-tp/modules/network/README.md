# Module Network

Module Terraform réutilisable pour créer des réseaux privés sur OpenStack.

## Description

Ce module crée :
- Un réseau privé
- Un sous-réseau avec configuration DHCP
- Un routeur (optionnel)
- Une interface vers le réseau externe (optionnel)

## Utilisation

```hcl
module "my_network" {
  source = "./modules/network"
  
  network_name          = "mon-reseau"
  subnet_cidr           = "192.168.1.0/24"
  dns_nameservers       = ["8.8.8.8", "8.8.4.4"]
  enable_dhcp           = true
  create_router         = true
  external_network_name = "public"
}
```

## Variables

| Nom | Type | Description | Défaut | Requis |
|-----|------|-------------|--------|--------|
| network_name | string | Nom du réseau | - | Oui |
| subnet_cidr | string | CIDR du sous-réseau | - | Oui |
| dns_nameservers | list(string) | Liste des DNS | ["8.8.8.8", "8.8.4.4"] | Non |
| enable_dhcp | bool | Activer DHCP | true | Non |
| create_router | bool | Créer un routeur | false | Non |
| external_network_name | string | Nom réseau externe | "" | Si create_router=true |

## Outputs

| Nom | Description |
|-----|-------------|
| network_id | ID du réseau créé |
| subnet_id | ID du sous-réseau créé |
| subnet_cidr | CIDR du sous-réseau |
| network_name | Nom du réseau |

## Exemple avec routeur

```hcl
module "public_network" {
  source = "./modules/network"
  
  network_name          = "public-network"
  subnet_cidr           = "10.0.1.0/24"
  create_router         = true
  external_network_name = "external"
}
```

## Exemple sans routeur (réseau isolé)

```hcl
module "private_network" {
  source = "./modules/network"
  
  network_name = "isolated-network"
  subnet_cidr  = "172.16.0.0/24"
  create_router = false
}
```
