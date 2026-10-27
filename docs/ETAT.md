# Tech Empire (Godot) — état et décisions

> Fichier court et stable : le **pourquoi**. Ce qui est en cours est dans le tableau de bord Jade #93.
> Dernière mise à jour : 27/10/2026, d'après `v013/demo-octobre` au commit `f72941a`.

## Vision
Jeu de gestion : on démarre dans un garage en 1971 et on bâtit un empire du hardware, avec Nora Bernard comme bras droit et guide. Références : Game Dev Tycoon et Devices Tycoon Simulator pour le plaisir et la lisibilité, PC Tycoon 2 pour l'interface, sans rien copier. Ni simulation hardcore ni jeu bâclé : un novice ne doit pas être perdu.

## Où on en est
- Démo Android en version `0.13.0-demo (25)`, signée avec la clé stable « Tech Empire » (PR #119 et #120, 26/10).
- Prix d'époque et marge par puce visible fusionnés (PR #117, 25/10).
- Presse plus variée (PR #88, #105, #115) et 30 scènes de test vérifiées par le CI (PR #112).

## Décisions et raisons
- **Démo d'abord :** quelque chose de jouable fin octobre, gratuit sur le Play Store ; phase 1 figée, aucun chantier ajouté. Objectif : agréable, compréhensible et stable, pas seulement des tests qui passent.
- **Difficulté Accessible par défaut** dans la démo, à réévaluer après correction de l'économie de début de partie.
- **Économie Standard :** prix de marché qui évoluent avec l'époque et marge par puce visible, pour que le joueur comprenne ses choix. La baisse des coûts avec la maturité du procédé est reportée.
- **Signature stable :** passage à la clé « Tech Empire », en acceptant une désinstallation unique sur le Pixel et la perte des parties de test, pour pouvoir mettre à jour l'app ensuite.
- **Performances jugées sur mesures réelles** sur le Pixel (fins de mois à ×3, changements d'onglets, pires temps d'image), avant et après, plutôt qu'optimiser à l'aveugle.
- **Conception CPU :** l'architecture est la base. Des équipes R&D par axe (vitesse, énergie, fiabilité) conçoivent les architectures, l'équipe de développement en tire jusqu'à trois modèles, et le retour d'expérience nourrit la génération suivante. Le joueur ne règle plus directement la fréquence. La conception doit rester claire, fun, et on doit sentir l'avancement.
- **Locaux :** garage, atelier, etc. plafonnent le nombre de puces produites et vendues par mois ; 6 à 8 grands paliers d'évolution au maximum.
- **Contenu technologique fini :** pas de générateur procédural. On annonce au joueur le niveau final, la suite vient par mises à jour, puis la partie continue en mode libre.
- **Modèle économique :** téléchargement gratuit puis partie payante déblocable dans le jeu ; cosmétiques possibles, jamais pay-to-win. Le but est de rembourser le temps passé, pas de maximiser les revenus.
- **Ambiance chaleureuse** du garage aux bureaux, et fêtes calées sur la vraie date (Halloween, fin d'année).
