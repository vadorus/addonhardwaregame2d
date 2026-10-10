# AUD-001 — Audit de développement multidisciplinaire Tech Empire

**Date : 10/10/2026.** **Code examiné :** `v013/demo-octobre` @ `c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f` ; version `0.12.2` (`project.godot`).  
**Méthode :** lecture ciblée des fichiers actuels, inventaire des scènes/scripts/tests, examen critique des rapports du 6 au 9 octobre. **Ce n'est PAS un nouvel essai du jeu sur Pixel, une campagne complète de tests ni une mesure de FPS.**  
**But :** distinguer défaut de code, défaut d'ergonomie, défaut d'équilibrage et manque de contenu pour prioriser sans défaire les améliorations validées.

## Complément QA-00 : une exécution réelle a suivi cet audit de code

Cet audit a été complété, **sans remplacement rétrospectif de sa méthode initiale**, par [QA-00 : campagne sur PC, sondes d'économie et de narration](reviews/RETOUR_2026-10-10_QA00.md). Les données nouvelles s'appliquent au **même HEAD `c1d4f6e`**. Résultats : tests CPU/Software/finance passants, problèmes de nettoyage lors du test tactile, faillites précoces en STANDARD pour une graine, accumulation de 225 M€ en ACCESSIBLE avec la stratégie ADAPTEE, 91 corps d'articles répétés sur 100 entrées homogènes. Aucun parcours utilisateur humain ni nouvelle performance Pixel.

## Synthèse et niveaux de confiance

**Verdict provisoire :** socle d'alpha techniquement jouable, nombreuses mécaniques et tests, mais qualité du jeu à confirmer par une partie humaine reproductible. Le risque dominant pour l'intérêt du joueur est le **temps passé à attendre et répéter des choix proches**, suivi de la lisibilité / cohérence des écrans, de la narration répétitive et de l'équilibrage de carrière. La performance est un **risque mesuré sur certaines anciennes révisions**, pas une permission de refaire l'interface au hasard. La croissance future présente un risque de couplage.

Notation de sévérité : **S0 = perte de données / impossible de jouer**, **S1 = bloque une démo convaincante**, **S2 = gêne sérieusement**, **S3 = amélioration ultérieure**. Sévérité ne signifie pas bug reproduit sur le HEAD.

| Discipline | Constat précis | Source du HEAD / preuve datée | Confiance | Priorité d'investigation |
| --- | --- | --- | --- | --- |
| Intégrité / sauvegardes | `SaveManager.gd` a version 34, sauvegarde .tmp/.bak et dossier test isolé ; ne rien casser. | `scripts/SaveManager.gd:5-40` | Haute pour existence ; fiabilité du HEAD non retestée | **S0 garde-fou** |
| Parcours débutant | Premier CPU, tutoriel et ateliers existent ; durée réelle jusqu'au premier lancement et compréhension à re-mesurer. | `tests/scenarios/FirstCpuJourneyScenario.gd`, `docs/design/NOVICE_15_MIN_PLAYTEST.md` | Moyenne | **S1** |
| Décisions CPU / Software | Trois jalons CPU fixes (phases 0, 2, 4) et trois choix logiciels (PLANNING, BUILD, STABILIZE) ont des impacts chiffrés ; cela ne prouve pas une expérience participative satisfaisante. | `scripts/ProjectDirectiveCatalog.gd:5-96`, `ResearchManager.gd`, `SoftwareManager.gd` | Haute sur code ; ressenti à tester | **S1** |
| Économie et carrière | Ancien test : crise en Standard 1972–73, emballement Accessible long terme, rang 1 inaccessible dans la sonde ; **résultats anciens à reproduire après tous les correctifs d'octobre**. | `docs/AUDIT_GAME_DESIGN_2026-10-08.md:47-56` | Historique, NON vérifié au HEAD | **S1** |
| Visualisation des conséquences | Modèles d'impact existent ; vérification systématique requise de « annoncé → effectivement débité/appliqué → observé ». | `scripts/ImpactPreview.gd`, `scripts/ProductionPreview.gd`, `ui/components/ProjectCard.gd` | Moyenne | **S1** |
| Interface / DA | Plusieurs scènes visuelles récentes, mais `CompanyScreen` (975 lignes) et `LabScreen` (1277 lignes) restent riches en formulaires/listes ; absence de vraie comparaison visuelle actuelle des 7 onglets dans cet audit. | `ui/screens/CompanyScreen.gd`, `LabScreen.gd`, `ProductsScreen.gd`, `MediaScreen.gd` | Haute sur structure, pas sur ressenti graphique | **S1 / S2** |
| Presse / dialogues | `MediaManager._review_text` utilise des tableaux HEADLINES/OPENERS/QUOTES et un `hash` du produit/média ; la trame reste constante. `PersonnelScreen` a quelques réponses prédéfinies aux situations d'équipe. | `scripts/MediaManager.gd:309-390`, `ui/screens/PersonnelScreen.gd:155-179` | Haute | **S1 / S2** |
| Vie d'entreprise / événements | `Interactions.pending()` relie événements existants à une conversation (RH, R&D, clients, fêtes…), mais la diversité de cadence et les conséquences ne sont pas quantifiées. | `scripts/Interactions.gd:1-85` | Haute sur déclencheurs, faible sur rythme | **S2** |
| Android / performances | Les optimisations `BranchMap` et `SalesPortfolio` sont présentes : réutilisation des lignes et signature de contenu. Ancienne mesure C4 Pixel : 33,50→2,38 ms pour `SalesPortfolio.refresh()` ; ne pas réintroduire l'ancien audit comme état actuel. Le test T2 ultérieur relève une pointe à 227,43 ms sur une période. | `ui/components/BranchMap.gd:65-102`, `ui/components/SalesPortfolio.gd:25-100`, `docs/reviews/C4_SALES_ROW_REUSE_AB_PIXEL_2026-10-08.md`, `docs/reviews/T2_PIXEL_C2_R1_A1_2026-10-09.md` | Haute sur historiques ; performance HEAD à mesurer | **S1 si ralentissement réel** |
| Architecture / extensibilité | `main.gd` ≈ 4128 lignes, `ResearchManager.gd` ≈ 1885, `SoftwareManager.gd` ≈ 1070 ; nombreux managers globaux. Bon pour prototyper, coûteux pour grandes extensions. | Fichiers du HEAD + `scripts/SimulationManager.gd` | Haute sur taille, moyenne sur risque exact | **S2**, refactor ciblé |
| Audio | Bus et limiteur intégrés ; ancien audit « sans bus » obsolète. Écoute finale non recontrôlée ici. | `default_bus_layout.tres` ; rapport T2/C2/R1/A1 | Haute sur existence, faible sur qualité audible | **S2** |
| Testabilité | Import, smoke, tests de parcours et de disposition sont versionnés ; T3 couvre explicitement Valider/Lancer/Confirmer. Quatre anciens tests signalés hors CI ; ni suite ni CI rejouées dans cet audit. | `tests/smoke_test.gd`, `tests/touch_tooltip_scenario.gd`, `docs/AUDIT_ARCHITECTURE_2026-10-08.md` | Haute sur présence, non évaluée au HEAD | **S0/S1 garde-fou** |
| Monétisation / futurs secteurs | `GameData.ACTIVE_SECTORS=["CPU"]` ; `CompanyBranches.gd` dessine des extensions, `BranchMap` désactive leur action ; document commercial est une proposition, pas une boutique. | `scripts/GameData.gd:1-13`, `scripts/CompanyBranches.gd:1-72`, `ui/components/BranchMap.gd:116-148`, `docs/MONETISATION_2026-10-08.md` | Haute | **S3** après tranche CPU |

## AUD-A — Direction de jeu / boucle principale

**Constat :** Le jeu possède le cycle conception → recherche → validation → fabrication → vente → presse / SAV. Il ne manque donc pas « des systèmes ». Il faut vérifier si chaque cycle produit un choix, une surprise, une conséquence visible et une modification de la stratégie suivante.

**Pourquoi c'est critique :** multiplier les réglages et les fenêtres sans enrichir la conséquence réelle accroît le travail plutôt que le plaisir. Les trois jalons actuellement modélisés sont réels : ne pas les supprimer ; tester plutôt leur différence perçue.

**Audit à réaliser :** deux profils humains (nouveau joueur, habitué) : trente minutes de début de partie + reprise d'une carrière avancée. Mesurer temps sans action significative, nombre de décisions distinctes, nombre de fois où un choix change la trajectoire, besoin de consulter une aide. Comparer la même partie en Accessible et Standard.

**Livrables :** chronologie « minute → intention → action → résultat → sentiment de maîtrise », problèmes S0/S1/S2 et recommandations testables. Pas de refonte avant ces observations.

## AUD-B — Économie, longévité et concurrence

Le rapport du 08/10 indique des falaises financières Standard et une inflation financière Accessible sur plusieurs décennies. **Ne pas annoncer que ces chiffres sont encore ceux du jeu actuel.**

**Audit à réaliser :** sonde de carrière sur graines officielles 104729, 208877, 313133, 417401, deux difficultés, stratégies figée/adaptée ; comparer trésorerie, capacité de financer la génération suivante, rang CPU, durée avant faillite, choix accessibles, rendement d'une nouvelle gamme et marge nette. Inclure un cas de second CPU avec 1 M€ de trésorerie pour reproduire ou réfuter une ancienne impossibilité de lancement.

**Règle :** corriger la cause (solvabilité, période d'investissement, coûts, blocage, explication) plutôt que distribuer de l'argent sans retour.

## AUD-C — Graphismes, ergonomie et accessibilité

Comparer **sept onglets réels** (QG, Entreprise, Équipe, Labo, Produits, Marché, Presse), leurs sous-pages en garage et carrière avancée. Capturer les mêmes états à 1280×720 et paysage Pixel ; annoter : action principale visible, hiérarchie, densité, cohérence des pictogrammes, tailles tactiles, défilement, cohérence de la typographie, animation et qualité des illustrations.

Les comparaisons avec Game Dev Tycoon / Devices Tycoon / PC Tycoon 2 doivent se faire sur **captures précises**, pas à partir du souvenir. L'élément de référence à reproduire est la **compréhension de la décision**, pas la copie d'une identité visuelle.

**Attention :** ne pas défaire les optimisations de rafraîchissement et les cibles tactiles existantes pendant les modernisations.

## AUD-D — Narration, presse et collaborateurs

Les textes sont partiellement contextuels mais combinatoires à partir de gabarits. Une variété de titres ne garantit pas l'absence de répétition ressentie.

**Audit à réaliser :** générer (sur copie / environnement de test) 100 articles de presse et 100 situations d'équipe à plusieurs états, compter doublons exacts et similaires, vérifier faits, époques, notes, prix, surnoms et personnages. Scénarios négatifs : rupture de stock vs mévente, CPU performant mais trop cher, équipe démotivée, concurrence dominante, ancien produit, produit identique réévalué.

**Architecture candidate :** faits typés fournis par simulation → sélection d'angle par média/personnalité → variantes de narration hors ligne → mémoire récente anti-répétition → texte final figé et sauvegardé. Les choix de phrases ne modifient **jamais** les chiffres du jeu ni le RNG économique. Favoriser résultat déterministe à graine/faits donnés. L'IA générative extérieure **n'est pas requise**.

## AUD-E — Architecture, compatibilité et tests

Auditer les dépendances entre `main.gd`, managers autoload, UI, simulation et sauvegarde. Établir des contrats stables pour les futurs secteurs : identité produit, évènements métiers, résultats économiques, stockage des données et migrations. Il ne faut **pas** découper tous les fichiers avant la démo.

**Essais requis avant code :** démarrage/import, smoke, scénarios de budget/projet/sauvegarde et T3, test d'ancienne sauvegarde sur dossier isolé, comparaison déterministe avant/après correctif, signaux sans rafraîchissement intempestif. Inspecter les quatre anciens tests hors CI et décider séparément s'ils sont maintenables.

## AUD-F — Mesures techniques Android et PC

**Acquis historique :** P0 réplicable sur Pixel, tests de 12 fins de mois par écran et 21 transitions ; `SalesPortfolio`/`BranchMap` optimisés avec résultats datés. **À faire :** rejouer la référence au commit courant, 30 puis éventuellement 60 FPS, sans toucher à l'original. Mesurer fin de mois, première ouverture des écrans séparément, frame-time p95/p99, pics, mémoire de textures, consommation/chauffe et lisibilité. Corriger uniquement le point chaud qui franchit le seuil.

## AUD-G — Commercialisation et extensibilité du contenu

Le jeu gratuit / version complète / DLC relève pour l'instant d'une **orientation produit**, pas d'une boutique fonctionnelle. Évaluer d'abord la capacité du contenu gratuit à retenir le joueur ; ensuite maquettes d'une rubrique « Extensions » affichant un statut honnête, jamais des fausses ventes. L'architecture de droits (Google/Steam/cache local) et les obligations des boutiques sont des chantiers séparés, à valider avant implémentation et publication.

## Arbitrage général

**Prioriser dans cet ordre :** intégrité et validation → compréhension des dix premières minutes → véritable pouvoir de décision CPU → économie et carrière → narration et cohérence visuelle → performance **mesurée** → extensibilité future et DLC. Ce n'est pas un plan de réécriture totale.

**Suite structurée :** [PLAN_PRIORISE_2026-10-10.md](PLAN_PRIORISE_2026-10-10.md). Revoir les conclusions avec captures, nouveaux tests et le retour du propriétaire. Les résultats historiques ne sont jamais requalifiés en PASS du HEAD.
