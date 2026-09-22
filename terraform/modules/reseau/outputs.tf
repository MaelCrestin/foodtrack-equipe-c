output "network_id" { value = google_compute_network.this.id }
output "network_name" { value = google_compute_network.this.name }
output "subnetwork_id" { value = google_compute_subnetwork.this.id }
output "subnetwork_name" { value = google_compute_subnetwork.this.name }
output "pods_range_name" { value = var.pods_range_name }
output "services_range_name" { value = var.services_range_name }
output "bastion_network_tag" { value = local.bastion_tag }

