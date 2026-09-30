# Brief graphismes V0.10 pour Astra (lots J1 à J4)

Rédigé le 30/09/2026 par Claude pour Alexandre. Référence : `docs/ROADMAP_V010.md`, `docs/UX_ART_DIRECTION.md`.
Astra ne touche **aucun fichier de code** (`.gd`, `.tscn`) : elle livre des images, Claude les intègre (lot K1).

## 1. Ce qui existe aujourd'hui

- Un seul décor : `assets/ui/garage_reference_v09.png`, **1774 × 887 px (format 2:1)**, 2,5 Mo, vue isométrique en coupe,
  lumière chaude. Il sert pour **tous** les paliers de locaux (le joueur ne voit jamais son entreprise changer).
- Les personnages sont **peints dans l'image** : l'équipe ne peut donc ni grandir ni réagir à l'écran.
- 5 repères cliquables posés en pourcentage de l'image (x, y du coin haut-gauche, largeur, hauteur) :

| Repère | Rôle | Position actuelle |
|---|---|---|
| Établi CPU | concevoir un processeur | x 0,24 • y 0,28 |
| Tableau de planification | R&D, pistes, équipe | x 0,61 • y 0,33 |
| Bureau du fondateur | direction de l'entreprise | x 0,39 • y 0,51 |
| Banc de test | prototype et validation | x 0,60 • y 0,54 |
| Stock & production | industrialisation | x 0,84 • y 0,60 |

## 2. Règles communes à toutes les images

**Style**
- Même famille que le garage actuel : isométrique en coupe, même angle de caméra, même hauteur de vue, lumière chaude,
  palette bois / crème / ambre (repères : bois `#3b2b1e`, ambre `#d9822b`, crème `#f6e3c6`). Ambiance chaleureuse, jamais froide.
- **Fidèle à l'époque** de chaque palier (voir tableau), sans marques ni logos réels (pas d'Intel, IBM, Apple…), sans copier
  Game Dev Tycoon ni PC Tycoon.
- **Aucun texte dans les images** (le jeu sera traduit). Les écrans, tableaux et affiches restent illisibles ou symboliques.

**Format**
- Décors : **2048 × 1024 px (2:1)**, PNG pour le fichier maître, plus un export **WebP qualité 85** pour le jeu
  (objectif **moins de 1,5 Mo** par décor : l'APK doit rester léger).
- Sprites et objets : PNG **fond transparent**.
- Icônes : **SVG** de préférence (sinon PNG 256 × 256 transparent).

**Zones cachées par l'interface** (ne rien y mettre d'important, juste du décor)
- en haut à gauche : 0 à 28 % de la largeur, 0 à 18 % de la hauteur (titre du lieu) ;
- colonne de droite : 73 à 100 % de la largeur, toute la hauteur (cartes projet et actus) ;
- en bas à gauche : 0 à 30 % de la largeur, 68 à 100 % de la hauteur (carte de Nora).
- **Zone utile** : le centre, entre 28 % et 73 % de la largeur.

**Les 5 repères doivent exister dans chaque décor** (établi, tableau, bureau du fondateur, banc de test, stock).
Pour chaque décor, Astra donne leurs **nouvelles positions** (x, y en pourcentage) dans un petit fichier texte,
car ils changeront de place d'un local à l'autre. Le repère « Stock & production » peut rester dans la colonne de droite (il est petit).

**Livraison**
- Dossier `assets/art/v010/<lot>/` (ex. `assets/art/v010/J1_decors/`), un `LISEZMOI.txt` par lot (positions des repères,
  remarques). Noms en minuscules sans accents : `decor_1_atelier.png`, `decor_1_atelier.webp`…
- Soit Astra les pousse sur une branche `v010/J1-decors` (sans toucher au code), soit Alexandre dépose le dossier et Claude le commite.

## 3. J1 — Décors par palier (priorité 1)

**Les décors sont livrés VIDES de personnages** : postes de travail inoccupés, chaises, écrans allumés.
C'est ce qui permettra au jeu d'afficher l'équipe réelle (J2) et de la faire grandir.

| Ordre | Palier | Époque | Ce qu'on doit voir | Postes visibles |
|---|---|---|---|---|
| 0 | Garage (refaire la version vide du décor actuel) | 1971-1974 | porte de garage, établi, oscilloscopes, fer à souder, voiture partiellement visible, cartons | 3 |
| 1 | Atelier | 1974-1978 | petit local loué, 2 établis, rangements, premier terminal, stock qui grossit | 6 |
| 2 | Petit bureau / labo | 1978-1985 | bureau vitré du fondateur, labo séparé, premiers ordinateurs personnels, tableau blanc | 12 |
| 3 | PME | 1985-1995 | open space, salle de réunion, coin salle blanche aperçue par une vitre, écrans cathodiques | 25 |
| 4 | Siège | 1995-2002 | hall d'entrée, plusieurs étages en coupe, écrans plats, trophées | 40 |
| 5 | Campus R&D | 2002-2008 | bâtiments reliés, laboratoire moderne, serveurs | 60 |
| 6 | Grand groupe | 2008-2010 | tour, salle du conseil, vue sur la ville | 80 |
| 7 | Empire | après 2010 | siège iconique, parvis, écrans géants | 100+ |

**Commencer par 0 à 3** (ce sont ceux qu'un joueur voit dans ses premières heures). 4 à 7 ensuite.
Critère : sur le Pixel en paysage, chaque décor se lit d'un coup d'œil, les 5 repères sont visibles hors des zones cachées,
et on sent tout de suite qu'on a changé de local.

## 4. J2 — Personnages (priorité 2)

Sprites séparés, fond transparent, **même angle que les décors**, hauteur d'un personnage assis ≈ **200 px** sur un décor de 2048 px.
- **8 personnages de base** variés (âges, genres, origines), chacun en 4 poses :
  assis au travail (tape sur le clavier), réfléchit (main au menton), content (bras levés, pour un lancement), inquiet (pour une crise).
- **Les 3 cofondateurs de la partie** reconnaissables : Camille Durand (R&D), Samira Lefèvre (développement), Noah Leroy (validation).
- **Nora Bernard** (bras droit du joueur) : même style.
- **Portraits** en buste 512 × 512 pour les fenêtres de dialogue (Nora, les 3 cofondateurs, un journaliste, un client),
  pour remplacer les portraits actuels.
- Option plus tard : vêtements qui changent selon la décennie (années 70, 80, 90, 2000).

## 5. J3 — Les moments forts mis en scène (priorité 3)

Illustrations **1024 × 640**, fond transparent ou sur carte crème, pour les fenêtres qui s'ouvrent à ces moments :
1. **Premier silicium** : la puce sur le banc de test en 3 images : éteinte ; allumée avec une petite lumière (réussite) ;
   petite fumée / étincelle (bug trouvé).
2. **Tri des puces** : une galette de silicium au centre et 4 bacs : entrée de gamme, cœur de gamme, haut de gamme, rebut.
   Claude animera les puces qui tombent dans les bacs selon les vrais pourcentages.
3. **Jour de sortie** : le produit en boîte sur un présentoir, confettis discrets.
4. **Triomphe de la presse** : pile de magazines / journal avec une étoile (sans texte lisible).
5. **Déménagement** (pour K1) : des cartons et une camionnette devant le nouveau local.

## 6. J4 — Icônes (priorité 4)

Style plat, trait arrondi de 2 px, couleurs crème et ambre, lisibles à 28 px sur le téléphone.
- **Barre du bas** : QG, Labo (puce), Équipe, Produits (boîte), Marché (graphique), Presse (journal), Entreprise (immeuble), cadenas.
- **Repères du décor** : puce, fiole de laboratoire, graphique, écran, boîte.
- Remplaceront les icônes dessinées au trait dans le code (`GarageBadge.gd`).

## 7. Ordre de travail et ce que fait Claude en face

1. Astra : décors 0 à 3 (J1) → Claude les branche sur les paliers avec un moment « déménagement » (K1).
2. Astra : 8 personnages + cofondateurs + Nora (J2) → Claude place l'équipe réelle à ses postes (K2).
3. Astra : moments forts (J3) → Claude les anime dans les fenêtres existantes.
4. Astra : icônes (J4), puis décors 4 à 7.

À chaque livraison : Claude intègre, vérifie au doigt sur le Pixel, fait une capture, et renvoie à Astra ce qui est à ajuster
(repère caché, objet peu lisible, poids du fichier).
