variable "project_id" { type = string }
variable "region" { type = string }
variable "name_prefix" { type = string }
variable "subnet_cidr" { type = string }
variable "pods_cidr" { type = string }
variable "services_cidr" { type = string }
variable "pods_range_name" { type = string }
variable "services_range_name" { type = string }
variable "admin_ssh_cidrs" { type = list(string) }

