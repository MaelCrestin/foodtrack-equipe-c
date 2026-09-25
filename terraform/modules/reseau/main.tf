# Module réseau : VPC privé, sous-réseau avec plages secondaires pour GKE,
# sortie Internet par Cloud NAT et règle de pare-feu SSH du bastion.

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  # Étiquette réseau du bastion : le pare-feu cible cette étiquette plutôt
  # qu'une plage d'adresses (exigence du CDC).
  bastion_tag = "${var.name_prefix}-bastion"
}

# VPC en mode personnalisé : la création automatique de sous-réseaux dans
# toutes les régions est désactivée, l'équipe reste dans sa seule région.
resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Sous-réseau des nœuds et du bastion. Les deux plages secondaires permettent
# le mode natif VPC du cluster ; l'accès privé Google laisse les nœuds sans IP
# publique joindre les API Google.
resource "google_compute_subnetwork" "this" {
  project                  = var.project_id
  name                     = "${var.name_prefix}-subnet"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pods_range_name
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name    = var.services_range_name
    ip_cidr_range = var.services_cidr
  }
}

# Routeur Cloud, support obligatoire de la passerelle Cloud NAT.
resource "google_compute_router" "this" {
  project = var.project_id
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.this.id
}

# Cloud NAT : sortie Internet des nœuds sans IP publique, indispensable pour
# tirer les images de Docker Hub. Limité au sous-réseau du cluster ; seuls les
# échecs de traduction sont journalisés, pour limiter le volume de journaux.
resource "google_compute_router_nat" "this" {
  project                            = var.project_id
  name                               = "${var.name_prefix}-nat"
  region                             = var.region
  router                             = google_compute_router.this.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.this.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# SSH vers le bastion uniquement, depuis les seules adresses d'administration,
# ciblé par étiquette réseau. Journalisé pour l'audit.
resource "google_compute_firewall" "bastion_ssh" {
  project       = var.project_id
  name          = "${var.name_prefix}-allow-bastion-ssh"
  network       = google_compute_network.this.name
  direction     = "INGRESS"
  source_ranges = var.admin_ssh_cidrs
  target_tags   = [local.bastion_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  log_config { metadata = "INCLUDE_ALL_METADATA" }
}