# V0.6 — économie du garage, playtest et critères de viabilité

> Document de référence pour la V0.6 « room-first ». Il consigne les décisions validées pendant le playtest Android réel et les garde-fous automatiques ajoutés au projet.

## 1. Prémisse de départ

La partie commence en **1971**. Le joueur a quitté son emploi pour lancer une petite entreprise technologique depuis un garage avec une épargne personnelle crédible.

Le garage n'est pas un simple décor : il définit aussi le **stade économique** de l'entreprise. Tant que la société n'a pas grandi, elle ne doit pas supporter artificiellement les charges d'une PME déjà structurée.

Règle canonique :

**le lieu, l'effectif, les fonctions disponibles et les charges doivent évoluer ensemble.**

Le joueur ne commence donc ni avec des millions d'euros, ni avec des départements complets de Production, Marketing et SAV.

## 2. Capital de départ V0.6

Réglages actuels :

| Difficulté | Capital initial |
|---|---:|
| Accessible | 150 000 € |
| Standard | 100 000 € |
| Réaliste | 95 000 € |

Ces montants sont des paramètres d'équilibrage et pourront encore évoluer, mais ils doivent rester compatibles avec le fantasme « épargne personnelle + prise de risque », pas avec celui d'une startup déjà massivement financée.

La difficulté ne doit jamais être compensée par des coûts absurdes puis un capital de départ artificiellement énorme.

## 3. Équipe fondatrice et charges du garage

Au stade garage, l'entreprise commence avec un petit noyau technique :

- Camille Durand — cofondatrice technique / R&D ;
- Samira Lefèvre — cofondatrice développement CPU ;
- Noah Leroy — associé validation CPU.

Les fonctions Production, Marketing et Support ne sont pas préremplies par des responsables salariés au jour 1.

Tant que l'entreprise est encore au garage et n'a pas lancé de produit commercial, les membres fondateurs touchent une **rémunération de subsistance** correspondant actuellement à 25 % de leur salaire nominal. Les vrais salaires deviennent applicables lorsque l'entreprise quitte ce stade.

Charges par défaut au garage :

- infrastructure administrative supplémentaire : 0 € ;
- entretien / local : 500 €/mois ;
- marketing : 0 € ;
- SAV/support structurel : 0 € tant qu'il n'existe pas de clients ou de dossier terrain ;
- environnement : 0 € ;
- avantages salariés : aucun par défaut.

Les nouvelles charges doivent apparaître parce qu'une fonction devient réellement nécessaire : locaux plus grands, premières ventes, SAV, marketing, production, recrutement, avantages, etc.

## 4. R&D : intensité de programme ≠ sortie de caisse

Le nombre affiché comme budget/intensité R&D représente l'**intensité du programme** : ambition, ressources techniques mobilisées et vitesse visée.

Pour un projet développé en interne, les salaires de l'équipe ne doivent pas être comptés une deuxième fois dans cette valeur. La sortie de caisse R&D interne représente surtout :

- prototypes ;
- composants ;
- outillage ;
- essais ;
- consommables ;
- sous-traitance ponctuelle.

L'interface V0.6 doit donc distinguer :

- **Intensité R&D mensuelle (référence)** ;
- **Sortie de caisse estimée au garage**.

Exemple réel du playtest : avec le brief « Simple & économique » et une intensité affichée de 35 000, la sortie de caisse de développement observée au premier mois est de **1 652 €**.

## 5. Industrialisation de la première génération

Le premier CPU en 10 µm est industrialisé comme une **petite série sous-traitée**, pas comme une production moderne à très gros volume.

Les coûts de fabrication doivent croître avec :

- la difficulté et la finesse du procédé ;
- la complexité du design ;
- le niveau de qualité demandé ;
- le volume ;
- la stratégie de fonderie ;
- les investissements propres de l'entreprise.

Le contrat pilote de la première génération possède donc un coût de mise en route faible par rapport aux procédés avancés. Les grosses dépenses industrielles doivent apparaître avec la croissance, pas être présentes dès 1971.

## 6. Playtest Android réel — référence V0.6

Test effectué sur Pixel en paysage, difficulté Standard, nouvelle entreprise, premier CPU « Simple & économique ».

### Départ

- Trésorerie : **100 000 €**
- Lieu : garage aménagé
- Projet : Nova 1

### Premier mois observé

- Revenus : 0 €
- Rémunération équipe fondatrice : **2 300 €**
- Entretien / locaux : **500 €**
- Développement Nova 1 : **1 652 €**
- Dépenses totales : **4 452 €**
- Trésorerie après clôture : **95 548 €**

À ce rythme initial précis, la société possède un peu plus de vingt mois de marge. Le premier CPU est estimé à environ 11–16 mois selon le compromis choisi ; l'objectif est donc d'avoir de la pression sans provoquer une faillite automatique.

Ce chiffre de « mois de survie » n'est pas une promesse permanente : il change avec le brief CPU, les décisions, les incidents et la croissance.

## 7. Corrections UX issues du playtest

Les défauts suivants ont été identifiés pendant le parcours réel et corrigés :

- le CTA **Lancer ce CPU** a été remonté pour rester visible en paysage ;
- l'établi CPU reçoit un indice visuel discret pendant le tout premier onboarding ;
- le banc de test route directement vers une décision prototype/validation en attente ;
- le temps est mis en pause lorsqu'une décision prototype importante est ouverte ;
- le libellé R&D distingue maintenant intensité du programme et sortie de caisse réelle estimée.

Point encore à surveiller :

- le clavier Android peut reprendre le focus sur certains champs numériques pendant une navigation tactile ; cela doit rester dans la liste de contrôle UX mobile.

## 8. Garde-fous automatiques

Les tests doivent empêcher le retour des erreurs de conception suivantes :

- capital de départ de plusieurs millions ;
- effectif de PME complet dès le garage ;
- marketing/SAV/avantages payés avant d'être utiles ;
- double comptage salaires + budget R&D interne ;
- première industrialisation impossible à financer ;
- blocage de la partie avant le premier produit ;
- raccourci du banc de test qui n'amène pas à la décision en attente.

Le scénario de parcours complet couvre désormais une première génération CPU jusqu'à l'industrialisation, la gamme, la commercialisation, les ventes, les retours terrain et la préparation d'une génération suivante.

Les tests fonctionnels d'industrialisation et de SAV sont isolés de la trésorerie du scénario de viabilité afin qu'ils testent leur mécanique propre sans introduire de faux besoin de capital initial.

## 9. État de validation au 25 septembre 2026

Sur le commit V0.6 courant :

- Godot CI : **succès** ;
- build Windows : **succès** ;
- build Android : **succès** ;
- nouvelle partie Android avec 100 000 € : **vérifiée manuellement** ;
- premier mois à 4 452 € de dépenses : **vérifié manuellement** ;
- parcours automatisé de viabilité : **succès**.

Le dernier changement d'affichage « intensité R&D / sortie de caisse » est validé par CI et builds. Sa vérification visuelle Android doit être refaite lorsque l'APK correspondante est installée avec une signature compatible.

## 10. Questions à soumettre à un audit externe

Un auditeur indépendant doit essayer de réfuter les choix actuels, notamment :

1. 100 000 € en Standard est-il crédible et suffisamment tendu pour le fantasme garage ?
2. La rémunération fondatrice à 25 % crée-t-elle une bonne pression ou une réduction trop artificielle ?
3. La différence entre intensité R&D et sortie de caisse est-elle compréhensible pour un joueur non technique ?
4. Le premier CPU peut-il être développé et industrialisé sans stratégie unique obligatoire ?
5. La croissance des coûts après le garage est-elle suffisamment progressive ?
6. Existe-t-il un softlock économique, UX ou de progression entre prototype, industrialisation et première vente ?
7. Le joueur comprend-il toujours la prochaine action sans transformer le jeu en tutoriel intrusif ?
8. Les tests automatiques vérifient-ils la vraie viabilité ou seulement un chemin heureux ?


## 11. Seconde passe d'audit externe — 25 septembre 2026

Claude a ré-audité la branche au commit `67e1ddc` avec Godot 4.7.2 et des sondes économiques plus longues. Deux blocants ont été confirmés : économie post-lancement trop généreuse et mode Réaliste trop étroit sur les briefs guidés les plus ambitieux.

Les correctifs issus de cette passe sont documentés dans `AUDIT_CLAUDE_V06_2026-09-25_R2.md`.

À partir du commit `b5d670c...` :
- la demande est fortement élastique au prix ;
- une marque inconnue ne reçoit plus automatiquement 7 % du marché ;
- engager de la capacité au lancement coûte de l'argent ;
- réserver de la capacité génère un coût mensuel, notamment si elle reste inutilisée ;
- le lancement d'un CPU prêt est une décision bloquante visible dans le garage ;
- le mode Réaliste conserve 95 000 € de capital mais ses multiplicateurs de coûts de départ ont été recalibrés ;
- la matrice CI couvre désormais 35 k€, 45 k€ et 55 k€ en Réaliste ;
- un garde-fou interdit le retour du cas « prix ×5 qui continue à se vendre normalement ».

**Important :** les chiffres de revenus post-lancement de l'ancien audit ne constituent plus une référence d'équilibrage après ces correctifs. Un nouveau playtest long Android doit établir la nouvelle référence.
