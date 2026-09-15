# Game Design — Tycoon Hardware / Tech Empire

## Piliers

### 1. Construire une entreprise, pas seulement des produits
Le joueur gère une société complète : finances, équipes, infrastructures, R&D, production, marketing, distribution, support, acquisitions et stratégie.

### 2. Choisir sa spécialisation puis se diversifier
Aucune route imposée. Une entreprise peut rester experte d'un secteur ou devenir un conglomérat technologique.

### 3. Créer des synergies entre divisions
Une même technologie peut alimenter plusieurs produits. Une division semi-conducteurs peut fournir les smartphones, TV, consoles, véhicules, datacenters et satellites du groupe.

### 4. Faire des choix avec des conséquences
Un produit excellent peut échouer s'il est trop cher, trop tardif, mal distribué ou construit sur une chaîne d'approvisionnement fragile.

### 5. Un monde concurrentiel crédible
Les concurrents investissent, lancent des produits, abandonnent des marchés, rachètent des sociétés, baissent leurs prix, signent des contrats et réagissent au joueur.

### 6. Réalisme configurable
Le jeu doit pouvoir être abordable sans supprimer sa profondeur. Les systèmes avancés pourront être activés progressivement selon le mode de difficulté.

## Boucle macro

**Observer le marché → décider d'une stratégie → investir → rechercher → concevoir → industrialiser → vendre → analyser → réinvestir / pivoter / acquérir.**

## Boucle produit

Chaque famille de produits utilise une structure commune :

1. choisir un marché cible ;
2. définir les besoins et contraintes ;
3. sélectionner ou développer les technologies ;
4. concevoir le produit ;
5. choisir composants / fournisseurs / intégration interne ;
6. valider coût, performances, qualité et délai ;
7. produire ;
8. fixer prix et marketing ;
9. distribuer ;
10. vendre ;
11. gérer support, retours et réputation ;
12. lancer la génération suivante.

## Entreprise

Systèmes envisagés :

- capital et trésorerie ;
- dette et financement ;
- revenus, coûts fixes et variables ;
- départements ;
- recrutement et compétences ;
- salaires ;
- bureaux, laboratoires et usines ;
- filiales ;
- marques ;
- R&D centrale et R&D spécialisée ;
- brevets et licences ;
- contrats ;
- acquisitions et participations ;
- intégration verticale ;
- gouvernance et croissance internationale.

## Marché

Chaque marché doit posséder :

- taille ;
- croissance ;
- segments ;
- sensibilité au prix ;
- sensibilité à la performance ;
- importance de la marque ;
- importance du logiciel / écosystème ;
- contraintes régionales ;
- concurrence ;
- maturité technologique ;
- événements et ruptures.

## Produits et technologies

Le moteur doit séparer :

- **technologies** : savoir-faire réutilisable ;
- **composants** : éléments physiques ou logiciels intégrables ;
- **produits** : objets vendus au client ;
- **services** : offres récurrentes ;
- **infrastructures** : actifs qui permettent production ou service.

Exemple :

Une architecture CPU est une technologie. Un SoC est un composant. Un smartphone est un produit. Un service cloud est un service. Une fab est une infrastructure.

## Concurrents

Chaque entreprise concurrente doit disposer au minimum de :

- capital ;
- portefeuille de produits ;
- technologies maîtrisées ;
- forces / faiblesses ;
- appétit au risque ;
- préférence prix / innovation / volume / premium ;
- stratégie d'expansion ;
- mémoire d'événements importants ;
- relations avec le joueur et les autres sociétés.

Leur logique de décision doit être calculée par la simulation, pas inventée librement par un LLM.

## Assistant du joueur

Le joueur pourra être accompagné d'un assistant capable de résumer les données du jeu et d'expliquer les conséquences possibles d'une décision.

À terme, l'assistant pourra agréger plusieurs rôles :

- CFO : finances ;
- CTO : technologie ;
- COO : production ;
- CMO : marketing ;
- RH ;
- juridique / réglementation ;
- stratégie / acquisitions.

Les réponses doivent se baser sur les données réelles de la partie.

## Mobile et PC

Le gameplay doit être identique sur les deux plateformes.

Sur mobile :
- grands contrôles tactiles ;
- navigation par onglets ;
- écrans focalisés ;
- densité d'information réduite.

Sur PC :
- panneaux côte à côte ;
- raccourcis ;
- graphiques plus riches ;
- meilleure utilisation des grands écrans.

## Règle de production

Aucune nouvelle famille de produits ne doit être ajoutée avant que la vertical slice initiale soit jouable de bout en bout. La profondeur du moteur commun passe avant la quantité de contenu.
