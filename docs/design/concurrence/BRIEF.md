# Brief — Faire de Tech Empire le meilleur de son genre

Demande d'Alexandre (01/10/2026, 22 h 26) : « Tu es chef développeur avec Codex. Votre mission : rendre ce jeu
le meilleur, comparé à ses concurrents directs comme PC Tycoon 2 ou Game Dev Tycoon. »

Destinataires : **Astra** et **Claude**, chacun de son côté. Coordination et synthèse : **Codex**. Décision : **Alexandre**.
Même méthode que les études I5 et monétisation : voir `PROTOCOLE.md`. **Personne ne modifie le code du jeu pendant l'étude.**

## 1. Le sujet

Comparer Tech Empire aux jeux du même genre, sur PC comme sur téléphone, puis proposer **le plan qui le rendra
meilleur qu'eux** : ce qu'on garde, ce qui manque, dans quel ordre, et comment on saura que c'est réussi.

## 2. Ce qu'Alexandre a déjà décidé (contraintes)

- **Ni simulation hardcore, ni jeu bidon plié en 5 minutes.** Un novice n'est jamais perdu ; un joueur aguerri a toujours un défi.
- Clair, pas prise de tête, fun, **on sent l'avancement**. Ambiance chaleureuse (garage, bois, crème, Nora).
- **Même jeu sur PC et Android**, pensé d'abord pour le téléphone. Publication prévue sur Google Play.
- Cosmétiques payants possibles, **jamais pay-to-win**.
- **Le contenu technologique a une fin** (2010 dans cette version), puis la partie continue en mode libre.
- Inspirations assumées : Game Dev Tycoon, PC Tycoon 2, Laptop Tycoon, **sans copier** interface, graphismes ni assets.
- Alexandre développe **sur son temps libre**, avec des IA (Claude pour le code, Astra pour les graphismes, Codex pour la
  coordination) : un plan réaliste vaut mieux qu'un plan géant.

## 3. Où en est le jeu (01/10/2026, branche `feature/ui-v09-navigation`, commit `94592cd`)

- Vertical slice CPU, 1971 → 2010 puis mode libre. 10 marchés (industriel, embarqué, PC familial, jeu, station de travail,
  serveur, console, mobile, centre de données, spatial). 3 modes (Accessible, Standard, Simulation).
- Architecture → modèles → retour d'expérience ; équipes R&D ; rivaux vivants (rachats, entrées sur le marché), filiales,
  marchés stratégiques, salon annuel, trophées de carrière, presse et Unes.
- QG vivant : 4 paliers de locaux illustrés (garage, atelier, siège, campus), équipe visible, saisons, fêtes, météo, jour/nuit,
  vitrine ; musique et ambiances sonores ; Nora guide.
- Sondes : `tests/tools/profiles_probe` (novice / intermédiaire / expert sur 10 ans), `tests/tools/campaign_probe` (1971-2030).

## 4. Les questions (répondre aux 9, dans l'ordre)

1. **Les concurrents** : lesquels comptent vraiment (PC et mobile) ? Pour chacun : ce qui plaît, ce que les joueurs reprochent.
   Citer ses sources (page Steam, avis, test).
2. **Où Tech Empire est déjà meilleur** qu'eux (à protéger) ?
3. **Où il est en retard** : les 3 manques qui coûteraient le plus de mauvais avis s'il sortait demain.
4. **La partie longue** : le reproche n°1 du genre est « après les premiers succès, plus aucun défi ». Comment garder le défi
   de 1975 à 2010 sans devenir hardcore ?
5. **Le moment du lancement et de la note** : comment le rendre aussi fort que dans Game Dev Tycoon, et compréhensible
   (le reproche n°1 de PC Tycoon 2 : on ne comprend pas sa note) ?
6. **Rejouer** : modes, scénarios, bac à sable, année de départ… Quoi, et pour quel effort ?
7. **La largeur** : d'autres produits que les CPU (cartes graphiques, mémoire, cartes mères, consoles…) — maintenant, plus tard, jamais ?
8. **Avant une bêta Google Play** : ce qui est indispensable (langue anglaise, performances, taille, prix…) et ce qui peut attendre.
9. **Le plan** : 5 lots au maximum, classés, chacun avec un **critère mesurable** (sonde, test, partie au doigt sur le Pixel).

## 5. Format attendu

- Un fichier par analyse, **250 lignes maximum**, en français simple, phrases courtes.
- Chaque chiffre dit d'où il vient : code (fichier:ligne), sonde, source web citée, ou supposition.
- Pas de jargon sans explication. Alexandre doit pouvoir le lire sur son téléphone.
