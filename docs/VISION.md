# Vision — Tycoon Hardware / Tech Empire

> Nom de travail : **Tycoon Hardware**. Le concept dépasse désormais le seul hardware ; le nom définitif pourra évoluer plus tard.

## Pitch

Le joueur crée une entreprise technologique et la fait évoluer d'une petite société spécialisée vers un groupe mondial capable d'opérer dans de nombreux secteurs : semi-conducteurs, informatique, logiciels, cloud, télécoms, électronique grand public, IA, robotique, satellites, mobilité, infrastructures et technologies futures.

L'objectif n'est pas seulement de fabriquer des produits. Le cœur du jeu est de **diriger une entreprise technologique complète** : stratégie, finances, R&D, production, ressources humaines, marketing, ventes, acquisitions, intégration verticale, concurrence, réglementation, réputation et gestion de crise.

## Fantasme joueur

Commencer petit, avec peu de capital et une expertise limitée, puis construire progressivement un empire technologique cohérent.

Le joueur doit pouvoir :

- créer ses propres marques et gammes de produits ;
- choisir les marchés sur lesquels entrer ;
- développer ou acheter des technologies ;
- sous-traiter ou intégrer verticalement la production ;
- ouvrir des filiales et des divisions ;
- recruter des spécialistes et dirigeants ;
- construire des bureaux, centres R&D, usines, fabs, datacenters et infrastructures ;
- racheter des entreprises, prendre des participations ou fusionner ;
- développer un écosystème matériel + logiciel + services ;
- gérer les crises, retards, pénuries, rappels, guerres de prix et ruptures technologiques ;
- devenir une multinationale influente sans être obligé de suivre un seul chemin.

## Domaines technologiques possibles

Le jeu doit être conçu pour accueillir une vaste palette de secteurs sans créer un moteur différent pour chacun :

### Semi-conducteurs et composants
- CPU, GPU, NPU / accélérateurs IA ;
- RAM, stockage, contrôleurs ;
- cartes mères, chipsets, SoC ;
- capteurs, puces radio, composants spécialisés ;
- fonderies, gravure, packaging et chaînes d'approvisionnement.

### Informatique et électronique grand public
- PC fixes et portables ;
- smartphones et tablettes ;
- TV, moniteurs et écrans ;
- consoles ;
- objets connectés et wearables ;
- périphériques et accessoires ;
- électronique domestique intelligente.

### Logiciel et services
- systèmes d'exploitation ;
- logiciels professionnels et grand public ;
- plateformes applicatives ;
- services cloud ;
- stockage en ligne ;
- SaaS ;
- cybersécurité ;
- streaming et services numériques.

### Infrastructures et réseaux
- datacenters ;
- serveurs ;
- fibre ;
- 5G / 6G ;
- équipements réseau ;
- fournisseurs d'accès ;
- CDN et infrastructure cloud.

### IA, robotique et automatisation
- modèles IA ;
- assistants ;
- robots industriels et grand public ;
- systèmes autonomes ;
- logiciels d'automatisation ;
- puces IA et infrastructures associées.

### Mobilité et spatial
- électronique automobile ;
- logiciels embarqués ;
- véhicules autonomes ;
- drones ;
- satellites ;
- communications orbitales ;
- services basés sur constellation.

## Principe fondamental de conception

Le jeu ne doit pas être une collection de mini-jeux indépendants. Les secteurs utilisent un **moteur économique et industriel commun**.

Une TV, un GPU, un satellite ou un smartphone diffèrent par leurs données, contraintes et chaînes de composants, mais partagent des concepts communs :

**recherche → conception → composants → production → qualité → prix → distribution → ventes → support → réputation → évolution de gamme**.

Cela permet d'ajouter de nouveaux secteurs sans réécrire le jeu.

## Principe UX — simple en surface, profond à la demande

Tech Empire doit retrouver la lisibilité immédiate d’un tycoon comme Game Dev Tycoon sans copier son contenu. Le joueur joue d’abord **dans son entreprise**, pas dans une succession de tableaux de bord.

- le garage / QG est la vue principale et permanente ;
- une seule action importante doit attirer l’attention à la fois ;
- les décisions arrivent dans le monde : établi, banc de test, stock, Nora, presse, retours clients ;
- créer un produit doit commencer par quelques choix simples : cible, promesse, nom, lancement du projet ;
- les paramètres techniques, économiques et organisationnels détaillés restent accessibles volontairement ;
- aucun écran expert ne doit être nécessaire pour réussir la première boucle ;
- une interaction doit autant que possible produire une conséquence visible dans l’entreprise plutôt qu’ouvrir une nouvelle page ;
- les systèmes profonds existants restent la simulation réelle : l’interface n’en montre que ce qui est utile au moment présent.

Règle de contrôle : **si le joueur doit comprendre l’interface avant de comprendre ce qu’il veut faire, l’interface a échoué.**

## Réalisme modulable

Le jeu doit pouvoir être accessible au départ, tout en permettant une profondeur élevée.

Exemples de couches de réalisme :

- trésorerie, marges, dette et investissements ;
- coûts de R&D et amortissement ;
- salaires, recrutement et compétences ;
- chaînes d'approvisionnement ;
- capacité industrielle ;
- rendement de fabrication ;
- taux de panne et SAV ;
- stocks et logistique ;
- fournisseurs et dépendances stratégiques ;
- brevets et licences ;
- réglementation et antitrust ;
- image de marque et satisfaction client ;
- concurrence prix / performance / innovation ;
- contrats et marchés professionnels ;
- expansion internationale ;
- fusions, acquisitions et participations.

Le niveau de détail devra rester configurable afin de conserver un jeu jouable sur mobile comme sur PC.

## Monde vivant

Le joueur ne doit pas affronter uniquement des tableaux de chiffres. Le monde doit réagir à ses décisions.

Le marché comprendra :

- entreprises concurrentes ;
- investisseurs ;
- clients ;
- fournisseurs ;
- médias et analystes ;
- employés et dirigeants ;
- partenaires ;
- gouvernements et régulateurs.

Leurs réactions doivent refléter les données réelles de la simulation.

## IA et immersion

L'IA générative ne doit pas contrôler la logique fondamentale du jeu. La simulation reste déterministe et auditable dans Godot.

L'IA générative intervient au-dessus du moteur pour :

- faire parler un assistant / conseiller du joueur ;
- produire des rapports naturels ;
- enrichir les négociations ;
- donner une personnalité aux dirigeants concurrents ;
- générer des réactions de presse et d'analystes ;
- contextualiser les événements ;
- rendre le monde plus crédible sans casser l'équilibrage.

Les concurrents doivent d'abord disposer d'une vraie logique de stratégie et de décision. Le modèle génératif sert ensuite à exprimer ces décisions de façon immersive.

## Plateformes

Le jeu est pensé dès le départ pour :

- **PC / Windows** : interface riche, souris/clavier, davantage d'informations visibles ;
- **Android** : tactile, interface responsive et garage-first ; les panneaux détaillés n’apparaissent que lorsque le joueur demande à approfondir ;
- éventuellement d'autres plateformes plus tard si l'architecture le permet.

Le projet doit rester un seul codebase Godot avec plusieurs exports.

## Objectif de développement

La vision est volontairement large, mais la production doit rester incrémentale.

La première version jouable ne cherchera pas à couvrir tout le monde technologique. Elle doit prouver une boucle complète sur un seul secteur, puis généraliser le moteur.

Premier objectif :

**créer une entreprise → rechercher un premier CPU → concevoir → produire → fixer le prix → vendre → mesurer marge, réputation et part de marché → financer la génération suivante.**

Cette vertical slice sert de fondation au futur empire technologique.
