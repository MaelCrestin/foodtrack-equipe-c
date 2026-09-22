# FoodTrack - equipe C - module reseau
#
# A FAIRE :
#  - google_compute_network (creation automatique de sous-reseaux desactivee)
#  - google_compute_subnetwork avec deux plages secondaires (pods, services)
#  - google_compute_router + google_compute_router_nat (sortie Internet des noeuds prives)
#  - google_compute_firewall (par etiquette reseau, jamais par plage large)
#
# Piege a ne pas rater : sans Cloud NAT, aucun pod ne demarre (ImagePullBackOff).
