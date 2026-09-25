# Sorties du module compute.

output "cluster_name" {
  description = "Nom du cluster GKE."
  value       = google_container_cluster.this.name
}

output "cluster_location" {
  description = "Zone du cluster GKE."
  value       = google_container_cluster.this.location
}

output "cluster_endpoint" {
  description = "Adresse du plan de contrôle GKE."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "bastion_external_ip" {
  description = "Adresse IP publique du bastion."
  value       = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}

output "artifact_registry_url" {
  description = "Préfixe des images du dépôt Artifact Registry."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}