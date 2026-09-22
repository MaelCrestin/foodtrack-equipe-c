output "cluster_name" { value = google_container_cluster.this.name }
output "cluster_location" { value = google_container_cluster.this.location }
output "cluster_endpoint" {
  value     = google_container_cluster.this.endpoint
  sensitive = true
}
output "bastion_external_ip" { value = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip }
output "artifact_registry_url" { value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}" }
