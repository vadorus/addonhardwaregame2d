# Tech Empire — journal de développement et de corrections

**Objectif :** donner à Claude un historique sans ambiguïté de tout ce qui a changé pendant son absence, sans confondre code livré, tests et suggestions.  
**Règle :** chaque lot a un identifiant, une branche, un ou plusieurs commits ciblés et un dossier de preuves. Le SHA/PR Git reste la preuve primaire des fichiers modifiés.

## Entrées

### DOC-001 — 10/10/2026 — Référentiel documentaire et passation

- **Auteur de la préparation :** ChatGPT.
- **Branche de travail :** `docs/journal-passation-2026-10-10`, dérivée de `v013/demo-octobre` @ `c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f`.
- **But :** centraliser état, décisions, journal, ordre de lecture, preuves et procédure de passation.
- **Fichiers ajoutés :** `docs/INDEX.md`, `docs/ETAT_ACTUEL.md`, `docs/DECISIONS.md`, `docs/JOURNAL_DEVELOPPEMENT.md`, `docs/HANDOFF_CLAUDE_2026-10-14.md`, `docs/DOC_MAINTENANCE.md`, `docs/reviews/INDEX.md`, `docs/MODELE_RAPPORT_LOT.md`.
- **Fichier adapté :** `README.md` (orientation vers le référentiel et correction des références version / branche de travail).
- **Modification de gameplay / données / sauvegardes :** aucune.
- **Vérifications :** inventaire GitHub et cohérence documentaire relus sur la base ; contrôle du diff / branche à joindre à la PR. **Aucun test Godot exécuté** pour ce lot uniquement documentaire.
- **Risques connus :** rapports anciens non supprimés et potentiellement contradictoires ; l'état du jeu reste une photographie datée.
- **Retour arrière :** fermer la PR / supprimer la branche, sans toucher au jeu.
- **Statut :** proposé sur branche de documentation ; **fusion non effectuée**, revue Claude possible à son retour.

## Prochaines entrées

Ne jamais combiner plusieurs sujets non liés sous « diverses corrections ». Pour chaque modification, dupliquer [MODELE_RAPPORT_LOT.md](MODELE_RAPPORT_LOT.md) dans un `docs/reviews/RETOUR_<DATE>_<LOT>.md` et ajouter ici :

| Lot | Date | Branche / commit | Fichiers principaux | Tests PC | Pixel | Revue / fusion |
| --- | --- | --- | --- | --- | --- | --- |
| DOC-001 | 10/10/2026 | `docs/journal-passation-2026-10-10` ; SHA via Git | Documentation, `README.md` | Non requis (docs) | Non requis | À relire ; pas fusionné |

**Jamais** écrire « PASS » sans commande, sortie et révision ; écrire « non exécuté » si besoin. Les décisions nouvelles se copient également dans [DECISIONS.md](DECISIONS.md).

