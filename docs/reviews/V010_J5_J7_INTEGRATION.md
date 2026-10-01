# V0.10 — Intégration du lot graphique 3 d'Astra (J5, J6, J7)

Livraison d'Astra du 01/10/2026 (brief : `docs/BRIEF_ASTRA_LOT3_SAISONS_FETES.md`), intégrée le 01/10 au soir.
Les 24 fichiers ont été vérifiés contre les empreintes SHA-256 des LISEZMOI : toutes identiques.

## Ce qui change à l'écran

- **J5, saisons** : l'atelier, le siège et le campus ont leur hiver, leur printemps et leur automne
  (`assets/art/v010/J5_saisons/`). Rien à coder : `WorkplaceArt.seasonal_art_path` les prend dès qu'ils existent.
- **J6, fêtes** : sapin et guirlande à Noël, ballons et table au Nouvel An, gâteau à l'anniversaire de
  l'entreprise, citrouilles et toile à Halloween, panier à Pâques, ventilateur l'été.
  - Sur téléphone, le décor 2:1 est rogné en haut et en bas : chaque objet est maintenant **gardé entier
    à l'écran** et **se décale sur le côté s'il cache Nora, quelqu'un de l'équipe ou un autre objet**
    (`GarageLife._fit_prop`).
  - La guirlande court tout le long du haut de l'écran (plusieurs guirlandes côte à côte, 30 à 60 px de haut).
  - La toile pend en haut, à gauche de la carte de projet (elle était prévue dans le coin gauche, caché par
    le titre du local).
- **J7, vitrine** : l'étagère, les coupes, les Unes encadrées et la pancarte dessinées en code sont
  remplacées par les images d'Astra. L'étagère et la pancarte s'allongent par le milieu seulement : les
  équerres et les ficelles gardent leurs proportions. **Coupe en or** pour les grands trophées (prestige
  ≥ 1,2 : fonderie, marchés stratégiques, numéro un mondial, empire), **en argent** pour les autres.
  Sans les fichiers, le dessin en code revient tout seul.

## Vérifications

- Smoke test complet : OK. `GarageLifeScenario` vérifie en plus que chaque objet de fête et chaque pièce de
  la vitrine se charge, et que l'étagère utilise bien l'image d'Astra.
- Captures à la taille logique du Pixel en paysage (1212 × 540), sur la partie d'Alexandre (Nova Technologies) :
  `J5_J7_captures/` — Noël à l'atelier, Nouvel An et anniversaire au garage, Halloween au siège,
  Pâques au campus, été à l'atelier. Outil : `tests/tools/capture_qg.tscn` (ne sauvegarde rien).

## À regarder sur le Pixel

- La taille des objets de fête au doigt (sapin et ballons sont les plus grands).
- Les notifications « Presse » et « Décision requise » passent par-dessus la vitrine tant qu'elles sont
  affichées : c'était déjà le cas avant ce lot.

## Hors jeu : import des images

`*.import` n'est pas suivi par git : chaque PC garde ses propres réglages d'import. Le PC de la maison
avait encore les réglages d'avant I7 (sans perte) pour 94 images, d'où un APK de 69,6 Mo au lieu de
41,6 Mo. Ses `.import` ont été alignés sur `[importer_defaults]` (avec perte, qualité 0,82) sans changer
les identifiants (`uid`) : les fichiers importés passent de 38,5 à 16,8 Mo.
