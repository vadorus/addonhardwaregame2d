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

## Décisions d'Alexandre (28/09, 21 h 40)

- **Une équipe par domaine** (Énergie, Performance, Fiabilité, Gravure…). Pas de doublon.
- **Plus il y a de monde dans une équipe, plus elle avance vite**, pondéré par le niveau de chaque employé.
  Recruter un bon ingénieur dans l'équipe Énergie accélère directement cette branche.

## Gammes et modèles : c'est le patron qui décide

Aujourd'hui, chaque CPU devient automatiquement une gamme de 3 modèles (Essentiel, Signature, Apex,
`CpuProductLine.TIERS`). Nouvelle règle, comme dans la vraie vie :

- **Le joueur crée ses gammes comme il veut** : un nom et une cible. Exemples : *Nova Gaming*, *Nova Grand public*,
  *Nova Pro*, *Nova Défense*, *Nova Spatial*. Une gamme garde son identité d'une génération à l'autre.
- **À chaque nouveau produit**, il choisit : *nouvelle gamme* ou *génération suivante d'une gamme existante*
  (on repart du design précédent et l'équipe propose ses plans).
- **Il décide du nombre de modèles** dans la génération : un seul modèle, ou jusqu'à trois (tri des puces :
  entrée, cœur de gamme, haut de gamme), puis passe à une nouvelle gamme ou génération.
  La technologie *Tri avancé (binning)* pourra permettre plus de modèles plus tard.
- **Marchés à ajouter** : *Défense / aérospatial*. Historiquement gros acheteur de puces dès les années 70 ;
  priorité fiabilité et résistance, prix élevé, petits volumes, ventes par appels d'offres
  (le jeu a déjà un panneau d'appels d'offres, `TenderPanel`). *Spatial* peut en être une variante plus tardive.
  Les 12 marchés existants (calculatrices → datacenters, dont *Gaming*) restent.

## Propositions par défaut (à confirmer)

1. **Coût d'une équipe spécialisée** : salaires + de la place dans les locaux. Pour ouvrir une nouvelle équipe,
   il faut parfois déménager : ça relie la recherche aux paliers garage → atelier → labo → PME → campus.
2. **Expérience gagnée en vendant** : elle va à l'équipe concernée. Beaucoup de pannes sur une gamme =
   l'équipe Fiabilité apprend plus vite (on apprend de ses erreurs), mais la réputation en pâtit.
