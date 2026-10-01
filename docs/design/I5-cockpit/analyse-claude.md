# Analyse de Claude — I5, la page « Vendre » après le lancement

Écrite le 01/10 avant de lire quoi que ce soit d'Astra. Base : `06930b3` + capture du 1er mois de vente (`captures/`).
Sources des chiffres : code (fichier:ligne), capture ou supposition, toujours indiquée.

## 1. Diagnostic

**Ce qui marche (à garder)**
- Les cartes de gamme (un bouton par modèle avec prix et ventes/mois) : on voit sa gamme d'un coup d'œil.
- Les 6 tuiles « Vie du produit » : ventes face à la prévision, satisfaction, contribution. Ce sont les bons chiffres.
- « Ce que le terrain nous dit » : prévision contre réel, puis une leçon. C'est le cœur du plaisir (la promesse tient ou pas).
- Les citations de clients : vivantes, et ça ne coûte rien de les garder.

**Ce qui coince, côté novice**
- **19 boutons au 1er mois** et aucune réponse à « qu'est-ce que je fais maintenant ? ». La bonne réponse est souvent « rien », ou une seule chose.
- Les actions sont rangées **par système** (promotion, stepping, firmware…), pas **par problème**. Le joueur doit savoir que « retours élevés » se soigne par « stepping fiabilité ». Il ne peut pas le deviner.
- Des actions dangereuses ou absurdes au mauvais moment :
  - **offensive à 20 000 € avec 20 303 € en caisse** (capture) ;
  - **retrait** le mois du lancement ;
  - stepping à plus de 13 000 € alors que les retours sont normaux (7 sur 143).
- **Deux boutons grisés sans raison affichée** : firmware et logiciel de contrôle. La raison n'existe que dans l'historique replié.
- **Message contradictoire, et c'est un vrai défaut** : la leçon dit « la capacité limite les ventes, augmentez-la » et le bouton dit « Réduire à 141 ».
  - Cause probable : le champ capacité avance par pas de 10 en partant de 1 (`UI.spin(1, 1000000, 10, 100)`, `ProductLifecyclePanel.gd:180`). La capacité réelle de 143 est arrondie à 141, donc le jeu croit qu'on veut baisser.
  - À corriger quoi qu'on décide (lot I6).

**Ce qui coince, côté expert**
- Avec 21 CPU (partie d'Alexandre, août 1985), on ne voit qu'un modèle à la fois, via un menu déroulant. Impossible de répondre à « lequel de mes CPU va mal ? » sans les ouvrir un par un.
- Aucune vue « portefeuille » : marge, âge, phase (lancement / en rythme / déclin) de tous les modèles côte à côte.

## 2. Proposition (le principe)

1. **La page s'ouvre sur une carte « Ce mois-ci » tenue par Nora.** Elle donne un verdict par modèle (✅ / ⚠ / 📉) et **0 à 2 conseils**, chacun avec son bouton vert déjà réglé, comme le conseil de fabrication de I4. Sans problème : « Tout va bien, laissez vendre. »
2. **Les actions sont proposées par problème, pas par système.** Chaque action a un déclencheur mesurable (§4). Hors déclencheur, elle n'est pas proposée.
3. **Une vue portefeuille remplace le menu déroulant** : une ligne par CPU en vente, triée du plus urgent au plus tranquille. On touche une ligne pour voir le détail.
4. **Tout reste accessible** dans un repli « Toutes les actions (mode expert) ». Chaque bouton grisé y dit pourquoi et ce qui le débloque.
5. **Garde-fous** : une action qui coûterait plus de la moitié de la trésorerie n'est jamais proposée par Nora. Dans le repli expert, son bouton affiche « ⚠ il vous resterait X € ».

## 3. Maquettes en texte

**1er mois (le cas de la capture)**
```
CE MOIS-CI                                             Nora
Votre gamme Nova 1 se vend : 333 puces, +10 830 € ce mois.
✅ Signature   ✅ Apex   ⚠ Essentiel : clients refusés, l'usine est pleine
┌ Conseil ───────────────────────────────────────────────┐
│ L'Essentiel pourrait vendre ~190/mois, l'usine en fait 143. │
│ [ Monter à 190/mois — 1 900 €, remboursé en ~2 mois ]   [Plus tard] │
└────────────────────────────────────────────────────────┘
VOS CPU EN VENTE  (tri : le plus urgent d'abord)
⚠ Nova 1 E  Essentiel  125 €  143/mois  marge 34 €  Lancement
✅ Nova 1 S  Signature  185 €  128/mois  …
✅ Nova 1 A  Apex       285 €   62/mois  …
▸ Détail du modèle (tuiles, terrain, clients, fiche)      ▸ Toutes les actions (expert)
```
Un seul bouton d'action visible. Le coût de 1 900 € est une supposition : le vrai devis vient de `capacity_change_quote`.

**12e mois, défaut de fiabilité**
```
CE MOIS-CI
⚠ Nova 1 S : 9 % de retours, la satisfaction tombe à 51/100.
┌ Conseil ─ L'équipe peut corriger la puce (stepping fiabilité) :
│ retours divisés par ~1,3, coût 18 000 €.   [ Lancer le stepping ]  [Plus tard] ┘
```

**Fin de partie, 20 CPU**
```
CE MOIS-CI : 2 conseils sur 20 CPU
⚠ Aster casse les prix sur le marché bureautique (Nova 7 S perd 30 % en 3 mois)  [ Riposter — 120 000 € ]
📉 Nova 3 E est vieux de 4 ans et Nova 7 E le remplace  [ Fin de série ]
VOS CPU EN VENTE  ⚠ 2   ✅ 15   📉 3      [Tout voir ▾]
```
Le portefeuille montre d'abord les modèles qui ont un ⚠ ou un 📉. Les ✅ sont repliés en une ligne.

## 4. Déclencheurs

Règle commune : la condition doit être vraie **2 mois de suite** avant le conseil (sauf la rupture, qui est immédiate). « Plus tard » met le conseil en pause 3 mois pour ce modèle. Au plus 2 conseils en même temps sur la page : le plus urgent d'abord.

| Action | Condition (mesurable) | Message de Nora |
|---|---|---|
| Capacité ↑ | ventes perdues ≥ 10 % de la demande (`last_month_lost_sales`) | « L'usine est pleine, des clients repartent. Monter à X. » |
| Capacité ↓ | utilisation < 60 % pendant 2 mois et stock qui grossit | « On produit trop, ça dort en stock. Réduire à X (gratuit). » |
| Prix ↓ | ventes < 70 % de la prévision 2 mois et un rival moins cher sur le segment | « Aster vend moins cher. Passer à X € ? » |
| Prix ↑ | rupture et satisfaction ≥ 75 | « Les clients en redemandent : le prix peut monter à X €. » |
| Promotion | ventes < 80 % de la prévision 2 mois, sans rival moins cher, et trésorerie ≥ 3 × le coût | « Peu de gens connaissent ce CPU. Une campagne de notoriété ? » |
| Stepping fiabilité | retours ≥ 5 % ou satisfaction < 55 | « Trop de retours : l'équipe peut corriger la puce. » |
| Stepping coût | marge par puce < 20 % du prix, après 6 mois de vente | « Chaque puce rapporte peu : une révision peut baisser le coût. » |
| Firmware | dès qu'il est débloqué, sur un modèle qui a des retours ou des plaintes de performance | « Nouveau : on peut corriger par microcode, sans refaire la puce. » |
| Offensive | part de marché −20 % en 3 mois face à un rival nommé, ou menace PRICE_WAR active, et trésorerie ≥ 3 × le coût | « Aster attaque. Riposter coûte X €. » |
| Fin de série | phase « En déclin » (> 36 mois, `MarketManager.gd:909`) ou successeur lancé sur le même segment, ou marge négative | « Nova 3 E a fait son temps. » |
| Retrait | jamais conseillé directement : il suit la fin de série | — |
| Logiciel de contrôle | une seule fois, quand il se débloque | « Nouveau : un logiciel pour vos CPU, qui fidélise les clients. » |

Les seuils sont des **suppositions de départ**. À caler avec `profiles_probe` : un novice ne doit pas recevoir plus d'un conseil par trimestre en moyenne la première année.

## 5. Replier, déplacer, retirer

- **Replier** : la grille des 7 actions va dans « Toutes les actions (expert) ». Même chose pour la fiche technique, les 6 barres de métriques et l'historique, sous « Détail du modèle ».
- **Déplacer** :
  - le prix et la capacité de chaque modèle vont dans le détail du modèle (ils restent à un toucher) ;
  - l'offensive pourrait vivre dans **Marché**, à côté des menaces, car c'est une action contre un rival, pas sur un produit. C'est à trancher (question 2).
- **Retirer** : rien. Aucun système de simulation ne disparaît.
- **Corriger** :
  - le pas du champ capacité (arrondi 143 → 141) ;
  - les deux boutons grisés qui doivent dire pourquoi.

## 6. Critères d'acceptation

1. **Test automatique, 1er mois** (scénario de la capture) : au plus 2 boutons d'action visibles hors replis. Exactement 1 ici, la capacité de l'Essentiel.
2. **Un scénario par déclencheur** : on force la condition, le conseil apparaît ; on la retire, il disparaît ; « Plus tard » le cache 3 mois.
3. **Garde-fou** : avec une trésorerie inférieure à 2 × le coût d'une action, Nora ne la propose jamais.
4. **Portefeuille** : avec 20 CPU, la carte « Ce mois-ci » et son bouton vert sont visibles sans défiler en 1616×720 (même méthode que `workshop_layout_test`).
5. **Cohérence** : la leçon du terrain et le conseil de capacité ne se contredisent jamais (test sur le cas 143/190).
6. **Sauvegardes** : une partie d'avant I5 s'ouvre. Les pauses « Plus tard » sont vides par défaut.
7. **Au doigt, sur le Pixel** : sur la partie d'Alexandre (21 CPU), il trouve en moins de 10 secondes le CPU qui va le plus mal.

## 7. Risques et parades

| Risque | Parade |
|---|---|
| Un joueur rate une action utile parce qu'elle est cachée | Le repli expert reste toujours là. La première fois qu'une action se débloque, elle porte un badge « nouveau ». |
| Trop de conseils : Nora devient une alarme | Hystérésis de 2 mois, « Plus tard » de 3 mois, 2 conseils au maximum, réglés avec `profiles_probe` |
| Seuils mal calibrés : jamais déclenchés ou toujours | Le banc 10 ans compte les conseils par profil. Cible : ≤ 4 la 1re année pour un novice. |
| L'expert trouve la page « assistée » | En mode Simulation, Nora est discrète : verdicts seulement, pas de bouton vert. Le repli expert est ouvert par défaut. |
| Doublon avec la carte « À faire » du QG (I3) | Seul un conseil urgent (rupture ou menace) remonte au QG. Les autres restent sur la page Vendre. |

## 8. Questions pour Alexandre

1. En mode **Accessible**, Nora peut-elle **appliquer seule** les conseils gratuits, comme baisser la capacité, et te le dire ensuite (comme I3 pour les décisions) ?
2. **L'offensive contre un rival** : dans Produits › Vendre, ou dans **Marché** avec les menaces ?
3. **Fin de vie** : quand un successeur sort sur le même marché, Nora propose-t-elle la fin de série de l'ancien, ou est-ce automatique ?
4. **Le portefeuille** se range-t-il par génération (Nova 1, Nova 2…) ou par marché (embarqué, bureautique…) ?
5. Les seuils (5 % de retours, −20 % de part…) : on part sur ces valeurs puis on règle au banc de simulation. D'accord ?
