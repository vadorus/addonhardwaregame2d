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

Le joueur choisit librement ses branches **pilotées directement**. Les autres restent opérationnelles en **gestion automatique courante, sans devoir recruter ni configurer un directeur**. Il peut reprendre une branche et en automatiser une autre, sans réinitialiser projets, équipe, contrats, soutien produits ni marque. **Nommer un directeur qualifié est une amélioration optionnelle du pilotage**, pas un prérequis d'autonomie.

Au-delà de la limite d'attention, les branches excédentaires passent automatiquement en gestion courante ; **aucune boîte de dialogue obligatoire de recrutement ou de paramétrage**. Le socle est une routine institutionnelle prudente (avec frais généraux normaux), pas un expert gratuit. Sans directeur compétent, l'autonomie est moins inventive et moins performante ; le joueur peut recruter ou promouvoir pour augmenter la qualité du pilotage. Pas de blocage des branches sans chef nommé.

## 3. Modes

| Mode | Ce que fait le joueur | Ce que fait la division |
|---|---|---|
| **DIRECT** | Projets et grandes décisions de gameplay, développement interactif, lancement, support | Simulation produit habituelle, comme aujourd'hui |
| **SUPERVISÉ** | Détermine stratégie et approuve certaines décisions majeures ; peut ouvrir un projet pour le piloter ponctuellement | Directeur gère les opérations récurrentes et prépare les décisions |
| **AUTONOME** | Ne fait rien au quotidien sauf exception ou demande de changement d'orientation ; peut nommer un directeur, fixer un mandat | Système de gestion courante (ou directeur nommé) poursuit projets, versions, ventes et support par les mêmes règles que le joueur, mais avec initiative limitée en l'absence d'expertise |

Le mode autonome **doit être opérant sans configuration préalable** : il ne suffit pas d'ajouter des bonus, d'afficher des alertes ou de trier des décisions. La division doit progresser réellement, générer les flux de trésorerie et pouvoir faire des choix admissibles sans un clic du CEO chaque mois.

Rendre le contrôle réversible depuis l'écran Entreprise → Divisions. Changer de mode **ne réinitialise pas** le pipeline et n'accorde pas un bonus rétroactif. Une passation peut générer un léger effet temporaire intelligible, sans punir excessivement les expérimentations.

## 4. Directeur : personne et non mode magique

Un directeur nommé est une **option de spécialisation et d'optimisation**, pas une condition d'accès à l'automatisation. Lorsqu'il est nommé, c'est un personnage de l'entreprise : identité, expérience, compétences techniques/financières/humaines, risque, affinité secteur, expérience de management, loyauté et traits de comportement **en jeu**. Exemple : excellent ingénieur CPU devenu directeur novice, ou expert financier efficace mais techniquement prudent.

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


## 12. Correction d'orientation validée le 8 octobre : automatisation d'abord

**Cette section prévaut sur toute formulation ancienne suggérant qu'une division supplémentaire exige un directeur nommé ou des paramètres de mandat.** La demande du joueur est de simplifier le système et d'éviter plusieurs modes de difficulté figés. Dès que le joueur dépasse le nombre acceptable de branches dirigées (hypothèse : deux, éventuellement trois après essais), une branche sort du pilotage direct et continue **automatiquement** ses opérations de base. Le joueur choisit quelle branche il conserve en direct. Aucune démarche administrative pour assurer la survie de l'autre branche.

### Trois mécanismes à dissocier

1. **Gestion automatique interne** : la division et ses salariés appartiennent au groupe. Une politique minimale de continuité (finir le projet en cours, ventes, maintenance, support de parc, mise à niveau prudente et renouvellement de gamme raisonnable) fonctionne sans administrateur explicite.
2. **Directeur nommé** : personnage du groupe qui améliore et spécialise cette autonomie ; coût salarial, expérience, faculté de déléguer des choix plus ambitieux, risques personnels. Son recrutement n'est **pas un verrou**.
3. **Sous-traitance industrielle/externe** : prestataire tiers effectuant une tâche de conception, de fabrication, de test, d'hébergement, de support ou de R&D. Cette opération implique prix, qualité, délai, dépendance, confidentialité et compétence du partenaire. Elle **ne doit jamais être confondue avec une branche automatique**.

### Algorithme de continuité sans résultats miraculeux

Une division laissée en pilotage automatique :
- achève les contrats et produits déjà engagés, gère les retours et le support existant ;
- continue les cycles commerciaux, la maintenance, les patchs et des améliorations modestes ;
- peut préparer/remplacer une gamme vieillissante en fonction de fonds disponibles, maturité et mandat par défaut ;
- choisit des projets de taille raisonnable sur ses compétences connues ; n'invente pas une technologie jamais recherchée par le groupe ;
- peut générer **des bénéfices comme des pertes** suivant marché, position concurrentielle, investissements et compétence ;
- subit des retards, prend du retard technologique ou perd des clients si son budget est trop faible ou ses choix sont inadaptés ;
- ne bénéficie pas d'un mécanisme de rattrapage invisible ni de performances offertes gratuitement.

La simulation doit être identique économiquement à celle du joueur : mêmes prix, mêmes coûts, mêmes délais, mêmes limitations techniques et mêmes risques. Si le joueur dirige en personne, il a davantage de choix *et de risques*, pas un bonus de puissance arbitraire.

Le groupe expose seulement un **résumé des divisions automatiques** et signale les exceptions dépassant leurs pouvoirs financiers ou les risques majeurs. Les décisions routinières ne doivent pas envahir la boîte du CEO.

### Activation progressive à tester

- Au lancement : une branche directe, le reste verrouillé selon la progression historique.
- À 2 branches : essayer en gameplay le choix libre de pilotage direct des deux **ou** d'une seule, toutes les autres restant automatiques.
- À 3 branches et plus : passage automatique à 2 branches directes (hypothèse), avec choix utilisateur des deux emplacements de pilotage. Tester la possibilité d'une 3e branche directe légère sur Pixel.
- À 10–15 branches : vue synthétique groupe, changement de contrôle en un geste, journal de passation, aucune perte d'historique.

L'automatisation est un **système de confort intégré au jeu**, non un réglage « facile » versus « difficile ». Ce n'est pas le nombre de divisions qu'on possède qui mesure la difficulté, mais la profondeur des décisions qu'on veut prendre soi-même.

## 13. Chaîne de valeur entre branches et commandes internes

Exemple de **fiction de gestion industrielle**, sans simulation tactique de systèmes militaires : une future branche navale/défense décroche un contrat de système informatique embarqué destiné à un sous-marin. Elle a besoin d'un CPU compatible avec contraintes de fiabilité, consommation, stabilité à long terme et sécurité de la chaîne d'approvisionnement.

La division concernée peut :
- **réutiliser un CPU commercial** déjà développé dans le groupe, avec adaptations logicielles et qualification supplémentaires ;
- **commander une variante CPU dédiée** auprès de la branche CPU, exploitant les connaissances et outils préalablement débloqués, mais mobilisant R&D, validation et capacité de production réelles ;
- **acheter des composants ou licences externes**, sous réserve des exigences du client et des fournisseurs disponibles ;
- **concevoir en interne mais faire fabriquer chez une fonderie partenaire**, ce qui sépare souveraineté de conception et souveraineté de fabrication ;
- utiliser une **fab interne** si la société en possède une, avec coûts fixes, capacités et limitations technologiques ;
- choisir une **fonderie extérieure qualifiée et contrôlée**, ce qui peut être acceptable pour un marché sensible si la traçabilité, la certification et la vérification satisfont les exigences.

### Scores et flux à suivre

Chaque sous-projet comporte : `required_technologies`, `owned_ip`, `licensed_ip`, `hardware_compatibility`, `internal_capacity`, `fabrication_route`, `qualification_level`, `supply_chain_assurance`, `lead_time`, `cost`, `technical_performance`, `reliability`, `support_horizon`, `compliance_for_target_market`.

**La propriété de la fab n'accorde pas automatiquement un score de sécurité maximal.** La confiance dépend aussi du personnel, des audits, de la provenance des pièces/outils, du contrôle de la chaîne de possession, des inspections, de la validation, de la gestion de confidentialité et de la continuité d'approvisionnement. Inversement, un fournisseur externe qualifié peut être digne de confiance. Il faut éviter l'équation fausse « tout fabriqué chez soi = 100 % sûr ».

Proposition de gamification : **maîtrise de la chaîne** en 4 sous-scores lisibles — maîtrise du design/IP, contrôle/traçabilité de la fabrication, assurance/qualification, dépendance fournisseurs. Le score global est spécifique aux exigences du contrat et explicable dans l'aperçu, sans technologies de sécurité sensibles réelles à implémenter.

Les ramifications interbranches :
- La branche CPU reçoit un **contrat interne** et mobilise réellement ses ressources ;
- La branche navale/défense paie au prix de transfert interne ou via allocation analytique ; **interdiction de compter deux fois le bénéfice consolidé du groupe** ;
- Le CPU personnalisé gagne des caractéristiques pertinentes pour l'usage ciblé, **pas des bonus de puissance universels** ;
- Software peut proposer pilotes, firmwares, outils de diagnostic ou correctifs adaptés aux CPU existants ;
- Fonderie/production engage le même stock de capacité pour projets commerciaux et internes ;
- La réussite apporte expérience, crédibilité client et parfois propriété intellectuelle réutilisable, mais peut détourner des ressources de la gamme grand public.

**Le prix du choix** : la solution la plus intégrée peut coûter beaucoup plus cher en investissements, être technologiquement moins avancée ou prendre du retard. Le fournisseur externe peut offrir meilleur rendement/coût/vitesse malgré une dépendance plus forte. Tous les chemins doivent être jouables et défendables.

### Essais de validation à ajouter après tranche CPU

1. Deux divisions actives, une automatique **sans leader nommé** : ventes, SAV et progression continue, sans entrée CEO obligatoire.
2. Commutation CPU → Software → CPU : les projets et les versions restent cohérents ; seules les futures décisions changent de propriétaire.
3. Sur plusieurs années, divisions automatiques normalement compétentes **mais non surpuissantes**, avec possibilité vérifiée de profits, pertes et retard.
4. Un contrat interne spécialisé utilise **uniquement** des technologies réellement possédées/licenciées et des ressources disponibles.
5. Trois voies de fourniture : composant standard du groupe, variante sur mesure interne, fournisseur externe qualifié ; coûts/délais/fiabilité et maîtrise de chaîne varient.
6. Fab interne **non suffisante** pour satisfaire automatiquement un client exigeant ; audits/qualifications nécessaires ; une chaîne tierce vérifiée peut être acceptée.
7. Pas de double comptabilité : consolidation bénéfice net groupe sans double revenus internes ; coûts et transfert par division traçables.
8. Anciennes sauvegardes : pas de nouveau verrou si le joueur possède déjà des divisions en mode `DIRECT`.
