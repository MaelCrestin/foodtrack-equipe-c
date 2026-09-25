# Supervision de la production : adresse IP publique fixe du portail qualité
# et appel du module monitoring (contrôle de disponibilité, alerte, tableau de
# bord, métrique de journaux). Les variables et sorties associées sont dans
# variables.tf et outputs.tf.
#
# Câblage restant hors Terraform :
#   1. terraform apply
#   2. terraform output portail_qualite_prod_ip_name
#   3. reporter ce NOM (pas l'adresse IP) dans l'annotation
#      kubernetes.io/ingress.global-static-ip-name de l'Ingress de prod
#      (manifests/overlays/prod/ingress-patch.yaml), puis
#      kubectl apply -k manifests/overlays/prod

# Adresse IP publique fixe du portail qualité de production. Réservée hors de
# l'Ingress pour que le contrôle de disponibilité garde une cible stable : un
# Ingress recréé sans adresse réservée change d'IP.
resource "google_compute_global_address" "portail_qualite_prod" {
  project      = var.project_id
  name         = "${local.prefix}-portail-prod-ip"
  address_type = "EXTERNAL"

  depends_on = [google_project_service.required]
}

# Supervision de foodtrack-prod, alimentée par l'adresse fixe ci-dessus.
module "monitoring" {
  source = "./modules/monitoring"

  project_id         = var.project_id
  equipe             = var.equipe
  notification_email = var.notification_email
  uptime_host        = google_compute_global_address.portail_qualite_prod.address

  depends_on = [google_project_service.required]
}