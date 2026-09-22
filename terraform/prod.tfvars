

# project_id       = "foodtrack-equipe-c"
project_id       = "poei-formation-gcp"

region           = "europe-west2"
zone             = "europe-west2-b"
storage_location = "europe-west2"

subnet_cidr            = "10.10.0.0/20"
pods_cidr              = "10.20.0.0/16"
services_cidr          = "10.30.0.0/20"
master_ipv4_cidr_block = "172.16.0.0/28"

admin_ssh_cidrs = ["5.39.6.57/32"]
master_authorized_networks = [
  { cidr_block = "0.0.0.0/0", display_name = "github-actions-phase-3" }
]
enable_private_endpoint = false

node_machine_type    = "e2-standard-2"
node_count           = 3
min_node_count       = 0
max_node_count       = 4
bastion_machine_type = "e2-micro"

backup_bucket_name = "foodtrack-c-backups-foodtrack-equipe-c"
logs_bucket_name   = "foodtrack-c-logs-foodtrack-equipe-c"
retention_days     = 90

