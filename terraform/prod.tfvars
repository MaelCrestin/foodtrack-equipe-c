# FoodTrack - equipe C - variables Terraform, environnement : prod
#
# dev.tfvars, test.tfvars et prod.tfvars portent VOLONTAIREMENT les memes
# valeurs : un seul cluster et un seul etat Terraform portent les trois
# environnements (contrainte du cahier des charges). Il n'existe donc qu'une
# infrastructure. Les differences entre dev, test et prod vivent dans
# Kustomize (manifests/overlays/), pas ici.
#
# Modifier une valeur = la modifier dans les TROIS fichiers, sinon le plan
# d'un environnement annoncera une derive sur l'infrastructure partagee.
# Voir README, section 8 "Un fichier de variables par environnement".
#
# notification_email n'est pas ici : export TF_VAR_notification_email="..."
# (le pipeline le passe avec -var).

equipe           = "c"
project_id       = "form-gke-eleve03-a8e9"
region           = "europe-west2"
zone             = "europe-west2-b"
storage_location = "europe-west2"

subnet_cidr            = "10.10.0.0/20"
pods_cidr              = "10.20.0.0/16"
services_cidr          = "10.30.0.0/20"
master_ipv4_cidr_block = "172.16.0.0/28"

admin_ssh_cidrs = ["5.39.6.57/32"]

# Plan de controle ouvert : compromis documente (README, section 4).
master_authorized_networks = [
  { cidr_block = "0.0.0.0/0", display_name = "github-actions-phase-3" }
]
enable_private_endpoint = false

# Dimensionnement justifie dans le README, section 5.
node_machine_type    = "e2-standard-2"
node_count           = 2
min_node_count       = 0
max_node_count       = 2
bastion_machine_type = "e2-micro"

backup_bucket_name    = "foodtrack-c-backups-foodtrack-equipe-c"
logs_bucket_name      = "foodtrack-c-logs-foodtrack-equipe-c"
retention_days        = 30
force_destroy_buckets = true

# Depot GitHub autorise a emprunter le compte de service du pipeline.
github_owner = "MaelCrestin"
github_repo  = "foodtrack-equipe-c"