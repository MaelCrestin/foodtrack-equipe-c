variable "project_id" {
  description = "Identifiant du projet Google Cloud de l equipe"
  type        = string
}

variable "github_owner" {
  description = "Proprietaire du depot GitHub : organisation ou compte utilisateur"
  type        = string
}

variable "github_repo" {
  description = "Nom du depot GitHub, sans le proprietaire"
  type        = string
}

variable "pool_id" {
  description = "Identifiant du pool d identites. Lettres minuscules, chiffres et tirets, 4 a 32 caracteres"
  type        = string
  default     = "github-pool"
}

variable "provider_id" {
  description = "Identifiant du fournisseur OIDC dans le pool"
  type        = string
  default     = "github-provider"
}

variable "ci_service_account_id" {
  description = "Identifiant du compte de service du pipeline"
  type        = string
  default     = "foodtrack-ci"
}

variable "roles_supplementaires" {
  description = "Roles IAM a ajouter au compte de service du pipeline, au-dela du minimum. Chaque role ajoute doit etre justifie dans le README du projet"
  type        = list(string)
  default     = []
}
