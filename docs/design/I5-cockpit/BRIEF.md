# Brief I5 — La page « Vendre » après le lancement d'un CPU

Destinataires : **Astra** et **Claude**, chacun de son côté. Coordination et synthèse : **Codex**. Décision : **Alexandre**.
Base de travail : branche `feature/ui-v09-navigation`, commit `06930b3` (lot I4).
Règles : voir `PROTOCOLE.md` dans ce dossier. **Personne ne modifie le code du jeu pendant cette étude.**

## 1. Le sujet en une phrase

Quand le premier CPU est en vente, la page **Produits › Vendre** montre d'un coup tout ce qu'on peut faire sur un produit. Comment l'organiser pour qu'un joueur novice comprenne quoi faire, sans retirer la profondeur au joueur expérimenté ?

## 2. Ce que le joueur voit aujourd'hui (1er mois de vente)

Partie neuve, mode Standard, gamme « Nova 1 » de 3 modèles (Essentiel 125 €, Signature 185 €, Apex 285 €) lancée aux réglages conseillés, 1 mois simulé. Écran 1616×720 (format paysage du Pixel 10). Captures dans `captures/vente_mois1_0.jpg` à `_3.jpg` (de haut en bas de la page).

Ordre de la page, de haut en bas :

1. En-tête « Cockpit produit — Fabriquer, vendre, suivre » et trois onglets (1 Fabriquer, 2 Vendre •3, 3 SAV).
2. **Votre gamme** : une ligne de résumé, puis une carte par génération avec un bouton par modèle (prix, ventes/mois).
3. **Modèle sélectionné** : un menu déroulant, puis 6 barres (performance, efficacité, fiabilité, satisfaction…), une ligne de chiffres (coût, prix, marge, capacité, ventes…), 3 citations de clients.
4. Repli « Fiche technique complète ».
5. Prix de vente + bouton « Appliquer le nouveau prix ».
6. **Vie après lancement** : « Vie du produit » avec 6 tuiles (ventes vs prévision, demande, satisfaction, retours, contribution, part de marché), puis la carte « Ce que le terrain nous dit » (prévision vs réel, leçon).
7. **7 lignes d'actions** (choix + bouton) :

| Action | Choix | Coût | Disponible au 1er mois ? |
|---|---|---|---|
| Capacité de production | nombre/mois | gratuit en baisse, payant en hausse | oui |
| Promotion | notoriété / valeur-prix / déstockage | 6 500 à 12 000 € | oui |
| Révision matérielle (stepping) | fiabilité / coût / efficacité | 13 000 € et plus | oui |
| Firmware / microcode | stabilité / équilibré / performance | 6 500 à 8 500 € | non (grisé, savoir-faire logiciel ≥ 12 et architecture ≥ 24) |
| Attaquer un rival | rival du segment | 40 % du CA mensuel, 20 000 € minimum | oui |
| Fin de vie | fin de série −25 % sur 3 mois, ou retrait | — | oui |
| Logiciel de contrôle | — | — | non (grisé, logiciel ≥ 18 et intégration ≥ 24) |

8. Repli « Historique et retours du terrain ».

**Compte : 19 boutons visibles sur cette page au 1er mois**, dont 2 grisés sans explication à l'écran.

Par-dessus, au même moment, le joueur a vu : la carte « Jour de sortie », la révélation des notes de presse, le moment illustré « Premier CPU », et 3 bulles d'actualité en haut à droite (presse, « Décision requise : Nora a vu la banque », objectif atteint).

## 3. Faits observés qui posent question

- **Offensive possible à 20 000 € avec 20 303 € en caisse** au 1er mois. Un clic et la trésorerie est à zéro.
- **Fin de série et retrait proposés le mois du lancement.**
- La carte « Ce que le terrain nous dit » dit : « la capacité limite les ventes : augmentez-la », alors que la ligne capacité propose de **réduire** (à 141/mois). À vérifier : les deux messages ne regardent peut-être pas le même modèle ou le même chiffre.
- Le stepping (révision matérielle) est proposé alors qu'aucune panne ni retour n'est encore un problème (7 retours sur 143 ventes).
- Rien ne dit au joueur **ce qu'il devrait faire maintenant**. La réponse attendue au 1er mois est souvent « rien, laissez vendre ».
- Plus tard dans la partie, ça se multiplie. La partie d'Alexandre (août 1985) compte **21 CPU** : la page reste centrée sur un seul modèle à la fois, choisi dans un menu déroulant.

## 4. La piste écrite dans la feuille de route (à challenger, pas à recopier)

`docs/ROADMAP_V010.md`, ligne I5, écrite par Claude le 29/09 :
> Cockpit après lancement progressif : les actions apparaissent quand un problème les rend utiles (stepping si pannes, offensive si un rival attaque). Critère : au 1er mois de vente, 2 actions visibles au maximum.

C'est une hypothèse, pas une décision. Vous pouvez la contredire.

## 5. Contraintes

- **Ligne du jeu (Alexandre, 30/09)** : ni simulation hardcore ni jeu bidon. Un novice ne doit pas être perdu, il faut du plaisir.
- Références d'Alexandre : Game Dev Tycoon, Laptop Tycoon, PC Tycoon 2, « à notre sauce », ambiance chaleureuse.
- Même jeu sur PC et Android. Le téléphone est la cible la plus dure : écran paysage 1616×720, au doigt.
- Nora (bras droit) guide déjà le joueur ailleurs : objectifs, conseils, dialogues. Le lot I3 limite à **3 décisions visibles** dans la carte « À faire » du QG.
- Les lots I1 à I4 ont posé un modèle : **une carte claire, 3 chiffres qui comptent, un bouton vert, le reste replié**.
- On ne supprime pas un système de simulation sans le dire clairement. Le cacher, le déclencher ou le regrouper, oui.
- Les anciennes sauvegardes doivent continuer à marcher.

## 6. Les questions auxquelles répondre

1. **Diagnostic** : qu'est-ce qui ne va pas sur cette page, du point de vue d'un novice puis d'un expert ? Qu'est-ce qui marche et qu'il faut garder ?
2. **Au 1er mois** : que doit voir le joueur, et quelle est la seule chose qu'on lui demande (si on lui demande quelque chose) ?
3. **Déclencheurs** : pour chacune des 7 actions, quand doit-elle apparaître, et avec quel message ? Donner une condition mesurable (exemple : « taux de retour > X % »).
4. **Plusieurs produits** : comment la page tient-elle avec 3 modèles, puis 20 ? Faut-il une vue « portefeuille » ?
5. **Expert** : comment le joueur avancé accède-t-il à tout, sans que le novice soit noyé ?
6. **Rôle de Nora** : doit-elle proposer ces actions (comme le conseil de fabrication en I4) ou rester en retrait ?
7. **Pièges** : quels risques (joueur qui rate une action utile parce qu'elle était cachée, argent dépensé trop tôt…) ?
8. **Critères de réussite** : comment vérifier, par un test automatique et sur le téléphone, que c'est réussi ?

## 7. Ce qu'on attend de vous

Un fichier `analyse-<votre nom>.md` dans ce dossier, avec ces parties :

1. Diagnostic (ce qui marche / ce qui coince)
2. Proposition (le principe en 5 lignes max)
3. Maquette en texte de la page : au 1er mois, au 12e mois avec un défaut, et en fin de partie avec 20 CPU
4. Tableau des déclencheurs (action → condition → message)
5. Ce qu'on replie, ce qu'on déplace, ce qu'on retire
6. Critères d'acceptation (testables)
7. Risques et parades
8. Questions que seul Alexandre peut trancher

250 lignes maximum. Simple et concret : Alexandre doit pouvoir lire la proposition en 5 minutes.
