# HardwareTycoon / Tech Empire — Prototype V0.2.3

Cette version transforme l'ancien prototype temps + économie en première boucle de simulation d'entreprise technologique.

## Systèmes présents

- création de l'entreprise et choix du secteur de départ ;
- temps mensuel, pause et vitesses x1/x2/x3 ;
- trésorerie, revenus, dépenses et rapport mensuel ;
- personnel avec compétence, aptitude, expérience, spécialisation, leadership, salaire et moral ;
- expérience individuelle et expérience d'équipe/cohésion ;
- départements avec responsable et autonomie Direct / Supervisé / Autonome ;
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
3. Lancer un projet R&D en choisissant secteur, clientèle, approche, priorité et budget.
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
