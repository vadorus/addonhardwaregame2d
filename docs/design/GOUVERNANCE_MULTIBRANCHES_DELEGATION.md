# Tech Empire — Gouvernance d'un groupe multi-branches et délégation réelle

> **Statut : vision de game design / spécification, pas implémenté ni validé en gameplay.**
> 8 octobre 2026. Branche source inspectée : `v013/demo-octobre` (`7f9228b`).
> Document complémentaire : `SOFTWARE_ECOSYSTEME_HARDWARE_CROSSPLAY.md`.
> Priorité court terme : démo CPU. Les branches spatiale, GPU, etc. restent des pistes **futures**, non des demandes de les implémenter avant validation CPU (`AGENTS.md`).

## 1. Thèse centrale

Tech Empire doit permettre de bâtir **10 à 15 divisions ou davantage sur une très longue partie**, chacune avec ses propres produits, générations, équipes, projets, marchés, technologies et cycles de vie. La profondeur et les synergies servent la rejouabilité, **sans obliger le joueur à microgérer 15 divisions**.

La durée de vie ne doit pas provenir de tâches répétées ou de temps d'attente artificiels. Elle vient :
- d'une liberté de spécialisation ;
- de branches aux boucles vraiment différentes ;
- de nombreuses trajectoires historiques/technologiques ;
- d'une économie durable où les anciens produits continuent à compter ;
- de choix de délégation, de priorités et de portefeuille ;
- d'interactions entre les découvertes des différentes branches.

**Une entreprise peut travailler sur toutes ses branches, le joueur ne doit pas être forcé de travailler sur toutes en même temps.**

## 2. Capacité d'attention et contrôle des divisions

Hypothèse à tester : **2 branches complexes pilotées directement**, avec option **3e branche légère**. Ne pas graver immédiatement un maximum à 2 ou 3 en dur : valider avec essais Android/PC, nombre de choix, fatigue et durée des tours. La capacité pourrait être un budget d'attention calculé à partir de la complexité active :
- branche complexe (CPU, OS avancé, spatial futur) : coût d'attention élevé ;
- branche stabilisée/faible activité : moindre attention ;
- compétence de management et progrès d'interface peuvent augmenter modérément la capacité, sans rendre 15 divisions directes viables.

Le joueur choisit librement ses branches **pilotées directement**. Les autres fonctionnent avec un **directeur désigné** et un mandat. Il doit pouvoir reprendre une branche et en déléguer une autre, sans réinitialiser projets, équipe, contrats, soutien produits ni marque.

Au-delà de la limite d'attention, l'interface demande de désigner un directeur sur les branches excédentaires. S'il manque un salarié qualifié, proposer responsable intérimaire/supervision restreinte ou recrutement, avec coût et risques visibles ; ne pas créer instantanément un directeur expert gratuit. Il ne doit pas être possible de contourner la limite en laissant des branches sans responsable ni en choisissant un mode non opérant.

## 3. Modes

| Mode | Ce que fait le joueur | Ce que fait la division |
|---|---|---|
| **DIRECT** | Projets et grandes décisions de gameplay, développement interactif, lancement, support | Simulation produit habituelle, comme aujourd'hui |
| **SUPERVISÉ** | Détermine stratégie et approuve certaines décisions majeures ; peut ouvrir un projet pour le piloter ponctuellement | Directeur gère les opérations récurrentes et prépare les décisions |
| **AUTONOME** | Mandat stratégique, allocation du capital, remplacement du directeur, exceptions majeures | Directeur planifie et exécute les projets successifs, mises à jour, ventes, contrats et soutien produit selon ses compétences et ses limites |

Le mode autonome **doit être opérant** : il ne suffit pas d'ajouter des bonus, d'afficher des alertes ou de trier des décisions. La division doit progresser réellement, générer les flux de trésorerie et pouvoir faire des choix admissibles sans un clic du CEO chaque mois.

Rendre le contrôle réversible depuis l'écran Entreprise → Divisions. Changer de mode **ne réinitialise pas** le pipeline et n'accorde pas un bonus rétroactif. Une passation peut générer un léger effet temporaire intelligible, sans punir excessivement les expérimentations.

## 4. Directeur : personne et non mode magique

Un directeur est un personnage de l'entreprise : identité, expérience, compétences techniques/financières/humaines, risque, affinité secteur, expérience de management, loyauté et traits de comportement **en jeu**. Exemple : excellent ingénieur CPU devenu directeur novice, ou expert financier efficace mais techniquement prudent.

Chaque directeur a une **politique accessible et modifiable** :
- priorité : performance, innovation, fiabilité, efficacité, croissance ;
- cible : segments clients/produits ;
- plafond budget mensuel et projets exceptionnels ;
- limite risque et qualité minimale ;
- maintien anciens produits / fréquence générations ;
- tolérance à l'endettement, sous-traitance, partenariats ;
- règles d'escalade (lancement crucial, investissement majeur, crise de réputation).

Sans microgestion, le CEO doit comprendre **pourquoi** son directeur a pris une décision et quelle valeur cela a produit. Une bonne personne fait mieux dans sa spécialité, pas automatiquement mieux partout.

### Exemple
En 2005, le CEO confie la division CPU au directeur ingénieur Luc, mandat « support ancien parc + renouvellement de la gamme, budget limité, risque modéré ». Luc continue les ventes et le SAV, lance des projets compatibles avec son mandat, fait corriger un erratum BSM3 par l'équipe firmware et prépare BSM4 quand la gamme vieillit. Il remonte un arbitrage si une nouvelle usine exige un investissement au-delà de son plafond. Le CEO travaille en parallèle sur la nouvelle division spatiale **future**.

## 5. Autonomie réelle : boucle mensuelle explicable

Chaque mois, pour chaque division active déléguée :
1. **Observer** portefeuille produits/projets/clients, demande, concurrents, argent disponible, RH, capacité, incidents, opportunités de synergies.
2. **Planifier** des actions admissibles selon mandat, période historique, technologies débloquées et capacité réelle.
3. **Exécuter** via les **mêmes managers/mêmes formules** que le joueur : R&D, projets, industrialisation, marketing, contrat, patch, SAV. Pas de raccourcis magiques ni de revenus fictifs.
4. **Réagir** : incidents, arbitrage d'équipe, retards, baisse de ventes, nouvelle génération, évolutions du marché.
5. **Rendre compte** : actions, dépenses, évolution KPI et motivations lisibles dans un journal de division.
6. **Escalader** seulement si risque/exposition dépasse le mandat, si la crise impacte d'autres branches ou si le CEO doit choisir une orientation à long terme.

**Règle anti-attente** : le directeur ne doit pas attendre indéfiniment la permission de lancer chaque CPU majeur ou chaque version logicielle ; les décisions de routine entrent dans son mandat. **Règle anti-surprise** : il ne peut pas dépenser sans plafond ni fusionner/fermer une activité centrale sans l'accord du CEO.

## 6. Portfolio, synergies et bénéfices croisés

Un projet peut produire des effets spécifiques **pour plusieurs divisions**, avec coûts de transfert, compatibilité et calendrier.

### Exemples
- Branche CPU → calcul embarqué, puissance de simulation et historique de revenus utiles à une future activité spatiale ; ne fournit **pas gratuitement** les compétences en systèmes spatiaux, sécurité et validation.
- Branche Software → outils internes R&D, bancs de validation, simulation, microcode, pilotes et SDK CPU, avantage propriétaire ciblé ; maintenance et spécialistes nécessaires.
- Branche GPU future → besoin d'OS/pilotes et de capacités de fabrication, opportunités de coopération CPU/Software.
- Branche datacenter → besoin de serveurs/réseaux, avantages et débouchés pour CPU et logiciels serveur.
- Branche spatiale future → hardware embarqué, logiciels de commande et fiabilité extrême, mais marchés et contraintes spécifiques.

Les actifs sont persistants : clientèle installée, familles de brevets/technologies lorsqu'applicable, savoir-faire, usine/chaîne industrielle, contrats, réputation, licences, partenariats et revenus. Passer le CPU en mode autonome ne fait pas disparaître les BSM2/BSM3 ni leur support.

La **valeur des autres branches** doit s'observer dans les bilans : bénéfices réels, réduction de coûts, fiabilité, temps R&D gagné, compétitivité et opportunités ouvertes. Effets synergiques non interchangeables et non multiplicatifs à l'infini.

## 7. PDG : un autre jeu, pas une grille de notifications

Avec 10–15 branches, interface **carte du groupe** :
- tableau de bord unique, 5 indicateurs pertinents par division, projets phares, cycle de vie et risques ;
- affichage visuel du QG / des implantations et repères spatiaux, sans imposer un déplacement libre 3D ;
- commandes simples « Piloter », « Superviser », « Déléguer », « Donner mandat », « Changer directeur » ;
- bilans trimestriels ou annuels, rapport mensuel compact et événements majeurs ;
- alertes classées par gravité et **regroupées**, pas dix dialogues chaque tour ;
- tableaux de synergies : dépendances CPU→logiciels, logiciels→CPU, CPU→serveurs, etc. ;
- possibilité de replonger dans une branche pour un projet exceptionnel sans provoquer une avalanche de décisions sur les autres.

Quand le joueur revient de cinq ans de spatial vers CPU, proposer un **récapitulatif de passation** : produits nouveaux, générations retirées, clientèle, problèmes SAV, investissements, concurrents, décisions du directeur. Le joueur récupère la pleine main immédiatement sur les opérations futures.

### Intrigues jouables de gouvernance
- Un directeur prudent a sauvé la fiabilité CPU mais a perdu le leadership performance.
- Le directeur Software vend un outil générant du profit, mais le labo CPU réclame qu'il soit adapté aux BSM3.
- Un marché serveur stratégique exige une capacité que deux divisions se disputent.
- La division historique continue à soutenir ses utilisateurs, améliorant réputation et fidélisation.
- Le CEO préfère arrêter une gamme mature pour financer une division innovante : arbitrage lourd, conséquences sociales et commerciales.

## 8. Structure de code à prolonger (constat au 08/10/2026)

`scripts/DivisionManager.gd` **existe** et propose :
- `CONTROL_MODES = [DIRECT, SUPERVISED, AUTONOMOUS]` ;
- un `leader_id`, mandat (priorité, budget, risque, qualité/croissance), compétence de management calculée, journal et remontées ;
- un traitement mensuel des divisions déléguées, mais **principalement de surveillance** (plafonds budgétaires, risque, fournisseur, absence de produits, lancement en attente).
- `_process_division_month` précise même que le directeur **ne lance pas seul une nouvelle génération structurante** et que le CEO garde le lancement commercial.

`scripts/CeoDefaults.gd` règle des décisions prudentes quand la boîte de décisions déborde ; **ce n'est pas un directeur autonome**.

**Verdict technique : gouvernance et délégation partiellement modélisées ; autonomie productive sur 10–15 branches ni mise en œuvre ni validée.** Ne pas confondre un multiplicateur `management_modifier` avec une simulation autonome.

Prochaine architecture : étendre `DivisionManager` avec **policy planner déterministe**, commandes d'actions typées via managers existants, validations économiques, journal de décision, test de non-régression. Ne pas déclencher un `ResearchManager` CPU sur une division Software par défaut.

## 9. Plan de déploiement, sans sacrifier le jeu actuel

**Phase CPU démo (immédiate)** : stabiliser la tranche CPU, fiabilité/UX/économie et le gameplay de choix. Aucune expansion GPU/spatial pour l'instant.

**Phase directeur CPU (premier incrément réel)** : un directeur CPU prend un mandat simple et sait au minimum poursuivre la gamme, vendre, maintenir, soutenir le parc client, préparer puis lancer un projet CPU via les chemins du joueur. Test comparatif DIRECT/AUTONOMOUS sur graines fixes. Garder les actions stratégiques hors plafond en escalade.

**Phase CPU + Software** : deux divisions réellement opérantes ; l'une pilotée, l'autre déléguée ; commutation libre ; microcode/pilote/outils internes et synergies. Simuler plusieurs années pour vérifier que les affaires continuent.

**Phase attention** : tester 2 branches complexes pilotées puis 3, mesurer le nombre de décisions significatives, la charge cognitive, les oublis de projets, la satisfaction et la durée d'une année en jeu. Choisir le plafond selon l'expérience, pas arbitrairement.

**Phase portefeuille 5 puis 10–15 divisions** : nouveaux archétypes, directeurs spécialisés, équipes, états persistants, marchés et synergies, map de groupe. Ajouter les secteurs futurs au rythme de systèmes réellement distincts, sans catalogue vide.

## 10. Tests d'acceptation : interdiction de simuler l'autonomie sur le papier

- 2 branches, une en direct et l'autre déléguée : progression mois après mois et bilan cohérent.
- Alternance du pilotage entre CPU et Software **en pleine production** : aucune perte de projet, contrat, génération, version, installation active ou historique.
- Directeur autonome : lance au moins un projet pertinent, maintient l'ancien produit, commercialise et gagne/perd de l'argent **par les voies communes**, sans intervention manuelle lors de tâches couvertes par mandat.
- Directeur prudent vs audacieux : stratégies comparables sur les mêmes graines, compromis risques/qualité/profit mesurables, pas de supériorité systématique d'une personnalité.
- Manque de trésorerie : pas de dépenses au-delà du plafond autorisé, pas de génération miraculeuse d'argent.
- 5 puis 10–15 divisions pendant 10+ années simulées : fluidité sur PC et Pixel, économie, sauvegarde, décisions stratégiques visibles et charges d'alertes contenues.
- Cas BSM3 : support et correctif post-lancement opérés par le directeur et retombées chez les utilisateurs existants ; bonus conservateurs et compatibles.
- Anciennes sauvegardes : migration sans effacement de `DivisionManager`, `CompanyManager`, produits/projets et données du joueur.
- Exécution réelle Godot et tactile Pixel obligatoires avant qualification PASS ; ce document n'en tient pas lieu.

## 11. Arbitrages encore ouverts (à éprouver)

1. Deux branches directes fixes, ou budget d'attention permettant deux branches lourdes plus une légère ?
2. Autonomie complète avec lancement produits de routine, mais consentement explicite pour investissements extraordinaires ?
3. Rapports mensuels compactés et rendez-vous trimestriels, ou autre cadence selon rythme réel des mois ?
4. Spécialité du directeur et maturité de la division : impact raisonnable, sans rendre l'autonomie punitive.

Privilégier l'option qui produit **le plus de décisions intéressantes à long terme**, pas celle qui affiche le plus de paramètres.
