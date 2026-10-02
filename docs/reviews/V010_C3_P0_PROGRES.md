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

## Bug trouvé en chemin : une nouvelle partie gardait les marchés de la précédente

`MarketManager.reset()` recalculait la liste des marchés connus **en lisant l'ancienne liste**. Après une partie menée
jusqu'en 2030, « Nouvelle partie » ouvrait donc tous les marchés dès 1971 (datacenters, mobiles…). Dans la sonde,
chaque carrière (sauf la toute première) héritait de la précédente : c'est ce qui produisait les **dizaines de millions
de 1980-1983** (marché Datacenter en 1980, historiquement 2002). Le constat P1 de Codex (« l'argent ne contraint plus
dès 1979 ») venait surtout de là.

- Correctif : la liste est vidée avant d'être recalculée.
- **Migration des sauvegardes** : au chargement, les marchés qui ne peuvent pas encore exister
  (plus de 7 ans avant leur date historique) sont retirés. Un produit lancé sur un tel marché ne s'y vendra plus.
- Test : `tests/scenarios/NewGameResetScenario.gd` (dans le smoke test).

## Mesure propre (même sonde, mêmes 6 graines, 1971 → 2030, correctif de réinitialisation appliqué)

« Avant » = jeu d'origine (`592510a`) + seul correctif de réinitialisation ; « après » = P0 + correctif.

| Mode | | FIGÉE | ADAPTÉE | EN RETARD | ADAPTÉE bat EN RETARD |
|---|---|---:|---:|---:|---:|
| STANDARD | avant | 6,6 M€ | 1 485,6 M€ | 1 851,5 M€ | 0 / 6 |
| STANDARD | **après** | 1,4 M€ | **534,8 M€** | 86,7 M€ | **6 / 6** |
| ACCESSIBLE | avant | 11,7 M€ | 2 002,8 M€ | 2 423,3 M€ | 0 / 6 |
| ACCESSIBLE | **après** | 6,1 M€ | **872,3 M€** | 200,3 M€ | **6 / 6** |

Marge cumulée moyenne en 2030. Le défaut P0 était bien réel (avant : EN RETARD gagne 6/6 même sans la fuite).
Après : suivre les conseils rapporte **6 fois plus** (Standard) et **4 fois plus** (Accessible) que rester en arrière.
36 / 36 carrières vont jusqu'en 2030, sans blocage, faillite ni erreur.

Trésorerie moyenne d'ADAPTÉE (Standard) : **3,5 M€ en 1980, 26 M€ en 1990, 41 M€ en 2000, 122 M€ en 2010, 535 M€ en 2030**.
Le seuil de 100 M€ est franchi en **2009-2010** en Standard (avant correctifs : 1983) et entre **2002 et 2007** en Accessible.
EN RETARD ne l'atteint jamais en Standard. Dans les années 1990, EN RETARD a un peu plus de trésorerie qu'ADAPTÉE
(36 contre 26 M€ en 1990) : le progrès coûte d'abord, puis rapporte. L'argent redevient un vrai arbitrage pendant
les trente premières années.

## Ce qui reste

- **P2 — le rang mondial** : les stratégies finissent 5e ou 6e, jamais n° 1, même avec 500 M€ de marge cumulée.
  C'est le prochain chantier (comment le rang est calculé, et ce qui permet de devenir n° 1).
- Années sans décision après 1985 : environ 1 sur 5 pour ADAPTÉE (57 / 276) — à surveiller, plus prioritaire.
- Constats n° 2 (Robuste), n° 3 (fréquence sans enveloppe) et n° 5 (piste Fiabilité) : non traités.

## Tests

`tests/scenarios/TechnologyLagScenario.gd` (dans le smoke test) : tolérance d'un cran, malus et plafonds,
bonus d'avance borné, axes d'architecture, facteur de ventes réservé au joueur, malus réellement appliqué aux notes
finales d'un projet (à hasard identique), propositions Audacieux / Équilibré / Prudent et cohérence de la conception
retargetée. Import, `--quit-after 2`, smoke, garage, atelier et plafonds d'équilibrage : OK.

Reproduction : `godot --headless --path . res://tests/tools/career_probe.tscn -- 104729,208877,313133,417401,521657,625919 STANDARD`
(puis `ACCESSIBLE`).
