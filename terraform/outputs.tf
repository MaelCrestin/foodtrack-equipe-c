# Sorties de la racine : noms et adresses utiles à l'exploitation, au pipeline
# et au câblage de l'Ingress de production.

output "network_name" {
  description = "Nom du VPC de l'équipe."
  value       = module.reseau.network_name
}

output "subnetwork_name" {
  description = "Nom du sous-réseau portant les nœuds et le bastion."
  value       = module.reseau.subnetwork_name
}

output "cluster_name" {
  description = "Nom du cluster GKE, pour gcloud container clusters get-credentials."
  value       = module.compute.cluster_name
}

output "cluster_location" {
  description = "Zone du cluster GKE."
  value       = module.compute.cluster_location
}

output "cluster_endpoint" {
  description = "Adresse du plan de contrôle GKE."
  value       = module.compute.cluster_endpoint
  sensitive   = true
}

output "bastion_external_ip" {
  description = "Adresse IP publique du bastion (connexion SSH depuis admin_ssh_cidrs)."
  value       = module.compute.bastion_external_ip
}

output "artifact_registry_url" {
  description = "Préfixe des images Docker de l'équipe dans Artifact Registry."
  value       = module.compute.artifact_registry_url
}

output "backup_bucket" {
  description = "Nom du bucket de sauvegardes."
  value       = module.stockage.backup_bucket_name
}

output "logs_bucket" {
  description = "Nom du bucket d'exports de journaux."
  value       = module.stockage.logs_bucket_name
}

output "wif_provider_name" {
  description = "Nom complet du fournisseur OIDC GitHub, à copier dans la variable GitHub WIF_PROVIDER."
  value       = module.wif_github.wif_provider_name
}

output "ci_service_account_email" {
  description = "Adresse du compte de service utilisé par GitHub Actions, à copier dans la variable GitHub CI_SERVICE_ACCOUNT."
  value       = module.wif_github.ci_service_account_email
}

output "portail_qualite_prod_ip" {
  description = "Adresse IP publique fixe du portail qualité de production, cible du contrôle de disponibilité."
  value       = google_compute_global_address.portail_qualite_prod.address
}

output "portail_qualite_prod_ip_name" {
  description = "Nom de l'adresse réservée, à reporter dans l'annotation kubernetes.io/ingress.global-static-ip-name de l'Ingress de prod."
  value       = google_compute_global_address.portail_qualite_prod.name
}