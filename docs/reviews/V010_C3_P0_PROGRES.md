# V0.10 — C3 / P0 : le progrès technique paie enfin (02/10)

Suite directe de la mesure de Codex (`docs/reviews/V010_C3_MESURE.md`, branche `v010/C3-mesure`, fusionnée) :
rester toute la partie en **10 µm + 4 bits** battait la stratégie qui suit les conseils **6 graines sur 6**,
dans les deux modes. Constats n° 1 et n° 4 de la fiche d'impact (`V010_FICHE_IMPACT.md`).

## Cause (vérifiée avant de toucher au jeu)

1. **Deux échelles de notes.** Les CPU du joueur étaient notés par rapport à *leur* procédé
   (fréquence, cœurs, cache comparés à la référence du procédé), les rivaux par rapport à l'état de l'art.
   Relevé graine 104729 : en 2030, un CPU 10 µm / 4 bits notait **83** en performance, les rivaux en 5 nm **65 à 71**.
2. **L'équipe avançait d'un seul cran par génération.** Dès 2000 la recherche permettait le 3 nm,
   mais le plan de génération proposait encore du 1,5 µm en 2005 (et la prudence restait sur place).
3. **Les ventes plafonnaient** (capacité, part de marché maximale) : à volume égal, la puce la moins chère gagnait.

## Ce qui change

- **`scripts/TechnologyLag.gd` (nouveau, pur)** : un CPU se juge face à l'état de l'art.
  - Procédé : on compare au plus fin procédé utilisé par un rival (à défaut, celui que l'époque permet).
    Un cran de retard toléré ; ensuite −3 performance, −4 innovation, −1,5 efficacité par cran.
    En avance : +1,5 performance, +3 innovation par cran (3 crans maximum).
  - Architecture : l'écart avec la plus récente coûte une part des axes du catalogue
    (Vitesse → performance ×0,40, Énergie → efficacité ×0,35, Fiabilité ×0,25) et −2,5 innovation par génération.
    **Les axes Vitesse / Énergie / Fiabilité des cartes d'architecture comptent enfin** (constat n° 1).
  - Plafonds : performance et innovation −40, efficacité −20, fiabilité −10.
  - Ventes : −10 % de demande par cran de procédé au-delà de la tolérance, −6 % par génération d'architecture
    au-delà de la précédente, plancher 15 %. Calculé **au moment de la vente** : un CPU vieillit commercialement
    quand les rivaux passent à la gravure suivante.
- **Notes finales** (`ResearchManager._calculate_final_metrics`) : malus / bonus appliqués aux CPU, mémorisés dans
  `project.technology_lag` (clé facultative, aucune migration de sauvegarde nécessaire).
- **Ventes** (`MarketManager.estimate_consumer_demand`) : nouveau facteur `technology_multiplier`,
  affiché dans « Pourquoi ces ventes » sous le nom **« Technologie dépassée »**.
- **Plans de génération** (`CpuGenerationPlanner`) : *Audacieux* vise le procédé le plus fin disponible,
  *Équilibré* un cran en dessous (procédé éprouvé), *Prudent* rattrape à deux crans quand il est très en retard.
  La conception suit le procédé (fréquence, cœurs, cache à l'échelle du nouveau procédé, enveloppe suffisante).
- **Ce que voit le joueur** : la fiche d'impact et les jauges de l'écran « Nouveau processeur » incluent ce retard,
  la proposition de l'équipe l'écrit en clair (« Face à l'état de l'art : gravure en retard de 4 générations
  (Perf −9, Innovation −12, ventes −30 %) »), et la fiche d'impact de la recherche montre désormais
  `Perf ▲ · Innovation ▲▲` pour une gravure plus fine.

## Mesure après correction (même sonde, mêmes 6 graines, 1971 → 2030)

| Mode | FIGÉE | ADAPTÉE | EN RETARD | ADAPTÉE bat EN RETARD |
|---|---:|---:|---:|---:|
| STANDARD — avant (eff0871, Codex) | 6,8 M€ | 2 181,5 M€ | 2 365,2 M€ | 0 / 6 |
| **STANDARD — après** | 1,8 M€ | **1 003,5 M€** | 532,3 M€ | **6 / 6** |
| ACCESSIBLE — avant (eff0871, Codex) | 11,9 M€ | 2 609,1 M€ | 3 161,8 M€ | 0 / 6 |
| **ACCESSIBLE — après** | 6,4 M€ | **1 617,5 M€** | 803,9 M€ | **6 / 6** |

Marge cumulée moyenne 2030. Suivre les conseils rapporte désormais **≈ 1,9 à 2 fois** plus que rester en arrière,
et ADAPTÉE bat FIGÉE 6/6. 36 / 36 carrières vont jusqu'en 2030, sans blocage, faillite ni erreur.
Trajectoire ADAPTÉE (104729 STANDARD) : 1 µm en 1988, 350 nm en 1992, 90 nm en 2000, 7 nm en 2008
(avant : 350 nm en 2030).

## Ce qui reste (P1, P2 du rapport de Codex)

- **P1 — l'argent ne contraint plus rien** : la trésorerie dépasse encore 100 M€ dès **1983** (STANDARD) et **1981**
  (ACCESSIBLE), 6/6 graines. La correction P0 a divisé les gains par deux mais n'a pas déplacé ce moment.
  Origine visible dans les relevés : 1979-1982, la demande dépasse de loin la capacité (des dizaines de milliers
  d'unités perdues par an) et chaque puce produite est vendue.
- **P2 — le rang mondial** : les stratégies finissent encore 4e à 6e malgré des marges élevées.
- Constats n° 2 (Robuste), n° 3 (fréquence sans enveloppe) et n° 5 (piste Fiabilité) : non traités.

## Tests

`tests/scenarios/TechnologyLagScenario.gd` (dans le smoke test) : tolérance d'un cran, malus et plafonds,
bonus d'avance borné, axes d'architecture, facteur de ventes réservé au joueur, malus réellement appliqué aux notes
finales d'un projet (à hasard identique), propositions Audacieux / Équilibré / Prudent et cohérence de la conception
retargetée. Import, `--quit-after 2`, smoke, garage, atelier et plafonds d'équilibrage : OK.

Reproduction : `godot --headless --path . res://tests/tools/career_probe.tscn -- 104729,208877,313133,417401,521657,625919 STANDARD`
(puis `ACCESSIBLE`).
