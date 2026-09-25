# Sorties du module stockage.

output "backup_bucket_name" {
  description = "Nom du bucket de sauvegardes."
  value       = google_storage_bucket.backup.name
}

output "logs_bucket_name" {
  description = "Nom du bucket d'exports de journaux."
  value       = google_storage_bucket.logs.name
}