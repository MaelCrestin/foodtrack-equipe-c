variable "project_id" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "backup_bucket_name" { type = string }
variable "logs_bucket_name" { type = string }
variable "retention_days" { type = number }
variable "force_destroy" { type = bool }
variable "log_filter" { type = string }

