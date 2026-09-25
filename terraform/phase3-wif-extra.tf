# Droits complémentaires du compte de service du pipeline, nécessaires pour que
# GitHub Actions joue terraform plan. Le module wif-github fourni ne donne que
# l'écriture sur Artifact Registry et le déploiement Kubernetes. Aucun de ces
# droits ne permet de créer ou modifier une ressource Google Cloud.

# Lecture seule sur tout le projet, pour que terraform plan rafraîchisse l'état
# de chaque ressource. Rôle de base large, retenu comme compromis : à citer
# dans l'audit, l'alternative étant une liste de rôles de lecture par service.
resource "google_project_iam_member" "ci_viewer_pour_plan" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

# Lecture et écriture des objets du seul bucket d'état : terraform plan pose et
# retire un verrou, ce qui exige l'écriture. Portée limitée à ce bucket.
resource "google_storage_bucket_iam_member" "ci_tfstate_access" {
  bucket = local.tfstate_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

# Rôle personnalisé réduit à une permission : roles/viewer ne contient pas
# storage.buckets.getIamPolicy, nécessaire pour rafraîchir les
# google_storage_bucket_iam_member pendant le plan.
resource "google_project_iam_custom_role" "ci_lecteur_iam_buckets" {
  project     = var.project_id
  role_id     = "ciLecteurIamBuckets"
  title       = "CI - lecture des IAM de buckets"
  description = "Lecture seule : permet a terraform plan de rafraichir les google_storage_bucket_iam_member."
  permissions = ["storage.buckets.getIamPolicy"]
}

# Attribution du rôle personnalisé ci-dessus au compte de service du pipeline.
resource "google_project_iam_member" "ci_lecteur_iam_buckets" {
  project = var.project_id
  role    = google_project_iam_custom_role.ci_lecteur_iam_buckets.id
  member  = "serviceAccount:${module.wif_github.ci_service_account_email}"
}