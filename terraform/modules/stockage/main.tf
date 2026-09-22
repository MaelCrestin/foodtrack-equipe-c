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

resource "google_logging_project_sink" "gke" {
  project                = var.project_id
  name                   = "${var.name_prefix}-gke-logs"
  destination            = "storage.googleapis.com/${google_storage_bucket.logs.name}"
  filter                 = var.log_filter
  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.gke.writer_identity
}
