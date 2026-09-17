# HardwareTycoon / Tech Empire — Prototype V0.2.5

Cette version transforme l'ancien prototype temps + économie en première boucle de simulation d'entreprise technologique.

## Systèmes présents

- création de l'entreprise et choix du secteur de départ ;
- temps mensuel, pause et vitesses x1/x2/x3 ;
- trésorerie, revenus, dépenses et rapport mensuel ;
- personnel avec compétence, aptitude, expérience, spécialisation, leadership, salaire et moral ;
- expérience individuelle et expérience d'équipe/cohésion ;
- départements avec responsable et autonomie Direct / Supervisé / Autonome ;
- laboratoire CPU avec cœurs, fréquence, cache, finesse de gravure et TDP ;
- estimation immédiate de performance, efficacité, fiabilité, innovation, coût, risque et durée ;
- R&D par phases : Concept, Architecture, Prototype, Alpha, Beta, Validation ;
- rapports du chef d'équipe à chaque phase ;
- choix développement interne / hybride-partenariat / externe ;
- savoir-faire technologique qui progresse avec les projets ;
- produits évalués sur performance, efficacité, fiabilité, ergonomie, innovation, écosystème et durabilité ;
- segments clients Budget, Grand public, Passionnés, Pro, Entreprise et Premium ;
- benchmark face à des concurrents ;
- prix de vente, capacité de production, ventes et parts de marché ;
- SAV, retours, coûts de garantie et budget support ;
- réputation multidimensionnelle ;
- marketing et budget environnement ;
- presse / médias ;
- opportunités et contrats B2B ;
- brevets et premières licences ;
- filiales simples ;
- sauvegarde / chargement.

## Branche actuellement active

La vertical slice jouable est limitée aux **processeurs (CPU)**.

GPU, smartphones, TV/écrans, logiciels/OS, cloud/services et satellites/télécoms restent paramétrés uniquement comme fondations de futures branches. Ils apparaissent comme « à venir », ne peuvent pas être sélectionnés et sont également refusés par la logique de R&D.

## Important

Cette V0.2 est une fondation jouable : elle ne cherche pas encore à simuler toutes les usines, fournisseurs, rachats, fusions ou fonctions multijoueur. Ces systèmes doivent être ajoutés au-dessus du moteur commun, pas sous forme de menus isolés.

## Premier test conseillé

1. Créer une entreprise.
2. Aller dans Personnel et observer les compétences/expériences.
3. Concevoir un CPU en réglant son architecture, sa clientèle, son approche, sa priorité et son budget.
4. Laisser passer les mois jusqu'aux rapports de phases.
5. Une fois le développement fini, lancer le produit avec prix et capacité.
6. Vérifier benchmark, réactions clients, presse, ventes, SAV et propositions B2B.
7. Tester les politiques d'entreprise et la délégation des départements.
8. Sauvegarder et recharger la partie.


## Correctif V0.2.2

- Compatibilité stricte Godot 4.7.2 : fonctions numériques typées (`clampf`, `maxf`, `maxi`, `mini`, `snappedf`).
- Suppression des inférences `Variant` qui pouvaient être traitées comme erreurs par GDScript.


## Correctif V0.2.3

- Branche CPU définie comme unique secteur actif de la vertical slice.
- Futurs secteurs conservés dans les données, affichés comme « à venir » et désactivés dans l’interface.
- Validation côté moteur empêchant le démarrage d’une partie, d’une filiale ou d’une R&D dans une branche inactive.
- Smoke test étendu pour vérifier le verrou CPU.


## Correctif V0.2.4 — premier passage interface

- Nouvelle identité sombre et technologique avec couleurs fonctionnelles cohérentes.
- Navigation principale dédiée : QG, Entreprise, Équipe, Laboratoire CPU, Produits, Marché et Presse.
- QG reconstruit autour du projet prioritaire, de sa progression, du rapport du CTO et des événements récents.
- Aperçu graphique du processeur dessiné directement par Godot, sans dépendance à un asset externe.
- Indicateurs et radar marché alimentés par l’état réel de la partie.
- Mise en page du QG adaptable aux écrans étroits.


## V0.2.5 — laboratoire CPU interactif

- Trois points de départ rapides : Efficace, Équilibré et Performance.
- Réglages techniques en direct : 2 à 32 cœurs, 2,0 à 6,0 GHz, 4 à 96 Mo de cache, 14 à 3 nm et 35 à 250 W.
- Aperçu du processeur qui réagit au nombre de cœurs, à la gravure et au TDP.
- Conséquences réelles sur les métriques finales, le coût de fabrication et la vitesse de développement.
- Indicateur d’adéquation au segment client et alerte claire sur le compromis principal.
- Migration automatique des anciens projets et produits CPU vers un design équilibré.
