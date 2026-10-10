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

### CAREER-01 — 10/10/2026 — Mesure de 24 carrières

- **Base :** `v013/demo-octobre` @ `c1d4f6e` ; Godot 4.7.2, worktree isolé, quatre graines, deux modes et trois stratégies.
- **Résultats :** 24/24 terminés sans erreur Godot ; STANDARD **12/12 faillites**, ACCESSIBLE **9/12 survies** ; ADAPTÉE Accessible 190,7 à 225,2 M€. Pas de leadership **Empire**, ce n'est pas la métrique CPU sectorielle.
- **Code :** aucun coefficient ni jeu modifié. Rapport [CAREER-01](reviews/RETOUR_2026-10-10_CAREER01_4SEEDS.md), [issue #84](https://github.com/vadorus/addonhardwaregame2d/issues/84), [issue #85](https://github.com/vadorus/addonhardwaregame2d/issues/85) pour narration.
- **QA-02** : [PR #86](https://github.com/vadorus/addonhardwaregame2d/pull/86) corrige la provenance SHA des CSV ; test dédié, smoke et sonde C3 PASS sur PC. Branches séparées, aucune fusion.

### BUD-01 — 10/10/2026 — Diagnostic financier et alerte de recrutement

- **Point vérifié sur le code de base `c1d4f6e` :** graine 104729, Standard, stratégie Adaptée. Après une trésorerie à 28 829 € en août 1972, une recrue coûte **11 214 € de prime**, puis **5 607 € de salaires supplémentaires chaque mois** ; solde 13 959 € en septembre, 2 270 € en décembre, **−696 € en clôture janvier 1973**. La sonde affiche « faillite 02/1973 » après incrément du mois.
- **Interprétation limitée :** l'engagement de recrutement non soutenable explique la chute immédiate dans **ce parcours automatisé**, pas toutes les faillites Standard d'un joueur humain. Issue [#84](https://github.com/vadorus/addonhardwaregame2d/issues/84) enrichie avec le tableau mensuel.
- **Correctif proposé sur branche distincte :** [PR #87 — BUD-01](https://github.com/vadorus/addonhardwaregame2d/pull/87), **brouillon non fusionné** : devis pur dans `PersonnelManager.gd`, affichage du coût réel et du risque dans `PersonnelScreen.gd`, bouton désactivé si prime impossible, choix risqué toujours autorisé quand financé.
- **Tests Godot PC :** re-import propre après avertissement UID initial ; nouveau scénario financier PASS, nouveau scénario UI PASS, smoke PASS, budget 2e CPU et projet finance PASS. **Pas de validation au doigt Pixel**, aucune sauvegarde personnelle touchée. Logs sur PC et [rapport de PR](https://github.com/vadorus/addonhardwaregame2d/blob/fix/recrutement-prevision-20261010/docs/reviews/RETOUR_2026-10-10_BUD01.md).
- **À faire** : revue Claude du sens des indicateurs, parcours humain prudent et équilibre Accessible, capture/tactile Pixel sur copie et tests de carrière après toute future modification économique.

### NAR-01 — 10/10/2026 — Presse plus variée, mesurée sous Godot

- **Branche :** `feat/press-narration-vary-20261010`, [PR #88](https://github.com/vadorus/addonhardwaregame2d/pull/88) **brouillon** ; base code `c1d4f6e`.
- **Fichiers :** `scripts/MediaManager.gd`, test de corpus `tests/press_narrative_variation_test.*`, `docs/reviews/RETOUR_2026-10-10_NAR01.md` dans la branche concernée.
- **Avant/après réellement mesuré :** 100 articles homogènes → **9 corps distincts** ancien système, **100 corps distincts** après correction. Le test final a été répété au commit `3d3b5b0` après polissage français : **PASS** ; smoke, boot et sauvegarde PASS ; import froid avertissement UID puis reimport propre.
- **Portée :** rotation factuelle basée sur les métriques, formulations multiples, pas de RNG économique. Anciens articles inchangés au chargement ; qualité littéraire et contextes variés à relire. Aucun Pixel.

### CAREER-02 — 10/10/2026 — Comparaison contrôlée d'un automate plus prudent

- **Branche :** `audit/career-prudent-20261010`, [PR #89](https://github.com/vadorus/addonhardwaregame2d/pull/89) **brouillon**, base `c1d4f6e`.
- **But :** tester la cause des six faillites 02/1973 sans changer les coefficients de jeu ou la sonde C3 officielle.
- **Méthode :** sonde dérivée qui conserve la règle de décision et exige six mois de réserve estimée avant recrutement.
- **Mesure réelle :** 4 graines × 3 stratégies Standard = **12 résultats** avec exit 0 / zéro erreur ; les **6 faillites précoces** sont évitées, mais **les 12 carrières meurent plus tard**. Donc piste de causalité partielle, **pas de correction d'équilibrage**.
- **Test spécifique au commit `2ffa96d` :** garde de recrutement PASS et non-mutation, smoke/boot PASS ; premier import UID warning puis reimport propre. **Pas de Pixel** ; preuve complète dans `docs/reviews/RETOUR_2026-10-10_CAREER02_PRUDENT.md` (PR #89).
- **Prochainement :** analyser coût/profit du CPU après 1990, concurrence, durée commerciale et leadership CPU sectoriel distinct du rang Empire.

### SCENARIO-01 — 10/10/2026 — Clarification fondamentale sur les défis et la durée de vie

- **Origine :** clarification explicite du propriétaire : un « défi » est le **bâton dans les roues mis par le jeu et les scénarios de carrière**, pas une réalisation passive à débloquer.
- **Analyse vérifiée :** `SimulationManager.gd` finit seulement à la faillite ; `ObjectivesManager.gd` propose déjà trois pistes de buts ; `CareerPrestige.gd` inclut 10 trophées et score Empire composite ; `MarketManager.gd` possède des menaces espacées (actuellement au moins 48 mois et après 1975) ; `ExecutiveManager.gd` gère des problèmes RH. La base existe mais reste fragmentée et souvent binaire.
- **Livrable :** [SCENARIO-01](SCENARIOS_DEFI_CLASSEMENTS_2026-10-10.md) : architecture proposée d'arcs, multiples palmarès indépendants, déclencheurs liés à l'état du monde, règles de justice, plan WORLD-00/RANK-01/WORLD-01 et tests.
- **Statut :** **conception seulement**, aucune scène ni règle de simulation modifiée ; pas de test Godot requis à ce stade. Intégration et coefficients **non autorisés sans revue de conception**.
- **À relire par Claude :** ne pas confondre objectifs/trophées avec scénarios d'adversité, éviter de dupliquer le système de menaces, préserver classement Empire existant en attendant décision et distinguer le n°1 CPU sectoriel.

## Prochaines entrées

Ne jamais combiner plusieurs sujets non liés sous « diverses corrections ». Pour chaque modification, dupliquer [MODELE_RAPPORT_LOT.md](MODELE_RAPPORT_LOT.md) dans un `docs/reviews/RETOUR_<DATE>_<LOT>.md` et ajouter ici :

| Lot | Date | Branche / commit | Fichiers principaux | Tests PC | Pixel | Revue / fusion |
| --- | --- | --- | --- | --- | --- | --- |
| DOC-001 | 10/10/2026 | `docs/journal-passation-2026-10-10` ; SHA via Git | Documentation, `README.md` | Non requis (docs) | Non requis | À relire ; pas fusionné |

| AUD-001 | 10/10/2026 | `docs/journal-passation-2026-10-10` ; [PR #83](https://github.com/vadorus/addonhardwaregame2d/pull/83) | Audit + plan priorisé | Non exécuté (audit documentaire) | Non exécuté | À relire ; pas fusionné |

| QA-00 | 10/10/2026 | `docs/journal-passation-2026-10-10` ; [PR #83](https://github.com/vadorus/addonhardwaregame2d/pull/83) | [Rapport tests réels](reviews/RETOUR_2026-10-10_QA00.md) | 12 commandes Godot code 0, limites détaillées | Non testé | PR brouillon ; pas fusionné |

| BUD-01 | 10/10/2026 | [PR #87](https://github.com/vadorus/addonhardwaregame2d/pull/87) | Aperçu réel du coût et du risque de recrutement | 2 tests ciblés + smoke + budget + finance PASS | **Non testé** | Brouillon, sans fusion ni changement des coûts |

**Jamais** écrire « PASS » sans commande, sortie et révision ; écrire « non exécuté » si besoin. Les décisions nouvelles se copient également dans [DECISIONS.md](DECISIONS.md).
