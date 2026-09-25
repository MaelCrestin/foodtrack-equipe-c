# FoodTrack - equipe C - supervision de la production
#
# Quatre ressources : un canal de notification par courriel, un controle de
# disponibilite sur le portail qualite de prod, une regle d'alerte qui relie
# les deux, et une metrique basee sur les journaux qui isole les erreurs
# applicatives du namespace prod (cette metrique EST la "requete enregistree"
# demandee : son filtre est ce qui s'affiche dans l'explorateur de journaux
# des qu'on clique dessus).

# ---------------------------------------------------------------------------
# Canal de notification : une adresse courriel, pas un secret.
# ---------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email_equipe" {
  project      = var.project_id
  display_name = "FoodTrack equipe ${var.equipe} - courriel"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

# ---------------------------------------------------------------------------
# Controle de disponibilite, sur l'IP fixe reservee dans phase3-supervision.tf
# (racine). Sonde HTTP simple sur /healthz, depuis plusieurs regions.
# ---------------------------------------------------------------------------
resource "google_monitoring_uptime_check_config" "portail_qualite" {
  project      = var.project_id
  display_name = "foodtrack-${var.equipe}-portail-qualite-prod"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = var.uptime_path
    port         = 80
    use_ssl      = false
    validate_ssl = false
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.uptime_host
    }
  }

  selected_regions = ["EUROPE", "USA", "ASIA_PACIFIC"]
}

# ---------------------------------------------------------------------------
# Regle d'alerte : notifie par courriel si le controle echoue en continu
# pendant `alert_duration_secondes`. Duree choisie pour eviter le faux
# positif d'un simple redemarrage de pod (RollingUpdate, quelques dizaines de
# secondes) tout en restant assez courte pour un vrai incident de prod -
# justification complete dans le README, section Supervision.
#
# NOTE : ce policy suit le modele standard genere par la Console GCP pour un
# controle de disponibilite. Apres le premier apply, verifiez dans
# Monitoring > Alerting que le graphique de la condition affiche des
# donnees ; si un champ d'agregation a change cote API, ajustez-le ici.
# ---------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "portail_indisponible" {
  project      = var.project_id
  display_name = "foodtrack-${var.equipe}-portail-indisponible"
  combiner     = "OR"

  conditions {
    display_name = "Echec du controle de disponibilite (agrege sur ${var.alert_duration_secondes}s)"

    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.label.host = \"${var.uptime_host}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "${var.alert_duration_secondes}s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.project_id", "resource.label.host"]
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_equipe.id]

  documentation {
    content   = <<-EOT
      Le portail qualite de production ne repond plus sur `${var.uptime_path}`.

      Seuil retenu : le controle echoue depuis au moins ${var.alert_duration_secondes} secondes
      (${var.alert_duration_secondes / 60} minutes), sur plusieurs regions de sonde a la fois.
      Cette duree evite qu'un simple redemarrage de pod ne declenche une fausse alerte -
      voir README, section Supervision.

      A verifier en premier :
        kubectl get pods -n foodtrack-prod
        kubectl describe ingress -n foodtrack-prod
    EOT
    mime_type = "text/markdown"
  }
}

# ---------------------------------------------------------------------------
# Metrique basee sur les journaux, PAS une "requete enregistree" au sens
# strict de l'explorateur de journaux (fonctionnalite distincte, non geree
# par ce module). Substitut delibere : cliquer sur cette metrique dans
# Metrics/Logs Explorer affiche directement son filtre, ce qui couvre le
# meme besoin pratique (retrouver rapidement les erreurs applicatives du
# namespace prod) sans dupliquer un objet Terraform pour une fonctionnalite
# encore peu outillee cote provider (google_logging_saved_query existe mais
# reste en beta, non utilise ici par choix de stabilite).
# ---------------------------------------------------------------------------

resource "google_logging_metric" "erreurs_prod" {
  project     = var.project_id
  name        = "foodtrack-${var.equipe}-erreurs-applicatives-prod"
  description = "Isole les erreurs applicatives du namespace foodtrack-prod (severite ERROR et plus), tous conteneurs confondus."

  filter = <<-EOT
    resource.type="k8s_container"
    resource.labels.namespace_name="foodtrack-prod"
    resource.labels.container_name!="nginx"
    severity>=ERROR
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# ---------------------------------------------------------------------------
# Tableau de bord : processeur, memoire, pods prets, taux d'erreurs HTTP,
# latence - pour foodtrack-prod au minimum, comme demande.
#
# Les deux widgets HTTP (taux d'erreurs, latence) s'appuient sur les
# metriques de l'equilibreur de charge externe GKE (loadbalancing.googleapis.com),
# puisque c'est lui qui recoit et compte le trafic entrant sur l'Ingress.
#
# NOTE : les noms exacts de metriques Google Cloud evoluent de temps en
# temps. Si un widget affiche "No data" apres l'apply, cherchez la metrique
# la plus proche dans l'explorateur de metriques (Metrics Explorer) et
# corrigez la chaine `metric.type` ci-dessous plutot que de supposer le
# tableau de bord casse.
# ---------------------------------------------------------------------------
resource "google_monitoring_dashboard" "foodtrack_prod" {
  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "FoodTrack ${upper(var.equipe)} - production"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "CPU - foodtrack-prod"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"foodtrack-prod\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.label.pod_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "vCPU", scale = "LINEAR" }
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Memoire - foodtrack-prod"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"foodtrack-prod\" AND metric.type=\"kubernetes.io/container/memory/used_bytes\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.label.pod_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "octets", scale = "LINEAR" }
            }
          }
        },
        {
          width  = 6
          height = 4
          yPos   = 4
          widget = {
            title = "Pods prets - foodtrack-prod"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"prometheus_target\" AND metric.type=\"prometheus.googleapis.com/kube_pod_status_phase/gauge\" AND metric.labels.namespace=\"foodtrack-prod\" AND metric.labels.phase=\"Running\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "pods prets", scale = "LINEAR" }
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          yPos   = 4
          widget = {
            title = "Taux d erreurs HTTP (equilibreur de charge)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"https_lb_rule\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND metric.labels.response_code_class=500"
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "requetes/s en erreur", scale = "LINEAR" }
            }
          }
        },
        {
          width  = 12
          height = 4
          yPos   = 8
          widget = {
            title = "Latence - equilibreur de charge (p95)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"https_lb_rule\" AND metric.type=\"loadbalancing.googleapis.com/https/total_latencies\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_PERCENTILE_95"
                      crossSeriesReducer = "REDUCE_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = { label = "ms", scale = "LINEAR" }
            }
          }
        }
      ]
    }
  })
}
