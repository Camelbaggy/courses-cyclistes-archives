# CLAUDE.md

Dépôt de **données** : `data/archives/` (saisons passées du dashboard des courses cyclistes), servi par GitHub Pages
(`https://camelbaggy.github.io/courses-cyclistes-archives/`). Tout est en français (logs, messages de commit).

- Il ne contient que des fichiers JSON générés par `.github/workflows/archives.yml`. Le code (collecteur, pipeline,
  page) et toute la documentation (CLAUDE.md, `docs/SPEC.md` §4.4, `docs/PLAN_ARCHIVES.md`) sont dans
  Camelbaggy/courses-cyclistes : y modifier le code, pas ici.
- **Ne jamais modifier `data/` à la main** (ni committer d'archives générées en local) : le workflow est seul auteur.
  Seuls les workflows (`archives.yml`, `wikidata.yml`, `thesports.yml`, `mdc.yml`, `cqranking.yml`, `veille.yml`) et README / CLAUDE.md se modifient ici.
- `veille.yml` (toutes les heures, GitHub saute souvent les crons) relance `archives.yml` si aucun passage n'a démarré depuis 20 h
  (entre 23 h et 11 h UTC pendant la saison ; en intersaison, `collector.periode_de_courses` faux, à toute heure et dès 1 h sans passage
  s'il reste des saisons incomplètes) et `wikidata.yml` si aucun depuis 8 jours ; rien si un passage est en file ou en cours.
  `archives.yml` se relance lui-même en journée aussi pendant l'intersaison.
- `thesports.yml` (cron quotidien `37 2 * * *`, entrée `budget` défaut 50 min, groupe `thesports-data` : tourne en parallèle d'`archives.yml`
  et `wikidata.yml`) lance `thesports.py` du dépôt principal et commite SEULEMENT `data/archives/sources/thesports/` (`courses.json`,
  `editions/`, `coureurs.json`, `etat.json`, `cache/`). Il se relance tant que `etat.json` dit `termine: false` ET que le passage a changé des
  fichiers.
- `mdc.yml` (même modèle que `thesports.yml` : cron `13 3 * * *`, groupe `mdc-data`, entrée `budget` défaut 50) lance `mdc.py` (Mémoire du Cyclisme, accord du 18/11/2026,
  >= 3,2 s entre requêtes) et commite SEULEMENT `data/archives/sources/mdc/` ; auto-relance tant que `etat.json` dit `termine: false` ET que le passage a progressé.
- `cqranking.yml` (même modèle : cron `51 3 * * *`, groupe `cqranking-data`) lance `cqranking.py` (CQ Ranking, accord du 18/11/2026, >= 2,6 s entre requêtes)
  et commite SEULEMENT `data/archives/sources/cqranking/` ; auto-relance tant que `etat.json` dit `termine: false` ET que le passage a progressé.
- `.nojekyll` doit rester à la racine (Pages sans Jekyll).
- Claude peut fusionner lui-même ses PR (outils GitHub MCP) une fois le travail vérifié (YAML valide, essai du workflow).
- Déléguer à des agents Sonnet (outil Agent, `model: "sonnet"`) les tâches opérationnelles (lecture de logs, contrôles)
  et l'écriture de code ; garder la conception et la vérification finale.
