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

  backend "gcs" {
    bucket = "foodtrack-c-tfstate-poei-formation-gcp"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}