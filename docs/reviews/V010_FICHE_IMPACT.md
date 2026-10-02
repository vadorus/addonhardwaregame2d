# V0.10 — Fiche d'impact (02/10)

## Le besoin

Retour joueur du 02/10 : comprendre vite, avec très peu d'information et sans surcharger l'écran,
**ce que touche chaque choix, ce qu'il améliore, ce qu'il dégrade, ce qu'il coûte et combien de temps il prend**.
PC Tycoon 2 est trop simple (des points de puissance, ni chaleur ni stabilité) ; Hardware Tycoon est
riche mais jargonneux. Notre réponse : des pastilles « avant → après » posées là où l'on clique.

## Ce qui change à l'écran (Nouveau processeur)

| Où | Ce qui s'affiche |
|---|---|
| Cartes d'objectif (Économique, Performant, Robuste…) | Ce que donnerait ce choix par rapport au choix actuel : `Perf ▲▲ · Chaleur ▲ · Fiabilité ▼▼ · +3 € / unité` |
| Chaque réglage (cœurs, fréquence, cache, gravure, enveloppe, effort mensuel) | Ce que fera **chaque flèche** avant de cliquer : `▶ Chaleur ▲ · Fiabilité ▼ · +1 € / unité` / `◀ Perf ▼ · …` ; « limite atteinte » quand la flèche ne peut plus rien changer |
| Cartes d'architecture | « Si vous la choisissez : … » (usure, première puce, tick / tock compris) |
| Jauges du bas | Après chaque clic, la jauge glisse de l'ancienne à la nouvelle valeur et affiche l'écart en couleur : `Performance 76 (+1)`, `31 € / unité (+1)` |

Lecture : **vert = ce que vous gagnez, rouge = ce que ça coûte**. 1 à 3 flèches selon l'ampleur
(1, 4, 9 points ; chaleur : 3 %, 15 %, 40 %). Un écart négligeable n'apparaît pas.
Quand la performance ne suit pas, la fiche dit pourquoi : **« Enveloppe trop juste »** (la puce est bridée)
ou **« Plus bridée »**.

Captures (téléphone en paysage, 1212 × 540) : `V010_FICHE_IMPACT/IMPACT_objectif.png`,
`IMPACT_reglages.png`, `IMPACT_architecture.png`.

## Règle de fidélité

La fiche n'invente rien : elle applique le choix à une copie, mesure avec les vraies formules
(`CpuDesign.evaluate`, `ResearchManager.estimate_cpu_development`, coût mensuel, ajustements
d'architecture `ArchitectureManager.metric_adjustments`), puis remet tout en place.
L'objectif choisi pousse son critère au développement (`start_project` : cible = max(valeur, 65) + 8) ;
la fiche en tient compte avec son poids réel dans la note finale (0,41 à l'échelle de la conception).

Le test `tests/scenarios/ImpactPreviewScenario.gd` vérifie que **ce qui est annoncé = ce qui arrive** :
chaque flèche de chaque réglage (12 cas), chaque objectif, chaque architecture possédée, et les jauges
du bas après un clic ; que l'aperçu ne modifie pas la conception ; que le résultat est déterministe.

## Fichiers

- `scripts/ImpactPreview.gd` (nouveau) : calcul pur des pastilles (`snapshot`, `chips`, `text`, `balance`, `focus_bonus`).
- `ui/components/CpuDesignStepper.gd` : `impact_snapshot`, `preview_setting/profile/architecture`, `_impact_flow`,
  cartes d'objectif cliquables en entier, réglages refactorés (`_step_setting` pur + `_shift_*`), jauges animées.
- `tests/scenarios/ImpactPreviewScenario.gd` (nouveau), branché dans `tests/smoke_test.gd`.
- `tests/tools/capture_impact.gd/.tscn` : outil de capture (pas un test CI).
- Lot recherche : `scripts/ResearchImpact.gd` (nouveau), `ui/components/ImpactChips.gd` (nouveau, rangée de pastilles partagée),
  `ui/components/ResearchTreePanel.gd`, `scripts/ResearchManager.gd` (fonctions partagées), `scripts/ResearchTree.gd` (texte),
  `tests/scenarios/ResearchImpactScenario.gd` (nouveau).

Aucune formule de jeu n'a changé ; aucune donnée de sauvegarde nouvelle (pas de migration nécessaire).

## Ce que la fiche a révélé (à trancher, pas corrigé ici)

1. **Les barres « Vitesse / Énergie / Fiabilité » des architectures ne changent pas la puce.** Elles ne sont lues
   par aucune formule : une architecture change seulement les limites (cœurs, cache, fréquence max), l'usure,
   la première puce et le tick / tock. Résultat honnête de la fiche : « 16 bits → sans effet notable ».
   Il faut soit brancher ces axes dans le calcul, soit les retirer des cartes. À décider avec la mesure C3.
2. **« Robuste » ne rend pas la conception plus fiable** : son profil baisse la fréquence et élargit l'enveloppe,
   ce qui n'améliore la fiabilité que si la puce était poussée au-delà de la référence. Sa fiabilité vient
   surtout de l'objectif de développement (désormais affiché). Une vraie marge (ex. fréquence sous la référence
   = fiabilité +) rendrait le choix plus lisible.
3. **Monter la fréquence sans élargir l'enveloppe ne rapporte presque rien** (la puce se bride) : la fiche
   l'annonce maintenant (« Chaleur ▲ · Fiabilité ▼ » sans « Perf ▲ »). C'est fidèle au modèle, et c'est
   justement l'arbitrage chaleur / stabilité qui manque à PC Tycoon.

## Deuxième lot : la recherche (Labo > Recherche)

Toucher un palier de l'arbre affiche maintenant, sous « Débloque » :

- **Pour votre prochain CPU (procédé, équilibré) :** les mêmes pastilles, calculées sur le CPU « Équilibré »
  que l'équipe proposerait avec votre meilleure gravure et votre architecture la plus récente.
  Exemple 1971 : `→ 8 µm : Chaleur ▲ · Fiabilité ▼ · Innovation ▲ · +4 € / unité`.
- **Pour y arriver :** `1 programme Concept · ~4 mois · ~2 400 €` ou `~4 mois avec 1 chercheur sur la piste · ~480 € / mois`.
  Le chemin rejoue les vraies formules mensuelles (avancement Concept, gain de connaissance, frein « état de l'art »),
  avec les réglages par défaut du Labo (15 000 € / mois, ambition normale).

Pour que l'aperçu et la simulation ne divergent jamais, les calculs mensuels ont été sortis en fonctions partagées
dans `ResearchManager` (`concept_month_progress`, `concept_nominal_gain`, `research_month_gain`,
`research_budget_factor`) — mêmes formules, résultat identique (tous les tests passent).
Le test `ResearchImpactScenario` lance un vrai programme Concept et vérifie qu'il dure **exactement** le nombre
de mois annoncé ; il fait travailler un vrai chercheur et vérifie l'annonce à un mois près
(la formation des équipes de recherche bouge un peu le rythme).

Captures : `IMPACT_recherche.png` (gravure), `IMPACT_recherche_piste.png` (piste Fiabilité).

4. **Graver plus fin ne rend pas votre CPU meilleur dans le modèle actuel.** Les notes du joueur sont relatives au
   procédé (fréquence, cœurs et cache comparés à la référence du procédé) : passer de 10 µm à 8 µm donne
   +0,5 performance et +1,4 innovation, mais plus de chaleur (puissance de base plus forte), moins de fiabilité
   (procédé moins mûr) et un coût unitaire plus élevé. Rien ne pénalise un joueur qui resterait sur un vieux procédé
   (les rivaux, eux, sont notés par rapport à l'état de l'art de l'époque). **C'est probablement le constat le plus
   important pour l'équilibrage C3** : la mesure FIGÉE / ADAPTÉE de Codex doit dire si rester en arrière est rentable.
   J'ai seulement retiré du texte « Débloque » la promesse « moins de consommation par calcul », que le jeu ne tenait pas.
5. **Les paliers de connaissance « Fiabilité & stabilité » rendent les estimations plus sûres, pas les CPU plus fiables.**
   Cette piste ne fait monter aucune maîtrise ; son effet passe par la confiance et les propositions de génération.
   La fiche affiche donc honnêtement « Confiance ▲ ». Si l'on veut tenir la promesse du texte, il faut brancher la piste
   sur la fiabilité (proposition pour C3).

## Prochaines étapes proposées

- Même langage de pastilles pour l'**équipe** (recruter un développeur, un validateur : délai, finition, salaire).
- Validation humaine pendant la bêta C4 : un novice doit pouvoir dire, sans aide, quelle flèche rend la puce plus froide.
