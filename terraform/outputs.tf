# A FAIRE : exposer ici les sorties utiles, notamment celles du module wif-github
# une fois integre :
#
# output "wif_provider_name" {
#   value = module.wif_github.wif_provider_name
# }
#
# output "ci_service_account_email" {
#   value = module.wif_github.ci_service_account_email
# }
#
# Ces deux valeurs vont dans Settings > Secrets and variables > Actions > Variables
# du depot GitHub, sous les noms WIF_PROVIDER et CI_SERVICE_ACCOUNT.


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
