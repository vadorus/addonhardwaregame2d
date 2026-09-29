# Lot B — remplir le début de partie (29/09)

But (plan `docs/PLAN_V09_V10.md`) : pendant le premier CPU, le joueur doit avoir quelque chose à faire
et un levier quand l'argent manque, et les deux grands moments de la vision doivent exister.

## Ce qui a été fait

Nouveau système `GarageBusiness` (`scripts/GarageBusinessManager.gd`), sauvegardé avec la partie.

**Contrats d'études (sous-traitance).** À partir du 3e mois, un client passe au garage avec une petite
puce à concevoir (calculatrice de bureau, jouet électronique, contrôleur de machine-outil, circuit
de mesure, module d'allumage, terminal de saisie).
- 2 ou 3 mois, 12 000 à 26 000 € (plus cher avec les années), 25 % d'avance à la signature,
  le solde à la livraison, clientèle pro +1 et un peu de savoir-faire.
- Le vrai choix : pendant le contrat, 25 à 40 % de l'équipe Développement y travaille,
  donc le CPU maison avance moins vite.
- Un client tous les 3 mois (tous les mois si la trésorerie tient moins de 6 mois) ;
  l'offre expire après 2 mois. Le client apparaît comme visiteur au garage et dans « À faire ».
- Les contrats disparaissent quand l'entreprise vit de ses CPU (12 salariés, ou 3 générations et
  plus de 300 000 €).

**Prêt bancaire de Nora.** Quand la trésorerie tient moins de 6 mois (et moins de 150 000 €),
Nora propose un prêt : au moins 60 000 € (6 mois de dépenses), remboursé en 36 mensualités,
20 % d'intérêts. Refusé, elle n'en reparle pas avant un an.

**Premier silicium.** Quand la revue du tout premier prototype s'ouvre, un développeur vient
raconter la mise sous tension (du premier coup, après une soudure refaite, ou après deux nuits
blanches selon la confiance de l'équipe), puis mène au banc de test.

**Tri des puces.** Quand la première génération sort d'usine, Nora annonce le résultat du tri :
la part de puces classées dans chaque modèle de la gamme et la part au rebut (selon le rendement réel), puis mène à
Produits › Vendre.

Les anciennes parties déjà lancées ne rejouent pas ces deux moments.

## Mesures (partie neuve jouée automatiquement, `progression_probe`)

| Joueur | Trésorerie la plus basse avant le lancement | 1er lancement | Prêt |
| --- | --- | --- | --- |
| Refuse contrats et prêt (= avant le lot B) | 12 000 € (mois 16) | mois 16-18 | — |
| Refuse les contrats, accepte le prêt | 29 900 € (février 1972, 4,7 mois de réserve), puis +60 000 € | mois 16-18 | 60 000 €, 2 000 €/mois |
| Accepte tout | 81 000 € | mois 18-24 | pas nécessaire |

Accepter les contrats retarde le premier CPU de quelques mois mais met fin à l'angoisse de
trésorerie : c'est le choix voulu. En 4 ans, un joueur qui accepte tout signe 15 contrats.

## Non fait

- Décaler le « Premier retour marché » d'un mois : il n'ouvre plus de fenêtre depuis le lot A
  (il rejoint la carte « À faire »), le gain ne justifiait pas de casser le test de retour marché.

## Tests

`GarageBusinessScenario` : offre → visiteur + « À faire » + conversation, avance, équipe occupée,
livraison et solde, fin des contrats quand l'entreprise grandit, prêt (versement, mensualité,
pas de second prêt), premier silicium affiché une seule fois, sauvegarde et rechargement.
