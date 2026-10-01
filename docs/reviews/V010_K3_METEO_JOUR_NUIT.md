# V0.10 / K3 — Météo et jour / nuit au QG

Idée d'Alexandre (01/10) : « un temps alternatif, pour avoir l'impression que le temps passe : la pluie, la nuit… »

## Ce qui change (`ui/GarageLife.gd`)

- **Une météo par mois**, tirée selon la saison. Elle est toujours la même pour un mois donné, et varie d'un mois à l'autre.

  | Saison | Météos possibles |
  |---|---|
  | Hiver | neige (40 %), nuageux, beau temps, brouillard |
  | Printemps | beau temps (45 %), pluie, nuageux |
  | Été | beau temps (60 %), orage, nuageux, pluie |
  | Automne | pluie (35 %), nuageux, brouillard, beau temps |

  Effets :
  - la **pluie** tombe dehors (au-dessus des murs et sur le trottoir, pas au milieu des bureaux), avec une lumière grise ;
  - l'**orage** ajoute des éclairs de temps en temps ;
  - la **neige** est plus forte un jour de neige ;
  - le **brouillard** voile le bas du décor ;
  - un temps **nuageux** rend la lumière plus terne.
- **La journée avance** avec le jeu : un tour complet en 2 minutes à vitesse ×1, plus vite en accéléré, arrêté en pause. On passe par le **matin** (lumière rosée), la **journée**, le **soir** (orangé) et la **nuit** (bleu sombre, les lampes du décor s'allument avec des halos chauds).
- Le détail de la vitrine affiche « Saison : printemps • pluie • soir ».
- **Rien ne change le jeu** : c'est de l'ambiance.

## Préparé pour les images d'Astra (J8)

Le brief d'Astra demande maintenant 8 retouches : nuit et pluie pour les 4 décors.
- Dès qu'un fichier `decor_X_…_nuit.webp` ou `…_pluie.webp` existe dans `assets/art/v010/J8_ambiances/`, le QG passe dessus en fondu quand il fait nuit ou quand il pleut.
- Le voile sombre en code s'efface alors presque entièrement.
- Sans ces fichiers, le QG garde son décor de saison et les effets en code.

## Tests

`GarageLifeScenario` vérifie :
- sur 10 ans : météo stable pour un mois donné, jamais de pluie en hiver ni de neige ou de brouillard l'été, au moins 5 sortes de temps ;
- le passage du jour (« journée ») à la nuit ;
- le décor de saison gardé tant que les images de nuit n'existent pas.

smoke et garage_layout : OK. Captures dans `K2_captures/meteo_*`.
