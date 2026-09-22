# FoodTrack - projet final - federation d identite entre GitHub Actions et Google Cloud
#
# Module FOURNI. Vous l integrez tel quel a votre racine Terraform.
# Vous n avez pas a l ecrire, mais vous devez savoir l expliquer : les quatre
# pieces ci-dessous sont une question de soutenance.

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.3"
    }
  }
}

data "google_project" "courant" {
  project_id = var.project_id
}

# ---------------------------------------------------------------------------
# Piece 1 : le pool d identites de charge de travail
#
# Un conteneur logique qui regroupe des identites externes a Google Cloud.
# Il ne donne aucun droit par lui-meme.
#
# ATTENTION : la suppression d un pool est differee. L identifiant reste
# reserve, et recreer le pool sous le meme nom echoue sur :
#   Error 409: Requested entity already exists
# Le pool supprime reste visible avec :
#   gcloud iam workload-identity-pools list --location=global --show-deleted
# Changez d identifiant, ou restaurez le pool avec undelete.
# ---------------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "Pool GitHub Actions"
  description               = "Identites federees des executions GitHub Actions du projet FoodTrack"
}

# ---------------------------------------------------------------------------
# Piece 2 : le fournisseur OIDC
#
# Il declare a qui Google fait confiance (l emetteur GitHub), comment lire le
# jeton recu (attribute_mapping), et qui a le droit de s en servir
# (attribute_condition).
#
# attribute_condition est la barriere de securite. Sans elle, n importe quel
# depot GitHub de la planete pourrait presenter un jeton valide et emprunter
# votre compte de service. Google refuse d ailleurs de creer un fournisseur
# GitHub sans condition.
# ---------------------------------------------------------------------------
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub Actions OIDC"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  attribute_condition = "assertion.repository == \"${var.github_owner}/${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ---------------------------------------------------------------------------
# Piece 3 : le compte de service que le pipeline emprunte
#
# C est lui qui porte les droits reels. Le pipeline n a pas d identite propre
# dans Google Cloud : il se fait passer pour ce compte, le temps d une
# execution, avec un jeton de courte duree.
# ---------------------------------------------------------------------------
resource "google_service_account" "ci" {
  project      = var.project_id
  account_id   = var.ci_service_account_id
  display_name = "Compte de service du pipeline FoodTrack"
}

# ---------------------------------------------------------------------------
# Piece 4 : la liaison qui autorise l emprunt
#
# Elle dit : "les executions du depot <owner>/<repo>, et elles seules, peuvent
# emprunter ce compte de service".
#
# Restreindre par attribute.repository plutot que par le pool entier est ce qui
# empeche un autre depot de l organisation d utiliser ce compte.
# ---------------------------------------------------------------------------
resource "google_service_account_iam_member" "ci_workload_identity" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${var.github_repo}"
}

# ---------------------------------------------------------------------------
# Les droits du compte de service
#
# Deliberement minimaux : publier des images, et agir sur les objets
# Kubernetes du cluster. Pas de creation de cluster, pas d administration IAM,
# pas de roles/editor.
#
# Si votre pipeline doit aussi jouer terraform plan, ajoutez les roles
# necessaires via var.roles_supplementaires - et justifiez chacun d eux.
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "ci_roles" {
  for_each = toset(concat(
    [
      "roles/artifactregistry.writer",
      "roles/container.developer",
    ],
    var.roles_supplementaires
  ))

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci.email}"
}
