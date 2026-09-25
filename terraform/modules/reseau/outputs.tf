# Sorties du module réseau, consommées par le module compute.

output "network_id" {
  description = "Identifiant du VPC."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "Nom du VPC."
  value       = google_compute_network.this.name
}

output "subnetwork_id" {
  description = "Identifiant du sous-réseau."
  value       = google_compute_subnetwork.this.id
}

output "subnetwork_name" {
  description = "Nom du sous-réseau."
  value       = google_compute_subnetwork.this.name
}

output "pods_range_name" {
  description = "Nom de la plage secondaire des pods."
  value       = var.pods_range_name
}

output "services_range_name" {
  description = "Nom de la plage secondaire des Services."
  value       = var.services_range_name
}

output "bastion_network_tag" {
  description = "Étiquette réseau à poser sur le bastion."
  value       = local.bastion_tag
}