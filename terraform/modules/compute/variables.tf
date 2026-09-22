variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "name_prefix" { type = string }
variable "network_id" { type = string }
variable "subnetwork_id" { type = string }
variable "pods_range_name" { type = string }
variable "services_range_name" { type = string }
variable "master_ipv4_cidr_block" { type = string }
variable "master_authorized_networks" { type = list(object({ cidr_block = string, display_name = string })) }
variable "enable_private_endpoint" { type = bool }
variable "node_machine_type" { type = string }
variable "node_count" { type = number }
variable "min_node_count" { type = number }
variable "max_node_count" { type = number }
variable "bastion_machine_type" { type = string }
variable "bastion_network_tag" { type = string }
variable "bastion_source_image" { type = string }

