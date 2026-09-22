<<<<<<< HEAD
# FoodTrack - equipe C - racine Terraform
#
# Cette racine ne contient PAS les ressources elles-memes : elle declare le
# backend distant (ou Terraform range son etat), configure le provider
# Google, et plus tard appellera les modules. Pour l instant, volontairement
# minimal : juste de quoi faire un `terraform init` qui reussit.

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

=======
terraform {
>>>>>>> main
  backend "gcs" {
    bucket = "foodtrack-c-tfstate-poei-formation-gcp"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
<<<<<<< HEAD
}
=======
  zone    = var.zone
}

locals {
  prefix = "foodtrack-c"
  required_apis = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each           = local.required_apis
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

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

module "compute" {
  source = "./modules/compute"

  project_id                     = var.project_id
  region                         = var.region
  zone                           = var.zone
  name_prefix                    = local.prefix
  network_id                     = module.reseau.network_id
  subnetwork_id                  = module.reseau.subnetwork_id
  pods_range_name                = module.reseau.pods_range_name
  services_range_name            = module.reseau.services_range_name
  master_ipv4_cidr_block         = var.master_ipv4_cidr_block
  master_authorized_networks     = var.master_authorized_networks
  enable_private_endpoint        = var.enable_private_endpoint
  node_machine_type              = var.node_machine_type
  node_count                     = var.node_count
  min_node_count                 = var.min_node_count
  max_node_count                 = var.max_node_count
  bastion_machine_type           = var.bastion_machine_type
  bastion_network_tag            = module.reseau.bastion_network_tag
  bastion_source_image           = var.bastion_source_image

  depends_on = [google_project_service.required, module.reseau]
}

module "stockage" {
  source = "./modules/stockage"

  project_id             = var.project_id
  location               = var.storage_location
  name_prefix            = local.prefix
  backup_bucket_name     = var.backup_bucket_name
  logs_bucket_name       = var.logs_bucket_name
  retention_days         = var.retention_days
  force_destroy          = var.force_destroy_buckets
  log_filter             = var.log_filter

  depends_on = [google_project_service.required]
}
>>>>>>> main
