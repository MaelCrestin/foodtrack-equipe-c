

# Lecture seule sur les ressources du projet : suffisant pour que
# `terraform plan` compare l'etat desire a l'etat reel. Aucune ecriture.
resource "google_project_iam_member" "ci_viewer_pour_plan" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

# Le verrouillage de l'etat Terraform ECRIT un objet de verrou dans le
# bucket (cf. phase 1) : une lecture seule ne suffit pas, `terraform plan`
# a besoin de creer et de supprimer ce verrou. Droit limite a CE bucket
# precis, jamais au niveau du projet.
resource "google_storage_bucket_iam_member" "ci_tfstate_access" {
  bucket = "foodtrack-c-tfstate-${var.project_id}"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

# Pendant son "refresh", `terraform plan` relit les ressources
# google_storage_bucket_iam_member existantes (celle juste au-dessus, et
# "sink_writer" dans modules/stockage) : ca demande storage.buckets.getIamPolicy,
# que ni "viewer" ni "objectAdmin" ne couvrent. Role predefini en lecture
# seule, limite a chaque bucket precis - pas de role personnalise
# (iam.roles.create n'est pas autorise sur ce projet).
resource "google_storage_bucket_iam_member" "ci_tfstate_bucket_read" {
  bucket = "foodtrack-c-tfstate-${var.project_id}"
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

resource "google_storage_bucket_iam_member" "ci_logs_bucket_read" {
  bucket = "foodtrack-c-logs-foodtrack-equipe-c"
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}