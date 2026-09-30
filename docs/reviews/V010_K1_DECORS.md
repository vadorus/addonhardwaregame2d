# V0.10 — K1 : décors par palier de locaux (graphismes de ChatGPT)

Date : 30/09/2026 — branche `v010/K1-decors` (depuis `feature/ui-v09-navigation`).

## Ce qui est livré

- **J1 — 4 décors vides, un par palier** (`assets/art/v010/J1_decors/`, WebP 1774×887, 380–510 Ko) :

  | Palier (ExecutiveManager) | Décor |
  |---|---|
  | 0 Garage aménagé | `decor_0_garage.webp` (garage avec la voiture) |
  | 1 Atelier + bureaux | `decor_1_atelier.webp` |
  | 2 Siège technique | `decor_2_siege.webp` (bureau vitré du fondateur) |
  | 3 Campus R&D | `decor_3_campus.webp` (salle blanche) |

- **Moment « déménagement »** : quand on monte de palier en cours de partie, le QG s'assombrit, le
  nouveau décor apparaît, l'équipe saute de joie et une carte dit ce qui change (place pour l'équipe,
  production maximale ou « sans limite » au campus, loyer). Si le déménagement est décidé depuis
  Entreprise, le moment est gardé pour le retour au QG. Pas de moment au chargement d'une partie.
- **Repères du QG par décor** : les 5 zones (établi, banc de test, tableau, bureau du fondateur, stock)
  sont posées sur les meubles de chaque décor (`ui/WorkplaceArt.gd`, `ZONE_SPOTS`).
- **J2 — l'équipe dessinée par ChatGPT** : 12 personnes × 4 poses (`J2_personnages/perso_NN_pose.png`).
  Au poste = pose « bureau » (le poste de travail est dans l'image), Nora debout = « réflexion »,
  lancement d'un CPU ou déménagement = « joie », trésorerie négative = « inquiet ».
  5 postes au garage, 6 à l'atelier et au siège, 8 au campus ; les gens sont plus petits dans les
  grands locaux, à l'échelle du décor. Chaque salarié garde le même visage.
- **J4 — icônes** : les 7 icônes du dock, le cadenas et les 5 icônes de zones remplacent les dessins
  vectoriels (`GarageBadge.gd`, repli vectoriel si une image manque).
- Planches d'origine gardées dans `assets/art/v010/_sources/` (ignorées par Godot, pas dans l'APK).

## Tests

- `tests/scenarios/GarageScenario.gd` : un décor 2:1 par palier, l'équipe suit le palier, au moins
  autant de postes quand les locaux grandissent, repères à l'écran, moment déménagement joué
  seulement lors d'un vrai déménagement, textes de la carte (16 personnes, 1 200 puces, « sans limite »),
  icônes J4 et 48 images J2 présentes.
- smoke, garage, workshop, balance_ceiling : verts (Godot 4.7.2 headless).

## À vérifier sur le Pixel

- Lisibilité des icônes du dock sur le fond ambre de l'onglet sélectionné.
- Position des personnages près du bord bas (cartes Nora / Actu).
- Les planches contiennent trois variantes de la même jeune femme (1, 5, 9) : on utilise d'abord
  les visages distincts ; à signaler à ChatGPT pour une prochaine planche.
