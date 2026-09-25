# Variables du module compute. Les validations sont portées par la racine,
# seule appelante du module.

variable "project_id" {
  description = "Identifiant du projet Google Cloud."
  type        = string
}

variable "region" {
  description = "Région du dépôt Artifact Registry."
  type        = string
}

variable "zone" {
  description = "Zone du cluster zonal et du bastion."
  type        = string
}

variable "name_prefix" {
  description = "Préfixe des noms de ressources (foodtrack-<lettre>)."
  type        = string
}

variable "network_id" {
  description = "Identifiant du VPC."
  type        = string
}

variable "subnetwork_id" {
  description = "Identifiant du sous-réseau des nœuds et du bastion."
  type        = string
}

variable "pods_range_name" {
  description = "Nom de la plage secondaire des pods."
  type        = string
}

variable "services_range_name" {
  description = "Nom de la plage secondaire des Services."
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "Plage /28 du plan de contrôle privé."
  type        = string
}

variable "master_authorized_networks" {
  description = "Réseaux autorisés à joindre le plan de contrôle ; liste vide : aucune restriction configurée."
  type        = list(object({ cidr_block = string, display_name = string }))
}

variable "enable_private_endpoint" {
  description = "Supprime l'adresse publique du plan de contrôle."
  type        = bool
}

variable "node_machine_type" {
  description = "Type de machine des nœuds (E2 ou N2)."
  type        = string
}

variable "node_count" {
  description = "Nombre de nœuds à la création du node pool."
  type        = number
}

variable "min_node_count" {
  description = "Minimum de l'autoscaler du node pool."
  type        = number
}

variable "max_node_count" {
  description = "Maximum de l'autoscaler du node pool."
  type        = number
}

variable "bastion_machine_type" {
  description = "Type de machine du bastion."
  type        = string
}

variable "bastion_network_tag" {
  description = "Étiquette réseau du bastion, ciblée par la règle de pare-feu SSH."
  type        = string
}

variable "bastion_source_image" {
  description = "Image de démarrage du bastion."
  type        = string
}