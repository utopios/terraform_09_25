# TP Terraform - Infrastructure Multi-Tiers avec Modules Réutilisables
 
## Objectif pédagogique
Créer une infrastructure complète multi-tiers (web, app, database) sur OpenStack en utilisant des modules partagés et réutilisables, avec conditions et itérations.
 
## Prérequis
- Accès à un environnement OpenStack
- Terraform installé (version >= 1.0)
- Une image disponible sur votre OpenStack
- Connaissance des concepts réseaux de base
 
## Scénario
 
Vous travaillez pour une entreprise qui déploie plusieurs applications. Vous devez créer des **modules génériques et partageables** que différentes équipes pourront réutiliser pour déployer leurs infrastructures.
 
### Architecture à déployer
 
```
┌─────────────────────────────────────┐
│         Load Balancer               │
│      (prod uniquement)              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Tier WEB (Nginx)               │
│  Dev: 1 instance / Prod: 2 instances│
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Tier APPLICATION (Backend)        │
│  Dev: 1 instance / Prod: 3 instances│
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Tier DATABASE (PostgreSQL)       │
│  Dev: 1 instance / Prod: 2 instances│
└─────────────────────────────────────┘
```
 
### Différences Dev vs Prod
 
| Caractéristique | DEV | PROD |
|----------------|-----|------|
| Instances Web | 1 | 2 |
| Instances App | 1 | 3 |
| Instances DB | 1 | 2 (avec volume supplémentaire) |
| Load Balancer | Non | Oui |
| Monitoring | Non | Oui |
| Backup volumes | Non | Oui |
| IP flottantes | Non | Oui (sur LB uniquement) |
| Flavor | small | medium |
 
## Structure du projet
 
```
terraform-openstack-tp/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
│
└── modules/
    ├── network/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security-group/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── instance/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── loadbalancer/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── volume/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```
 
## Travail à réaliser
 
### Module 1 : `network` (Réseau réutilisable)
 
Créez un module qui gère la création de réseaux privés et sous-réseaux.
 
**Doit accepter** :
- Nom du réseau
- CIDR du sous-réseau
- Liste des DNS servers
- Activation/désactivation DHCP
 
**Doit créer** :
- Un réseau OpenStack
- Un sous-réseau avec les paramètres fournis
- Un routeur (conditionnel, seulement si demandé)
- L'interface entre le routeur et le réseau externe (conditionnel)
 
**Doit retourner** :
- ID du réseau
- ID du sous-réseau
- CIDR du sous-réseau
 
**💡 Astuce** : Utilisez une variable boolean pour rendre le routeur conditionnel
 
---
 
### Module 2 : `security-group` (Groupes de sécurité génériques)
 
Créez un module qui génère des groupes de sécurité avec des règles dynamiques.
 
**Doit accepter** :
- Nom du groupe de sécurité
- Description
- Map de règles avec structure :
  ```
  {
    "rule_name" = {
      port     = 80
      protocol = "tcp"
      cidr     = "0.0.0.0/0"
    }
  }
  ```
 
**Doit créer** :
- Un groupe de sécurité
- Des règles en **itération avec for_each** sur la map de règles
 
**Doit retourner** :
- ID du groupe de sécurité
- Nom du groupe de sécurité
 
**💡 Astuce** : Utilisez `for_each` pour itérer sur la map de règles
 
---
 
### Module 3 : `instance` (Instances génériques)
 
Créez un module générique pour créer des instances de calcul.
 
**Doit accepter** :
- Nombre d'instances (pour utiliser count)
- Préfixe du nom
- Flavor
- Image
- Network ID
- Liste des security groups IDs
- Map de metadata (tags)
- Boolean pour créer un volume supplémentaire
- Taille du volume (si créé)
 
**Doit créer** :
- Des instances en **itération avec count**
- Des volumes conditionnellement (seulement si demandé)
- L'attachement des volumes aux instances (conditionnel)
 
**Doit retourner** :
- Liste des IDs d'instances
- Liste des IPs privées
- Liste des IDs de volumes (si créés)
 
**💡 Astuce** : Utilisez `count` avec un ternaire pour les volumes conditionnels
 
---
 
### Module 4 : `volume` (Volumes de stockage)
 
Créez un module pour gérer les volumes de stockage.
 
**Doit accepter** :
- Nombre de volumes
- Préfixe du nom
- Taille du volume
- Type de volume (optionnel)
- Map de metadata
 
**Doit créer** :
- Des volumes avec **count**
 
**Doit retourner** :
- Liste des IDs de volumes
- Liste des noms de volumes
 
---
 
### Module 5 : `loadbalancer` (Load Balancer)
 
Créez un module pour un load balancer.
 
**Doit accepter** :
- Nom du load balancer
- Subnet ID
- Liste des IDs des instances backend
- Port du service
- Protocole
- Boolean pour activer le health check
 
**Doit créer** :
- Un load balancer
- Un listener
- Un pool
- Des members en **itération avec for_each** sur les instances
- Un health monitor (conditionnel)
 
**Doit retourner** :
- ID du load balancer
- VIP address du load balancer
 
**💡 Astuce** : Utilisez `for_each` avec `toset()` pour créer les members
 
---
 
### Configuration principale (main.tf)
 
Dans votre fichier principal, vous devez :
 
1. **Créer un bloc `locals`** qui définit pour chaque tier :
   ```
   web_config = {
     count  = var.environment == "prod" ? 2 : 1
     flavor = var.environment == "prod" ? "m1.medium" : "m1.small"
     ...
   }
   ```
 
2. **Appeler le module network** pour créer :
   - Un réseau pour chaque tier (web, app, db) en utilisant **for_each**
 
3. **Appeler le module security-group** pour créer :
   - Groupes de sécurité pour web (80, 443, 22)
   - Groupes de sécurité pour app (8080, 22)
   - Groupes de sécurité pour db (5432, 22)
   - Utiliser **for_each** pour itérer sur une map de configurations
 
4. **Appeler le module instance** trois fois :
   - Pour le tier web (avec le bon count selon env)
   - Pour le tier app (avec le bon count selon env)
   - Pour le tier db (avec volumes supplémentaires en prod uniquement)
 
5. **Appeler le module loadbalancer** conditionnellement :
   - Seulement en production
   - Pointant vers les instances web
 
6. **Créer des volumes de backup** conditionnellement :
   - Seulement en prod pour les DBs
   - Utiliser le module volume
 
---
 
## Variables à définir
 
Dans `variables.tf`, créez au minimum :
 
- `environment` (avec validation dev/prod)
- `project_name`
- `openstack_*` (credentials)
- Possibilité d'ajouter d'autres variables selon vos besoins
 
---
 
## Outputs à créer
 
Affichez :
- Informations réseau de chaque tier
- IPs de toutes les instances par tier
- IP du load balancer (si créé)
- Liste des groupes de sécurité créés
- Résumé de la configuration déployée
 