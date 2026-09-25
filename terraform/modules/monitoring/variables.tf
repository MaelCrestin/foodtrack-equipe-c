# Variables du module monitoring.

variable "project_id" {
  description = "Identifiant du projet Google Cloud de l'équipe."
  type        = string
}

variable "equipe" {
  description = "Lettre de l'équipe, préfixe des ressources de supervision."
  type        = string

  validation {
    condition     = contains(["a", "b", "c", "d", "e"], var.equipe)
    error_message = "equipe doit être une lettre de a à e."
  }
}

variable "notification_email" {
  description = "Adresse qui reçoit l'alerte si le portail qualité de production ne répond plus."
  type        = string
  sensitive   = true
}

variable "uptime_host" {
  description = "Adresse IP publique fixe du portail qualité de production, surveillée par le contrôle de disponibilité."
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.uptime_host))
    error_message = "uptime_host doit être une adresse IPv4."
  }
}

variable "uptime_path" {
  description = "Chemin HTTP vérifié par le contrôle de disponibilité."
  type        = string
  default     = "/healthz"

  validation {
    condition     = startswith(var.uptime_path, "/")
    error_message = "uptime_path doit commencer par /."
  }
}

variable "alert_duration_secondes" {
  description = "Durée d'échec continu avant déclenchement de l'alerte. Trop courte, elle alerte sur un simple redémarrage de pod (voir README, section Supervision)."
  type        = number
  default     = 300

  validation {
    condition     = var.alert_duration_secondes >= 60 && var.alert_duration_secondes % 60 == 0
    error_message = "alert_duration_secondes doit être un multiple de 60, d'au moins 60."
  }
}