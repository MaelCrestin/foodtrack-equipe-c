variable "project_id" {
  description = "Projet Google Cloud de l equipe"
  type        = string
}

variable "equipe" {
  description = "Lettre de l equipe, prefixe des ressources"
  type        = string
  default     = "c"
}

variable "notification_email" {
  description = "Adresse qui recoit l alerte si le portail qualite de production ne repond plus"
  type        = string
}

variable "uptime_host" {
  description = "Adresse IP publique fixe du portail qualite de production, surveillee par le controle de disponibilite"
  type        = string
}

variable "uptime_path" {
  description = "Chemin verifie par le controle de disponibilite"
  type        = string
  default     = "/healthz"
}

variable "alert_duration_secondes" {
  description = "Duree pendant laquelle le controle doit echouer en continu avant que l alerte se declenche. Justification : voir README, section Supervision - une valeur trop courte declenche l alerte sur un simple redemarrage de pod."
  type        = number
  default     = 300
}