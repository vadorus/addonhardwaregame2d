# Plan priorisé de développement de Tech Empire — 10 octobre 2026

**État : PROPOSITION DE PILOTAGE / AUD-001**, basée sur `v013/demo-octobre` au commit `c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f`.  
**Ne remplace pas en silence** le [plan de phase 1 figé le 08/10](PLAN_CODEX_2026-10-08.md). Réconcilier chaque lot déjà fusionné avant de commencer : P0, C3, C2, R1, A1, T2, T3 et les C4 ciblés ont des traces d'intégration / de validation partielles.  
**Source d'audit :** [AUDIT_MULTIDISCIPLINAIRE_2026-10-10.md](AUDIT_MULTIDISCIPLINAIRE_2026-10-10.md).  
**Périmètre immédiat :** démo CPU Android + sauvegardes intactes ; Software déjà présent mais boucle distincte à améliorer **sans ouvrir de nouveaux secteurs**.

## Mise à jour de preuve QA-00 — 10/10

[Résultats de tests réellement exécutés](reviews/RETOUR_2026-10-10_QA00.md) au commit `c1d4f6e` : **12 commandes Godot sorties 0**, avertissement UID à froid non reproduit au re-import, **fuites moteur au test tactile**, budget second CPU/parcours CPU et Software PASS. La sonde `104729` confirme une **forte instabilité d'équilibrage** selon le mode (STANDARD ADAPTEE faillite février 1973, ACCESSIBLE ADAPTEE 225 M€ fin de sonde). La presse donne **9 textes distincts sur 100 articles homogènes**. Une capture QG PC est valide ; les autres onglets sont encore à revoir.

**Arbitrage recommandé après preuve :** avancer `CAREER-01` et `BUD-01` à côté de `PLAY-00`, puis traiter `NAR-00` et `NAR-01` avant toute expansion. **Ne pas modifier les valeurs économiques avant la sonde multi-graines.**

## Règles de priorisation

- **P0 — Bloquant :** corruption/effacement de partie, crash, mauvais comportement d'un bouton payant/critique, progression impossible, calcul économique faux démontré, tests de base cassés.
- **P1 — Qualité de la démo :** nouveau joueur ne comprend pas, attente passive, manque de conséquences ou faillite injuste, interface illisible.
- **P2 — Différenciation / finition :** contenu narratif varié, dynamisme visuel, audio contextuel, confort, performance résiduelle *mesurée*.
- **P3 — Industrialisation produit :** outils d'édition de contenu, découplage progressif, tests longues carrières, publication et système d'accès aux extensions.
- **P4 — Après cœur validé :** nouvelles divisions commerciales, grands DLC et Steam.

**Effort indicatif** : XS ≈ 0,5–1 j, S ≈ 1–3 j, M ≈ 3–6 j, L ≈ 1–2 semaines, XL = chantier à découper. Ce ne sont pas des délais promis ni des durées validées : recalibrer après diagnostic.

## Inventaire exécutable — phase 0, conserver la base et mesurer

| ID | Priorité / effort | But et fichiers candidats | Dépendance | Critère de sortie / preuve |
| --- | --- | --- | --- | --- |
| QA-00 | **P0 / S** | Relever HEAD/CI Git, import, boot, smoke, scénarios ciblés T2/T3, budget du 2e CPU. `tests/`, `project.godot` | Aucune | Rapport au HEAD : commandes, PASS/FAIL, avertissements, aucune écriture partie personnelle |
| SAVE-01 | **P0 / S–M** | Tester sauvegarde courante, 3 slots, .tmp/.bak, migration version 34, retour arrière. `SaveManager.gd`, `SaveCodec.gd` | QA-00 | Deux anciennes sauvegardes **anonymisées / copiées** chargent sans altérer origine ; checksum de l'original constant |
| PERF-00 | **P1 conditionnel / M** | Rejouer P0 et produire captures/CSV par onglet + première ouverture séparée. `PerfProbe.gd`, `reviews/` | QA-00, SAVE-01, Pixel disponible | 12 fins de mois × 3 écrans, 21 transitions, mêmes données et conditions, problème localisé ou absence de problème constatée |
| VIS-00 | **P1 / M** | Audit visuel comparatif des 7 onglets, sous-onglets et 2 états de carrière. `ui/screens/`, `ui/components/` | QA-00, partie test | Matrice d'ergonomie avec captures du **HEAD** et priorités écran par écran |
| PLAY-00 | **P1 / M** | Jouer le début et une carrière avancée à la main ; instrumenter temps de lecture, attente, décisions. `tests/scenarios/`, `docs/design/NOVICE_15_MIN_PLAYTEST.md` | QA-00 | Chronologie 30 min + 1 sauvegarde avancée : causes de confusion et d'ennui réelles, pas supposées |

**Garde :** QA-00 / SAVE-01 sont toujours prioritaires si un bug S0 apparaît. PERF-00 n'autorise aucune optimisation spéculative.

## Phase 1 — rendre la démo CPU convaincante

| ID | Priorité / effort | Objectif et périmètre | Dépendance | Acceptation et tests |
| --- | --- | --- | --- | --- |
| FTUE-01 / ancien M6 | **P1 / M** | Premier jour J en moins de 10 min lors d'un essai joueur novice, intentions et prochaines actions explicites (`main.gd`, `DashboardScreen.gd`, `NoraGuidePanel.gd`) | PLAY-00, VIS-00 | 3 essais novices observés ; ≥ 2/3 terminent sans instruction extérieure ; temps médian ≤ 10 min |
| UX-01 | **P1 / M–L** | Une action principale et une conséquence compréhensible sur chaque écran. Priorité par gêne observée (Entreprise/Labo/Presse si confirmé). `ui/screens/` et `SceneHeader.gd` | VIS-00 | Pour chaque écran : capture avant/après, contrôle au doigt, aucune régression du scrolling/T2/T3, test disposition |
| CPU-01 / ancien G7 | **P1 / L** | Décisions de développement **vécues** : phase, conseil personnage, coût/risque/performance, suivi garage, répercussion sur prochain jalon. Réutiliser `ProjectDirectiveCatalog.gd`, `ResearchManager.gd`, `ProjectCockpitModel.gd` | PLAY-00, SAVE-01 | 2 chemins CPU contrastés avec mêmes graines montrent différence mesurable (coût, temps, risque et/ou performances) ; joueur voit d'où vient l'écart |
| BUD-01 / ancien G1 | **P1 / M** | Anticiper embauche/R&D/industrialisation et expliquer impossible de lancer un deuxième CPU même avec trésorerie élevée. `EconomyManager.gd`, `DevelopmentEstimator.gd`, `ResearchManager.gd` | PLAY-00, QA-00 | Tests de solvabilité + affichage autonomie après action ; aucun message « budget insuffisant » sans cause et montant indiqués |
| CAREER-01 / ancien G3 | **P1 / M** | Garde-fous déterministes de carrière en CI sur deux difficultés + graines figées. `tests/tools/career_probe.tscn` | QA-00 | Rapport comparatif reproductible (liquidité, durée, rang, rentabilité, choix), sans modifier les seuils pour faire passer la CI |
| CAREER-02 / anciens G4–G6 | **P1 / L** | Ajuster difficultés / progression / concurrence seulement après CAREER-01 ; faire comprendre déclin et objectif de leadership CPU réalisable. | CAREER-01, CPU-01 | 4 graines par difficulté, aucune dégradation inexpliquée du début, sommet CPU atteignable par au moins une stratégie crédible, risque durable de régression observable |
| CPU-02 | **P1 / M** | Garage = état compact des projets actifs CPU + Software, décision en attente, progrès, prochain risque, clic contextuel. `DashboardScreen.gd`, `ProjectCard.gd` | CPU-01, VIS-00 | Toutes les activités en cours apparaissent sur reprise de sauvegarde ; zéro action importante cachée ; mise à jour après décision |

**À ne pas faire :** multiplier les événements décoratifs pour masquer une boucle vide ; rendre le jeu « facile » pour cacher une prévision de trésorerie incorrecte ; refactor géant avant la validation CPU.

## Phase 2 — renouvellement de l'expérience et identité visuelle

| ID | Priorité / effort | Objectif et fichiers candidats | Dépendance | Critère / test |
| --- | --- | --- | --- | --- |
| NAR-00 | **P1 / S–M** | Mesurer répétitions, contradictions et diversité de presse / employés / messages. `MediaManager.gd`, `MarketVoices.gd`, `PersonnelScreen.gd`, `Interactions.gd` | QA-00 | Corpus de 100 événements × plusieurs états, duplications classées et erreurs factuelles identifiées |
| NAR-01 | **P2 / L** | Narration procédurale **hors ligne** avec faits typés, choix d'angle, personnalité, rotation d'expressions, historique récent. Pas de génération LLM nécessaire. | NAR-00, SAVE-01 | 0 contradiction sur corpus connu ; article publié persiste identique après save/load ; pas de modification des scores/simulation ; diversité mesurée et relue |
| NAR-02 | **P2 / M** | Dialogues Nora/Camille/Noah et autres employés avec contexte, émotions cohérentes et conséquences exactes, sans fausse causalité. | NAR-01, CPU-01 | Même fait expliqué par voix distinctes ; jamais de promesse non tenue ; test des valeurs avant/après |
| EVENT-01 | **P2 / M–L** | Événements à conséquences : opportunités, pannes, retards, clients, conflits RH, réactions concurrentielles — varier selon l'état du jeu, non selon hasard gratuit. | CPU-01, CAREER-01 | 5 situations distinctes reproductibles ; choix alternatifs mesurés, sauvegarde compatible, fréquence non excessive |
| ART-01 | **P1/P2 / L découpé par onglet** | Design system commun, pictogrammes, tableaux de bord illustrés, animations de feedback, cartes de décisions. Réorganiser écran par écran, pas tout d'un coup. | VIS-00, UX-01 | 7 fiches de validation ; captures avant/après à état constant ; contraste et lecture au doigt ; coût rafraîchissement stable |
| ART-02 / anciens G2+A2 | **P2 / M** | Jour J et succès : révélation visuelle/sonore proportionnée, animation réduite respectée. `ReviewRevealPanel.gd`, `SoundManager.gd` | CPU-01, ART-01 | Comparaison avec/sans animation, conséquence toujours accessible en texte ; pas de saut de FPS significatif mesuré |
| SOFTWARE-01 | **P2 / M–L** | Approfondir la boucle Software existante sans ouvrir d'autre secteur ; décisions et correctifs qui affectent réellement client / qualité / trésorerie. `SoftwareManager.gd`, `SoftwarePlayCatalog.gd` | CPU-01, CAREER-01 | Parcours court complet : développement, lancement, retours, mise à jour ; résultats reproductibles, gestion garage compréhensible |
| AUDIO-01 | **P2 / S–M** | Valider niveau sonore réel Android puis tension / succès / décennies manquantes seulement si bénéfice perceptible. `SoundManager.gd` | ART-02 | Tests mute, volume persistant, limiteur, écoute Pixel sans saturation |

## Phase 3 — qualité technique et futur commercial

| ID | Priorité / effort | Objectif | Dépendance | Acceptation |
| --- | --- | --- | --- | --- |
| PERF-01 | **P1/P2 si seuil dépassé / M** | Optimiser uniquement écran/fonction pointé par PERF-00, préserver C4, re-tester. | PERF-00 | Même scénario/HEAD avant-après, gain mesuré, 0 fuite/régression visible |
| TECH-01 | **P2/P3 / L découpé** | Diminuer couplage UI↔managers et taille `main.gd` en extrayant 1 responsabilité à la fois derrière interface / signaux testables. | SAVE-01, QA-00 | Diff limité, mêmes sauvegardes, même chronologie déterministe, tests de rafraîchissement passants |
| TECH-02 | **P3 / M** | Catalogue de faits/événements de domaine et contrats de données pour futurs secteurs, pas un nouveau manager par fonctionnalité. | TECH-01, NAR-01 | Nouveau type d'événement testé sans modification du calcul économique ni de l'UI existante |
| QA-01 | **P2/P3 / M** | Réviser les 4 anciens tests défaillants hors CI ; tester fuites de nœuds, formats 1280/1600, perte de focus T3. | QA-00 | Liste de tests validés/écartés et justification ; CI ne masque pas un FAIL |
| ACCESS-01 | **P2 / M** | Clavier/manette/Steam Deck, gros textes, réduction d'animations et sons, traduction si cible internationale. | UX-01, ART-01 | Navigation sans souris et sans tactile sur écrans de base, pas de focus piégé |
| MON-00 | **P3 / S–M** | Décider découpage gratuit/version complète/DLC, prix, cosmétiques et plateforme avec le propriétaire. Document existant **proposition**. | CPU-01, CAREER-02 | Décisions explicites dans `docs/DECISIONS.md` |
| MON-01 | **P3 / M** | Maquette « Extensions et avenir » honnête, contenus à venir et statut, pas de vente de fonctionnalités absentes. | MON-00, ART-01 | Maquette Android + UX claire ; aucune prétendue propriété d'un DLC non acheté |
| MON-02 | **P3 / L** | Droits d'accès/achat, restauration, hors ligne et confidentialité sur Android puis Steam ; ne pas stocker le droit seul dans une sauvegarde de partie. | MON-00, TECH-02, validations boutique à date | Tests FakeStore puis vraie sandbox de la plateforme ; absence de perte de progression ; détails politiques vérifiés le jour de l'intégration |
| RELEASE-01 | **P3 / L** | Préparation Play Store : propriété intellectuelle, politique de confidentialité, tests fermés, crash/ANR, tailles, fiche et captures honnêtes, pipeline reproductible. | QA-00, FTUE-01, SAVE-01, UX-01 | Checklist de sortie signée, APK/AAB testé, aucun avis/texte trompeur, pas de publication sans accord |
| FUTURE-01 | **P4 / XL** | Après cœur CPU validé : gameplay des nouvelles branches, synergies, délégation à échelle empire ; DLC conçus comme contenu réellement nouveau. | CPU-01, TECH-02, MON-00 | Spécification et tests inter-branches, compatibilité anciennes sauvegardes ; aucun lancement anticipé |

## Ordre réel des cinq prochains lots proposés

1. **QA-00 / SAVE-01 :** relance du socle, inventaire des défauts, sauvegarde test isolée. Premier lot strictement sans nouveau gameplay.
2. **PLAY-00 + VIS-00 :** audit humain et captures des sept onglets ; établir une carte visuelle des manques et du temps d'attente.
3. **FTUE-01 + BUD-01 :** lever les obstacles du début de partie et expliquer clairement les coûts.
4. **CPU-01 + CPU-02 :** rendre le développement vivant et le garage informatif, avec deux parcours opposés testés.
5. **NAR-00 puis NAR-01 :** mesurer puis corriger la répétition, sans IA réseau. En parallèle **CAREER-01** peut être développé en lot isolé.

**CAREER-02 et refonte ART-01** suivent les mesures ; **PERF-01** n'est déclenché que par un point chaud reproduit.

## Mesures transversales de sortie « démo convaincante »

- **Technique :** import + lancement + smoke + tests affectés passent au commit exact ; sauvegarde originale inchangée ; les erreurs de sortie sont signalées, pas cachées.
- **Compréhension :** 3 joueurs novices, ≥2 parviennent au premier jour J sans assistance, médiane ≤10 min (objectif, non résultat acquis).
- **Contrôle :** les choix CPU de 2 parcours opposés entraînent des écarts chiffrés et compréhensibles, sans modifier secrètement le marché.
- **Économie :** stratégie jouable sur un horizon intermédiaire, rang CPU explicable, absence de faux message de budget ; sondes graines fixes et difficultés comparables.
- **Lisibilité :** les 7 onglets révisés au doigt à leur état déverrouillé ; aucune action masquée et retour visible.
- **Variété :** tester 100 textes contextuels, diversifiés et sans contradiction ; ne pas imposer un objectif arbitraire de « zéro ressemblance » au détriment du français naturel.
- **Performance :** comparer mêmes CSV/sauvegardes sur Pixel ; distinguer écran froid / fin de mois / GPU ; aucun seuil chiffré revendiqué comme PASS sans nouvelle mesure.
- **Commercial :** déclarer honnêtement CPU jouable, Software selon couverture vérifiée et autres branches futures.

## Protocole Git à appliquer à chaque lot

1. `git fetch`, identifier HEAD cible, branche propre spécifique, **pas de modification de `TechEmpire-dev` ni de la partie personnelle**.
2. Un problème et un résultat attendus ; mentionner avant de coder les impacts croisés (finances, sauvegarde, UI, tactile).
3. Commit par changement cohérent, sans mélanger architecture / équilibre / graphismes ; test déterministe pour chaque mécanique.
4. Reporter commandes réellement exécutées, sorties, captures et risques dans `docs/reviews/RETOUR_AAAA-MM-JJ_<LOT>.md` ; tenir [JOURNAL_DEVELOPPEMENT.md](JOURNAL_DEVELOPPEMENT.md).
5. Push sur branche de travail autorisée, PR **brouillon** tant que la revue et le feu vert de fusion n'ont pas été donnés.
6. À son retour, Claude lit les PR/diffs, **revérifie au HEAD**, corrige en commits supplémentaires plutôt que réécrire l'historique. Pas de publication boutique sans décision explicite.

## Ce qui reste à confirmer humainement

Les comparaisons graphiques exactes aux références, la fluidité ressentie à 20 Hz, le ressenti de la narration, la durée des parties réelles, le degré de difficulté et le produit monétisé. **Aucun choix de prix ni extension jouable n'est acté par ce plan.**
