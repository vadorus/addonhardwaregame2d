# Recherche, équipes et technologies — refonte V0.9

*Conception d'Alexandre (28/09/2026), mise en forme par Claude. À valider avant tout code.*

## Pourquoi

Aujourd'hui, six notions différentes font « progresser » l'entreprise : technologies (`cpu`, `manufacturing`),
capacités (Architecture, Cartographie, Miniaturisation), connaissances de recherche avec chercheurs affectés,
programmes Concept, compétences des employés, expérience marché/terrain. L'écran Recherche montre à la fois
« Architecture » et « Architecture & performance ». Le joueur ne sait pas ce qu'il débloque ni pourquoi.

## Le modèle : trois idées

1. **L'équipe produit de l'expérience.** Chaque mois, selon sa taille, ses compétences et ce qu'elle a déjà fait.
2. **Le joueur choisit où va cette expérience.** Une technologie qu'on ne choisit pas n'avance pas.
3. **Les technologies permettent les produits.** Chaque niveau de maîtrise débloque une option concrète
   dans la création, puis rend les produits meilleurs.

Boucle : *faire des produits → l'équipe progresse → plus d'expérience → technologies → meilleurs produits.*

## Ce qui va plus loin que Game Dev Tycoon

### Des équipes spécialisées

- Au garage, une seule équipe **généraliste** : le joueur choisit chaque mois la technologie qu'elle travaille.
- Quand l'entreprise grandit (palier *petit labo* puis *PME*), on peut **créer une équipe spécialisée** :
  Énergie & thermique, Performance, Fiabilité & validation, Gravure & fabrication…
- Une équipe spécialisée travaille **en continu** sur son domaine, en plus de la généraliste.
  Tout miser sur l'efficacité énergétique devient un vrai choix de stratégie qui dure sur plusieurs générations.
- Grandir devient **nécessaire** : plus d'équipes = plus de domaines maîtrisés. Ça répond au constat de la
  partie de 15 ans (3 personnes dans le garage pendant 15 ans).

### Maîtrise par niveaux et arbre à choix

- Chaque technologie a un **niveau de maîtrise de 1 à 5**.
  - Niveau 1 : l'option apparaît dans la création (ex. « 2 cœurs », « gravure 8 µm »).
  - Niveaux 2 à 5 : bonus visibles sur les produits (moins de pannes, moins cher, plus rapide à développer, plus sobre).
- Au niveau 3, une technologie **ouvre une ou plusieurs suivantes**. Le joueur choisit sa voie :
  deux parties ne se ressemblent pas.
- Exemple : *Transistors bipolaires* niv. 3 → ouvre *Gravure 8 µm* et *Alimentation double phase*.

### L'équipe conseille le joueur

Une équipe spécialisée assez avancée propose des actions, présentées comme un conseil de son responsable :

- **Mise à jour du microcode** d'une gamme en vente : « Équipe Énergie CPU : on peut gagner jusqu'à 25 %
  d'efficacité sur la gamme tv2 avec une mise à jour du microcode. » Coût, délai, gain.
- **Refresh / stepping** d'un modèle : corrige ses défauts (pannes, SAV), améliore un point.
- **Conseil pour la prochaine gamme** : « Notre maîtrise permet de viser +25 % d'efficacité sur la suivante. »
- **Règle** : une amélioration ne fait **jamais dépasser la dernière génération** de l'entreprise.

Ces actions existent déjà dans le code (`ProductManager.REVISION_TYPES` pour les steppings,
`FIRMWARE_TYPES` pour le firmware/microcode). La refonte les fait **proposer par l'équipe**, au bon moment,
au lieu de menus cachés dans Produits.

## Arbre de départ (CPU, 1971 → 2010) — dates indicatives, à caler sur `CpuDesign.NODE_PROFILES`

| Domaine | Technologies dans l'ordre (exemples) |
|---|---|
| Gravure & fabrication | 10 µm → 8 µm → 6 µm → 3 µm → 1,5 µm → 1 µm → 0,8 µm → 0,35 µm → 0,18 µm → 130 nm → 90 nm → 65 nm → 45 nm → 32 nm ; plaquettes 100 → 150 → 200 → 300 mm |
| Performance / architecture | Bus 8 bits → 16 bits → 32 bits → 64 bits ; pipeline ; cache L1 ; cache L2 intégré ; superscalaire ; exécution dans le désordre ; SIMD ; multicœur ; multithreading |
| Énergie & thermique | Basse tension (5 V → 3,3 V) ; alimentation double phase ; gestion dynamique de fréquence ; états de veille ; coupure de blocs inutilisés |
| Fiabilité & validation | Tests paramétriques ; rodage (burn-in) ; microcode modifiable ; correction d'erreurs (ECC) ; tri avancé des puces (binning) |

## Ce qui disparaît ou change dans le code

- Affectation de chercheurs par domaine, programmes Concept, capacités Architecture/Cartographie/Miniaturisation,
  technologies `cpu`/`manufacturing` → **remplacés par l'arbre** (un seul système).
- `ResearchTree.gd` devient le cœur du système (aujourd'hui il ne fait qu'afficher).
- Création de produit : chaque valeur verrouillée affiche « Débloqué par : … » et mène à la bonne tuile.
- **Anciennes sauvegardes** : conversion des valeurs actuelles en niveaux de maîtrise (la partie *jade orp* doit se recharger).
- **Équilibrage** : à refaire et à vérifier avec la partie automatique de 15 ans (rythme des déblocages, coût des équipes).

## Questions ouvertes pour Alexandre

1. Combien d'équipes spécialisées au maximum ? Une par domaine, ou plusieurs sur le même domaine ?
2. Une équipe spécialisée coûte-t-elle seulement des salaires, ou aussi des locaux (lien avec les paliers garage → campus) ?
3. L'expérience gagnée en vendant (SAV, retours terrain) va-t-elle à l'équipe du domaine concerné ?
   Ex. beaucoup de pannes → l'équipe Fiabilité apprend plus vite.
