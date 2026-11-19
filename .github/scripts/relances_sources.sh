#!/usr/bin/env bash
# Relance des 5 collectes de sources (thesports, mdc, cqranking, museo, cyclingranking) dont la chaîne d'auto-relance s'est arrêtée :
# le etat.json PUBLIÉ (API contents, pas le checkout du job) dit « termine: false », aucun passage n'est en file ou en
# cours, et le dernier passage s'est TERMINÉ il y a au moins 60 min. Appelé par battement.yml seulement.
# Environnement : REPO, GH_TOKEN. Surcharges facultatives : MAINTENANT (epoch), SOURCES (liste, défaut les 5),
# SEUIL_SOURCES_MIN (défaut 60), BRANCHE_DONNEES (défaut main).
set -u
RACINE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$RACINE/commun.sh"
: "${REPO:?REPO manquant}"
maintenant=${MAINTENANT:-$(date -u +%s)}
seuil=${SEUIL_SOURCES_MIN:-60}
branche=${BRANCHE_DONNEES:-main}

for src in ${SOURCES:-thesports mdc cqranking museo cyclingranking}; do
  wf="$src.yml"
  etat=$(gh api -H "Accept: application/vnd.github.raw+json" \
           "repos/$REPO/contents/data/archives/sources/$src/etat.json?ref=$branche" 2>/dev/null) || etat=""
  termine=$(printf '%s' "$etat" | python3 -c "
import json, sys
try:
    e = json.load(sys.stdin)
    print('oui' if e.get('termine') else 'non')
except ValueError:
    print('inconnu')
" 2>/dev/null || echo inconnu)
  if [ "$termine" != "non" ]; then echo "[BATTEMENT] $wf : etat.json termine=$termine, rien à faire"; continue; fi
  en_cours=$(nb_en_cours "$wf")
  if [ "$en_cours" != "0" ]; then echo "[BATTEMENT] $wf : un passage est en file ou en cours (ou liste illisible : $en_cours), rien à faire"; continue; fi
  fin=$(date_dernier_passage "$wf" updatedAt)
  if [ "$fin" = "?" ]; then echo "[BATTEMENT] $wf : liste des passages illisible, rien à faire"; continue; fi
  if [ -n "$fin" ]; then
    age=$(( (maintenant - $(date -u -d "$fin" +%s)) / 60 ))
  else
    age=999999
  fi
  if [ "$age" -lt "$seuil" ]; then echo "[BATTEMENT] $wf : travail restant, dernier passage terminé il y a ${age} min (< ${seuil} min), rien à faire"; continue; fi
  if [ "$(nb_en_cours "$wf")" != "0" ]; then echo "[BATTEMENT] $wf : un passage vient d'être lancé, rien à faire"; continue; fi
  echo "[BATTEMENT] $wf : travail restant, chaîne arrêtée depuis ${age} min (>= ${seuil} min) : relance"
  gh workflow run "$wf" --repo "$REPO" --ref "$REF_RELANCE"
done
