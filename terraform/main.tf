# Racine Terraform de FoodTrack : état distant, fournisseur Google, activation
# des API et appel des modules réseau, compute, stockage et fédération
# d'identité GitHub. La supervision et les droits complémentaires du pipeline
# sont dans phase3-monitoring.tf et phase3-wif-extra.tf ; Terraform fusionne
# tous les fichiers .tf du dossier.

# État distant sur Cloud Storage, versioning activé sur le bucket (contrainte
# du CDC : l'état est partagé par toute l'équipe). Le bucket est créé à la main
# avant le premier terraform init : c'est la seule ressource hors Terraform,
# documentée comme telle. Un backend n'accepte ni variable ni local, d'où le
# nom en dur, qui doit rester égal à local.tfstate_bucket.
terraform {
  backend "gcs" {
    bucket = "foodtrack-c-tfstate-form-gke-eleve03-a8e9"
    prefix = "terraform/state"
  }
}

# Fournisseur Google, cantonné au projet et à la région attribués à l'équipe.
# default_labels pose les labels communs sur toutes les ressources qui
# acceptent des labels, pour suivre les coûts dans les rapports de facturation.
provider "google" {
  project        = var.project_id
  region         = var.region
  zone           = var.zone
  default_labels = local.labels_communs
}

# Valeurs dérivées partagées par toute la racine. L'environnement vaut
# "mutualise" : un seul cluster porte dev, test et prod, les environnements
# ne se distinguent qu'au niveau Kubernetes (namespaces et Kustomize).
# required_apis couvre toutes les API appelées par la configuration, y compris
# celles de la fédération d'identité (iam, iamcredentials, sts), pour qu'un
# redéploiement depuis un projet vierge fonctionne.
locals {
  prefix         = "foodtrack-${var.equipe}"
  tfstate_bucket = "${local.prefix}-tfstate-${var.project_id}"

  labels_communs = {
    projet        = "foodtrack"
    equipe        = var.equipe
    environnement = "mutualise"
    gere_par      = "terraform"
  }

  required_apis = toset([
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ])
}

# Active les API nécessaires avant toute autre ressource. disable_on_destroy
# à false : un destroy ne coupe pas une API dont d'autres ressources du projet
# peuvent dépendre.
resource "google_project_service" "required" {
  for_each           = local.required_apis
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Réseau privé : VPC, sous-réseau avec plages secondaires pour les pods et les
# services (mode natif VPC), Cloud NAT pour la sortie Internet des nœuds sans
# IP publique, pare-feu SSH du bastion.
module "reseau" {
  source = "./modules/reseau"

  project_id          = var.project_id
  region              = var.region
  name_prefix         = local.prefix
  subnet_cidr         = var.subnet_cidr
  pods_cidr           = var.pods_cidr
  services_cidr       = var.services_cidr
  admin_ssh_cidrs     = var.admin_ssh_cidrs
  pods_range_name     = "${local.prefix}-pods"
  services_range_name = "${local.prefix}-services"

  depends_on = [google_project_service.required]
}

# Calcul : cluster GKE Standard zonal unique, node pool pd-standard, bastion et
# dépôt d'images. La dépendance au réseau passe par les sorties référencées.
module "compute" {
  source = "./modules/compute"

  project_id                 = var.project_id
  region                     = var.region
  zone                       = var.zone
  name_prefix                = local.prefix
  network_id                 = module.reseau.network_id
  subnetwork_id              = module.reseau.subnetwork_id
  pods_range_name            = module.reseau.pods_range_name
  services_range_name        = module.reseau.services_range_name
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  master_authorized_networks = var.master_authorized_networks
  enable_private_endpoint    = var.enable_private_endpoint
  node_machine_type          = var.node_machine_type
  node_count                 = var.node_count
  min_node_count             = var.min_node_count
  max_node_count             = var.max_node_count
  bastion_machine_type       = var.bastion_machine_type
  bastion_network_tag        = module.reseau.bastion_network_tag
  bastion_source_image       = var.bastion_source_image

  depends_on = [google_project_service.required]
}

# Stockage : bucket de sauvegardes et bucket d'exports de journaux, avec le
# puits de journaux qui l'alimente.
module "stockage" {
  source = "./modules/stockage"

  project_id         = var.project_id
  location           = var.storage_location
  name_prefix        = local.prefix
  backup_bucket_name = var.backup_bucket_name
  logs_bucket_name   = var.logs_bucket_name
  retention_days     = var.retention_days
  force_destroy      = var.force_destroy_buckets
  log_filter         = var.log_filter

  depends_on = [google_project_service.required]
}

# Fédération d'identité GitHub Actions (module fourni) : le pipeline obtient
# un jeton de courte durée sans clé JSON de compte de service (contrainte du
# CDC).
module "wif_github" {
  source = "./modules/wif-github"

  project_id   = var.project_id
  github_owner = var.github_owner
  github_repo  = var.github_repo

  depends_on = [google_project_service.required]
}