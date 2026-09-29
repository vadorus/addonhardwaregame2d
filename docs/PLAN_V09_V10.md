# Tech Empire — plan de correction et d'amélioration (V0.9 → V1.0)

Rédigé le 29/09/2026. Il compare **ce qu'on veut** (VISION, ROADMAP, RECHERCHE_EQUIPES_V09,
UX_ART_DIRECTION, décisions d'Alexandre) à **ce qu'on a vu** (revue de tous les onglets,
`docs/reviews/V09_LEVEL_DESIGN_AUDIT.md`, simulations d'économie sur 15 et 40 ans).

## 1. Ce qu'on veut du jeu (rappel court)

- **Garage d'abord** : une seule action importante à la fois, décisions dans le monde (personnages,
  bureau), aucun écran expert pour la première boucle. « Si le joueur doit comprendre l'interface
  avant de comprendre ce qu'il veut faire, l'interface a échoué. »
- **Rythme** : premier CPU en ~15 min réelles, une étape de projet = 1 à 3 min, un événement
  intéressant environ chaque minute ; deux grands moments : « premier silicium » et « tri des puces ».
- **Progression visible** : 6 à 8 paliers de locaux (garage → atelier → petit bureau/labo → PME →
  siège → campus R&D → grand groupe → empire), l'interface se débloque au fil de la partie.
- **Profondeur de tycoon** : plus riche que Game Dev Tycoon / Laptop Tycoon — industrie, marché
  vivant, concurrents, presse, entreprise, filiales, rachats, brevets.
- **R&D V09 (modèle retenu le 28/09)** : architecture de base, équipes par axe (Vitesse / Énergie /
  Fiabilité), personnes avec formation et experts, l'équipe dev propose les modèles, usure
  d'architecture, tick-tock, gammes créées par le joueur (1 à 3 modèles).
- **Fin de campagne** : la technologie plafonne vers 2010, le joueur est prévenu que la suite viendra
  par mises à jour/DLC, **la partie continue et doit rester intéressante** grâce aux autres systèmes.
- Gameplay identique PC / Android, cosmétiques jamais pay-to-win.

## 2. Ce qu'on a vu (état au 29/09)

| Sujet | Constat | Gravité |
| --- | --- | --- |
| Début de partie | Mois 6-14 : rien à faire, trésorerie 100 k€ → 39 k€ sans levier | Haute |
| Déblocages | Entreprise (5 sous-pages de formulaires) ouverte au mois 2 | Haute |
| Objectifs | Après le 1er CPU, rien ne dit quoi viser ; 2,2 M€ en 1975 avec 3 salariés, toujours au garage | Haute |
| Lancement | Presse + premier retour + nouvelle fonction + crise SAV en même temps (crise corrigée) | Moyenne |
| Gamme | 21 modèles en vente dans la partie d'Alexandre, on ne retire jamais rien | Haute |
| Marché | Riche mais passif : seule action = répondre à un appel d'offres | Moyenne |
| Doublons | Produits › Concevoir = renvoi au Labo ; SAV présent deux fois ; Brevets = coquille | Moyenne |
| QG | Jusqu'à 3 bulles « Décision requise » empilées | Basse |
| Recrutement | Un candidat à la fois dans une liste déroulante | Moyenne |
| Presse | Textes variés maintenant, mais lecture seule (seule interaction : interview) | Basse |
| Argent en milieu de partie | S'accumule sans usage (22 M€ en 1985) ; puits ajoutés (marketing, usines) mais peu visibles | Moyenne |
| Équilibre long terme | Joueur passif 32 M€ en 2010, joueur investisseur 502 M€ : l'investissement paie (bon) | OK |
| Fin de campagne | Annonce « niveau technologique final » en place (2003-2010) ; peu à faire après | Moyenne |
| Déjà corrigé | Pages Fabriquer, Produits, Équipe, Contrats, Labo repliées ; presse moins répétitive ; SAV 12 % → 5-6 % | — |

## 3. Le plan, en 7 lots

Chaque lot se termine par : smoke test vert, sonde de progression (`progression_probe`) relancée,
build Android installé sur le Pixel, commit + push, note dans `docs/reviews/`.

### Lot A — Nettoyage et lisibilité (petit, 1 session) — ✅ fait le 29/09 (`docs/reviews/V09_LOT_A_NETTOYAGE.md`)

But : moins d'écrans en double, une seule chose à regarder à la fois.
- Supprimer Produits › Concevoir (le Labo suffit) → Produits = Fabriquer / Vendre / Supporter.
- Un seul écran SAV (garder Produits › Supporter, retirer Marché › SAV ou l'inverse).
- Brevets fusionné dans Labo › Recherche (un brevet = une découverte qu'on choisit de protéger).
- QG : une seule carte « À faire (n) » au lieu de bulles empilées.
- Lancement en séquence : tests de presse → (1 mois plus tard) premier bilan des ventes ; les
  annonces « nouvelle fonction » attendent la fin de la séquence.
- Déblocages par sous-page d'Entreprise : Aperçu au mois 2 ; Locaux quand la place manque ;
  Budgets après le 1er lancement ; Divisions à 10 salariés ; Groupe/filiales à 5 M€.

Critères : au mois 2 d'une partie neuve, Entreprise montre 1 sous-page ; jamais plus d'une fenêtre
bloquante au même mois pendant le 1er lancement (vérifié par la sonde).

### Lot B — Remplir le début de partie (moyen, 1-2 sessions) — ✅ fait le 29/09 (`docs/reviews/V09_LOT_B_DEBUT_DE_PARTIE.md`)

But : le premier CPU reste le fil rouge, mais le joueur a quelque chose à faire chaque minute.
- **Contrats de sous-traitance** (façon Game Dev Tycoon) pendant le 1er projet : « Delta Office veut
  une puce de calculatrice : 2 mois, 15 000 € ». Petits, courts, donnent argent + expérience ;
  occupent une partie de l'équipe (vrai choix : aller plus vite sur son CPU ou gagner de l'argent).
- Levier de trésorerie proposé par Nora quand il reste moins de 6 mois de réserve : petit prêt
  bancaire, avance d'un client, ou vendre un contrat de plus.
- Mettre en scène les deux moments forts de la vision : **« premier silicium »** (le prototype
  démarre ou non) et **« tri des puces »** (combien sortent en haut de gamme).
- Rythme cible mesuré : 1er CPU en 12 à 18 min réelles à vitesse normale, au moins une décision ou
  un événement par minute entre le mois 3 et le lancement.

Critères : la sonde ne montre plus de trésorerie < 30 k€ sans proposition de levier ; au moins
2 contrats proposés avant le 1er lancement.

### Lot C — Objectifs de Nora et paliers de locaux (moyen, 2 sessions) — ✅ fait le 29/09 (`docs/reviews/V09_LOT_C_OBJECTIFS_LOCAUX.md`)

But : le joueur sait toujours quoi viser, et le décor raconte sa progression.
- 3 objectifs affichés en permanence au QG, choisis selon le moment : « Lancer un 1er CPU »,
  « 1 000 ventes/mois », « Passer à 5 salariés », « Entrer sur le marché PC », « Déménager dans
  l'atelier », « Première usine », « Racheter un concurrent »…
- Récompense visible pour chaque objectif : réputation, argent, déblocage d'écran ou de décor.
- Paliers de locaux branchés sur les objectifs : garage → atelier → petit bureau/labo → PME →
  siège → campus R&D → grand groupe → empire. Chaque palier = nouveau décor au QG + plus de
  places d'équipe (la place limite l'équipe, cf. RECHERCHE_EQUIPES_V09) + un loyer (puits d'argent).
- Les 5 niveaux de progression visuelle de UX_ART_DIRECTION servent de guide pour les décors.

Critères : partie neuve jouée 48 mois → au moins 1 déménagement et 6 objectifs réussis ;
la partie d'Alexandre (1985, 22 M€) reçoit des objectifs adaptés à son niveau dès le chargement.

### Lot D — Gamme et marché actif (moyen, 2 sessions) — ✅ fait le 29/09 (`docs/reviews/V09_LOT_D_GAMME_MARCHE_ACTIF.md`)

But : le joueur agit sur le marché au lieu de le regarder.
- **Retirer du marché** : déstockage (prix bas pendant 2-3 mois) puis arrêt ; Nora le conseille
  quand une génération a plus de 3 ans ou vend moins de 5 % de la gamme.
- **Baisser le prix** d'une ancienne génération pour vider les stocks ou bloquer un rival.
- **Gammes créées par le joueur** (1 à 3 modèles par génération : entrée / milieu / haut),
  au lieu de modèles générés en nombre.
- **Guerre des prix / attaquer un rival** : cibler un segment tenu par un concurrent ; réponse
  de l'IA (baisse de prix, pub, sortie anticipée).
- Recrutement : « Nora a trouvé 3 profils » (expert cher, junior prometteur, généraliste).

Critères : la partie d'Alexandre peut passer de 21 à ≤ 8 modèles en vente en quelques clics ;
un concurrent réagit visiblement (presse + prix) quand on attaque son segment.

### Lot E — Refonte R&D V09 (gros, 3-4 sessions, déjà décidé le 28/09) — ✅ fait le 29/09 (`docs/reviews/V09_LOT_E_EQUIPES_ARCHITECTURE.md`)

But : le cœur du jeu devient la gestion d'équipes et d'architectures, comme prévu.
- Architecture de base + usure (au bout de quelques générations, elle freine) → choix tick-tock.
- Équipes R&D par axe Vitesse / Énergie / Fiabilité, avec individus, formation, experts,
  responsables ; l'équipe dev propose les modèles, retour d'expérience entre générations.
- 5 étapes Idée → Conception → Prototype → Production → Lancement, chacune de 1 à 3 min.
- Garder la compatibilité des sauvegardes (migration de la partie d'Alexandre obligatoire).

Critères : smoke test + scénario dédié ; la sauvegarde de 1985 se charge sans perte ; un joueur
qui investit dans une équipe voit l'effet sur la génération suivante.

### Lot F — Après 2010 : la partie continue (moyen-gros, 2-3 sessions)

But : une fois le plafond technologique atteint, d'autres systèmes prennent le relais.
- **Rachats** de concurrents (fragiles ou en difficulté) et **filiales** avec leur propre mandat.
- **Événements de marché** : pénurie de silicium, crise économique, nouvelle norme, boom d'un
  secteur, procès de brevets.
- **Salon annuel** (présentation, fuite, démenti de rumeur) = presse interactive.
- **Nouveaux marchés** sans nouvelle techno : Défense / aérospatial, diversification GPU / RAM / PC.
- **Prestige** : classement mondial, trophées de carrière, bilan « empire ».
- Ces systèmes servent aussi de **puits d'argent** en milieu de partie (le problème des 22 M€).

Critères : simulation 2010 → 2030 : au moins un événement par an, l'argent a toujours un usage,
les rivaux ne restent pas figés.

### Lot G — Finition (en continu)

- Délégation : préréglages Accessible / Standard / Simulation.
- Tutoriel court guidé par Nora (repose sur les objectifs du lot C).
- Passe Android : tailles de texte, zones de toucher, performances sur le Pixel 10.
- Relecture de tous les textes (français naturel, pas de jargon interne).

> **Ajout du 29/09 (audit `docs/reviews/V09_AUDIT_LEAD_TYCOON.md`)** : proposition d'un lot M
> « marché vivant et croissance qui paie » (courbes de vente, segments qui montent et descendent,
> projets plus gros pour les grandes équipes, presse qui attend mieux que la génération précédente,
> menaces) à placer avant ou avec le lot C. ✅ Fait le 29/09 (ChatGPT + Claude) :
> `docs/reviews/V09_LOT_M_MARCHE_VIVANT.md`. Prochain : lots B + C.

## 4. Ordre recommandé

1. **Lot A** (rapide, rend tout le reste plus lisible).
2. **Lot B + Lot C** ensemble : ce sont eux qui corrigent la première heure de jeu, la plus
   importante selon la vision.
3. **Lot D** : règle le problème des 21 modèles et donne des gestes de tycoon.
4. **Lot E** : grosse refonte, à faire quand la structure (objectifs, déblocages) est stable.
5. **Lot F** : fin de partie et longévité.
6. **Lot G** en fil rouge.

Alternative si Alexandre préfère attaquer le cœur tout de suite : A → E → B/C → D → F
(plus risqué : on refait la R&D avant d'avoir corrigé le rythme du début).
