# FoodTrack - equipe C - racine Terraform
#
# Cette racine declare le backend distant et appelle les modules. Le bucket
# de backend est cree a la main (exception documentee dans le README).

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # A FAIRE : verifier la derniere version stable
    }
  }

  backend "gcs" {
    bucket = "foodtrack-c-tfstate-foodtrack-equipe-c"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# A FAIRE : module reseau (vpc, sous-reseau, cloud router, cloud nat, pare-feu)
# module "reseau" {
#   source = "./modules/reseau"
#   ...
# }

# A FAIRE : module compute (cluster gke, node pool, bastion)
# module "compute" {
#   source = "./modules/compute"
#   ...
# }

# A FAIRE : module stockage (buckets de sauvegarde et d exports de journaux)
# module "stockage" {
#   source = "./modules/stockage"
#   ...
# }

# Fourni : federation d identite GitHub Actions -> Google Cloud.
# Copiez le contenu de labs/projet-final/terraform-fourni/wif-github/ dans
# terraform/modules/wif-github/ puis decommentez :
# module "wif_github" {
#   source = "./modules/wif-github"
#
#   project_id   = var.project_id
#   github_owner = "VOTRE-ORGANISATION-GITHUB"
#   github_repo  = "foodtrack-equipe-c"
# }
