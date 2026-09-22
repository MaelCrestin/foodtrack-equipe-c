output "wif_provider_name" {
  description = "Nom complet du fournisseur OIDC. A copier dans la variable GitHub WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "ci_service_account_email" {
  description = "Adresse du compte de service du pipeline. A copier dans la variable GitHub CI_SERVICE_ACCOUNT"
  value       = google_service_account.ci.email
}

output "principal_set" {
  description = "Identite federee autorisee a emprunter le compte de service. Utile pour diagnostiquer un refus d echange de jeton"
  value       = google_service_account_iam_member.ci_workload_identity.member
}

output "project_number" {
  description = "Numero du projet, present dans le nom du pool et dans les messages d erreur IAM"
  value       = data.google_project.courant.number
}
