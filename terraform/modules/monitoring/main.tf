# Module monitoring : supervision du portail qualité de production. Un canal
# de notification par courriel, un contrôle de disponibilité, une règle
# d'alerte qui les relie, une métrique de journaux sur les erreurs de prod et
# un tableau de bord.

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

# Canal de notification par courriel de l'équipe, destinataire de l'alerte.
resource "google_monitoring_notification_channel" "email_equipe" {
  project      = var.project_id
  display_name = "FoodTrack equipe ${var.equipe} - courriel"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

# Contrôle de disponibilité HTTP sur l'IP fixe réservée dans
# phase3-monitoring.tf (racine), toutes les 60 s, depuis trois zones
# géographiques : une panne réseau locale d'une sonde ne suffit pas à
# conclure à l'indisponibilité.
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

# Alerte : notifie quand plus d'une localisation de sonde est en échec, sans
# interruption, pendant alert_duration_secondes. La durée écarte le faux
# positif d'un redémarrage de pod (quelques dizaines de secondes) tout en
# restant courte pour un vrai incident ; justification dans le README,
# section Supervision. La fenêtre d'alignement de 120 s couvre deux périodes
# de sonde, pour tolérer la gigue entre deux résultats.
resource "google_monitoring_alert_policy" "portail_indisponible" {
  project      = var.project_id
  display_name = "foodtrack-${var.equipe}-portail-indisponible"
  combiner     = "OR"

  conditions {
    display_name = "Echec du controle de disponibilite pendant ${var.alert_duration_secondes}s"

    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.label.host = \"${var.uptime_host}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "${var.alert_duration_secondes}s"

      aggregations {
        alignment_period     = "120s"
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

      Condition : plus d'une localisation de sonde en echec, sans interruption,
      pendant ${var.alert_duration_secondes} secondes.
      Cette duree evite qu'un simple redemarrage de pod ne declenche une fausse
      alerte - voir README, section Supervision.

      A verifier en premier :
        kubectl get pods -n foodtrack-prod
        kubectl describe ingress -n foodtrack-prod
    EOT
    mime_type = "text/markdown"
  }
}

# Métrique basée sur les journaux : compte les entrées de sévérité ERROR et
# plus du namespace foodtrack-prod. Son filtre sert de requête de référence
# dans l'explorateur de journaux pour isoler les erreurs applicatives de prod.
resource "google_logging_metric" "erreurs_prod" {
  project     = var.project_id
  name        = "foodtrack-${var.equipe}-erreurs-applicatives-prod"
  description = "Isole les erreurs applicatives du namespace foodtrack-prod (severite ERROR et plus), tous conteneurs confondus."

  filter = <<-EOT
    resource.type="k8s_container"
    resource.labels.namespace_name="foodtrack-prod"
    severity>=ERROR
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# Tableau de bord de production : processeur, mémoire, pods en phase Running,
# taux d'erreurs HTTP et latence. Le widget des pods lit la métrique
# kube-state-metrics collectée par Managed Service for Prometheus. Les deux
# widgets HTTP lisent les métriques de l'équilibreur de charge externe et
# agrègent tous les équilibreurs du projet, pas seulement celui de prod.
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
            title = "Pods Running - foodtrack-prod"
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
              yAxis = { label = "pods Running", scale = "LINEAR" }
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