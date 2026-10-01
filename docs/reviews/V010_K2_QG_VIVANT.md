# V0.10 / K2 — Le QG vit

Objectif de la feuille de route : sur une partie de 10 ans, le QG montre au moins 5 changements visibles.

## Ce qui s'ajoute au décor (`ui/GarageLife.gd`, dessiné sous les cartes du QG)

- **L'étagère murale**, en haut au centre. Elle apparaît avec le premier CPU vendu.
  - Une puce par génération sortie (les puces d'Astra, selon la finesse de gravure), 5 au plus, les plus récentes.
  - Une coupe dorée par trophée de carrière (Premier silicium, Le million, Maître du silicium…).
  - Un magazine encadré par « Une » de la presse (moyenne des notes ≥ 78), avec « ×N » au-delà.
  - Toucher l'étagère ouvre le détail : vos CPU, vos trophées, vos Unes, l'équipe, l'événement du moment et la saison. Le détail se referme seul au bout de 8 secondes.
- **Les saisons**, selon le mois du jeu :
  - hiver : neige, lumière un peu plus froide, et une **guirlande qui clignote en décembre** ;
  - printemps : pétales roses ;
  - été : poussière dorée qui monte ;
  - automne : feuilles qui tombent, lumière orangée.
- **La pancarte d'événement**, sous l'étagère : le salon mondial de l'année, ou une menace du marché avec sa durée (guerre des prix, récession, pénurie de silicium…), ou un grand événement de marché (boom sectoriel, nouvelle norme…).
- Déjà en place avant K2 : le décor qui change avec les locaux (K1) et l'équipe qui grandit à l'écran (J2).
- Les repères du QG évitent l'étagère, comme ils évitent déjà les cartes.

## Sauvegarde

`MediaManager.front_pages` compte les Unes et il est sauvegardé. Une ancienne partie commence à 0.

## Mesure (banc 10 ans `profiles_probe`, hors saisons)

| Profil | Changements visibles au QG | Détail |
|---|---|---|
| Novice | 15 | vitrine 5, trophée 1, Unes 7, événements 2 |
| Intermédiaire | 23 | + équipe 3, déménagements 2 |
| Expert | 32 | Unes 19 |

L'objectif de 5 changements visibles est atteint pour les trois profils, et les saisons s'ajoutent tous les 3 mois.

## Tests

- `GarageLifeScenario` (smoke) vérifie :
  - les 4 saisons, et la guirlande seulement en décembre ;
  - la vitrine limitée à 5 puces ;
  - les Unes affichées et sauvegardées, et une ancienne sauvegarde qui commence à 0 ;
  - la pancarte d'une guerre des prix ;
  - la signature de scène.
- smoke, garage_layout, workshop_layout et balance_ceiling : OK.
- Captures dans `K2_captures/` : hiver avec la guirlande, printemps, automne, détail de la vitrine.

## J5 — Les saisons du garage dessinées par Astra (01/10)

- Astra a livré `decor_0_garage_hiver`, `_printemps` et `_automne` (1774 × 887 px, environ 240 Ko chacun, dans `assets/art/v010/J5_saisons/`).
- **Contrôle d'alignement** : contours de l'original comparés à chaque retouche, avec le meilleur décalage cherché de −6 à +6 pixels. Résultat : **(0, 0) pour les trois saisons**. L'équipe et les repères restent posés au bon endroit.
- **Dans le jeu** :
  - le décor suit le mois : décembre à février l'hiver, mars à mai le printemps, septembre à novembre l'automne, et l'été garde le décor de base ;
  - le passage d'une saison à l'autre se fait en **fondu de 1,6 s** ;
  - les effets en code (neige, pétales, feuilles, guirlande de décembre) restent par-dessus pour le mouvement ;
  - les locaux dont les saisons ne sont pas encore livrées gardent leur décor de base.
- Test ajouté à `GarageLifeScenario`. Capture des 4 saisons dans le jeu : `K2_captures/garage_4_saisons_astra.jpg`.

## J6 — Les fêtes, prêtes à recevoir les objets d'Astra

- **Calendrier** :
  - Noël : décembre ;
  - Nouvel An : janvier ;
  - anniversaire de l'entreprise : janvier, à partir de la 2e année ;
  - Halloween : à partir du 15 octobre ;
  - Pâques : avril ;
  - vacances d'été : juillet et août.
- **Les objets** (`assets/art/v010/J6_fetes/*.png`) apparaissent dans le décor dès qu'ils sont livrés. Sans fichier, rien n'est dessiné. Leur position (pied de l'objet, devant l'entrée ou au pied des murs) sera réglée à la livraison sur le Pixel.
- **La guirlande d'Astra**, une fois livrée, remplace celle dessinée en code.
- **Le détail de la vitrine** dit « C'est Noël ! », « C'est Nouvel An et l'anniversaire de l'entreprise ! »…
- **Test** : calendrier des fêtes dans `GarageLifeScenario`.
