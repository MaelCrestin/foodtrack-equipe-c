# Variables du module stockage. Les validations sont portées par la racine.

variable "project_id" {
  description = "Identifiant du projet Google Cloud."
  type        = string
}

variable "location" {
  description = "Emplacement des buckets."
  type        = string
}

variable "name_prefix" {
  description = "Préfixe des noms de ressources (foodtrack-<lettre>)."
  type        = string
}

variable "backup_bucket_name" {
  description = "Nom du bucket de sauvegardes."
  type        = string
}

variable "logs_bucket_name" {
  description = "Nom du bucket d'exports de journaux."
  type        = string
}

variable "retention_days" {
  description = "Durée de rétention, en jours, des journaux et des anciennes versions de sauvegardes."
  type        = number
}

variable "force_destroy" {
  description = "Autorise la suppression de buckets non vides au destroy."
  type        = bool
}

variable "log_filter" {
  description = "Filtre des journaux exportés."
  type        = string
}