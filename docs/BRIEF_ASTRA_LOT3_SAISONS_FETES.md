# Brief graphismes — lot 3 pour Astra : saisons, fêtes, vitrine

Rédigé le 01/10/2026 par Claude pour Alexandre. Suite du `BRIEF_ASTRA_GRAPHISMES_V010.md` (mêmes règles de style).
**Astra ne touche à aucun fichier de code.** Elle livre des images, et Claude les intègre.

## Pourquoi ce lot

Le QG change déjà avec les saisons et les événements (lot K2), mais seulement avec des effets dessinés en code : neige, pétales, feuilles, une guirlande, une étagère et des coupes simples. Alexandre veut **plus de décors qui varient** : les saisons et les fêtes du moment.

Ce lot remplace ces effets par de vraies illustrations. Plus tard, une partie de ce travail pourra servir de modèle à des **thèmes cosmétiques payants** (jamais d'avantage en jeu). Ce lot-ci est **gratuit dans le jeu**.

## Règles communes (rappel + nouveautés)

- Même style que les décors actuels : isométrique en coupe, même angle de caméra, lumière chaude, palette bois / crème / ambre (`#3b2b1e`, `#d9822b`, `#f6e3c6`).
- **Aucun texte lisible**, aucune marque, aucun logo.
- Objets : **PNG à fond transparent**, détourage propre (pas de halo blanc), **même angle que les décors** (vue de trois quarts, plongée d'environ 30°).
- Noms en minuscules sans accents. Un `LISEZMOI.txt` par dossier, avec tes remarques.
- Livraison : un zip par dossier, déposé par Alexandre. Ou bien une branche `v010/J5-saisons` qui ne contient **que** les images.

---

## J5 — Les 4 décors en hiver, printemps et automne (priorité 1) : 12 retouches

**Le plus important : c'est une RETOUCHE, pas une nouvelle image.**
Pars de chaque décor existant (fichiers ci-dessous) et garde **exactement** :
- le même cadrage ;
- les mêmes meubles, aux mêmes places ;
- les mêmes murs, fenêtres et portes ;
- la même perspective.

L'équipe et les repères du jeu sont posés au pixel près sur ces décors.

> Contrôle de Claude : il superpose l'original et la retouche. Si un bureau, une chaise, une fenêtre ou un mur a bougé de plus de quelques pixels, l'image est refusée.

| Décor | Fichier de départ dans le dépôt | Grand format (si tu l'as gardé) |
|---|---|---|
| 0 Garage | `assets/art/v010/J1_decors/decor_0_garage.webp` | `assets/art/v010/_sources/decors_garage.png` |
| 1 Atelier | `assets/art/v010/J1_decors/decor_1_atelier.webp` | `assets/art/v010/_sources/decors_atelier.png` |
| 2 Siège | `assets/art/v010/J1_decors/decor_2_siege.webp` | `assets/art/v010/_sources/decors_siege.png` |
| 3 Campus | `assets/art/v010/J1_decors/decor_3_campus.webp` | `assets/art/v010/_sources/decors_campus.png` |

**Format de sortie** : exactement **1774 × 887 px**, même taille que le fichier de départ. WebP qualité 85, moins de 1,5 Mo. Les noms :
- `decor_0_garage_hiver.webp`, `decor_0_garage_printemps.webp`, `decor_0_garage_automne.webp` ;
- même chose pour `decor_1_atelier_…`, `decor_2_siege_…` et `decor_3_campus_…`.

L'été reste le décor actuel.

### Ce qui change selon la saison

Surtout **dehors et aux fenêtres**. Dedans, seulement 1 ou 2 petits détails, posés sur des surfaces libres.

**Hiver** : texte à utiliser tel quel pour chaque décor :
> Retouche cette image sans rien déplacer : même cadrage, mêmes meubles aux mêmes places. Version hiver : neige épaisse sur le sol extérieur, sur les toits et sur les branches ; arbres sans feuilles, givrés ; lumière extérieure froide et bleutée, mais intérieur toujours chaud et éclairé par les lampes ; un peu de givre dans les coins des vitres ; une écharpe et un manteau sur un portemanteau ou un dossier de chaise. Aucun personnage, aucun texte.

**Printemps** :
> Retouche cette image sans rien déplacer : même cadrage, mêmes meubles aux mêmes places. Version printemps : arbres extérieurs en fleurs (rose pâle et blanc), herbe vert tendre, lumière douce du matin ; quelques pétales au sol près de l'entrée ; un petit pot de fleurs sur un bureau libre. Aucun personnage, aucun texte.

**Automne** :
> Retouche cette image sans rien déplacer : même cadrage, mêmes meubles aux mêmes places. Version automne : feuillage orange, rouge et brun, tas de feuilles mortes dehors et quelques feuilles près de l'entrée ; lumière dorée de fin d'après-midi, rasante ; une tasse fumante et un plaid sur un fauteuil. Aucun personnage, aucun texte.

**Ordre** : garage (3 saisons) d'abord. Claude l'intègre et le vérifie sur le Pixel, puis tu fais l'atelier, le siège et le campus.

---

## J6 — Les fêtes : objets à poser dans le QG (priorité 2)

Ce sont des objets détachés. Le jeu les pose au bon endroit dans chaque décor, à la bonne période. La hauteur indiquée est celle de l'image livrée (environ 2 fois la taille affichée).

| Fichier | Fête et période dans le jeu | Ce qu'on doit voir | Hauteur |
|---|---|---|---|
| `fete_noel_sapin.png` | Noël, décembre | sapin décoré (boules ambre et rouges, guirlande, étoile), petits cadeaux au pied | 420 px |
| `fete_noel_guirlande.png` | Noël, décembre | guirlande lumineuse qui pend en 3 arcs, ampoules multicolores, **bande horizontale** | 1600 × 140 px |
| `fete_nouvel_an_ballons.png` | Nouvel An, janvier | grappe de ballons (or, crème, ambre) et serpentins | 380 px |
| `fete_nouvel_an_table.png` | Nouvel An, janvier | petite table ronde avec des coupes et un seau à glace (sans étiquette) | 200 px |
| `fete_halloween_citrouilles.png` | Halloween, fin octobre | 3 citrouilles sculptées éclairées, de tailles différentes, l'air sympathique et pas effrayant | 160 px |
| `fete_halloween_toile.png` | Halloween, fin octobre | toile d'araignée décorative pour un coin de plafond, avec une petite araignée mignonne | 300 × 300 px |
| `fete_paques_panier.png` | Pâques, avril | panier d'œufs peints avec un ruban | 150 px |
| `fete_ete_ventilateur.png` | Été, juillet-août | ventilateur sur pied, rétro, couleur crème | 300 px |
| `fete_anniversaire_gateau.png` | Anniversaire de l'entreprise | gâteau à étages avec bougies sur une petite table, 2 ballons attachés | 260 px |

Fais attention à l'époque : le jeu commence en 1971. Les objets doivent être un peu rétro (années 70-80) et pas trop modernes.

---

## J7 — La vitrine et les trophées (priorité 3)

Ils remplacent l'étagère et les coupes dessinées en code en haut du QG.

| Fichier | Ce qu'on doit voir | Taille |
|---|---|---|
| `vitrine_etagere.png` | étagère murale en bois vernis, vue de face légèrement plongeante, avec 2 équerres en laiton, **vide** | 1000 × 90 px |
| `trophee_or.png` | coupe dorée à deux anses sur un socle en bois | 128 × 170 px |
| `trophee_argent.png` | même coupe en argent | 128 × 170 px |
| `une_encadree.png` | une de magazine encadrée (grande photo de puce, colonnes de texte illisibles, bandeau rouge en haut), cadre en bois | 120 × 160 px |
| `pancarte_evenement.png` | pancarte en bois peinte en rouge brique, suspendue par 2 ficelles, **vide** (le jeu écrit dessus) | 640 × 110 px |

---

## Ce que fait Claude en face

1. **Saisons** : le décor change avec le mois du jeu, en fondu. Les petits effets en code (neige qui tombe, feuilles…) restent par-dessus pour le mouvement.
2. **Fêtes** : les objets apparaissent à la bonne période, posés dans chaque décor (sapin près du bureau du fondateur, ballons près de l'entrée…), sans cacher les repères ni l'équipe. Le gâteau sort le mois anniversaire de la création de l'entreprise.
3. **Vitrine** : l'étagère et les trophées dessinés en code sont remplacés par tes images.
4. À chaque livraison : intégration, vérification sur le Pixel, une capture, et un retour précis si quelque chose est à reprendre (objet qui a bougé, détourage, poids du fichier).

## Pour plus tard (pas dans ce lot)

- Les décors 4 à 7 (PME, siège, campus, grand groupe, empire), quand le jeu aura ces paliers.
- Peut-être des **thèmes cosmétiques payants** : par exemple un bureau « néon années 80 », un « chalet en bois » ou un « spatial », des tenues d'équipe ou des boîtes de CPU spéciales. Ce sera décidé avec Alexandre, avec la même méthode d'étude croisée.
