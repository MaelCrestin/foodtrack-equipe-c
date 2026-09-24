#!/usr/bin/env bash
set -euo pipefail

# FoodTrack - equipe C - purge des exports de journaux
#
# Supprime, dans le bucket d exports de journaux, tout objet cree il y a
# plus de trente jours. Rejouable sans dommage : sans objet a purger, le
# script ne fait rien et se termine normalement.
#
# Usage : ./scripts/purge-logs.sh

BUCKET_LOGS="foodtrack-c-logs-foodtrack-equipe-c"
JOURS_DE_RETENTION=30

DATE_LIMITE="$(date -u -d "-${JOURS_DE_RETENTION} days" +%Y-%m-%d)"

echo "[purge] bucket : gs://${BUCKET_LOGS}"
echo "[purge] seuil de retention : ${JOURS_DE_RETENTION} jours (avant ${DATE_LIMITE})"

NB_SUPPRIMES=0

while read -r taille date_creation url; do
  [ -z "${url:-}" ] && continue
  date_objet="${date_creation%%T*}"
  if [[ "$date_objet" < "$DATE_LIMITE" ]]; then
    echo "[purge] suppression : ${url} (cree le ${date_objet})"
    gcloud storage rm "$url"
    NB_SUPPRIMES=$((NB_SUPPRIMES + 1))
  fi
done < <(gsutil ls -l "gs://${BUCKET_LOGS}/**" 2>/dev/null | grep -v "^TOTAL:" || true)

echo "[purge] termine - ${NB_SUPPRIMES} objet(s) supprime(s)"