# Variables du module réseau. Les validations sont portées par la racine.

variable "project_id" {
  description = "Identifiant du projet Google Cloud."
  type        = string
}

variable "region" {
  description = "Région du sous-réseau, du routeur et du NAT."
  type        = string
}

variable "name_prefix" {
  description = "Préfixe des noms de ressources (foodtrack-<lettre>)."
  type        = string
}

variable "subnet_cidr" {
  description = "Plage principale du sous-réseau."
  type        = string
}

variable "pods_cidr" {
  description = "Plage secondaire des pods."
  type        = string
}

variable "services_cidr" {
  description = "Plage secondaire des Services."
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

variable "admin_ssh_cidrs" {
  description = "Adresses autorisées en SSH vers le bastion."
  type        = list(string)
}