#!/usr/bin/env bash
set -euo pipefail

# FoodTrack - equipe C - sauvegarde de la configuration
#
# Archive horodatee de : le code d infrastructure (terraform/, manifests/,
# workflow) et un instantane de l etat reellement deploye sur les trois
# namespaces. Les Secrets Kubernetes sont explicitement exclus de cet
# instantane - on ne capture jamais de valeur sensible en clair dans une
# sauvegarde, meme chiffree au repos par GCS (cf. incident secret.env
# documente dans l audit securite).
#
# Rejouable sans dommage : chaque execution cree une nouvelle archive
# horodatee dans le bucket, n ecrase et ne supprime jamais rien.
#
# A executer depuis la racine du depot.
# Usage : ./scripts/sauvegarde.sh

PROJECT_ID="form-gke-eleve03-a8e9"
CLUSTER="foodtrack-c-cluster"
ZONE="europe-west2-b"
# A VERIFIER : nom reel du bucket dedie aux sauvegardes
# (terraform output dans terraform/, ou gcloud storage ls --project="$PROJECT_ID")
BUCKET_SAUVEGARDE="foodtrack-c-backups-foodtrack-equipe-c"

HORODATAGE="$(date -u +%Y%m%dT%H%M%SZ)"
REPERTOIRE_TRAVAIL="$(mktemp -d)"
trap 'rm -rf "$REPERTOIRE_TRAVAIL"' EXIT

echo "[sauvegarde] debut - horodatage ${HORODATAGE}"

# --- 1. code d infrastructure --------------------------------------------
tar --exclude="*.env" --exclude=".terraform" --exclude="*.tfstate*" \
    -czf "${REPERTOIRE_TRAVAIL}/configuration.tar.gz" \
    terraform/ manifests/ .github/ scripts/

# --- 2. instantane de l etat reellement deploye ---------------------------
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT_ID" --quiet

mkdir -p "${REPERTOIRE_TRAVAIL}/etat-deploye"
for namespace in foodtrack-dev foodtrack-test foodtrack-prod; do
  kubectl get deployment,statefulset,service,ingress,configmap,hpa \
    -n "$namespace" -o yaml \
    > "${REPERTOIRE_TRAVAIL}/etat-deploye/${namespace}.yaml" \
    || echo "[sauvegarde] avertissement : namespace ${namespace} inaccessible, ignore"
done

# --- 3. archive finale et envoi -------------------------------------------
ARCHIVE_FINALE="sauvegarde-foodtrack-c-${HORODATAGE}.tar.gz"
tar -czf "/tmp/${ARCHIVE_FINALE}" -C "${REPERTOIRE_TRAVAIL}" configuration.tar.gz etat-deploye

gcloud storage cp "/tmp/${ARCHIVE_FINALE}" "gs://${BUCKET_SAUVEGARDE}/${ARCHIVE_FINALE}"
rm -f "/tmp/${ARCHIVE_FINALE}"

echo "[sauvegarde] terminee : gs://${BUCKET_SAUVEGARDE}/${ARCHIVE_FINALE}"