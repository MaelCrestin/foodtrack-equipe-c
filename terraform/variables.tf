variable "project_id" {
  description = "Projet Google Cloud, PARTAGE entre les 5 equipes de la formation"
  type        = string
  default     = "poei-formation-gcp"
}

variable "region" {
  description = "Region attribuee a l equipe"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "Zone du cluster (mode Standard zonal)"
  type        = string
  default     = "europe-west2-b"
}

variable "equipe" {
  description = "Lettre de l equipe, utilisee dans le prefixe de toutes les ressources"
  type        = string
  default     = "c"
}