# CLAUDE.md

Dépôt de **données** : `data/archives/` (saisons passées du dashboard des courses cyclistes), servi par GitHub Pages
(`https://camelbaggy.github.io/courses-cyclistes-archives/`). Tout est en français (logs, messages de commit).

- Il ne contient que des fichiers JSON générés par `.github/workflows/archives.yml`. Le code (collecteur, pipeline,
  page) et toute la documentation (CLAUDE.md, `docs/SPEC.md` §4.4, `docs/PLAN_ARCHIVES.md`) sont dans
  Camelbaggy/courses-cyclistes : y modifier le code, pas ici.
- **Ne jamais modifier `data/` à la main** (ni committer d'archives générées en local) : le workflow est seul auteur.
  Seuls les workflows (`archives.yml`, `wikidata.yml`, `veille.yml`) et README / CLAUDE.md se modifient ici.
- `veille.yml` (toutes les heures, GitHub saute souvent les crons) relance `archives.yml` si aucun passage n'a démarré depuis 20 h
  (seulement entre 23 h et 11 h UTC) et `wikidata.yml` si aucun depuis 8 jours ; rien si un passage est en file ou en cours.
- `.nojekyll` doit rester à la racine (Pages sans Jekyll).
- Claude peut fusionner lui-même ses PR (outils GitHub MCP) une fois le travail vérifié (YAML valide, essai du workflow).
- Déléguer à des agents Sonnet (outil Agent, `model: "sonnet"`) les tâches opérationnelles (lecture de logs, contrôles)
  et l'écriture de code ; garder la conception et la vérification finale.
