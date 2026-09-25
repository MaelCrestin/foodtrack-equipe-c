# Module stockage : bucket de sauvegardes, bucket d'exports de journaux et
# puits de journaux qui l'alimente.

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

# Bucket des sauvegardes de configuration. Versionné et privé ; les versions
# remplacées sont supprimées après retention_days jours pour borner le coût,
# la version courante est conservée.
resource "google_storage_bucket" "backup" {
  project                     = var.project_id
  name                        = var.backup_bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.force_destroy
  versioning { enabled = true }
  lifecycle_rule {
    condition {
      age        = var.retention_days
      with_state = "ARCHIVED"
    }
    action { type = "Delete" }
  }
}

# Bucket d'exports de journaux. La politique de rétention interdit toute
# suppression avant retention_days jours ; la purge au-delà est faite par
# scripts/purge-logs.sh. Conséquence : terraform destroy échoue sur ce bucket
# tant qu'il contient des objets encore sous rétention, malgré force_destroy.
resource "google_storage_bucket" "logs" {
  project                     = var.project_id
  name                        = var.logs_bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.force_destroy
  versioning { enabled = true }
  retention_policy { retention_period = var.retention_days * 86400 }
}

# Puits de journaux du projet vers le bucket d'exports, filtré par log_filter.
# Une identité d'écriture propre au puits évite de partager un compte.
resource "google_logging_project_sink" "gke" {
  project                = var.project_id
  name                   = "${var.name_prefix}-gke-logs"
  destination            = "storage.googleapis.com/${google_storage_bucket.logs.name}"
  filter                 = var.log_filter
  unique_writer_identity = true
}

# Droit de création d'objets donné à l'identité du puits, sur ce seul bucket.
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.gke.writer_identity
}