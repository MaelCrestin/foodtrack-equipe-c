#!/usr/bin/env bash
set -euo pipefail

# FoodTrack - equipe C - extinction / rallumage du cluster
#
# Sur un cluster GKE Standard, les noeuds sont factures tant qu ils
# tournent, week-end compris. Ce script descend le node pool a zero le
# soir et le remonte le matin - ce n est pas un bonus, c est ce qui rend
# le projet financable sur la duree de la formation.
#
# Rejouable sans dommage : redemander un nombre de noeuds deja atteint ne
# fait rien de plus qu une commande sans effet.
#
# Usage :
#   ./scripts/extinction-cluster.sh soir     # descend a 0 noeud
#   ./scripts/extinction-cluster.sh matin    # remonte au nombre nominal

PROJECT_ID="form-gke-eleve03-a8e9"
CLUSTER="foodtrack-c-cluster"
ZONE="europe-west2-b"
# A VERIFIER : gcloud container node-pools list --cluster "$CLUSTER" --zone "$ZONE"
NODE_POOL="foodtrack-c-pool"
# Doit correspondre a node_count dans terraform/dev.tfvars - sinon
# Terraform verra une derive au prochain plan.
NB_NOEUDS_JOUR=2

MODE="${1:-}"

case "$MODE" in
  soir)
    NB_NOEUDS_CIBLE=0
    ;;
  matin)
    NB_NOEUDS_CIBLE="$NB_NOEUDS_JOUR"
    ;;
  *)
    echo "Usage : $0 {soir|matin}" >&2
    exit 1
    ;;
esac

echo "[extinction] ${MODE} - node pool ${NODE_POOL} -> ${NB_NOEUDS_CIBLE} noeud(s)"

gcloud container clusters resize "$CLUSTER" \
  --node-pool "$NODE_POOL" \
  --num-nodes "$NB_NOEUDS_CIBLE" \
  --zone "$ZONE" \
  --project "$PROJECT_ID" \
  --quiet

echo "[extinction] termine"