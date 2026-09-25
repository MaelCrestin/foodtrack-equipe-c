# Module compute : cluster GKE Standard zonal, node pool, bastion
# d'administration et dépôt Artifact Registry, avec le compte de service
# dédié des nœuds.

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

# Compte de service dédié aux nœuds GKE : évite le compte Compute Engine par
# défaut, souvent doté de roles/editor.
resource "google_service_account" "nodes" {
  project      = var.project_id
  account_id   = substr(replace("${var.name_prefix}-gke-nodes", "_", "-"), 0, 30)
  display_name = "GKE nodes ${var.name_prefix}"
}

# Rôles minimaux des nœuds : tirer les images d'Artifact Registry, écrire
# journaux et métriques, lire la configuration de supervision.
resource "google_project_iam_member" "nodes" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.nodes.email}"
}

# Bastion d'administration : plus petite machine utile, disque pd-standard
# (hors quota SSD), Shielded VM. OS Login lie l'accès SSH à l'identité Google
# de chaque membre, par clé uniquement. Aucun compte de service n'est attaché :
# la VM ne porte aucune identité Google Cloud. L'IP publique sert au SSH depuis
# admin_ssh_cidrs, filtré par le pare-feu du module réseau.
resource "google_compute_instance" "bastion" {
  project      = var.project_id
  name         = "${var.name_prefix}-bastion"
  zone         = var.zone
  machine_type = var.bastion_machine_type
  tags         = [var.bastion_network_tag]

  boot_disk {
    initialize_params {
      image = var.bastion_source_image
      size  = 10
      type  = "pd-standard"
    }
  }
  network_interface {
    subnetwork = var.subnetwork_id
    access_config {}
  }
  metadata = { enable-oslogin = "TRUE" }
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

# Cluster GKE Standard zonal unique pour dev, test et prod (contrainte du CDC :
# Autopilot est exclu par le quota SSD, trois clusters seraient hors budget).
# Nœuds privés, mode natif VPC (NEG pour l'Ingress), Workload Identity, canal
# REGULAR pour les mises à jour automatiques, protection contre la
# suppression. Le node pool par défaut est supprimé au profit d'un pool dont
# le type de disque est maîtrisé. L'accès au plan de contrôle dépend de
# var.master_authorized_networks, documenté dans le README.
resource "google_container_cluster" "this" {
  project                  = var.project_id
  name                     = "${var.name_prefix}-cluster"
  location                 = var.zone
  network                  = var.network_id
  subnetwork               = var.subnetwork_id
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = true
  enable_shielded_nodes    = true
  networking_mode          = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) == 0 ? [] : [1]
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }
  release_channel { channel = "REGULAR" }
  workload_identity_config { workload_pool = "${var.project_id}.svc.id.goog" }
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Les rôles du compte de service des nœuds doivent exister avant que les
  # premiers nœuds ne démarrent et ne tirent leurs images.
  depends_on = [google_project_iam_member.nodes]
}

# Node pool unique : disque pd-standard de 50 Go (le défaut pd-balanced
# consommerait le quota SSD), compte de service dédié, Shielded Nodes,
# réparation et mise à jour automatiques, métadonnées GKE pour Workload
# Identity. node_count est ignoré après création : l'autoscaler et le script
# d'extinction le modifient hors Terraform, ce qui créerait sinon une dérive
# à chaque plan.
resource "google_container_node_pool" "primary" {
  project    = var.project_id
  name       = "${var.name_prefix}-pool"
  location   = google_container_cluster.this.location
  cluster    = google_container_cluster.this.name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  node_config {
    machine_type    = var.node_machine_type
    disk_type       = "pd-standard"
    disk_size_gb    = 50
    service_account = google_service_account.nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    labels          = { project = var.name_prefix }
    metadata        = { disable-legacy-endpoints = "true" }
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    workload_metadata_config { mode = "GKE_METADATA" }
  }

  lifecycle {
    ignore_changes = [node_count]
  }
}

# Dépôt d'images Docker de l'équipe, dans la même région que le cluster pour
# éviter le trafic interrégional au tirage des images.
resource "google_artifact_registry_repository" "docker" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.name_prefix}-images"
  description   = "Images Docker de ${var.name_prefix}"
  format        = "DOCKER"
}