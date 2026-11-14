# courses-cyclistes-archives

Archives des saisons passées (hommes élite, route) du dashboard des courses cyclistes
[Camelbaggy/courses-cyclistes](https://github.com/Camelbaggy/courses-cyclistes). Ce dépôt ne contient **que des données
JSON**, générées automatiquement par le workflow `archives.yml` ; le code (collecteur, pipeline, page) et la
documentation (`docs/SPEC.md` §4.4, `docs/PLAN_ARCHIVES.md`) sont dans le dépôt principal.

La page du dashboard lit ces fichiers à la demande, depuis GitHub Pages (CORS ouvert) :

    https://camelbaggy.github.io/courses-cyclistes-archives/data/archives/

## Arborescence

```
data/archives/
├── index.json              récapitulatif des saisons présentes (saison, complete, nombre de courses, taille)
├── editions.json           éditions d'une même course (clé : nom normalisé + pays)
├── carrieres/              saisons d'un coureur, regroupées par initiale (<lettre>.json) + index.json
└── <année>/                une saison UCI (ex. 2024)
    ├── index.json          liste des courses de la saison, victoires françaises, derniers résultats
    ├── races/<id>.json     une fiche par course (étapes, classements, coureurs), compactée
    ├── riders.json         fiches coureurs de la saison
    ├── ranking.json        classement UCI de fin de saison
    └── state.json          état de la collecte (complete, décisions mémorisées)
```

Exemple : `https://camelbaggy.github.io/courses-cyclistes-archives/data/archives/index.json`.

## Fonctionnement

- Le workflow `archives.yml` (passages nocturnes, relance automatique tant qu'une saison demandée n'est pas complète)
  récupère le code du dépôt principal, collecte les saisons de la plus récente à la plus ancienne (2016-2025 par
  défaut, variable de dépôt `ARCHIVES_SAISONS` ou entrée manuelle `saisons`) puis commite `data/`.
- Une saison `complete` n'est plus recollectée (sauf révision ciblée des temps illisibles).
- Les saisons N-2 et plus anciennes quittent le Calendrier du dépôt principal pour arriver ici ; le dépôt principal
  retire alors ses propres fichiers de la saison, une fois qu'elle figure ici avec `complete: true`.
- Ne jamais modifier `data/` à la main.

## Source et licence

Source : UCI DataRide (résultats officiels). Classement UCI : pages publiques DataRide. Les données sont reproduites à
titre d'information pour le dashboard ; voir le dépôt principal pour les sources et conditions d'usage.
