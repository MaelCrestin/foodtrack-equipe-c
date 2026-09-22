<<<<<<< HEAD
variable "project_id" {
  description = "Projet Google Cloud, PARTAGE entre les 5 equipes de la formation"
  type        = string
  default     = "poei-formation-gcp"
}
=======
variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "storage_location" { type = string }
variable "subnet_cidr" { type = string }
variable "pods_cidr" { type = string }
variable "services_cidr" { type = string }
variable "master_ipv4_cidr_block" { type = string }
variable "admin_ssh_cidrs" {
  type = list(string)
  validation {
    condition     = length(var.admin_ssh_cidrs) > 0 && !contains(var.admin_ssh_cidrs, "0.0.0.0/0")
    error_message = "Fournissez au moins un CIDR d'administration précis ; 0.0.0.0/0 est interdit."
  }
>>>>>>> main
}
variable "master_authorized_networks" {
  type = list(object({ cidr_block = string, display_name = string }))
  default = []
}
variable "enable_private_endpoint" {
  type    = bool
  default = false
}
<<<<<<< HEAD

variable "equipe" {
  description = "Lettre de l equipe, utilisee dans le prefixe de toutes les ressources"
  type        = string
  default     = "c"
}
=======
variable "node_machine_type" {
  type    = string
  default = "e2-standard-2"
}
variable "node_count" {
  type    = number
  default = 1
}
variable "min_node_count" {
  type    = number
  default = 1
}
variable "max_node_count" {
  type    = number
  default = 3
}
variable "bastion_machine_type" {
  type    = string
  default = "e2-micro"
}
variable "bastion_source_image" {
  type    = string
  default = "debian-cloud/debian-12"
}
variable "backup_bucket_name" { type = string }
variable "logs_bucket_name" { type = string }
variable "retention_days" {
  type    = number
  default = 30
}
variable "force_destroy_buckets" {
  type    = bool
  default = false
}
variable "log_filter" {
  type    = string
  default = "resource.type=\"k8s_container\""
}
>>>>>>> main
