#!/usr/bin/env bash
# Un passage de veille : relance archives.yml et wikidata.yml quand leur passage a été sauté. Appelé par veille.yml (cron,
# secours) ET par battement.yml (toutes les 10 min). Mêmes règles dans les deux cas.
#   - archives.yml si aucun passage n'a démarré depuis 20 h, et, pendant la saison des courses, seulement entre 23 h et 11 h UTC
#     (hors créneau d'update.yml) ; en intersaison (collector.periode_de_courses faux), à toute heure, et dès 1 h sans passage
#     s'il reste des saisons à collecter ;
#   - wikidata.yml si aucun passage n'a démarré depuis 8 jours.
# Rien n'est relancé si un passage du même workflow est en file ou en cours (vérifié juste avant chaque relance).
# Environnement : REPO, GH_TOKEN, SAISONS (défaut 2009-2025), CODE_DIR (checkout du dépôt principal, défaut ./code).
# Surcharges facultatives (essais locaux) : MAINTENANT (secondes epoch), HEURE_UTC, COURSES (oui|non : saute le Calendrier),
# INCOMPLETES (liste, éventuellement vide ou « inconnu » : saute l'index publié).
set -u
RACINE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$RACINE/commun.sh"
: "${REPO:?REPO manquant}"
SAISONS=${SAISONS:-2009-2025}
CODE_DIR=${CODE_DIR:-code}

maintenant=${MAINTENANT:-$(date -u +%s)}
heure=$((10#${HEURE_UTC:-$(date -u +%H)}))
# « non » seulement si le Calendrier montre l'intersaison ; toute autre sortie (erreur comprise) : prudence
if [ -n "${COURSES:-}" ]; then
  courses=$COURSES
else
  courses=$(cd "$CODE_DIR" && python3 -c "import collector; print('oui' if collector.periode_de_courses_depuis() else 'non')" 2>/dev/null || echo oui)
fi
echo "[VEILLE] période de courses : $courses"
# saisons demandées encore incomplètes, d'après l'index publié (vide = tout est complet ; « inconnu » si illisible)
if [ "${INCOMPLETES+x}" = "x" ]; then
  incompletes=$INCOMPLETES
else
  incompletes=$(curl -sf "https://camelbaggy.github.io/courses-cyclistes-archives/data/archives/index.json" | (cd "$CODE_DIR" && python3 -c "
import json, sys
from run_pipeline import parse_saisons
d = json.load(sys.stdin)
ok = {s['season'] for s in d.get('seasons', []) if s.get('complete')}
print(','.join(str(a) for a in parse_saisons(sys.argv[1]) if a not in ok))
" "$SAISONS") || echo inconnu)
fi
echo "[VEILLE] saisons d'archives incomplètes : ${incompletes:-aucune}"
# intersaison avec des saisons à collecter : relance dès 1 h sans passage (chaîne de relances cassée) ; sinon 20 h
if [ "$courses" = "non" ] && [ -n "$incompletes" ]; then age_archives=1; else age_archives=20; fi

# relancer <workflow> <âge maximal en heures> <fenêtre nocturne : oui|non>
relancer() {
  local wf="$1" age_max=$2 nuit="$3" en_cours dernier age
  en_cours=$(nb_en_cours "$wf")
  if [ "$en_cours" != "0" ]; then echo "[VEILLE] $wf : un passage est en file ou en cours (ou liste illisible : $en_cours), rien à faire"; return; fi
  dernier=$(date_dernier_passage "$wf" createdAt)
  if [ "$dernier" = "?" ]; then echo "[VEILLE] $wf : liste des passages illisible, rien à faire"; return; fi
  if [ -n "$dernier" ]; then
    age=$(( (maintenant - $(date -u -d "$dernier" +%s)) / 3600 ))
  else
    age=999999
  fi
  if [ "$age" -lt "$age_max" ]; then echo "[VEILLE] $wf : dernier passage il y a ${age} h (< ${age_max} h), rien à faire"; return; fi
  if [ "$nuit" = "oui" ] && [ "$courses" != "non" ] && [ "$heure" -ge 11 ] && [ "$heure" -lt 23 ]; then
    echo "[VEILLE] $wf : dernier passage il y a ${age} h, mais il est ${heure} h UTC (créneau d'update.yml) : relance à partir de 23 h"; return
  fi
  # contrôle « en file ou en cours » refait juste avant la relance (un autre veilleur a pu passer entre-temps)
  if [ "$(nb_en_cours "$wf")" != "0" ]; then echo "[VEILLE] $wf : un passage vient d'être lancé, rien à faire"; return; fi
  echo "[VEILLE] $wf : dernier passage il y a ${age} h (>= ${age_max} h) : relance"
  gh workflow run "$wf" --repo "$REPO" --ref "$REF_RELANCE"
}
relancer archives.yml "$age_archives" oui
relancer wikidata.yml 192 non
