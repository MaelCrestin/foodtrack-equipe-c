resource "google_project_iam_member" "ci_viewer_pour_plan" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

resource "google_storage_bucket_iam_member" "ci_tfstate_access" {
  bucket = "foodtrack-c-tfstate-${var.project_id}"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

resource "google_project_iam_custom_role" "ci_lecteur_iam_buckets" {
  role_id     = "ciLecteurIamBuckets"
  title       = "CI - lecture des IAM de buckets"
  description = "Lecture seule : permet a terraform plan de rafraichir les google_storage_bucket_iam_member."
  permissions = ["storage.buckets.getIamPolicy"]
}

resource "google_project_iam_member" "ci_lecteur_iam_buckets" {
  project = var.project_id
  role    = google_project_iam_custom_role.ci_lecteur_iam_buckets.id
  member  = "serviceAccount:${module.wif_github.ci_service_account_email}"
}