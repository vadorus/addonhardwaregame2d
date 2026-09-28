# Recherche, équipes et technologies — refonte V0.9

*Conception d'Alexandre (28/09/2026), mise en forme par Claude. À valider avant tout code.*

## MODÈLE RETENU (28/09, 22 h) — prime sur les sections plus bas en cas de contradiction

**Idée centrale : l'architecture est la base du CPU.** Le joueur ne règle plus la fréquence à la main ;
il choisit l'architecture de sa gamme, et ses équipes font le reste.

1. **Architecture de départ.** En 1971, pas d'équipe R&D : les fondateurs partent d'une architecture simple
   (4 bits, comme le 4004 commandé par un fabricant de calculatrices). On la reçoit, on ne la choisit pas.
2. **Équipes R&D par axe** : Vitesse, Énergie, Fiabilité (une par axe, créées quand l'entreprise grandit).
   Elles conçoivent les **architectures** (1 à 3 ans). **Les qualités d'une architecture dépendent du niveau de
   chaque équipe au moment de la conception** ; le joueur peut l'orienter (« architecture orientée énergie »).
   L'architecture fixe les limites : cœurs possibles, fréquence maximale, cache.
3. **Les individus font le niveau des équipes.** Former un ingénieur (coût, moins disponible quelques mois,
   niveau en hausse), recruter un expert (cher, gros coup de pouce), nommer un responsable (compte double,
   donne les conseils). Pour orienter une architecture, on investit dans les personnes de l'axe voulu.
4. **Équipe de développement : les modèles.** Le joueur choisit l'architecture de sa gamme et dit ce qu'il veut
   (économique, performant, basse consommation) ; l'équipe **propose la configuration** dans les limites de
   l'architecture. Un seul modèle ou plusieurs configurations, y compris pour des gammes différentes
   (Gaming et Industriel peuvent partager la même architecture). Réglages fins en mode avancé.
5. **Retour d'expérience** à chaque modèle vendu :
   - vers l'équipe de **développement** : meilleure maîtrise de l'architecture (modèles suivants plus rapides,
     moins de bugs, meilleur rendement ; propositions de modèle amélioré ou de refresh) ;
   - vers les équipes **R&D** de l'axe concerné (beaucoup de pannes → l'équipe Fiabilité progresse) :
     ça prépare la **prochaine architecture**.
6. **Usure de l'architecture.** Plus elle a servi, plus elle est mûre, mais elle plafonne ; l'équipe de
   développement le signale. C'est le moment de lancer la suivante. Deux horizons à piloter :
   **les modèles d'aujourd'hui (développement) et l'architecture de demain (R&D).**
7. **Choix de patron** (esprit « tick-tock ») : même architecture sur une gravure plus fine (rapide, sûr, gain moyen)
   ou nouvelle architecture (plus long, cher, risqué, gros saut).
8. **Même langue partout** : Vitesse → barre performance, Énergie → barre efficacité, Fiabilité → barre fiabilité,
   dans la conception, les ventes et les notes de la presse. La gravure reste commune à tous les produits.
9. **Autres produits plus tard** (GPU, RAM, carte mère…) : même structure (architectures + axes), décrits dans
   un fichier de données ; affichés dès le début en pointillés avec leur condition d'ouverture.

Onglets : **Conception** (axe principal : projets, frise des 5 étapes, créer) · **Recherche / Architectures** ·
**Équipes** (cartes d'équipe, personnes, formation, conseils), reliés par des liens (« Débloqué par… », « Équipe… »).

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

## La vie d'une puce : du vrai processus au jeu

### Le vrai processus (résumé)

Définir le produit → architecture → conception logique → vérification (souvent plus de la moitié de l'effort)
→ conception physique → envoi à l'usine (tape-out) → fabrication (~3 mois) → premier silicium (bugs : microcode
ou nouvelle révision) → qualification → tri des puces (une puce = toute une gamme) → production en volume
→ lancement → vie du produit (microcode, refresh, fin de série). En 1971, l'Intel 4004 : une petite équipe,
~2 300 transistors en 10 µm, plans en partie dessinés à la main, commande d'un fabricant de calculatrices.

### Correspondance avec le jeu

| Vraie vie | Dans le jeu | Existe ? | Équipe |
|---|---|---|---|
| Définir le produit | Création : gamme, marché, priorité | En partie | Le patron |
| Architecture | Création : cœurs, fréquence, cache | Oui | Performance |
| Conception + vérification | Développement (phases, bulles de points) | Oui | Performance, Fiabilité |
| Conception physique | Choix de la gravure | Oui | Gravure |
| Tape-out + fabrication | Prototype (coût, attente) | Oui | Gravure |
| Premier silicium | Décision prototype : corriger maintenant ou plus tard | Oui | Fiabilité |
| Qualification | Décision de validation | Oui | Fiabilité |
| Tri des puces | Nombre de modèles (1 à 3) | À faire | Gravure |
| Production | Industrialisation | Oui | Gravure |
| Lancement | Prix, presse, interview | Oui | Le patron |
| Vie du produit | Conseils : microcode, stepping, fin de série | En partie | Toutes |

## Règle d'or : clair, pas prise de tête, fun, on sent l'avancement

*Demande d'Alexandre (28/09) : « faut que ça soit clair, pas casse-tête non plus, et fun à faire, qu'on sente l'avancement ».*

**Le joueur ne voit que 5 grandes étapes**, toujours les mêmes de 1971 à 2010 (le réalisme reste dans la simulation) :

1. **Idée** : quoi, pour qui, quels réglages (le parcours de création).
2. **Conception** : l'équipe travaille, les bulles de points montent (performance, efficacité, fiabilité, bugs).
3. **Prototype** : moment « premier silicium ».
4. **Production** : tri des puces, puis usine.
5. **Lancement et vie** : prix, notes de la presse, puis conseils des équipes.

**Clair**
- Une frise de 5 pastilles sur le projet, dans le garage et dans le Labo : l'étape en cours s'allume.
- Chaque étape dit en une phrase ce qui se passe et quelle équipe travaille.
- Au plus **une décision par étape**, avec 2 ou 3 choix. Chaque choix affiche sa conséquence en clair
  (« +2 mois, −40 % de pannes »). Les réglages fins restent dans le mode avancé.

**Pas prise de tête**
- Jamais de tableau de chiffres pour avancer. Des jauges, des couleurs, des phrases de l'équipe.
- Les options verrouillées disent pourquoi (« Débloqué par : … »), les technologies disent à quoi elles servent.

**Fun, on sent l'avancement**
- **Bulles de points** qui montent au-dessus de l'équipe pendant la conception (façon Game Dev Tycoon).
- **Moment « premier silicium »** : on allume la puce, petit suspense, puis le résultat
  (« Elle démarre ! 2 bugs trouvés. Corriger maintenant ou par microcode ? »).
- **Moment « tri des puces »** : les puces tombent dans 3 bacs (entrée, cœur, haut de gamme) ;
  on voit combien de bonnes puces on a, et on choisit combien de modèles sortir.
- **Révélation des notes de la presse** au lancement (déjà faite).
- Un son et une animation à chaque étape franchie. Des petits imprévus (percée, bug, départ d'un ingénieur).
- **Rythme cible** : une étape = 1 à 3 minutes de jeu à vitesse normale ; un événement ou une décision
  environ toutes les minutes ; un premier CPU complet en ~15 minutes.

**La complexité grandit avec l'époque, pas avec les écrans** : en 1971 les étapes sont courtes et simples ;
plus tard la vérification pèse plus lourd, et des technologies (conception assistée, émulation)
raccourcissent les phases. Le joueur sent l'industrie évoluer sans nouvel écran à apprendre.

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
