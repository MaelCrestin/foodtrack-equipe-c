# FoodTrack - equipe C - phase 3 : supervision
#
# A deposer tel quel a la racine terraform/, a cote de main.tf. Terraform
# fusionne tous les fichiers .tf d'un meme dossier : il n'y a rien a copier-
# coller a l'interieur de main.tf, ce fichier s'ajoute de lui-meme au graphe.
#
# Cablage restant, hors Terraform :
#   1. terraform apply
#   2. terraform output portail_qualite_prod_ip
#   3. reporter cette adresse dans l'annotation de l'Ingress prod
#      (manifests/overlays/prod/ingress-patch.yaml - voir le patch fourni
#      a cote de ce fichier) puis kubectl apply -k manifests/overlays/prod

# Adresse IP publique FIXE pour le portail qualite de production. Reservee
# ici pour que le controle de disponibilite ait une cible stable : sans
# cela, recreer l'objet Ingress peut changer son adresse, et le controle de
# disponibilite se retrouverait a surveiller une IP qui n'existe plus.
resource "google_compute_global_address" "portail_qualite_prod" {
  project      = var.project_id
  name         = "foodtrack-${var.equipe}-portail-prod-ip"
  address_type = "EXTERNAL"
}

variable "notification_email" {
  description = "Adresse qui recoit l'alerte si le portail qualite de production ne repond plus"
  type        = string
}

variable "equipe" {
  description = "Lettre de l'equipe, prefixe des ressources"
  type        = string
  default     = "c"
}

module "monitoring" {
  source = "./modules/monitoring"

  project_id         = var.project_id
  equipe             = var.equipe
  notification_email = var.notification_email
  uptime_host        = google_compute_global_address.portail_qualite_prod.address
}

output "portail_qualite_prod_ip" {
  description = "A reporter dans l'annotation kubernetes.io/ingress.global-static-ip-name de l'Ingress de prod"
  value       = google_compute_global_address.portail_qualite_prod.address
}