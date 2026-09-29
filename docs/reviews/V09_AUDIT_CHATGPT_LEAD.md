# Tech Empire — audit lead dev ChatGPT (29/09/2026)

Périmètre : build Android réellement lancée sur le Pixel 10 d'Alexandre, sauvegarde `jade orp` (août 1985), code de `GarageHub`, `GarageCrew`, marché et produits, et comparaison de structure avec Game Dev Tycoon / PC Tycoon 2.

## Verdict

Tech Empire a déjà sa signature : la profondeur CPU / fonderie / binning / SAV / concurrence est plus ambitieuse que les références du genre. Le problème n'est pas le manque de systèmes : **le jeu ne met pas encore ces systèmes en scène**.

L'objectif V0.9/V1.0 doit devenir : **un tycoon que l'on comprend en regardant son entreprise vivre**. Le joueur doit voir sa société grandir, ses ingénieurs travailler, ses produits vieillir, ses rivaux frapper et son argent être réinvesti, avant d'aller lire un tableau.

## Ce qui fonctionne déjà

- Le QG illustré est la bonne direction : atelier chaud, identifiable, personnages visibles, repères interactifs.
- Nora joue déjà le rôle de fil conducteur.
- `GarageCrew` sait déjà afficher des salariés, visiteurs, bulles de dialogue et bulles de points pendant le travail.
- Les cinq zones du QG (établi, banc de test, planification, bureau, stock) donnent une base idéale pour des interactions dans le décor.
- La barre de navigation mobile est claire et les cibles tactiles sont confortables sur Pixel 10.
- La révélation presse, le premier silicium et le tri des puces sont les futurs grands moments émotionnels du jeu.

## Problème visuel n°1 — la croissance n'existe pas à l'écran

`GarageHub.WORKPLACE_ART` utilise actuellement la même ressource `garage_reference_v09.png` pour les tiers 0, 1, 2 et 3.

Conséquence observée sur la partie d'Alexandre : l'interface indique **Campus R&D**, 49 salariés et 22,8 M€, mais l'image reste le même garage et `GarageCrew` ne possède que cinq postes de travail.

C'est la priorité visuelle absolue : le décor doit être la jauge de progression principale du joueur.
## Direction visuelle à retenir

On ne copie pas Game Dev Tycoon ni PC Tycoon 2 ; on reprend leur force structurelle : **la pièce raconte le niveau de l'entreprise**.

- Garage : 2-3 personnes, établi bricolé, cartons, une seule machine importante.
- Atelier : davantage de bancs, stockage, prototype, premier coin administratif.
- Petit labo : zones séparées conception / validation / production pilote.
- PME : plusieurs équipes visibles, salle de réunion, vraie réception, mini-ligne de test.
- Siège / Campus : plusieurs pièces ou zones, managers, labo avancé, salle presse, visiteurs.
- Grand groupe / Empire : campus technologique, fab, datacenter, divisions visibles.

Chaque palier doit changer au minimum : fond, nombre de postes visibles, circulation, objets interactifs, ambiance sonore et type de visiteurs.

Les salariés hors champ ne doivent pas disparaître dans une liste : on les représente par **équipes**. Cinq à huit personnages visibles suffisent si chaque groupe représente une équipe entière et si le responsable est identifiable.

## Audit écran par écran

### QG
Très bon socle, mais trop de HUD posé sur l'image. La priorité doit être donnée au décor et à une seule décision active. Projet, actualité et Nora peuvent devenir des éléments contextuels plus compacts qui s'ouvrent depuis le monde.

### Labo
L'écran est très vide pendant qu'un projet existe. À la place du grand espace blanc : frise des 5 étapes, architecture utilisée, équipe au travail, prochaine décision et raccourci vers Recherche. Le bouton « Nouveau CPU » ne doit pas dominer quand une génération est déjà en cours.

### Équipe
À 32 personnes R&D, une grille de fiches individuelles devient un annuaire. Vue par défaut : cartes d'équipes (Performance, Énergie, Fiabilité, Gravure, Dev produit) avec niveau, responsable, moral, charge et progression. Les individus restent en profondeur.

### Produits
Le cockpit reste textuel. Il faut une **ligne de vie de gamme** : génération actuelle, anciennes générations, courbe de ventes, prix, marge, âge, satisfaction, stock/capacité et actions directes (prix, promo, refresh, fin de série).

### Marché
C'est aujourd'hui un tableau de chiffres. Il doit devenir le radar du joueur : segments qui grossissent/rétrécissent, courbes de parts de marché, sorties rivales sur une timeline, flèches de tendance et alertes de substitution.

### Presse
Le fil est lisible mais trop uniforme. Il faut distinguer visuellement : test produit, grosse annonce concurrente, rumeur, contrat, crise, récompense. Les tests doivent ressembler à un événement, pas à une ligne de flux.
## Gameplay — ce qui doit changer avant d'ajouter du contenu

### 1. Lot M reste prioritaire
Le marché actuel sait surtout croître ; il ne raconte pas assez la vie commerciale d'un produit. Un produit doit faire : lancement → montée → pic → plateau → déclin → fin de série.

La demande doit réagir au **meilleur rival pertinent**, pas seulement à une moyenne. Quand Helix sort un CPU nettement meilleur sur le même segment, le joueur doit le voir immédiatement : presse, courbe, part de marché et baisse des ventes.

Les segments doivent avoir une vraie histoire : naissance, croissance, maturité, déclin. Un marché ancien peut rester une niche, mais pas vendre éternellement comme au lancement.

### 2. Grandir doit changer ce que l'on peut entreprendre
Une entreprise de 5 personnes et une entreprise de 50 personnes ne doivent pas simplement produire le même projet avec plus de charges.

La taille ouvre : projets de plus grande ampleur, plusieurs projets en parallèle, architectures simultanées, marchés professionnels, contrats plus gros, capacité industrielle, meilleure couverture SAV et marketing international.

Le rendement n'a pas besoin d'être linéaire : une grosse société peut coûter très cher, mais elle doit avoir accès à des revenus et ambitions impossibles au garage.

### 3. L'argent doit redevenir une décision
Les gros montants servent à acheter de la capacité et du futur : fab, machines de gravure, labo, licences, brevets, campagnes mondiales, stocks stratégiques, rachats, expansion de locaux, équipes parallèles, gestion de crise.

Pas de taxe arbitraire pour vider la banque : chaque gros puits d'argent doit offrir un avantage, un pari ou une protection.

### 4. Les notes doivent être relatives à l'époque
Les métriques techniques peuvent rester absolues en interne, mais la **note presse** doit juger le produit par rapport : au marché actuel, au meilleur rival, à la génération précédente du joueur et à son positionnement prix.

Ainsi, un CPU techniquement à 94/100 en 1985 peut recevoir 6/10 si le marché attendait mieux, et un produit beaucoup plus modeste en 1972 peut recevoir 9/10 s'il bouleverse son époque.

## Le cœur de la boucle à viser

**Voir un besoin → décider d'une génération → équipe qui travaille visiblement → premier silicium → tri des puces → lancer → révélation presse → ventes qui vivent → réaction des rivaux → réinvestir → déménager / recruter → viser plus gros.**

Si cette boucle est excellente, toutes les futures branches (GPU, RAM, PC, serveurs, logiciel) pourront réutiliser le même squelette.
## Ordre de production recommandé

1. **M1 — marché vivant** : cycle de vie, rival qui déplace la demande, segments qui montent/baissent, vraie fin commerciale.
2. **M2 — croissance qui paie** : taille d'équipe → ampleur/parallelisme/capacité/revenus accessibles.
3. **Validation 40 ans** : plusieurs graines + sauvegarde 1985, avant toute nouvelle couche de contenu.
4. **B — début de partie** : contrats courts et respiration du premier CPU.
5. **C — progression visible** : objectifs Nora + vrais paliers de locaux, avec décors distincts et cartes de sièges par palier.
6. **D — gestion active des gammes** : prix, fin de série, 1-3 modèles choisis, guerre de prix.
7. **E — R&D équipes / architectures**.
8. **F — empire / après 2010**.
9. **G — finition mobile, sons, animations et textes**, en continu.

Le visuel des paliers de locaux doit être préparé pendant M/B pour que le lot C ne soit pas seulement une mécanique de loyer.

## Critères de qualité supplémentaires

- Le joueur doit pouvoir comprendre l'état de son entreprise en 5 secondes depuis le QG.
- Une action importante doit produire un changement visible ou sonore dans le monde.
- Une sortie produit doit créer un moment de tension et de récompense, pas seulement une nouvelle ligne.
- À 50 salariés, l'entreprise doit paraître radicalement différente du garage, même avant d'ouvrir un menu.
- Une nouvelle génération rivale majeure doit être perceptible sans aller consulter l'onglet Concurrents.
- Aucun écran ne doit demander de lire un mur de chiffres pour savoir « qu'est-ce que je dois faire maintenant ? ».

## Positionnement

Tech Empire ne doit pas devenir « PC Tycoon 2 avec plus de boutons » ni « Game Dev Tycoon avec des CPU ».

Sa place est : **la lisibilité et le rythme d'un grand tycoon accessible, avec une simulation industrielle de hardware beaucoup plus profonde en dessous**.

C'est cette combinaison qui peut rendre le jeu distinctif : simple à regarder, difficile à maîtriser, et toujours vivant.