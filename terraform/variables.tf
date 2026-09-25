# Variables d'entrée de la racine. Les valeurs sont portées par dev.tfvars,
# test.tfvars et prod.tfvars (identiques : infrastructure mutualisée).
# notification_email est passée hors fichier (TF_VAR_notification_email ou -var).
# Les validations sont centralisées ici : les modules ne sont appelés que par
# cette racine.

variable "project_id" {
  description = "Identifiant du projet Google Cloud de l'équipe."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id doit respecter le format d'un identifiant de projet Google Cloud."
  }
}

variable "equipe" {
  description = "Lettre de l'équipe, préfixe des ressources (foodtrack-<lettre>-...). Doit correspondre au nom du bucket d'état déclaré dans le backend."
  type        = string

  validation {
    condition     = contains(["a", "b", "c", "d", "e"], var.equipe)
    error_message = "equipe doit être une lettre de a à e."
  }
}

variable "region" {
  description = "Région attribuée à l'équipe ; toutes les ressources régionales y sont créées (les quotas se comptent par région)."
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "region doit être un nom de région Google Cloud, par exemple europe-west2."
  }
}

variable "zone" {
  description = "Zone du cluster zonal et du bastion, située dans la région de l'équipe."
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "zone doit être un nom de zone Google Cloud, par exemple europe-west2-b."
  }
}

variable "storage_location" {
  description = "Emplacement des buckets de sauvegarde et de journaux."
  type        = string
}

variable "subnet_cidr" {
  description = "Plage principale du sous-réseau (nœuds et bastion)."
  type        = string

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr doit être un bloc CIDR valide."
  }
}

variable "pods_cidr" {
  description = "Plage secondaire réservée aux pods (mode natif VPC)."
  type        = string

  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "pods_cidr doit être un bloc CIDR valide."
  }
}

variable "services_cidr" {
  description = "Plage secondaire réservée aux Services Kubernetes (mode natif VPC)."
  type        = string

  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "services_cidr doit être un bloc CIDR valide."
  }
}

variable "master_ipv4_cidr_block" {
  description = "Plage /28 du plan de contrôle GKE privé. Attribut immuable : le modifier recrée le cluster."
  type        = string

  validation {
    condition     = can(cidrhost(var.master_ipv4_cidr_block, 0)) && endswith(var.master_ipv4_cidr_block, "/28")
    error_message = "master_ipv4_cidr_block doit être un bloc CIDR en /28."
  }
}

variable "admin_ssh_cidrs" {
  description = "Adresses autorisées à se connecter en SSH au bastion."
  type        = list(string)

  validation {
    condition     = length(var.admin_ssh_cidrs) > 0 && !contains(var.admin_ssh_cidrs, "0.0.0.0/0") && alltrue([for c in var.admin_ssh_cidrs : can(cidrhost(c, 0))])
    error_message = "Fournissez au moins un CIDR d'administration précis et valide ; 0.0.0.0/0 est interdit."
  }
}

variable "master_authorized_networks" {
  description = "Réseaux autorisés à joindre le plan de contrôle. Liste vide : aucune restriction configurée. L'ouverture à 0.0.0.0/0 est un compromis documenté (exécuteurs GitHub à adresses variables)."
  type        = list(object({ cidr_block = string, display_name = string }))
  default     = []

  validation {
    condition     = alltrue([for n in var.master_authorized_networks : can(cidrhost(n.cidr_block, 0))])
    error_message = "Chaque cidr_block de master_authorized_networks doit être un bloc CIDR valide."
  }
}

variable "enable_private_endpoint" {
  description = "Si vrai, le plan de contrôle n'a plus d'adresse publique (nécessite un exécuteur auto-hébergé dans le VPC)."
  type        = bool
  default     = false
}

variable "node_machine_type" {
  description = "Type de machine des nœuds GKE. Familles E2 ou N2 uniquement : les autres n'acceptent pas de disque pd-standard (contrainte du CDC)."
  type        = string

  validation {
    condition     = can(regex("^(e2|n2)-", var.node_machine_type))
    error_message = "node_machine_type doit appartenir à la famille E2 ou N2."
  }
}

variable "node_count" {
  description = "Nombre de nœuds à la création du node pool. Ensuite géré par l'autoscaler et le script d'extinction."
  type        = number

  validation {
    condition     = var.node_count >= 0
    error_message = "node_count doit être positif ou nul."
  }
}

variable "min_node_count" {
  description = "Nombre minimal de nœuds de l'autoscaler du node pool. 0 autorise l'extinction nocturne."
  type        = number

  validation {
    condition     = var.min_node_count >= 0
    error_message = "min_node_count doit être positif ou nul."
  }
}

variable "max_node_count" {
  description = "Nombre maximal de nœuds de l'autoscaler du node pool (plafond de coût)."
  type        = number

  validation {
    condition     = var.max_node_count >= 1
    error_message = "max_node_count doit valoir au moins 1."
  }
}

variable "bastion_machine_type" {
  description = "Type de machine du bastion : la plus petite taille utile."
  type        = string

  validation {
    condition     = can(regex("^(e2|n2)-", var.bastion_machine_type))
    error_message = "bastion_machine_type doit appartenir à la famille E2 ou N2 (disque pd-standard)."
  }
}

variable "bastion_source_image" {
  description = "Image de démarrage du bastion."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "backup_bucket_name" {
  description = "Nom du bucket de sauvegardes (unique à l'échelle mondiale)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.backup_bucket_name))
    error_message = "backup_bucket_name doit être un nom de bucket Cloud Storage valide."
  }
}

variable "logs_bucket_name" {
  description = "Nom du bucket d'exports de journaux (unique à l'échelle mondiale)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.logs_bucket_name))
    error_message = "logs_bucket_name doit être un nom de bucket Cloud Storage valide."
  }
}

variable "retention_days" {
  description = "Durée de conservation, en jours, des journaux exportés et des anciennes versions de sauvegardes."
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 1
    error_message = "retention_days doit valoir au moins 1."
  }
}

variable "force_destroy_buckets" {
  description = "Autorise terraform destroy à supprimer des buckets non vides (nettoyage de fin de projet)."
  type        = bool
  default     = false
}

variable "log_filter" {
  description = "Filtre des journaux exportés vers le bucket de journaux."
  type        = string
  default     = "resource.type=\"k8s_container\""

  validation {
    condition     = length(trimspace(var.log_filter)) > 0
    error_message = "log_filter ne peut pas être vide : le puits exporterait tous les journaux du projet."
  }
}

variable "notification_email" {
  description = "Adresse qui reçoit l'alerte si le portail qualité de production ne répond plus. Passée hors dépôt (TF_VAR_notification_email ou -var)."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.notification_email))
    error_message = "notification_email doit être une adresse courriel valide."
  }
}

variable "github_owner" {
  description = "Propriétaire du dépôt GitHub autorisé à emprunter le compte de service du pipeline."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+$", var.github_owner))
    error_message = "github_owner doit être un nom de compte ou d'organisation GitHub."
  }
}

variable "github_repo" {
  description = "Nom du dépôt GitHub, sans le propriétaire."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "github_repo doit être un nom de dépôt GitHub."
  }
}
