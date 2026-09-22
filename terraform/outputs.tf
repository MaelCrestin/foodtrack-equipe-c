
output "network_name" { value = module.reseau.network_name }
output "subnetwork_name" { value = module.reseau.subnetwork_name }
output "cluster_name" { value = module.compute.cluster_name }
output "cluster_location" { value = module.compute.cluster_location }
output "cluster_endpoint" {
  value     = module.compute.cluster_endpoint
  sensitive = true
}
output "bastion_external_ip" { value = module.compute.bastion_external_ip }
output "artifact_registry_url" { value = module.compute.artifact_registry_url }
output "backup_bucket" { value = module.stockage.backup_bucket_name }
output "logs_bucket" { value = module.stockage.logs_bucket_name }
