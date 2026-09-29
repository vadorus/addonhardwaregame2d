# Tech Empire — revue level design / gameplay (29/09)

Méthode : partie d'Alexandre (août 1985, 49 salariés, 21 CPU en vente) + une partie neuve jouée
automatiquement avec photos du QG et de chaque onglet à 0, 2, 6, 12, 18, 30 et 48 mois
(`_claude_probe/progression_probe.gd`), + les simulations d'économie de la veille (15 et 40 ans).

## 1. La courbe de la partie

| Moment | Ce que voit le joueur | Diagnostic |
| --- | --- | --- |
| Mois 0 | Garage, Nora, un seul bouton vert « Nouveau projet CPU ». QG + Labo débloqués. | Très bon départ, lisible. |
| Mois 2 | Équipe **et Entreprise** débloquées (5 sous-pages : divisions, budgets, filiales…). | Trop tôt : l'Entreprise est un écran de patron de groupe, pas de garage. |
| Mois 6-12 | Le CPU avance, 1-2 décisions de prototype. Trésorerie 100 k€ → 39 k€ (8 mois de réserve). | **Creux** : rien à faire pendant ~10 mois de jeu, et une angoisse de trésorerie sans levier. |
| Mois 14-17 | Premier lancement. En même temps : « Nouvelle fonction Presse », révélation des tests, « Premier retour marché », **« Crise SAV »**. | Le plus beau moment du jeu est noyé sous 4 fenêtres, dont une crise à chaque sortie (retours à 12 %). |
| Années 2-4 | Argent qui monte vite (0,7 M€ → 2,2 M€ en 1975), toujours 3 salariés, toujours le garage. | **Pas d'objectif** : rien ne dit au joueur quoi viser ; le décor n'évolue pas. |
| 1985 (partie d'Alexandre) | 21 modèles en vente dont 18 anciens, 49 salariés, 22 M€. | Gestion de gamme absente (on ne retire jamais un vieux CPU), l'argent n'a plus d'usage. |

## 2. Onglet par onglet (rôle, verdict, piste)

- **QG** — le cœur, réussi (personnages, repères, carte « Projet en cours »). Défaut : jusqu'à 3 bulles
  « Décision requise » empilées sur la carte de droite. Piste : une seule file « À faire (3) ».
- **Labo** — Nouveau CPU (parcours en étapes) / Recherche (arbre) / Projets (cartes) : clair depuis la v0.9.
  **Brevets** est une coquille (2 boutons, aucun choix) : à fusionner dans Recherche ou à enrichir.
- **Équipe** — lisible maintenant, mais recruter = 1 candidat à la fois dans une liste déroulante.
  Piste : « Nora a trouvé 3 profils » (un expert cher, un junior prometteur, un généraliste).
- **Produits** — 4 étapes Concevoir / Fabriquer / Vendre / Supporter. **Concevoir** ne fait que renvoyer
  au Labo (doublon). **Supporter** double **Marché › SAV** (même écran deux fois).
- **Marché** — Mes ventes / Besoins / Concurrents / Appels d'offres / SAV. Riche mais passif :
  la seule action est « soumettre une offre ». Manque le geste clé d'un tycoon : **retirer un produit**,
  **baisser le prix d'une vieille génération**, **attaquer le marché d'un rival**.
- **Presse** — lecture seule. L'interview de lancement est la seule interaction ; à étendre
  (fuite avant lancement, démenti de rumeur, salon annuel).
- **Entreprise** — 5 sous-pages de formulaires (mandat de division à 7 réglages, budgets en champs
  numériques, filiale « Nova Cloud » à 100 000 €). Utile en fin de partie, écrasant au mois 2.

## 3. Priorités proposées

1. **Objectifs de Nora (structure de progression).** 3 objectifs à la fois, adaptés au moment
   (« Lancer un 1er CPU », « 1 000 ventes/mois », « Passer à 5 salariés », « Entrer sur le marché PC »,
   « Déménager dans l'atelier »…), chacun avec une récompense visible (réputation, argent, déblocage,
   évolution du décor). C'est ce qui manque le plus : le joueur ne sait pas quoi viser après le 1er CPU.
2. **Remplir le creux du début** : petits contrats de sous-traitance pendant le 1er projet
   (« Delta Office veut une puce de calculatrice : 2 mois, 15 000 € »), comme les contrats de
   Game Dev Tycoon — de l'argent, de l'expérience, et quelque chose à faire.
3. **Déblocages progressifs par sous-page** : Entreprise › Aperçu au mois 2, Locaux quand il y a un
   problème de place, Budgets après le 1er lancement, Divisions à 10 salariés, Groupe à 5 M€.
4. **Gestion de gamme** : bouton « Retirer du marché » (déstockage puis arrêt) + conseil de Nora quand
   une génération a plus de 3 ans. Résout aussi les 21 modèles de la partie d'Alexandre.
5. **Moment de lancement** : une seule séquence (tests de presse → premier bilan), sans crise SAV
   automatique (corrigé, voir §4).
6. Fusionner les doublons : Produits › Concevoir (supprimer), SAV (un seul écran), Brevets (dans Recherche).

## 4. Corrigé tout de suite

- **Retours SAV** : un CPU fiable à 80/100 revenait à 12 % → « Crise SAV » à chaque lancement.
  Taux ramené à ~5-6 % pour un CPU correct ; une crise n'arrive plus que si fiabilité ou défauts sont
  vraiment mauvais.
- **Bulle de notification** : au centre au QG (le coin droit est pris par la carte projet), à droite
  dans les onglets (le titre est à gauche).
