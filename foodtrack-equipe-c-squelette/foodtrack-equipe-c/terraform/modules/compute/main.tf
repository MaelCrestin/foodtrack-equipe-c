# FoodTrack - equipe C - module compute
#
# A FAIRE :
#  - google_container_cluster : mode Standard, cluster zonal, node pool par
#    defaut supprime, mode natif VPC (plages secondaires du module reseau)
#  - google_container_node_pool : disk_type = "pd-standard" (obligatoire,
#    50 Go max), machine_type en famille E2 ou N2 uniquement
#  - bloc master_authorized_networks_config (exposition du plan de controle,
#    a documenter comme compromis assume)
#  - google_compute_instance : VM bastion, source SSH restreinte
#
# Piege a ne pas rater : le type de disque par defaut de GKE (pd-balanced)
# consomme le quota SSD_TOTAL_GB, plafonne et non relevable a la demande.
