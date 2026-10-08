# Audit du rendu, des textures et des appels de rendu — 08/10/2026

Base : `v013/demo-octobre` (`546586d`). Mesures faites dans le cloud :

- partie jouée automatiquement pendant 7 ans, fenêtre de 1600×720 (le format d'un Pixel en paysage) ;
- pilote `opengl3`, le même pipeline que la cible Android ;
- moniteurs `Performance.RENDER_*` pour les appels de rendu et la mémoire.

Ce rendu se fait sur un processeur graphique logiciel. Le nombre d'appels de rendu et la mémoire des textures sont fiables ; le temps d'image ne l'est pas et devra être mesuré sur le Pixel.

## Nature du rendu

Tech Empire est une interface 2D : `Control`, `StyleBoxFlat`, `TextureRect`, quelques `_draw()` dessinés à la main.

Plusieurs points des audits 3D ne s'appliquent donc pas :
- pas de lumière dynamique, d'ombre portée 3D ni de shader personnalisé (aucun `.gdshader`) ;
- pas de niveaux de détail (LOD) ni de masquage par occlusion (*occlusion culling*) ;
- l'instanciation 3D (*instancing*) n'a pas d'équivalent ici.

Le coût vient du **remplissage** (des surfaces empilées les unes sur les autres) et du **nombre d'appels de rendu**, pas de la complexité des shaders.

| Réglage | Valeur actuelle | Commentaire |
|---|---|---|
| Android | `gl_compatibility` (OpenGL ES 3.0) | **Bon choix** pour la 2D : compatible partout, économe. Vulkan (rendu *Mobile*) n'apporterait rien ici. |
| PC | Pas de réglage, donc **Forward+** (Vulkan / D3D12) | Pipeline 3D lourd pour de la 2D : démarrage plus long, plus de mémoire vidéo, et un rendu qui peut différer légèrement du Pixel. |
| Cadence d'images | Non limitée (synchronisation verticale par défaut) | L'interface est redessinée à 60, 120 ou 144 images/s même quand rien ne bouge. |
| Compression des textures | `compress/mode=1` (*Lossy*) pour les 125 images importées | Léger sur le disque (WebP), mais **décompressé en RGBA8 en mémoire vidéo**. Le réglage ETC2/ASTC du projet ne sert donc à rien aujourd'hui. |
| Mipmaps | Aucune | Correct pour de l'interface affichée à peu près à sa taille, mais les grands décors (1774×887) réduits dans des bandeaux crénèlent un peu. |

## Mesures

| Écran | Appels de rendu | Objets dessinés | Surface dessinée (recouvrement) | Ombres `StyleBoxFlat` | Mémoire textures |
|---|---|---|---|---|---|
| Menu | 206 | 349 | — | — | 52,6 Mo |
| QG | **368** | 1 702 | **10,0× l'écran** | 10 | 62,0 Mo |
| Entreprise | 332 | 1 848 | 7,0× | 3 | 63,4 Mo |
| Équipe | 302 | 1 800 | 6,6× | 3 | 69,5 Mo |
| Labo | 341 | 2 027 | 7,2× | 10 | 69,7 Mo |
| Produits | 287 | 1 697 | 6,8× | 3 | 69,7 Mo |
| Marché | 310 | 2 082 | 6,7× | 3 | 69,7 Mo |
| Presse | 300 | 1 638 | 7,2× | 9 | **71,0 Mo** |

La mémoire des textures ne fait qu'augmenter d'un onglet à l'autre : les images chargées restent en mémoire (cache des ressources).

## Constats, par gravité

| # | Gravité | Constat | Cible |
|---|---|---|---|
| 1 | **Élevée** | **Recouvrement de 7 à 10× l'écran.** Fond, cartes, bandeaux de scène, panneaux et décor saisonnier se superposent. Sur un GPU mobile, c'est le remplissage qui coûte le plus. | ≤ 3× |
| 2 | **Élevée** | **300 à 370 appels de rendu par image.** Chaque panneau a un style différent (couleur, arrondi, bordure), ce qui empêche de les regrouper ; les textes et les icônes alternent avec les panneaux. | ≤ 150 sur mobile |
| 3 | **Élevée** | **Textures non compressées en mémoire vidéo : 71 Mo.** Chaque décor de 1774×887 coûte 6,3 Mo. C'est encore acceptable sur 6 Go de RAM, mais trop pour un téléphone de 3 Go qui fait tourner d'autres applications. | ≤ 30 Mo |
| 4 | Moyenne | Le PC utilise Forward+, alors que le Pixel et tous les tests utilisent OpenGL. | Un seul pipeline |
| 5 | Moyenne | L'interface est redessinée à chaque image même quand rien ne change, et sans plafond de cadence (lié à C2 : mode basse consommation). | 30 ou 60 images/s sur mobile, 60 sur PC par défaut |
| 6 | Faible | 12 `StyleBoxFlat` ont une ombre (`shadow_size`) : géométrie supplémentaire et flou approché à chaque image. | Ombres pré-dessinées dans une texture 9-patch, ou supprimées sur mobile |
| 7 | Faible | Les décors réduits sans mipmaps crénèlent légèrement. | Mipmaps pour les décors seulement |

## Budget proposé

| Type d'image | Android (ETC2/ASTC importés) | PC (S3TC/BPTC) | Pourquoi |
|---|---|---|---|
| Décors, moments clés, bandeaux (grandes images peintes) | **VRAM compressé** : ASTC 4×4 (8 bits/pixel) ou ETC2 en secours, mipmaps activées, taille limitée à 2048 px | BC7 | 4 fois moins de mémoire ; les artefacts sont invisibles sur une peinture |
| Portraits et personnages | ASTC 4×4, sans mipmaps | BC7 | Contours fins : vérifier à l'œil |
| Icônes, puces, logos, pictogrammes à aplats nets | **Lossless** (RGBA8), sans compression | Lossless | Petites images : la compression abîmerait les bords nets pour un gain négligeable |
| Sources (`_sources/`) | Exclues (`.gdignore` déjà en place) | — | — |

Budget global : **30 Mo** de textures chargées sur mobile ; une seule saison de décor chargée à la fois.

Avec ce budget, les 35 Mo de RGBA8 des images importées passent à environ 10 à 12 Mo pour les décors et les portraits.

## À vérifier sur le Pixel

- Le temps d'image réel au QG et dans l'onglet le plus chargé, avec le profileur Godot en débogage à distance.
- Le rendu des décors et des portraits après compression ASTC : Alexandre juge à l'œil, avec des captures avant/après.
- La batterie : chauffe et consommation sur 15 minutes, avant et après le plafond de cadence et le mode basse consommation.
