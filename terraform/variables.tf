variable "project_id" {
  description = "Projet Google Cloud de l equipe"
  type        = string
  default = "poei-formation-gcp"
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
  description = "Lettre de l equipe, utilisee dans le prefixe des noms de ressources"
  type        = string
  default     = "c"
}

# A FAIRE : ajouter les variables specifiques a vos modules
# (machine_type, node_count, disk_size_gb, plages secondaires, etc.),
# avec des valeurs differentes par environnement dans dev.tfvars / test.tfvars / prod.tfvars
