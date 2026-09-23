#!/usr/bin/env python3
"""FoodTrack - equipe C - controle de sante de l'API capteurs.

Script autonome (aucune dependance hors bibliotheque standard) : interroge
l'API, verifie le code de retour, mesure la latence, rend un rapport lisible.

Code de sortie :
    0   l'API repond, code 200, latence sous le seuil
    1   l'API repond mais avec un code d'erreur, ou une latence excessive
    2   l'API ne repond pas du tout (delai depasse, connexion refusee, DNS)

Ce code de sortie non nul est ce qui rend le script utilisable tel quel dans
un CronJob Kubernetes (la sonde echoue, l'objet Job passe en echec, une
alerte peut se brancher dessus) ou comme etape de verification dans le
pipeline (cf. .github/workflows/deploy.yml).

Usage :
    python3 healthcheck.py --url http://portail-qualite.foodtrack-prod.svc.cluster.local:8080/api/
    python3 healthcheck.py --url https://136.81.139.17/api/ --timeout 3 --max-latency-ms 500
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, asdict


@dataclass
class Resultat:
    url: str
    ok: bool
    code_retour: int | None
    latence_ms: float | None
    erreur: str | None


def controler(url: str, timeout: float) -> Resultat:
    debut = time.monotonic()
    try:
        requete = urllib.request.Request(url, headers={"User-Agent": "foodtrack-healthcheck/1.0"})
        with urllib.request.urlopen(requete, timeout=timeout) as reponse:
            latence_ms = (time.monotonic() - debut) * 1000
            code = reponse.getcode()
            return Resultat(url=url, ok=True, code_retour=code, latence_ms=round(latence_ms, 1), erreur=None)
    except urllib.error.HTTPError as exc:
        # Le serveur a repondu, mais avec un code d'erreur (4xx / 5xx) :
        # c'est une reponse, pas une absence de reponse - la latence compte.
        latence_ms = (time.monotonic() - debut) * 1000
        return Resultat(url=url, ok=False, code_retour=exc.code, latence_ms=round(latence_ms, 1), erreur=str(exc))
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        # Aucune reponse : DNS, connexion refusee, delai depasse.
        return Resultat(url=url, ok=False, code_retour=None, latence_ms=None, erreur=str(exc))


def rapport_lisible(resultat: Resultat, max_latency_ms: float) -> str:
    lignes = [f"Controle de sante - {resultat.url}"]

    if resultat.code_retour is None:
        lignes.append("  Etat        : INJOIGNABLE")
        lignes.append(f"  Detail      : {resultat.erreur}")
        return "\n".join(lignes)

    etat_code = "OK" if resultat.code_retour == 200 else f"CODE INATTENDU ({resultat.code_retour})"
    lignes.append(f"  Code retour : {resultat.code_retour} - {etat_code}")

    if resultat.latence_ms is not None:
        etat_latence = "OK" if resultat.latence_ms <= max_latency_ms else "TROP LENTE"
        lignes.append(f"  Latence     : {resultat.latence_ms} ms - {etat_latence} (seuil {max_latency_ms} ms)")

    lignes.append(f"  Resultat    : {'SAIN' if resultat.ok else 'EN ECHEC'}")
    return "\n".join(lignes)


def code_sortie(resultat: Resultat, max_latency_ms: float) -> int:
    if resultat.code_retour is None:
        return 2
    if resultat.code_retour != 200:
        return 1
    if resultat.latence_ms is not None and resultat.latence_ms > max_latency_ms:
        return 1
    return 0


def main() -> int:
    parseur = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parseur.add_argument("--url", required=True, help="URL de l'API a controler")
    parseur.add_argument("--timeout", type=float, default=5.0, help="delai maximal d'attente, en secondes (defaut 5)")
    parseur.add_argument("--max-latency-ms", type=float, default=1000.0, help="latence maximale acceptee, en millisecondes (defaut 1000)")
    parseur.add_argument("--json", action="store_true", help="rapport au format JSON plutot que texte lisible")
    args = parseur.parse_args()

    resultat = controler(args.url, args.timeout)
    code = code_sortie(resultat, args.max_latency_ms)

    if args.json:
        print(json.dumps({**asdict(resultat), "code_sortie": code}, ensure_ascii=False))
    else:
        print(rapport_lisible(resultat, args.max_latency_ms))

    return code


if __name__ == "__main__":
    sys.exit(main())