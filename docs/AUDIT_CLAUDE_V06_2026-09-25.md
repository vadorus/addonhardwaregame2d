> **Audit externe archivé.** Rapport produit par Claude sur le commit `913610afb5241ee30297d0a5e8fba5281d798c8e`. Les correctifs effectués après ce commit peuvent avoir déjà résolu certains constats. Ne pas modifier ce rapport historique ; documenter les résolutions séparément.

# Audit indépendant — Tech Empire V0.6 « room-first » (second auditeur)

- **Branche auditée :** `prototype/v06-room-first-ui`
- **Commit vérifié :** `913610afb5241ee30297d0a5e8fba5281d798c8e` (lu dans `.git/refs/heads/prototype/v06-room-first-ui`)
- **Date :** 25 septembre 2026
- **Auditeur :** Claude (second audit indépendant)

---

## 0. Méthode et niveau de preuve

Ce qui a été fait :

1. **Lecture du code** : tous les fichiers demandés (`BalanceManager`, `CompanyManager`, `PersonnelManager`, `ExecutiveManager`, `ResearchManager`, `ProductionManager`, `FoundryManager`, `AfterSalesManager`, `FirstCpuWorkshop`, `GarageHub`, `LabScreen`, `main.gd`, les scénarios de test, `smoke_test.gd`), plus les fichiers dont ils dépendent (`EconomyManager`, `SimulationManager`, `TimeManager`, `DevelopmentGates`, `DevelopmentEstimator`, `CpuGenerationPlanner`, `GameData`, `ProductManager`, `DivisionManager`, `DashboardScreen`, `CompanyScreen`, `NoraGuidePanel`, `IndustrializationPanel`).
2. **Lecture de la documentation** : `README.md`, `docs/DESIGN_BIBLE.md`, `docs/CPU_VERTICAL_SLICE.md`, `docs/ROADMAP.md`, `docs/UX_ART_DIRECTION.md`, `docs/V06_PLAYTEST_ECONOMY.md`, `AGENTS.md`.
3. **Exécution réelle** : le dossier a été copié en lecture seule dans un bac à sable Linux. Les trois étapes de la CI y ont été lancées avec le binaire officiel **Godot 4.7.2 headless** (import, boot, smoke test).
4. **Sondes de simulation** : des scripts GDScript ont été ajoutés **uniquement dans la copie du bac à sable**. Ils rejouent ~45 parties complètes avec d'autres stratégies (brief, intensité, décisions de revue, stratégie industrielle, fonderie, gamme lancée, prix, approche de sourcing, difficulté, recrutement, recherche, déménagement). Ils mesurent aussi la taille réelle du viewport sous plusieurs résolutions et journalisent la trésorerie juste avant chaque injection d'argent du smoke test.

Ce qui n'a **pas** été fait :

- Aucun fichier du projet sur le PC n'a été modifié, à part l'écriture de ce rapport. Aucun commit, aucun push.
- Desktop Commander n'était pas disponible dans cette session. L'accès s'est fait par le pont Claude Desktop, en copiant les fichiers dans le bac à sable.
- **Aucun test visuel sur appareil Android n'a été fait.** Les constats mobiles ci-dessous viennent du code et d'une mesure du viewport en headless. Les tailles physiques sont des **estimations** à confirmer sur appareil.

Convention : **[VÉRIFIÉ]** = mesuré par exécution ; **[CODE]** = déduit d'une lecture précise du code ; **[ESTIMÉ]** = raisonnement à confirmer.

---

## 1. Synthèse

- **Techniquement, la V0.6 est saine.** La CI est reproduite (0 erreur d'import, boot propre, smoke test « passed » en 3,5 s). Les chiffres du playtest Android sont reproduits **à l'euro près** (2 300 / 500 / 1 652 → 4 452 €, trésorerie 95 548 €).
- **Réaliste (70 000 €) mène à une faillite automatique** avant la première vente. Les 5 trajectoires les moins chères testées font toutes faillite pendant l'industrialisation, entre les mois 14 et 18.
- **Standard (100 000 €) est sur le fil du rasoir.** Le chemin par défaut arrive au lancement avec **14 522 €** (85,5 k€ consommés en 16 mois). Plusieurs choix raisonnables et proposés par l'interface mènent à la faillite juste avant la première vente : une correction payante en revue, une intensité ≥ 75 k, une embauche, un chercheur affecté, un programme Concept, un partenaire. Aucun levier ne permet de se redresser.
- **Après le lancement, l'économie n'a plus de limite.** On gagne **+166 k€/mois** dès le premier mois, à l'identique pendant 30 mois. Les 100 k€ deviennent **4 M€ en 24 mois** avec 3 fondateurs ; en lançant les 3 modèles, on atteint **10 M€**. La tension du garage disparaît d'un coup.
- **La séparation « intensité R&D / sortie de caisse » n'existe que dans l'atelier du premier CPU.** Le planificateur de génération, les revues prototype/validation, la recherche fondamentale, les programmes Concept, le mandat de division et deux écrans traitent encore l'intensité comme des euros.
- **Les tests couvrent un seul chemin heureux.** Deux injections de trésorerie masquent de vrais défauts : 3 M€ dans `NextGenerationMarketLearningScenario`, et une trésorerie déjà négative (−15 246 €) avant l'injection du smoke test industriel.
- **Mobile :** le CTA « Lancer ce CPU » est bien visible en paysage, mais par effet de bord. Avec `canvas_items` + `expand`, la largeur logique ne descend jamais sous 1 280 px. **Tous les points de rupture « mobile » du code sont donc inatteignables**, et le test qui les vérifie teste une largeur qui n'existe pas en jeu.

---

## 2. Mesures clés (simulations exécutées sur Godot 4.7.2)

### 2.1 Premier mois (reproduction du playtest)

| Difficulté | Capital | Masse salariale projetée | Masse salariale réellement débitée | Dépenses mois 1 |
|---|---:|---:|---:|---:|
| Accessible | 150 000 | 2 116 | **2 024** | 3 918 |
| Standard | 100 000 | 2 300 | 2 300 | **4 452** ✔ |
| Réaliste | 70 000 | 2 484 | **2 530** | 4 930 |

L'écart projection/réel en Accessible et Réaliste est expliqué en I5‑d.

### 2.2 Coût complet jusqu'au lancement — Standard, brief « Simple & économique », choix par défaut [VÉRIFIÉ]

| Poste (16 mois) | Montant |
|---|---:|
| Rémunération équipe fondatrice | 36 800 |
| Entretien / locaux | 8 000 |
| Développement Nova 1 | 19 824 |
| Revue prototype (BALANCE) | 5 250 |
| Mise en production (Pioneer) | 3 500 |
| Industrialisation (4 mois) | 12 104 |
| **Total avant première vente** | **85 478** |
| **Trésorerie au lancement** | **14 522** |

### 2.3 Matrice de stratégies — Standard sauf mention contraire [VÉRIFIÉ]

| Variante (le reste = défaut) | Résultat | Trésorerie au lancement |
|---|---|---:|
| Défaut (Calculatrice 35 k, BALANCE, APPROVE) | OK | 14 522 |
| Intensité 10 k | OK | 20 696 |
| Intensité 60 k | OK | 7 876 |
| **Intensité 75 k** | **Faillite M14 (industrialisation)** | — |
| **Intensité 92,5 k** | **Faillite M13** | — |
| **Intensité 150 k** | **Faillite M8 (développement)** | — |
| Brief Embarqué 45 k | OK | 7 002 |
| Brief Industriel 47,5 k | OK | 10 609 |
| Brief Pionnier 55 k | OK | **3 886** |
| Revue prototype FIX | OK | 4 820 |
| **Validation CORRECT** | **Faillite M17** | — |
| Validation HARDEN | OK | 3 070 |
| **FIX + HARDEN** | **Faillite M17** | — |
| **Pionnier + FIX** | **Faillite M15** | — |
| **Pionnier + HARDEN** | **Faillite M14** | — |
| **Embarqué + FIX** | **Faillite M17** | — |
| **Embarqué + CORRECT** | **Faillite M15** | — |
| **Industriel + HARDEN** | **Faillite M16** | — |
| Industrialisation QUALITY + EuroSilicon | OK | **946** |
| **Approche PARTNER** | **Faillite M4** | — |
| **Approche LICENSE** | **Faillite M2** | — |
| **1 recrutement au garage** | **Faillite M8** | — |
| **1 chercheur affecté (budget par défaut)** | **Faillite M7** | — |
| **Programme Concept minimal (5 k, ambition 1)** | **Faillite M16** | — |
| Accessible, défaut | OK | 74 466 |
| **Réaliste, défaut** | **Faillite M14** | — |
| **Réaliste, 10 k + PUSH + ECONOMY + RapidFab (le moins cher)** | **Faillite M18** | — |

### 2.4 Après le lancement — Standard, modèle Signature seul [VÉRIFIÉ]

| Mois de vente | Demande | Capacité | Ventes | Recettes | Dépenses | Trésorerie |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 2 558 | 920 | 920 | 211 600 | 46 297 | 179 825 |
| 12 | 2 620 | 920 | 920 | 211 600 | 46 297 | 1 998 158 |
| 24 | 2 373 | 920 | 920 | 211 600 | 46 297 | 3 981 794 |
| 30 | 2 293 | 920 | 920 | 211 600 | 46 297 | 4 973 612 |

Prix 230 €, coût unitaire 37 €. Les 3 modèles lancés ensemble donnent +420 795 €/mois et 10,1 M€ après 24 mois.

---

## 3. BLOQUANT

### B1 — Réaliste : faillite automatique avant la première vente [VÉRIFIÉ]

- **Où :** `BalanceManager.PROFILES.REALISTIC` (capital 70 000, facteurs de coût 1,08–1,12), en lien avec le coût total du chemin jusqu'au lancement (§2.2).
- **Pourquoi :** le chemin minimal coûte déjà ~82 k€ en Réaliste (développement ~15 mois + industrialisation ~4 mois), plus que le capital. Il n'existe aucun revenu avant lancement (les appels d'offres exigent un produit READY) ni aucun financement.
- **Impact joueur :** 15 à 18 mois de jeu, puis un game over pendant l'industrialisation, quelle que soit la stratégie. C'est exactement le « chemin qui mène mécaniquement à la faillite » que la V0.6 voulait éviter.
- **Correction recommandée :** calibrer chaque difficulté sur le **coût complet jusqu'au lancement** (développement + charges fixes × durée + revue moyenne + mise en production + industrialisation), pas sur le premier mois. En ordre de grandeur, il faut soit un capital Réaliste ≈ 95–100 k€, soit des coûts Réaliste plus bas sur ce chemin précis. Ajouter un **scénario de parcours complet par difficulté** en CI (voir I7).

### B2 — Économie post-lancement sans limite : la partie est « résolue » dès la première vente [VÉRIFIÉ]

- **Où :** `MarketManager.estimate_consumer_demand` / `estimate_portfolio_demand` (demande 2,5–2,8× la capacité), `ProductManager.launch_product` (capacité gratuite jusqu'à `max_monthly_capacity`), `ProductManager._sell_product_month` (aucun coût fixe lié au volume, aucun stock, aucun coût par SKU).
- **Pourquoi :** marge brute de 84 % (230 € contre 37 €). Les ventes sont plafonnées par la capacité, donc **identiques chaque mois pendant 30 mois**. La pression de l'âge (−4,8 pts à 30 mois) ne passe jamais sous la capacité. Lancer toute la gamme ne coûte rien de plus et multiplie le profit par 2,5. Trois fondateurs vendent 920 à 2 700 CPU par mois sans Production, Marketing ni SAV.
- **Impact joueur :** toute la tension du garage disparaît au premier mois de vente. Le saut des salaires fondateurs (×4) devient anecdotique (9 200 € contre +166 k€). Les tests de viabilité post-lancement passent trivialement. Le fantasme « garage 1971 » (épargne, prise de risque) tient 16 mois, puis on atteint 4 M€ en deux ans.
- **Correction recommandée :**
  1. Recalibrer la taille et les prix des segments de 1971 pour qu'un premier produit rentabilise plutôt **en 12–24 mois**, pas en un.
  2. Rendre la capacité coûteuse : engagement de volume ou achat de lots de wafers au fondeur, minimum de commande, stock, délai.
  3. Faire coûter chaque SKU lancé (validation, qualification, support), comme le promet `CPU_VERTICAL_SLICE.md` (« une gamme trop large coûte en validation, marketing, stock et support »).
  4. Ajouter un test borné, par exemple « trésorerie après 12 mois commerciaux ∈ [x ; y] × capital ».

### B3 — Standard : une seule famille de trajectoires survit, sans aucun moyen de se rattraper [VÉRIFIÉ]

- **Où :**
  - `DevelopmentGates.build_prototype_review` / `build_validation_review` : les coûts sont indexés sur `monthly_budget`, donc sur l'**intensité**, pas sur la sortie de caisse. CORRECT = 35 % de l'intensité, soit **12 250 €** à 35 k et **19 250 €** à 55 k, alors que la vraie sortie de caisse du développement est de 1 652 €/mois.
  - `ResearchManager.resolve_project_decision` : ne vérifie que `can_afford(cost)` immédiat, pas la capacité à financer l'industrialisation derrière.
  - Il n'existe aucune fonction pour annuler un projet, baisser l'intensité en cours de route, licencier, emprunter ou lever des fonds.
- **Pourquoi :** la marge au lancement est de 3,9 k€ (Pionnier) à 14,5 k€ (Calculatrice). Une seule correction payante, proposée comme un « vrai choix » par l'interface, suffit à provoquer la faillite dans 3 briefs sur 4 (§2.3). Même le brief le plus prudent meurt avec CORRECT à la validation.
- **Impact joueur :** les revues prototype/validation sont des **faux choix** : la seule stratégie sûre est « ne jamais payer pour la qualité ». Le joueur l'apprend par un game over au mois 15–17, sans avertissement. Cela contredit `DESIGN_BIBLE.md` §139 (« plusieurs trajectoires raisonnables vers un premier CPU industrialisé »).
- **Correction recommandée :**
  1. Calculer le coût des revues sur la sortie de caisse (`development_monthly_base_cost × k` ou un coût propre au prototype, fonction du nœud et de la complexité).
  2. Afficher et contrôler dans l'arbitrage « trésorerie restante après cette décision **et** après une industrialisation estimée ».
  3. Donner au moins deux leviers de redressement : réduire l'intensité en cours de projet, mettre le projet en sommeil, apport personnel ou petit prêt bancaire de 1971 avec intérêts.
  4. Viser, en Standard, une marge au lancement de 25–35 % du capital sur le chemin par défaut, et > 0 avec une correction payante.

---

## 4. IMPORTANT

### I1 — Planificateur de génération : coût programme fantôme multiplié par 20 à 30, et recommandation faussée [VÉRIFIÉ]

- **Où :** `CpuGenerationPlanner._build_proposal` et `_mark_recommendation`.
- **Pourquoi :**
  - `monthly_program_cost = monthly_budget × approach_cost` **sans** `development_cash_factor`. Il ajoute un `prototype_cost` qui n'est **débité nulle part** (grep : aucune autre occurrence).
  - Mesures au premier CPU : plans SAFE/BALANCED/BOLD affichés à **460 k€ / 544 k€ / 710 k€** (35 k) et **537 k€ / 644 k€ / 858 k€** (45 k), contre **21–25 k€** estimés par le laboratoire pour le même design.
  - Les durées divergent aussi : BOLD affiche 17 mois contre 13 dans le laboratoire, car le laboratoire ignore `duration_factor`.
  - La recommandation compare ces montants fantômes à la trésorerie. Avec 100 k€, Camille recommande donc toujours SAFE, et BOLD n'est jamais recommandé tant que la trésorerie reste sous ~520 k€.
- **Test masquant :** `NextGenerationMarketLearningScenario` fixe `Economy.money = 3_000_000`. Rejoué avec 100 000 € **et** 400 000 €, il échoue : *« Strong profitable unmet demand did not influence Camille toward the ambitious next-generation plan »*.
- **Impact joueur :** dans les « Réglages avancés », le même écran affiche un programme à ~25 k€ et un plan de génération à ~640 k€, six fois le capital. Le conseil de Camille devient illisible ou faux.
- **Correction recommandée :** faire appeler `ResearchManager.estimate_cpu_development` (ou une fonction de coût commune) par le planificateur ; supprimer ou débiter réellement `prototype_cost` ; appliquer `duration_factor` au laboratoire ou le retirer du planificateur ; ramener le test à une trésorerie réaliste.

### I2 — La séparation « intensité / sortie de caisse » n'est appliquée qu'au développement interne [VÉRIFIÉ / CODE]

| Endroit | Traitement actuel | Conséquence mesurée |
|---|---|---|
| `ResearchManager._process_continuous_research` | débite `continuous_research_budget` (12 000 par défaut) **en entier** dès qu'un chercheur est affecté | 1 chercheur (Camille) → **16 452 €** au mois 1, faillite au **mois 7** |
| `ResearchManager._process_concept_programs` | débite `monthly_budget` en entier (min 5 000, défaut UI 15 000) | Concept minimal → faillite au **mois 16** ; dans le smoke test, trésorerie à **−48 000 €** avant restauration |
| `DevelopmentGates` | coûts proportionnels à l'intensité | voir B3 |
| `DivisionManager.current_commitments` | additionne des intensités et les compare à un plafond en € | alertes de mandat faussées dès que la délégation existe |
| `DashboardScreen` l.540 | affiche l'intensité en « €/mois » | libellé faux (masqué en room-first, actif sinon) |
| `LabScreen` l.220–222 | « Budget mensuel développement CPU », 10 k à 250 k | l'écran avancé n'a pas la nouvelle distinction |

- **Pourquoi :** la recherche et les programmes Concept sont menés par des salariés déjà payés (Camille est la seule personne en R&D). C'est exactement le double comptage que la V0.6 voulait supprimer.
- **Impact joueur :** le « Tableau de planification » est accessible dès le départ et propose une action standard (affecter un chercheur) qui ruine l'entreprise en 7 mois.
- **Correction recommandée :** une fonction unique `cash_cost(kind, intensity, stage)` utilisée partout ; le même libellé à deux lignes (intensité / sortie de caisse) sur tous les écrans ; un budget de recherche par défaut compatible avec le garage (ou 0 tant que le joueur ne le règle pas) ; des tests dédiés.

### I3 — L'intensité R&D est un piège non signalé [VÉRIFIÉ]

- **Où :** `ResearchManager.estimate_cpu_development` / `_process_project_month` (`budget_ratio` plafonné à 2,2 × 42 000 = **92 400**) ; `FirstCpuWorkshop._budget` (max 150 000) ; `LabScreen.rd_budget` (max 250 000).
- **Pourquoi :**
  - Au-delà de 92 400, chaque euro d'intensité est une dépense sans aucun effet sur la vitesse ou la qualité. À 150 k, la sortie de caisse est de 7 080 €/mois pour la même durée de 9 mois.
  - En dessous, l'intensité rend le projet plus rapide, mais **alourdit les revues** (B3).
  - Mesures : 10 k → 16 mois, 52,8 k€ jusqu'à la fin du développement ; 92,5 k → 9 mois, 64,5 k€, puis faillite pendant l'industrialisation à cause du coût de revue ; 150 k → faillite au mois 8.
- **Impact joueur :** le réflexe « plus d'intensité = plus vite » est puni sans explication.
- **Correction recommandée :** limiter le curseur à la zone utile (ou afficher « aucun gain au-delà de … ») ; découpler le coût des revues de l'intensité ; faire apparaître le coût total jusqu'au lancement dans l'aperçu.

### I4 — Les décisions bloquantes sont invisibles depuis le QG room-first, et le temps continue de coûter [VÉRIFIÉ / CODE]

- **Où :**
  - `main.gd:_on_dashboard_navigation` : la pause n'est activée que pour `context == "PROJECT_DECISION"`, c'est-à-dire le « Banc de test ».
  - `main.gd:_close_month_report` : remet `time_scale = 1.0` même si une décision attend.
  - `DashboardScreen.refresh` : en room-first, la carte priorité, les alertes et le guide Nora sont masqués (`visible = not room_first` / `false`).
  - `DashboardScreen._dashboard_priority_pressed` et `NoraGuidePanel` naviguent avec un contexte vide.
  - `GarageHub` : aucun badge sur la zone concernée.
- **Mesure :** un mois avec une revue prototype en attente coûte **2 800 €** (fondateurs + local) pour **0 progression**. Le même schéma vaut pour l'industrialisation sans route choisie (`route_selected == false` → aucun progrès) et pour un produit READY non lancé.
- **Impact joueur :** après « Continuer » sur le rapport mensuel, le temps repart. Le QG ne montre que la pièce, rien n'indique qu'une décision bloque le projet. Avec des marges de 3,9 à 14,5 k€, **2 à 5 mois d'inattention suffisent à la faillite**. La règle UX du doc (« une décision bloquante … doit … mettre le temps en pause ») n'est respectée que si le joueur pense à toucher le banc de test.
- **Correction recommandée :**
  - Mettre en pause automatiquement quand une décision bloquante apparaît, et ne pas relancer le temps au sortir du rapport mensuel tant qu'elle existe.
  - Ajouter au rapport mensuel une section « Décisions en attente » avec un bouton direct.
  - Afficher un badge pulsé sur la zone du décor concernée (Banc de test, Stock & production).
  - Ajouter un test de routage UI.

### I5 — Rémunération fondatrice à 25 % : défendable dans le récit, fragile mécaniquement [VÉRIFIÉ / CODE]

- **Où :** `PersonnelManager.founding_stage_active`, `employee_monthly_pay`, `process_month`, `monthly_payroll_cost`.

**Ce qui est défendable :** des fondateurs de 1971 qui vivent sur leur épargne et se paient au minimum, c'est crédible. Le chiffre de 2 300 € correspond au playtest.

**Ce qui ne l'est pas :**

- **a. Subvention cachée plus grande que le capital.** 6 900 €/mois non versés × 16 mois ≈ **110 k€**. L'équilibrage de la Standard repose davantage sur cette règle que sur les 100 k€. Si le taux passe de 25 % à 50 %, le chemin par défaut fait faillite.
- **b. Aucune contrepartie.** Pas de dette de salaire, pas d'effet sur le moral ou la rétention, pas de parts. Le commentaire du code dit « reportent une partie de leur rémunération », mais rien n'est jamais rattrapé.
- **c. Falaise ×4.** Le stade fondateur prend fin au **premier produit en statut LAUNCHED**, même s'il ne vend rien, ou au premier déménagement. La masse salariale passe alors de 2 300 à 9 200 €.
- **d. Mauvaise catégorie de dépense.** « Rémunération équipe fondatrice » ne contient pas « salaire ». `BalanceManager.expense_factor` lui applique donc le facteur **frais généraux** (0,88 / 1,10) au lieu du facteur **salaires** (0,92 / 1,08). La projection et le débit réel divergent en Accessible et Réaliste (§2.1). `DifficultyScenario` ne teste que la catégorie « Salaires » et masque l'écart.
- **e. Libellé trompeur.** Un salarié embauché pendant le garage est payé à 100 %, mais apparaît sous « Rémunération équipe fondatrice ».
- **f. État non persistant.** Le stade dépend du statut *courant* des produits. Si une fin de commercialisation est ajoutée un jour, les fondateurs repasseront à 25 %.
- **g. Plancher magique** `maxi(400, …)`.

**Correction recommandée :**
- Un drapeau persistant `founding_stage`, clos par une décision du CEO (« verser les vrais salaires ») ou par un seuil de marge brute cumulée.
- Soit une dette de salaires différés remboursée plus tard, soit une contrepartie en parts, ainsi qu'un léger effet sur le moral.
- Une montée progressive des salaires (50 % → 75 % → 100 %) plutôt qu'une marche.
- La catégorie « Salaires — fondateurs », et un test qui compare projection et débit réel **pour les 3 difficultés**.

### I6 — Conseil financier et déménagement : le coût réel est sous-estimé d'un facteur 3 [VÉRIFIÉ]

- **Où :** `ExecutiveManager.workplace_upgrade_recommendation` → `financial_advice(upgrade_cost, delta_loyer)`, et `estimated_structural_monthly_cost`.
- **Mesure :** pour « Atelier + bureaux » au mois 1, le conseil annonce une dépense de **4 400 €/mois**, 5,7 mois de marge, niveau « TENDU ». Après le déménagement, les charges structurelles réelles sont de **12 500 €/mois** (fin du stade fondateur → salaires ×4, plus 1 200 € d'infrastructure). La vraie marge est de ~2 mois, ce qui devrait être « DANGEREUX ».
- **Autres défauts :**
  - Les charges structurelles excluent la sortie de caisse R&D et l'industrialisation en cours.
  - Le texte conseille de « préserver une solution de financement », alors qu'il n'en existe aucune dans le jeu (aucun prêt ni investisseur), malgré `DESIGN_BIBLE.md` §56 (« financements privés »).
- **Impact joueur :** un conseil rassurant sur une décision qui ruine l'entreprise.
- **Correction recommandée :** simuler l'état après la décision (fin du stade fondateur, infrastructure, loyer, engagements en cours) avant de calculer la marge. Retirer la mention de financement tant qu'elle n'existe pas.

### I7 — Les tests de viabilité ne mesurent qu'un chemin heureux ; certaines injections masquent des bugs [VÉRIFIÉ]

**Couverture réelle :**
- `FirstCpuRunwayScenario` et `FullCpuPlayerJourneyScenario` jouent **une seule stratégie** : Standard, design par défaut, intensité 45 k, BALANCE, APPROVE, industrialisation BALANCED, fonderie recommandée, lancement Signature.
- Il n'y a aucun parcours Accessible ou Réaliste, aucune revue payante, aucune recherche, aucun recrutement, aucun déménagement, aucun délai de décision.
- `FullCpuPlayerJourney` vérifie seulement `money > 0`, trivial à cause de B2.
- Le seuil de `FirstCpuRunway` (≥ 30 k€ à l'entrée en industrialisation) ignore le coût de l'industrialisation elle-même.
- Le garde-fou « first_cpu_burn > 9 000 » est lâche (valeur réelle : 4 924).

**Analyse des injections (question 9) :**

| Injection | Trésorerie juste avant (mesurée) | Verdict |
|---|---:|---|
| `smoke_test` bloc Concept : `Economy.money = concept_money_before` | **−48 000** → restaurée à 64 000 | **Masque un bug** : un programme Concept est inabordable au garage (I2). |
| `smoke_test` l.893 industrialisation : `maxi(money, 75000)` | **−15 246** | L'isolation de la mécanique est acceptable, mais l'état du smoke est déjà insolvable et la configuration testée (QUALITY + dernière fonderie, EuroSilicon) ne laisse que **946 €** dans une vraie partie. Aucun test de viabilité ne couvre ce choix. |
| `smoke_test` l.1285 SAV : `maxi(money, 75000)` | 2 800 | Isolation saine : elle ne masque rien de significatif, vu B2. |
| `NextGenerationMarketLearningScenario` : `Economy.money = 3_000_000` | — | **Masque I1** : le test échoue à 100 k€ et à 400 k€. |
| `DifficultyScenario` teste « Salaires » uniquement | — | **Masque I5‑d.** |
| `FirstCpuWorkshopScenario` teste la largeur 700 px | — | Cette largeur n'existe pas en jeu (I8) : fausse assurance. |

**Correction recommandée :**
- Transformer la matrice du §2.3 en scénario CI paramétré : 3 difficultés × 4 briefs × {APPROVE, une correction payante} × {fonderie la moins chère, la plus chère}.
- Attendus : tous les chemins « raisonnables » atteignent le lancement avec une réserve minimale, et le chemin le plus cher échoue de façon lisible.
- Ajouter des bornes post-lancement, un test « décision laissée en attente N mois » et un test « affecter un chercheur au garage ».
- Chaque injection d'argent doit journaliser la trésorerie qu'elle écrase et échouer si elle était négative sans que ce soit l'objet du test.

### I8 — Mobile/paysage : les points de rupture sont du code mort ; les règles UX mobiles ne sont pas appliquées [VÉRIFIÉ / ESTIMÉ]

- **Où :** `project.godot` (`stretch/mode="canvas_items"`, `aspect="expand"`, base 1280×720) ; `main.gd:_update_responsive_layout` ; `FirstCpuWorkshop.set_viewport_width` ; `GarageHub.set_viewport_width` ; `DashboardScreen.set_viewport_width`.
- **Mesure (headless) :** fenêtre 2400×1080 → `main.size` = **1600×720** ; 1080×2400 → 1280×2844 ; 800×600 → 1280×960. La largeur logique ne descend **jamais sous 1 280**. Toutes les branches `< 1000`, `< 900`, `< 760` et `< 620` sont inatteignables.
- **Conséquences :**
  - ✔ Le CTA « Lancer ce CPU » est en tête de la colonne droite dans la mise en page à 2 colonnes : **visible en paysage** [CODE]. Mais c'est un effet de bord. Si une mise en page à une colonne s'activait un jour, le CTA passerait sous toute la colonne gauche.
  - ✘ La règle du doc « Mobile : une colonne principale » n'est jamais appliquée.
  - ✘ Sur un téléphone ~1080 px de haut, le facteur d'échelle est ~1,5. Un texte de 12 px fait ~18 px physiques, et un bouton de 44 px fait ~66 px, soit **~4 mm** sur un écran ~420 ppi. La recommandation Android est de 48 dp ≈ 7,6 mm. Les curseurs font 32 px [ESTIMÉ, à mesurer sur appareil].
  - ✘ Le test `FirstCpuWorkshopScenario` valide une largeur de 700 px qui n'arrive jamais.
- **Correction recommandée :** décider des mises en page selon la taille physique (`DisplayServer.screen_get_dpi()`, `screen_get_scale()`) ou via un facteur d'échelle d'interface (`content_scale_factor`) adapté au DPI ; tester sur un vrai Pixel ; faire vérifier par le test que le CTA reste dans le rectangle visible, à la résolution logique réelle 1600×720.

---

## 5. MOYEN

### M1 — Les approches non internes sont inabordables, donc INTERNAL est obligatoire [VÉRIFIÉ]

- **Où :** `ResearchManager.development_cash_factor` (INTERNAL 0,04 ; PARTNER 0,62 ; toutes les autres 1,0) ; `start_project` ne vérifie que le premier mois.
- **Mesure à 35 k :** INTERNAL 1 652 €/mois ; PARTNER **20 832** + 9 000 de frais d'accès (faillite M4) ; LICENSE **32 900** + 35 000 (faillite M2) ; PURCHASE 28 000 + 22 000 ; SUBCONTRACT 36 400 + 14 000.
- **Incohérence :** `GameData.APPROACHES.INTERNAL.description` dit « développement plus lent et **plus coûteux** », alors qu'il est 12 à 22 fois moins cher en trésorerie.
- **Correction :** facturer les fournisseurs sur un forfait réaliste qui ne dépend pas de l'intensité ; refuser ou avertir au lancement si le coût du programme dépasse la trésorerie ; corriger la description.

### M2 — Le coût de développement ne dépend pas de la technologie [CODE / VÉRIFIÉ]

- `development_monthly_base_cost` ne dépend ni du nœud ni de la complexité. Un CPU en 3 nm coûte le même montant par mois qu'un 10 µm à intensité égale ; seule la durée change. Le `prototype_cost` du planificateur n'est jamais débité.
- L'industrialisation, elle, augmente correctement et de façon monotone : 3 300 €/mois (10 µm, complexité 50) → 26 400 € (3 nm), soit ×8 au maximum ; les frais de mise en production vont jusqu'à ×6. C'est bon sur le principe, mais la courbe est plate face aux revenus de B2.
- **Correction :** ajouter une composante de sortie de caisse liée au nœud et à la complexité (masques, séries de prototypes) ; recalibrer ×8 après la correction de B2.

### M3 — Les estimations montrées au joueur ignorent la moitié du coût réel [VÉRIFIÉ]

- L'atelier affiche un « budget programme ~16–27 k€ » (développement seul, hors équipe et local), alors que le chemin réel jusqu'à la vente coûte **85,5 k€**.
- `CompanyScreen` affiche une « marge structurelle théorique au départ » de **35,7 mois**. Ce chiffre exclut la R&D et, après le lancement, se recalcule avec la masse salariale *courante* malgré le mot « au départ ».
- `V06_PLAYTEST_ECONOMY.md` §6 parle d'« un peu plus de vingt mois de marge ».
- **Correction :** afficher « coût estimé jusqu'au premier lancement » et « réserve estimée au lancement », avec une fourchette.

### M4 — Politiques Marketing/SAV : SAV Premium gratuit, marketing payable sans effet [VÉRIFIÉ]

- `CompanyManager.get_support_modifier` ne dépend que de `support_level`. **PREMIUM avec un budget de 0 donne ×1,18 sur les retours pour 0 €.**
- Le marketing est réglable dès le mois 1 (onglet Entreprise) et débité (mesure : 20 000 €/mois) alors qu'aucun produit n'existe, sans aucun effet.
- Avec un budget SAV à 0 et aucun employé Support, une enquête SAV progresse à ~8 %/mois, soit ~12 mois pour un diagnostic.
- **Correction :** lier le coût au niveau de SAV ; afficher « sans effet avant lancement » ou désactiver le marketing avant l'onglet MARKET ; rendre la vitesse d'enquête lisible.

### M5 — Recrutement mal calibré au garage ; fonctions débloquées mais jamais nécessaires [VÉRIFIÉ / CODE]

- Candidat Production généré à **7 038 €/mois**, soit plus du double des fondateurs, avec une prime d'embauche de 2 mois (14 076 €) et une paie à 100 % → **faillite au mois 8**. `generate_candidate` ne tient compte ni de l'époque ni du stade.
- Après le lancement, `ProductManager.active_departments()` active Production, Marketing et Support, mais sans personne. Aucune mécanique n'exige ces embauches : les trois fondateurs suffisent (B2).
- **Correction :** salaires adaptés à l'époque et au stade, prime réduite au garage ; besoins réels de personnel liés au volume (capacité, SAV, marketing).

### M6 — Aucun levier de redressement [CODE]

- Il n'existe aucune fonction pour annuler ou suspendre un projet, modifier l'intensité en cours, licencier, vendre un actif, emprunter ou faire un apport. Dès qu'un chemin est condamné (B3, I2, I3, M1, M5), le joueur ne peut qu'attendre le game over.
- **Correction :** ajouter au minimum « réduire l'intensité » et « mettre le projet en sommeil », plus un prêt bancaire simple avec intérêt et plafond.

### M7 — Documentation contradictoire sur des points de gameplay

| Document | Affirmation | Réalité code / mesure |
|---|---|---|
| `V06_PLAYTEST_ECONOMY.md` §6 | « un peu plus de vingt mois de marge … pression sans faillite automatique » | 16 mois consomment 85,5 %, Réaliste = faillite automatique (B1) |
| `V06_PLAYTEST_ECONOMY.md` §7 et `UX_ART_DIRECTION.md` §V0.6 | « le temps est mis en pause lorsqu'une décision prototype importante est ouverte » | seulement via le Banc de test (I4) |
| `V06_PLAYTEST_ECONOMY.md` §8 | garde-fou « double comptage salaires + budget R&D interne » | vrai pour le développement uniquement (I2) |
| `V06_PLAYTEST_ECONOMY.md` §8 | « tests fonctionnels … isolés de la trésorerie » | l'injection NextGen de 3 M€ n'est pas mentionnée et masque I1 |
| `DESIGN_BIBLE.md` §56 | « capital et financements privés » | aucun financement dans le code |
| `DESIGN_BIBLE.md` §139 | « plusieurs trajectoires raisonnables » | vrai seulement sans correction payante (B3) |
| `CPU_VERTICAL_SLICE.md` l.11 | les prévisions du conseil d'architecture tiennent compte de la trésorerie | oui, mais avec un coût fantôme (I1) |
| `CPU_VERTICAL_SLICE.md` l.314 | « une gamme trop large coûte en validation, marketing, stock et support » | lancer 3 SKU ne coûte rien (B2) |
| `UX_ART_DIRECTION.md` l.205–215 | `garage_shell.webp` / `garage_stage0-3.webp` par palier, « sans recadrage » | `GarageHub` utilise `garage_hq.svg` pour les 4 paliers, en mode *cover* (recadrage) ; les WebP ne sont pas utilisés |
| `UX_ART_DIRECTION.md` l.196–201, 207 | zones « Tableau de direction », « Poste du fondateur », 3 postes au départ dont le poste du fondateur | code : « Tableau de planification » (R&D) et « Bureau du fondateur », verrouillé jusqu'au mois 1 |
| `UX_ART_DIRECTION.md` §9 | mobile : une colonne, 44–48 px | inatteignable (I8) |

---

## 6. MINEUR

- **m1 — Valeurs héritées ou magiques :**
  - `500_000` dans `CompanyManager.reset`, `EconomyManager` (variable et `load_state`), `BalanceManager.starting_capital` (valeur de repli).
  - `1450000` dans `main._refresh_setup_difficulty` ; « 500 000 € » affiché dans `DashboardScreen` avant la création.
  - Seuils de couleur de la trésorerie 75 k / 175 k : la Standard démarre en ambre, la Réaliste en rouge.
  - Valeurs initiales 6000 / 5000 / 2500 des SpinBox de politique dans `CompanyScreen`.
  - `first_generation_runway_target` défini par difficulté mais **jamais utilisé**.
  - `projected_first_cpu_monthly_burn(45000)`, plancher 400, recherche 12 000.
- **m2 — Catégories de dépense par sous-chaînes.** `BalanceManager.expense_factor` cherche des mots-clés dans des libellés qui contiennent le **nom du CPU saisi par le joueur**. Un CPU nommé « Fab… » ou « Production… » change le facteur appliqué ; « fondatrice » n'est pas reconnu comme salaire. Utiliser une énumération.
- **m3 — Banc de test.** Il met en pause et affiche « le prototype attend votre décision » même quand aucune décision n'existe (phase Concept, par exemple). Il dit aussi « prototype » pour une revue de *validation*.
- **m4 — Texte obsolète.** `NoraGuidePanel` cite « Camille et **Alex** », qui n'existe plus dans l'équipe fondatrice.
- **m5 — `GarageHub` :** les zones cliquables se chevauchent (Tableau/Bureau et Bureau/Stock, agrandies par le minimum de 96×54), d'où des touches ambiguës sur mobile. Le même visuel sert à tous les paliers.
- **m6 — Migration de sauvegarde.** `ExecutiveManager.load_state` active HEALTH et REST en BASIC par défaut si la clé manque : une ancienne sauvegarde paie des avantages au garage.
- **m7 — Libellé de paie.** Les salaires d'employés embauchés sont classés sous « Rémunération équipe fondatrice » (voir I5‑e).
- **m8 — État fondateur.** Il dépend du statut courant des produits, ce qui fera régresser le jeu si une fin de vie est ajoutée (voir I5‑f).
- **m9 — `README.md` :** description de la CI (liste du smoke test) et mention « L'interface V0.2.8 » périmées. **`ROADMAP.md` :** Phase 0 « Importer le projet Godot réel » non cochée, et lot V0.2.6 non coché alors que procédé, rendement, fournisseurs et découvertes sont implémentés.

---

## 7. BON POINT / VALIDÉ

- **CI reproduite :** import sans erreur, boot sans erreur, `[CI] Smoke test passed` sur Godot 4.7.2 officiel.
- **Playtest reproduit exactement :** 2 300 + 500 + 1 652 = 4 452 € ; 95 548 € après le premier mois.
- **Démarrage garage cohérent** avec le récit et protégé par des tests : 3 fondateurs, marketing, SAV, environnement et avantages à 0, local 500 €, infrastructure 0, capitaux 150 / 100 / 70 k€.
- **Double comptage supprimé pour le développement interne :** le facteur 0,04 est appliqué de façon cohérente dans l'estimation, l'engagement du premier mois et le débit mensuel.
- **Estimation de durée fiable :** 12 mois estimés, 12 simulés ; le test tolère ±2.
- **Pas de coût de développement fantôme** pendant une décision en attente : le projet est gelé et ne débite rien de plus que les charges fixes.
- **Support facturé seulement avec une activité client** (`has_customer_operations`).
- **Première industrialisation 10 µm peu chère** (3,3 k€/mois + 3,5 k€ de mise en production) et monotone avec le procédé et la complexité. Le passage en industrialisation exige un choix de route explicite (pas de contournement) et c'est testé.
- **Choix industriels différenciés :** EuroSilicon est plus cher et plus sûr, RapidFab moins cher et plus rapide, QUALITY réduit les dossiers SAV.
- **Les 4 briefs atteignent le lancement en Standard** si aucune correction payante n'est choisie : pas de brief unique obligatoire.
- **Onboarding room-first lisible au premier contact :** seul l'établi est visible, avec un indice ; l'atelier met le temps en pause ; le lancement relance le temps et revient au QG.
- **Faillite gérée proprement :** pause, écran dédié, rechargement possible.
- **Migrations de sauvegarde explicites** (département Développement, profils, politiques).
- **CTA « Lancer ce CPU » visible en paysage** dans la mise en page réellement utilisée (voir la réserve de I8).

---

## 8. Réponses aux 15 questions

1. **Réalisme du scénario garage et des montants.** Le décor, l'équipe et les charges du mois 1 sont crédibles. Le chemin complet n'est pas modélisé côté joueur (M3), et l'après-lancement est irréaliste (B2).
2. **Faillite automatique, softlock, chemin unique.** Oui : Réaliste échoue systématiquement (B1). Standard n'admet qu'une famille de trajectoires sans correction payante (B3), avec des pièges supplémentaires (I2, I3, M1, M5) et aucun levier de redressement (M6). Il y a un risque de blocage « silencieux » par décision invisible (I4).
3. **100 k€ en Standard.** Ce n'est pas trop généreux avant le lancement, c'est même trop serré : 14,5 % de marge sur le meilleur chemin. Après le lancement, le montant n'a plus d'importance (B2). La tension est mal répartie, pas mal dosée globalement.
4. **Rémunération à 25 %.** Défendable dans le récit, mais elle fait ~110 k€ du travail d'équilibrage, sans contrepartie, avec une falaise ×4 et un bug de catégorie (I5).
5. **Séparation intensité / sortie de caisse.** Claire dans l'atelier ; incohérente dans le planificateur, les revues, la recherche, les programmes Concept, la division, le dashboard et le laboratoire avancé (I1, I2).
6. **Coûts selon la technologie.** L'industrialisation augmente correctement ; le développement ne dépend pas du nœud ; le coût prototype n'est jamais débité (M2).
7. **Déblocage Marketing/SAV/Production.** Les onglets s'ouvrent au bon moment. Les politiques sont réglables trop tôt (marketing inutile) et le SAV Premium est gratuit (M4). Les départements ne sont jamais réellement nécessaires (M5).
8. **Les tests mesurent-ils la vraie partie ?** Non : un seul chemin, un seul niveau de difficulté, des bornes lâches (I7).
9. **Injections de trésorerie.** Isolation saine pour le SAV ; acceptable mais incomplète pour l'industrialisation ; **masquante** pour le programme Concept (−48 k€) et pour NextGen (3 M€ → masque I1).
10. **Transitions UX.** Garage → établi → atelier → projet : bon. Projet → revue prototype/validation → industrialisation → vente : chaque étape peut rester en attente sans signal au QG pendant que le temps coûte (I4). Le Banc de test affiche un message faux hors décision (m3).
11. **Mobile/paysage.** CTA visible, mais les points de rupture sont inatteignables et les tailles tactiles probablement sous la norme (I8).
12. **Doubles comptages, coûts fantômes, valeurs magiques, dépendances circulaires.** Double comptage recherche/Concept (I2) ; coût fantôme du planificateur et `prototype_cost` jamais débité (I1) ; valeurs magiques (m1) ; mots-clés de catégorie (m2). **Aucune dépendance circulaire à l'exécution** n'a été trouvée : les appels croisés entre autoloads ne se font qu'à l'appel, dans un ordre de traitement mensuel déterministe.
13. **Cohérence entre les six documents.** Les chiffres (capitaux, playtest) sont cohérents. Les affirmations de gameplay le sont souvent moins (M7).
14. **Documentation obsolète.** `UX_ART_DIRECTION` (assets, zones), `ROADMAP` (cases), `README` (CI, V0.2.8) (M7, m9).
15. **Plusieurs stratégies ou seulement le chemin heureux ?** Seulement le chemin heureux (I7). La matrice du §2.3 est une base directe pour un scénario paramétré.

---

## 9. Ordre de correction conseillé

1. **Modèle de coût « jusqu'au lancement ».** Revues calculées sur la sortie de caisse (B3), une seule fonction de coût partagée par la recherche, les Concepts, le planificateur, la division et les écrans (I1, I2), plafond d'intensité utile (I3), puis recalibrage des trois difficultés sur ce coût complet (B1).
2. **Visibilité des décisions bloquantes** et pause automatique (I4).
3. **Calibrage du marché post-lancement** et coût réel de la capacité et des SKU (B2).
4. **Refonte du stade fondateur** (I5) et du conseil financier (I6), leviers de redressement (M6).
5. **CI :** matrice de parcours par difficulté avec des bornes ; suppression des injections masquantes (I7).
6. **Mobile :** mise à l'échelle selon le DPI et test sur appareil (I8).
7. **Documentation** alignée sur l'état réel (M7, m9).

---

## 10. Conclusion sur la viabilité réelle d'une partie V0.6

La V0.6 est **stable et cohérente sur ses premiers mois**. Le démarrage « garage 1971 » raconte enfin la bonne histoire, les chiffres du playtest sont exacts, la CI est verte et aucun crash ni blocage technique n'a été rencontré sur ~45 parties simulées.

En revanche, **la viabilité d'une vraie partie n'est pas encore établie** :

- en **Réaliste**, la partie mène mécaniquement à la faillite avant la première vente ;
- en **Standard**, elle n'est jouable que si le joueur ne paie jamais pour la qualité, n'affecte pas de chercheur, ne recrute pas, ne dépasse pas ~60 k d'intensité et repère sans aide chaque décision bloquante sur un QG qui ne l'affiche pas ;
- en **Accessible**, le premier lancement arrive confortablement ;
- dans **tous** les cas, dès la première vente, l'économie cesse d'opposer la moindre résistance.

Les tests actuels confirment l'unique chemin qui fonctionne. Ils ne peuvent donc pas signaler ces problèmes, et deux d'entre eux les masquent.

Pour considérer la V0.6 comme validée côté économie, il faut en priorité corriger B1–B3 et I1–I4, puis faire tourner en CI une matrice de stratégies par difficulté avec des attendus bornés, avant et après le lancement.

---

### Annexe — Reproduire les mesures

Les sondes utilisées (non versionnées, bac à sable uniquement) :

- rejouent `SimulationManager.reset_all`, `ResearchManager.start_project` / `resolve_project_decision`, `ProductionManager.set_strategy` / `set_manufacturing_route` et `ProductManager.launch_product` mois par mois via `SimulationManager.process_month_end()` ;
- relancent `NextGenerationMarketLearningScenario` en remplaçant 3 000 000 par 100 000 et 400 000 ;
- ajoutent au smoke test un `print` de `Economy.money` avant chaque injection ;
- instancient `main.tscn` et forcent `get_tree().root.size` (2400×1080, 1080×2400, 1280×720, 800×600) pour lire `main.size`.

Commande : `godot --headless --path . res://probe/<sonde>.tscn`.