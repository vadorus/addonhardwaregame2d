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
- **Vérifications :** comparaison Git : **9 fichiers documentaires seulement**, aucun script du jeu ; vérification automatisée de **64 liens internes dans les 9 fichiers : 0 lien manquant** ; **aucun test Godot exécuté** pour ce lot uniquement documentaire.
- **Risques connus :** rapports anciens non supprimés et potentiellement contradictoires ; l'état du jeu reste une photographie datée.
- **Retour arrière :** fermer la PR / supprimer la branche, sans toucher au jeu.
- **PR :** [#83 — référentiel documentaire, brouillon](https://github.com/vadorus/addonhardwaregame2d/pull/83). Commit principal `f075c76`, correction README `43a4fcd`.
- **Statut :** poussé sur branche de documentation et PR brouillon ouverte ; **fusion non effectuée**, revue Claude possible à son retour.

### AUD-001 — 10/10/2026 — Audit de développement et priorités

- **Auteur :** ChatGPT ; **base examinée :** `v013/demo-octobre` @ `c1d4f6e`, version `0.12.2`.
- **Fichiers ajoutés :** `docs/AUDIT_MULTIDISCIPLINAIRE_2026-10-10.md` et `docs/PLAN_PRIORISE_2026-10-10.md`.
- **Fichiers de suivi complétés :** `docs/INDEX.md`, `docs/JOURNAL_DEVELOPPEMENT.md` et `docs/HANDOFF_CLAUDE_2026-10-14.md`.
- **Travaux :** inventaire de la simulation, du gameplay, des scripts narratifs, des écrans, des sauvegardes, des optimisations C4, de la monétisation ; distinction preuves historiques / état présent.
- **Vérifications réelles :** lecture GitHub et contrôle des liens sur la branche ; **aucun test Godot ni essai Pixel réalisé** pour cet audit documentaire.
- **Livraison :** ajout sur la **PR #83 en brouillon** ; aucun changement de code de jeu ni fusion.
- **Suite Claude :** confronter le plan aux modifications ultérieures, valider l'ordre proposé et identifier les nouvelles mesures / captures nécessaires.

### QA-00 — 10/10/2026 — Contrôles fonctionnels et sondes réelles

- **Responsable :** ChatGPT ; **base de test :** `c1d4f6e`, Godot 4.7.2 stable, copie `TechEmpire-AUD001-20261010` isolée.
- **Fichiers ajoutés :** `docs/reviews/RETOUR_2026-10-10_QA00.md`.
- **Résultats :** 12 commandes code 0, import à froid UID transitoire résolu par un second import, test tactile PASS mais fuites à la sortie ; budget second CPU, finance, CPU, Software, smoke PASS.
- **Sondes :** STANDARD graine 104729 ADAPTEE faillite 02/1973 ; ACCESSIBLE ADAPTEE **225 187 329 €** fin 2030, rang Empire 3 ; 100 articles homogènes → 9 corps distincts seulement.
- **Visuel :** QG rendu 1280×720. Les autres onglets étaient normalement verrouillés dans la fixture de départ, **non validés visuellement**.
- **Code / sauvegardes :** aucun fichier suivi du jeu modifié, worktree personnel non utilisé, aucune action sur Pixel.
- **État Git :** rapport ajouté sur PR #83 brouillon, aucune fusion. Prochains travaux `CAREER-01`, `NAR-00`, `PLAY-00` / `VIS-00`.

## Prochaines entrées

Ne jamais combiner plusieurs sujets non liés sous « diverses corrections ». Pour chaque modification, dupliquer [MODELE_RAPPORT_LOT.md](MODELE_RAPPORT_LOT.md) dans un `docs/reviews/RETOUR_<DATE>_<LOT>.md` et ajouter ici :

| Lot | Date | Branche / commit | Fichiers principaux | Tests PC | Pixel | Revue / fusion |
| --- | --- | --- | --- | --- | --- | --- |
| DOC-001 | 10/10/2026 | `docs/journal-passation-2026-10-10` ; SHA via Git | Documentation, `README.md` | Non requis (docs) | Non requis | À relire ; pas fusionné |

| AUD-001 | 10/10/2026 | `docs/journal-passation-2026-10-10` ; [PR #83](https://github.com/vadorus/addonhardwaregame2d/pull/83) | Audit + plan priorisé | Non exécuté (audit documentaire) | Non exécuté | À relire ; pas fusionné |

| QA-00 | 10/10/2026 | `docs/journal-passation-2026-10-10` ; [PR #83](https://github.com/vadorus/addonhardwaregame2d/pull/83) | [Rapport tests réels](reviews/RETOUR_2026-10-10_QA00.md) | 12 commandes Godot code 0, limites détaillées | Non testé | PR brouillon ; pas fusionné |

**Jamais** écrire « PASS » sans commande, sortie et révision ; écrire « non exécuté » si besoin. Les décisions nouvelles se copient également dans [DECISIONS.md](DECISIONS.md).
