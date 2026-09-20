# Bible de conception — Tech Empire

> Document canonique des décisions de conception prises avec le créateur du jeu. Il décrit la cible complète sans élargir prématurément la version jouable : la branche CPU reste la seule branche active tant que sa boucle n'est pas aboutie.

## 1. Promesse du jeu

Tech Empire est une simulation de direction d'entreprise technologique. Le joueur part de presque rien, construit une première équipe, développe une expertise, lance des produits, assume leurs conséquences puis transforme progressivement sa petite structure en groupe technologique.

Le plaisir recherché repose sur quatre sensations :

- comprendre pourquoi un produit réussit ou échoue ;
- voir l'entreprise, les bureaux, les équipes et les technologies évoluer ;
- prendre des décisions importantes sans remplir un tableur interminable ;
- pouvoir gérer personnellement les sujets que l'on aime et déléguer les autres.

Le jeu n'impose pas de fin définitive. Les grandes réussites ouvrent de nouveaux terrains : marchés, divisions, projets communs, défis environnementaux, contrats stratégiques et monde en ligne optionnel.

## 2. Principes non négociables

1. **Une simulation commune.** Les modes accessible et expert utilisent les mêmes règles. La délégation change la quantité de microgestion, pas la réalité du monde.
2. **Une décision, une conséquence lisible.** Le joueur doit comprendre le lien entre choix, coût, délai, qualité, risque, réputation et résultat commercial.
3. **Profondeur progressive.** Les détails sont révélés quand ils deviennent utiles. Les chiffres avancés restent accessibles, mais les écrans principaux montrent les décisions.
4. **Le CPU d'abord.** Les futurs secteurs sont documentés et prévus dans les données, mais ne doivent pas détourner le développement de la vertical slice CPU.
5. **Une entreprise vivante.** Les personnes, rapports, découvertes, avis clients, médias, fournisseurs et incidents donnent un visage à la simulation.
6. **Une progression visible.** Une entreprise modeste doit paraître modeste ; sa montée en gamme doit se voir dans les locaux, les outils, les sons et la qualité de l'interface.
7. **PC et mobile, même jeu.** La densité et la disposition changent, pas les systèmes de fond.

## 3. Boucle principale

**Observer → décider → financer → rechercher → concevoir → valider → industrialiser → lancer → vendre → supporter → apprendre → préparer la génération suivante.**

Chaque étape produit des informations et des décisions pour l'étape suivante. Une génération imparfaite peut rester utile : elle fait gagner de l'expérience, révèle une technologie, développe la marque ou finance un meilleur projet.

## 4. Modèle commun de l'entreprise

Le moteur doit distinguer les objets suivants :

| Objet | Rôle dans la simulation | Exemple CPU |
|---|---|---|
| Technologie | Savoir-faire réutilisable | architecture, cache, interconnexion |
| Composant | Élément intégrable dans plusieurs produits | chiplet CPU, contrôleur mémoire |
| Produit | Offre vendue avec prix et cycle de vie | processeur grand public |
| Service | Offre continue ou récurrente | cloud, abonnement logiciel |
| Plateforme | Base accueillant plusieurs générations/offres | socket + chipset + outils |
| Infrastructure | Actif qui rend une activité possible | laboratoire, fab, datacenter |
| Division | Unité stratégique possédant équipe et portefeuille | division processeurs |
| Marque | Identité commerciale visible du client | marque grand public du groupe |
| Filiale | Entité juridique ou opérationnelle du groupe | fonderie acquise |

Cette séparation autorise les synergies sans confondre les métiers. Une architecture CPU peut devenir un composant, alimenter un serveur, accélérer une branche IA et être licenciée à un partenaire.

### Trésorerie, propriété et maturité financière

La simulation distingue strictement **la trésorerie** de **la valeur de l'entreprise**. La trésorerie est l'argent immédiatement disponible pour payer R&D, salaires, production, support et autres charges. Une valorisation élevée, une réputation forte ou une future capitalisation boursière ne remplacent jamais des liquidités disponibles.

La Bourse n'est pas accessible au démarrage. Une jeune entreprise commence avec son capital et ses financements privés. Les possibilités financières se débloquent avec la maturité du groupe :

- capital initial et trésorerie ;
- emprunts et investisseurs privés ;
- levées de fonds plus importantes lorsque l'entreprise est établie ;
- introduction en Bourse seulement lorsqu'un niveau suffisant de taille, historique, réputation et gouvernance est atteint ;
- après cotation : capitalisation, cours de l'action, dilution, dividendes, rachats d'actions et pression des investisseurs deviennent des systèmes distincts.

La propriété des sociétés doit également pouvoir évoluer à long terme. Le joueur pourra créer des filiales ou entreprises, céder une participation ou vendre une société, conserver ou perdre le contrôle selon la transaction, puis tenter un rachat ultérieur lorsque les conditions le permettent.

Un futur système **Groupe & Succession** permettra la transmission à un héritier, la direction d'une filiale par un descendant, la création d'entreprises familiales distinctes et l'évolution de ces entités en partenaires ou concurrents. Ce système appartient au moyen/long terme et ne doit pas alourdir la vertical slice CPU.

## 5. Divisions et diversification

Une entreprise peut posséder plusieurs divisions : CPU, serveurs, logiciel, cloud, IA, robotique ou autres branches futures. Une division comprend au minimum :

- un état : verrouillée, en création, active, en pause ou cédée ;
- une maturité et une expérience accumulée ;
- une stratégie ;
- un responsable et un niveau de délégation ;
- des équipes et infrastructures affectées ;
- un budget et un portefeuille de projets ;
- des technologies possédées, partagées ou licenciées ;
- des dépendances envers d'autres divisions ou fournisseurs.

### Règle de la vertical slice

La première version n'active que la division CPU. Le moteur peut connaître les futures branches, mais il refuse leurs projets tant que leur contenu n'est pas jouable. Cette frontière évite les écrans vides et les systèmes superficiels.

### Coût réel de la diversification

Ouvrir une division apporte de nouvelles recettes et des synergies, mais augmente :

- les coûts fixes ;
- les besoins en recrutement ;
- la complexité de coordination ;
- le risque de dilution du savoir-faire ;
- le nombre de crises simultanées ;
- la dépendance à certains composants ou infrastructures.

Le joueur peut rester un spécialiste très performant. Devenir un conglomérat n'est pas automatiquement la meilleure stratégie.

## 6. Délégation : la difficulté choisie pendant la partie

Chaque département ou division peut utiliser l'un de ces niveaux :

| Niveau | Rôle du joueur | Rôle du responsable |
|---|---|---|
| Direct | Règle les décisions importantes et avancées | Conseille et signale les risques |
| Supervisé | Fixe objectifs, budget et limites | Prépare des plans et demande des arbitrages |
| Autonome | Définit la stratégie générale | Exécute, optimise et envoie des synthèses |

Le joueur peut changer ce niveau à tout moment, sans recommencer une partie. Il peut gérer la R&D en détail tout en automatisant marketing, production ou SAV, puis reprendre la main plus tard.

Un responsable n'est pas un bouton magique. Sa compétence, son expérience, son caractère et son style de management influencent :

- la qualité des décisions automatiques ;
- la précision et la longueur des rapports ;
- la vitesse de réaction ;
- le moral, la cohésion et le turnover ;
- la prudence face aux risques ;
- le respect du budget et des objectifs.

Un chef très strict peut produire des rapports précis et tenir les délais, tout en épuisant son équipe si l'entreprise n'offre pas un bon cadre de travail.

## 6A. Onboarding progressif, bras droit et comité de direction

La complexité de Tech Empire doit grandir au même rythme que l'entreprise et que l'apprentissage du joueur. Le jeu ne présente jamais tous ses systèmes dès le départ.

### Le garage comme phase d'apprentissage

La partie commence dans un petit garage ou bureau improvisé avec très peu de fonctions visibles. Le joueur pilote directement son premier domaine — CPU dans la vertical slice — et n'a accès qu'aux informations nécessaires au problème courant.

Les nouvelles fonctions apparaissent lorsqu'un événement concret les rend utiles : embauche d'une équipe → RH ; première industrialisation → Production ; premières ventes → Marché et SAV ; croissance de l'effectif → management ; seconde branche → Divisions et délégation. Les menus ne doivent pas être remplis dès le départ de boutons grisés annonçant des dizaines de systèmes futurs.

### Le bras droit est présent dès le début

Le bras droit / vice-président accompagne le joueur dès le garage. Il sert à la fois de guide contextuel, de filtre de complexité et de conseiller stratégique. Il doit :

- expliquer une nouvelle mécanique au moment où elle devient utile ;
- traduire les indicateurs techniques ou financiers en conséquences compréhensibles ;
- rappeler les risques importants sans donner une « bonne réponse » automatique ;
- résumer les décisions ouvertes et aider à les prioriser ;
- présenter plusieurs options avec leurs compromis ;
- signaler clairement l'incertitude lorsqu'il ne dispose pas d'assez d'information.

Au début, son rôle est proche d'un mentor. À mesure que le joueur maîtrise le jeu, ses interventions deviennent plus synthétiques et plus stratégiques.

### Une responsabilité directe obligatoire

Le joueur doit toujours piloter directement au moins un domaine, une division ou un programme important. Il peut déléguer le reste, mais le jeu ne doit jamais devenir totalement passif.

Le niveau de contrôle est défini séparément pour chaque domaine : direct, supervisé ou autonome. Le joueur peut donc gérer personnellement les CPU tout en confiant Mobile, IA, TV ou Spatial à des responsables.

### Directeurs de division et chefs de projet

Les divisions sont confiées à des directeurs qui reçoivent un mandat clair : budget, priorité, segment visé, niveau de risque, qualité attendue, politique de croissance et autonomie autorisée. Les chefs de projet pilotent ensuite des produits ou programmes précis.

Leur profil influence réellement les résultats : expertise technique, finance, innovation, gestion humaine, prudence, vitesse d'exécution, maîtrise des coûts, communication et capacité à détecter un problème tôt. Un bon responsable n'est pas un bonus fixe ; il prend de meilleures décisions dans les limites de son mandat.

### Comité de direction

Lorsque l'entreprise grandit, le comité de direction devient l'interface principale de synthèse. Il réunit le joueur, le bras droit et les responsables transversaux ou de division. Il remonte surtout trois catégories de sujets :

- information : aucun arbitrage nécessaire ;
- recommandation : un responsable propose une action ;
- arbitrage dirigeant : plusieurs options, budgets, équipes ou divisions sont en conflit et le joueur doit trancher.

Le comité doit éviter d'obliger le joueur à ouvrir dix écrans pour comprendre la situation de l'entreprise.

### Fonctions transversales

À mesure que la société grandit, des responsables spécialisés peuvent rejoindre la direction :

- RH : recrutement, conflits, départs, fatigue, satisfaction et avantages salariés ;
- Finance / DAF : trésorerie, budget, réserve de sécurité, financement et faisabilité des investissements ;
- Juridique / fiscal : contrats, implantation, propriété intellectuelle, réglementation, fiscalité et subventions ;
- Opérations / immobilier : bureaux, laboratoires, ateliers, capacité et environnement de travail.

Ils servent eux aussi de filtres pédagogiques. Par exemple, le DAF ne se contente pas de dire qu'un investissement est possible : il explique la trésorerie restante, les charges mensuelles et le risque associé.

### Avantages salariés et environnement de travail

La qualité de l'entreprise doit être visible et avoir des conséquences réelles. Le joueur peut améliorer les locaux, laboratoires et conditions de travail, ainsi que proposer des avantages adaptés au pays et à la taille de la société : mutuelle, primes, intéressement, formation, restauration, télétravail, espaces de repos, transport, crèche, activités d'équipe ou autres avantages.

Ces choix influencent attractivité, fidélisation, fatigue, absentéisme, productivité, recrutement et réputation employeur. Ils ne doivent pas se réduire à des niveaux abstraits du type « mutuelle +5 bonheur ».

### Principe d'interface

Comme dans un jeu où les capacités se débloquent progressivement avec la progression du personnage, Tech Empire ne montre au joueur que ce qu'il peut raisonnablement apprendre et utiliser à ce stade. L'entreprise peut devenir gigantesque après des dizaines d'heures sans que les trente premières minutes soient intimidantes.

La règle UX associée est : **simulation profonde derrière, décisions limitées et lisibles devant**.

## 7. Équipes, expérience et découvertes

Les employés possèdent des compétences générales, des spécialisations, de l'expérience de domaine, du leadership, du moral et une aptitude d'apprentissage. Ils disposent aussi de profils semi-aléatoires cohérents avec leur métier : rigueur, résolution de problèmes, travail en équipe, résistance au stress, créativité et qualité de process. Ces valeurs doivent influencer les systèmes concernés et ne pas rester décoratives. Les équipes progressent en travaillant réellement sur un sujet.

Pendant un projet, elles peuvent :

- améliorer une technologie connue ;
- découvrir une piste de recherche ;
- proposer une architecture inattendue ;
- réduire une contrainte thermique ou électrique ;
- trouver un matériau, un procédé ou une méthode de test ;
- débloquer un projet de R&D séparé ;
- détecter tôt un défaut ;
- créer une invention brevetable ;
- échouer ou produire une fausse piste.

Une découverte doit être liée au travail, à la spécialisation de l'équipe, à son équipement et à son niveau. Elle ne tombe pas au hasard sans explication.

## 7A. R&D produit, R&D Concept et apprentissage technique

La recherche CPU est séparée en deux intentions complémentaires.

### R&D produit / publique

Elle transforme les connaissances déjà suffisamment maîtrisées en produits commercialisables. Elle cherche un compromis viable entre performance, consommation, fiabilité, coût, délai et capacité industrielle.

### R&D Concept CPU

Elle sert de laboratoire avancé, comparable au rôle d'un programme de compétition dans l'automobile : le but n'est pas nécessairement de vendre immédiatement le prototype, mais de préparer des technologies qui pourront migrer vers les produits futurs.

Un programme Concept choisit quelques axes prioritaires : très basse consommation, performance, miniaturisation, fiabilité, architecture des circuits, interconnexions, matériaux, packaging ou autres domaines débloqués. Les résultats progressent par étapes : compréhension, prototype, technologie transférable, puis industrialisation éventuelle.

Une entreprise riche peut donc investir pendant plusieurs années dans un concept optimisé pour le mobile et obtenir plus tard un avantage majeur sur téléphones, portables ou systèmes embarqués. Ce n'est pas un bonus abstrait : la technologie découverte modifie ce que les équipes peuvent réellement recommander et construire.

### Départ historique et évolution non scriptée

La partie doit commencer au début de l'ère des microprocesseurs, avec des technologies cohérentes avec cette période. L'histoire réelle sert de point de départ physique et pédagogique, pas de calendrier obligatoire.

Le joueur n'est pas forcé de reproduire exactement l'évolution historique. En investissant dans des domaines précis — architecture de circuits, cartographie/layout, procédés, matériaux, consommation ou autres — il peut accélérer certaines pistes, en délaisser d'autres et créer une trajectoire technologique propre à son entreprise.

## 7B. Laboratoire guidé et pédagogie par les conséquences

Le joueur règle lui-même quelques paramètres importants du CPU. L'équipe technique fournit une référence, mais ne verrouille jamais les choix.

Chaque jauge possède trois zones permanentes et expliquées :

- **vert — recommandé** : plage que l'équipe estime actuellement bien maîtrisée ;
- **orange — ambitieux** : choix crédible qui demande davantage de validation ou de moyens ;
- **rouge — hors zone maîtrisée** : choix possible à tenter, mais que l'équipe ne sait pas encore garantir.

La recommandation possède un **niveau de confiance** distinct. Une équipe jeune peut donner une estimation large et incertaine ; une équipe expérimentée, nourrie par R&D, développement, production et retours terrain, prédit plus précisément les conséquences.

Quand le joueur modifie une jauge, l'équipe explique immédiatement les effets causaux : davantage de TDP peut donner plus de marge de fréquence mais demander un refroidissement et une alimentation plus robustes ; davantage de cœurs augmente surface, consommation, coût et validation ; un procédé plus avancé offre un potentiel supérieur mais peut être moins maîtrisé.

L'équipe peut aussi proposer une voie pour rendre un objectif viable : technologie supplémentaire, validation renforcée, changement de procédé, amélioration du refroidissement, nouvelle architecture ou autre programme R&D. Le joueur choisit alors entre modifier son design, accepter un délai/coût supplémentaire ou tenter malgré le risque.

Le jeu doit enseigner les notions techniques par leur usage. Les termes réels peuvent être employés, mais ils sont traduits immédiatement en conséquences compréhensibles. Une base de connaissances peut se remplir progressivement lorsque le joueur rencontre pour la première fois rendement, binning, TDP, layout, microcode, stepping ou autres notions.

### Fondation jouable de la R&D Concept

La première implémentation conserve une interface volontairement compacte. Trois compétences techniques persistantes résument actuellement ce que l'entreprise sait réellement faire :

- **Architecture des circuits** : capacité à organiser des conceptions plus ambitieuses, à monter en fréquence et, plus tard, à rendre crédibles des organisations multicœurs ;
- **Cartographie / layout** : qualité du placement et du routage, qui réduit la complexité, améliore la robustesse électrique et rend progressivement l'intégration de cache plus réaliste ;
- **Miniaturisation & procédés** : savoir-faire nécessaire, avec la maîtrise de fabrication, pour accéder à des procédés plus fins.

Ces compétences progressent lentement par la recherche produit et l'expérience réelle, mais les bonds importants viennent des **programmes Concept CPU**. Un programme Concept possède un axe, un budget, un niveau d'ambition, une progression étude → prototype → validation → technologie transférable, un niveau de confiance et un résultat persistant.

Les premiers axes jouables sont très basse consommation, architecture de rupture, cartographie/densité, miniaturisation/procédé et fiabilité extrême. Une technologie Concept achevée ne donne pas un bonus magique au produit en cours : elle augmente les capacités techniques disponibles pour les générations futures, modifie les recommandations de l'équipe et peut ouvrir de nouveaux procédés.

L'accès à un procédé de fabrication dépend donc désormais de deux choses : **savoir le miniaturiser** et **savoir l'industrialiser**. Avoir seulement une bonne usine ou seulement une bonne idée de procédé ne suffit pas.

### Solutions techniques proposées par l'équipe

Lorsqu'un design CPU dépasse ce que l'entreprise maîtrise, l'interface ne doit pas se limiter à afficher du rouge. L'équipe peut proposer une voie concrète pour conserver l'objectif du joueur.

La première implémentation fournit trois niveaux :

- **solution rapide** : peu de retard et de coût, réduction limitée du risque ;
- **solution recommandée** : compromis standard, actuellement environ trois mois supplémentaires ;
- **solution ambitieuse** : investissement plus lourd, davantage de délai, mais apprentissage technique plus important.

Chaque proposition expose explicitement le problème traité, le surcoût initial, le coût total estimé avec les mois supplémentaires, la confiance de l'équipe et l'effet attendu sur le risque. Les solutions sont générées à partir de la contrainte réellement rencontrée : fréquence agressive, marge électrique/thermique, cache/layout, multicœur, miniaturisation ou validation générale.

Si le joueur accepte une solution, elle devient une **vraie phase de mise au point technique** avant le développement produit. Durant ces mois le CPU n'avance pas dans ses phases normales. Quand la mise au point est validée, une partie du savoir acquis devient une compétence réutilisable par l'entreprise pour les projets suivants.

Le joueur conserve toujours les trois choix fondamentaux : modifier son CPU, accepter le détour technique proposé, ou conserver une conception plus risquée sans cette aide.

### Vie après lancement d'un CPU

Un CPU commercialisé continue d'évoluer sans que toutes les améliorations soient confondues entre elles.

- **Prix et promotion** : décisions commerciales temporaires. Elles peuvent améliorer l'attractivité sans modifier le matériel.
- **Révision matérielle / stepping** : change uniquement les unités fabriquées après validation. Elle peut viser fiabilité, coût ou efficacité. Les unités déjà vendues restent physiquement inchangées.
- **Firmware / microcode** : peut toucher le parc compatible déjà vendu et créer un compromis performance / stabilité / efficacité.
- **Logiciel de contrôle** : produit associé distinct, avec version et liste explicite des CPU compatibles. Il améliore surtout utilisabilité et écosystème, sans transformer magiquement le silicium.

Les fonctionnalités logicielles avancées ne sont pas débloquées par une année arbitraire. Elles deviennent disponibles lorsque l'entreprise a acquis assez de savoir-faire logiciel, d'intégration et d'architecture.

L'interface respecte la progression pédagogique : la section de gestion post-lancement reste invisible tant qu'aucun produit sélectionné n'est réellement commercialisé.

### Direction, RH, avantages salariés et locaux

Le bras droit / vice-président est présent dès le garage et devient le guide transversal de l'entreprise. Il ne remplace pas les spécialistes : il filtre les informations, hiérarchise jusqu'à trois priorités et renvoie le joueur vers la bonne décision.

La première fondation jouable comprend :

- un brief du bras droit sur la trésorerie, les dossiers RH, les locaux, les projets techniques, le SAV et les lancements ;
- un suivi RH capable de détecter baisse de moral, manque de cohésion et locaux saturés ;
- des réponses RH concrètes (entretien/médiation ou mesure financière) ;
- une politique d'avantages salariés : couverture santé/mutuelle, repas, formation continue et espaces de qualité de vie ;
- des coûts mensuels réels et des effets sur moral, fidélisation et progression des salariés ;
- une progression des locaux : garage aménagé → atelier + bureaux → siège technique → campus R&D ;
- capacité, état, qualité de l'environnement, coût d'entretien et rénovation ;
- un avis financier qui calcule la trésorerie restante, la charge structurelle estimée et le nombre de mois de réserve avant d'accepter une dépense.

L'avis financier ne décide jamais pour le joueur. Il classe la situation (confortable, maîtrisée, tendue, dangereuse ou impossible), explique pourquoi et laisse le joueur arbitrer.

Le suivi RH et financier est d'abord assuré avec le bras droit. À mesure que l'effectif grandit, l'interface peut ensuite matérialiser un DRH et un DAF dédiés sans changer la logique sous-jacente.

### Dispersion des dies, gravure, binning et marge électrique

La « silicon lottery » est un résultat de fabrication, pas une statistique abstraite sur la qualité du silicium brut.

La qualité électrique des dies et leur dispersion viennent principalement de la **technologie de gravure utilisée**, de la **précision et stabilité des équipements**, de la **maturité du procédé**, du **layout**, des **marges de conception**, de la fréquence visée et de la qualité de l'industrialisation. Une conception agressive sur un procédé ou des machines encore peu maîtrisés peut donner quelques très bons dies, mais une distribution plus large et moins prévisible.

Le moteur distingue donc :
- précision gravure / équipement ;
- maîtrise du procédé ;
- marge de conception ;
- qualité électrique moyenne des dies ;
- dispersion et prévisibilité ;
- marge OC et undervolt.

Le joueur choisit ensuite une politique de **binning**, qui ne crée pas de meilleurs dies : elle décide seulement comment trier ceux qui ont réellement été fabriqués.

- **Binning volume** : critères plus larges, davantage de dies dans les bins élevés, mais davantage de dispersion dans chaque référence ;
- **Binning équilibré** : compromis par défaut ;
- **Binning strict** : moins de dies Apex, mais sélection plus homogène et davantage de marge électrique moyenne dans le bin.

Les modèles Essentiel, Signature et Apex sont donc des sélections différentes d'une même distribution physique. L'Apex reçoit les dies les plus favorables ; l'Essentiel utilise davantage de dies fonctionnels mais moins marginés.

La marge OC n'est jamais une fréquence garantie. L'interface affiche la fréquence officielle et une estimation typique issue de la distribution mesurée. Le marché Enthousiaste peut valoriser cette marge ; les segments professionnels valorisent davantage la constance et l'undervolt.

Une révision matérielle peut améliorer les **futures unités** en changeant le layout, les règles électriques, la calibration ou le procédé, sans modifier physiquement les CPU déjà vendus.

## 8. Générations et propositions d'architecture

Quand le joueur demande une nouvelle génération, l'équipe prépare idéalement trois plans compréhensibles :

- **prudent** : moins risqué, moins cher, progrès limité ;
- **équilibré** : compromis entre nouveauté, coût et durée de vie ;
- **ambitieux** : potentiel élevé, budget, délai et risque importants.

Chaque plan annonce une estimation : gains, segments visés, coûts, délai, risque, dépendances, potentiel de gamme et durée de compétitivité. La précision de ces estimations dépend de l'équipe et des outils ; elles ne constituent jamais une certitude absolue.

Une architecture sert plusieurs modèles : entrée de gamme, grand public, gaming, professionnel, serveur ou embarqué selon ses capacités. Le joueur amortit ainsi sa R&D sur une gamme et plusieurs révisions au lieu de créer chaque CPU depuis zéro.

## 9. Cycle de vie commun des produits

### Matériel

Opportunité → architecture → conception → prototypes → validation → industrialisation → lancement → production → SAV et correctifs → révisions → fin de commercialisation → support et pièces → fin de support.

### Logiciel

Opportunité → conception → développement → tests → lancement → correctifs → mises à jour → contenu ou extensions → maintenance → migration vers une nouvelle version → fin éventuelle de support.

Le logiciel peut être vendu une fois, par abonnement, avec maintenance, contenu, extensions ou service associé. Un produit logiciel peut durer des années et continuer d'évoluer ; il ne se termine pas le jour de sa sortie.

### Service

Conception → déploiement → acquisition d'utilisateurs → exploitation continue → capacité et fiabilité → évolution de l'offre → renouvellement ou fermeture.

Le moteur commun conserve coûts, qualité, satisfaction, réputation, risques, équipe et cycle de support, puis applique les règles propres à la catégorie.

## 10. Production, matériaux et fournisseurs sans microgestion excessive

La fabrication doit avoir un impact réel sans demander au joueur de commander chaque matière brute. La simulation regroupe les choix en contrats et blocs lisibles :

- procédé/fonderie ;
- wafer ou capacité réservée ;
- packaging et substrat ;
- assemblage et test ;
- mémoire et interfaces ;
- fournisseurs critiques ;
- équipements de laboratoire et de validation ;
- capacité, rendement, qualité et délai.

Chaque bloc influence plusieurs conséquences : coût unitaire, volume, rendement, consommation, performance, fiabilité, délai, dépendance, impact environnemental et risque de pénurie.

La première implémentation CPU impose déjà une industrialisation entre Développement et lancement. La maîtrise du procédé, la qualité, la maintenance et la stratégie de production déterminent rendement, défauts, capacité et coût. Cette base sera ensuite étendue aux fournisseurs, machines, packaging et contrats industriels.

En mode accessible, le responsable choisit les fournisseurs selon une politique. En mode simulation, le joueur compare contrats, capacité, qualité, exclusivité, stocks et dépendances.

## 11. Microcode, logiciel bas niveau et compatibilité

Un CPU ne se réduit pas au silicium. Le microcode, le firmware, le BIOS/UEFI, les pilotes, les compilateurs, le système d'exploitation et les cartes mères peuvent modifier stabilité, consommation, performances et compatibilité.

Le jeu doit permettre :

- validation croisée matériel/firmware ;
- investissement dans les outils et l'écosystème logiciel ;
- correction par microcode lorsque c'est possible ;
- régression de performance après correctif ;
- incompatibilités avec des partenaires ;
- coopération avec éditeurs, fabricants de cartes et systèmes d'exploitation ;
- support long terme et publication de correctifs.

## 12. Qualité, bugs, SAV et fin de vie

Un produit continue d'exister après son lancement. Défauts de fabrication, chauffe, instabilité, vulnérabilités, bugs firmware, incompatibilités et usure peuvent apparaître pendant sa vie commerciale.

Le responsable SAV ou qualité remonte un dossier comprenant : fréquence estimée, gravité, population touchée, confiance de l'analyse, coût d'étude et risque d'image. Le joueur peut :

- ignorer ou surveiller ;
- financer une enquête ;
- publier un correctif ;
- remplacer, réparer ou rembourser ;
- prolonger une garantie ;
- rappeler une série ;
- proposer une compensation ou un nouveau modèle ;
- arrêter la vente ;
- réserver des pièces et une capacité de support.

Le bon choix dépend du contexte. Une réponse chère peut sauver la confiance ; une économie immédiate peut produire des pertes durables. La réparabilité, les stocks de pièces et la durée des mises à jour deviennent des éléments de marque.

La première implémentation CPU suit déjà les retours terrain, classe les incidents en fabrication, thermique, stabilité ou firmware, permet surveillance/enquête/correctif/rappel et accumule une expérience terrain persistante. Cette expérience retourne ensuite vers la R&D et la Production afin qu'une génération difficile puisse améliorer les suivantes.

## 13. Clients, tests, créateurs et marketing

Les clients sont divisés en segments dont les attentes diffèrent. Ils évaluent les caractéristiques objectives, le prix, la marque, les promesses, le support, la concurrence et leur expérience précédente.

Les médias et créateurs de contenu testent les produits à partir des données de la simulation : benchmarks, stabilité, consommation, température, valeur, compatibilité et service. Leur personnalité influe sur l'angle et le public, pas sur les faits fondamentaux.

Le marketing choisit cible, message, canal, budget, durée et territoire. Une promesse excessive augmente l'attente et donc le risque de déception. Les tests, retours, forums, streamers et bouche-à-oreille doivent expliquer au joueur ce qui se passe sur le marché.

## 14. Synergies entre divisions

Les technologies internes peuvent être réutilisées :

- un CPU maison réduit les coûts ou améliore l'optimisation d'un serveur ;
- une division logicielle optimise les compilateurs et le système pour le matériel du groupe ;
- une branche IA utilise CPU, accélérateurs et cloud internes ;
- un robot combine calcul, modèle IA, capteurs, logiciel et service ;
- une technologie de packaging profite à plusieurs puces ;
- le SAV et les données qualité améliorent les générations suivantes.

Une synergie n'est pas un bonus gratuit. Elle exige compatibilité, coordination, capacité et temps d'intégration. Une technologie interne médiocre peut au contraire pénaliser plusieurs divisions à la fois.

## 15. Marchés publics, privés, militaires et spatiaux

Public, privé, militaire et spatial sont d'abord des **contextes de clients et de contrats**, pas nécessairement quatre moteurs de produits distincts. Ils modifient les exigences :

- certification et audit ;
- sécurité et confidentialité ;
- fiabilité et durée de support ;
- volumes et marges ;
- délais de décision ;
- clauses d'exclusivité ;
- risques géopolitiques, juridiques et d'image.

Une même technologie CPU peut donc viser le grand public, un datacenter, un satellite ou un système critique avec des variantes, validations et contrats différents.

## 16. Environnement et grands défis

L'énergie, les ressources, les émissions, l'eau, les déchets électroniques et la réparabilité font partie de la stratégie. Les technologies propres peuvent réduire les coûts à long terme, améliorer la réputation ou satisfaire un contrat, mais demandent recherche et investissement.

Les entreprises très avancées peuvent participer à des défis sans retour financier garanti : recherche climatique, calcul scientifique, dépollution, santé, exploration spatiale, énergie ou standards ouverts. Les récompenses peuvent être réputation, influence, relations, savoir-faire, recrutement et classement.

Ces défis s'ajoutent à la partie ; ils ne constituent pas une fin obligatoire.

## 17. Multijoueur optionnel et partenariats

Le mode en ligne recommandé est un monde économique asynchrone relié au serveur. Le solo reste complet et indépendant.

Les joueurs peuvent :

- comparer entreprises et produits ;
- vendre ou licencier technologies et composants ;
- répondre ensemble à un appel d'offres ;
- co-développer un produit hardware ou software ;
- créer une joint-venture ;
- partager coût, capacité, brevets et revenus ;
- participer à un grand projet mondial.

Un partenariat apporte financement, expertise, accès au marché et partage du risque, mais impose coordination, partage de propriété intellectuelle, dépendance et conflit possible sur les priorités. Aucun joueur ne perd son entreprise sans consentement hors d'un mode compétitif explicitement choisi.

## 18. Monétisation — garde-fous

Le modèle économique définitif reste à décider après une bêta jouable. Les principes retenus sont :

- ne pas vendre les statistiques, la victoire ou une supériorité multijoueur ;
- ne pas dégrader volontairement l'ergonomie pour vendre une solution ;
- ne pas enfermer la sauvegarde ou les correctifs essentiels derrière un paiement ;
- annoncer clairement ce qui est inclus sur Steam et mobile ;
- privilégier achat du jeu, extensions réelles, soutien optionnel ou contenu cosmétique ;
- séparer strictement économie réelle et économie simulée.

Les éventuels bonus payants ne doivent jamais casser l'équilibre, notamment dans les classements et partenariats en ligne.

## 19. Direction artistique et chaleur

Le jeu associe technologie moderne et lieu de travail chaleureux. Au départ, le bureau est petit, usé et improvisé. La progression apporte progressivement meilleur mobilier, lumière, plantes, rangements, objets d'équipe, machines, laboratoire et architecture prestigieuse.

Le joueur doit ressentir qu'il revient dans **son** entreprise, comme dans un coin de travail familier. La chaleur vient des matériaux, de la lumière, des sons, des petites histoires d'équipe et des traces de projets, pas d'un thème rustique plaqué sur une interface technique.

Les règles détaillées sont dans `UX_ART_DIRECTION.md`.

## 20. Priorité d'implémentation

### Maintenant — vertical slice CPU

- divisions génériques avec CPU seul actif ;
- génération CPU et plans d'architecture ;
- caractéristiques CPU lisibles et paramètres avancés optionnels ;
- équipes, spécialisations, découvertes et rapports ;
- microcode/validation simplifiés ;
- industrialisation, rendement et fournisseurs simplifiés ;
- lancement, tests, clients, incidents, SAV et génération suivante ;
- interface chaleureuse et évolution visible.

### Ensuite — moteur commun

- cycle de vie générique matériel/logiciel/service ;
- composants, plateformes, infrastructures et contrats ;
- délégation complète par système ;
- synergies entre divisions ;
- première diversification choisie pour sa complémentarité avec le CPU.

### Plus tard

- nouveaux secteurs ;
- grands défis ;
- multijoueur économique ;
- monétisation définitive ;
- IA générative d'immersion, sans dépendance du moteur de simulation.

## 21. Règle de validation d'une nouvelle fonctionnalité

Une fonctionnalité n'entre dans la version jouable que si elle :

1. crée une décision compréhensible ;
2. modifie réellement la simulation ;
3. produit un retour visuel ou narratif ;
4. peut être déléguée si elle devient répétitive ;
5. est sauvegardée et testée ;
6. fonctionne sur PC et reste utilisable au tactile ;
7. renforce d'abord la boucle CPU ou le moteur commun.

## 22. Références techniques de cadrage

Ces liens servent d'ancrage au modèle, pas de cahier des charges à reproduire au niveau transistor :

- RISC-V International — spécifications d'ISA : https://riscv.org/specifications/ratified/
- Arm — rôle d'une architecture comme contrat matériel/logiciel : https://www.arm.com/architecture
- Arm — présentation des chiplets : https://www.arm.com/glossary/chiplets
- TSMC — technologies et packaging 3DFabric : https://www.tsmc.com/english/dedicatedFoundry/technology/3DFabric
- UCIe Consortium — interconnexion ouverte entre chiplets : https://www.uciexpress.org/specification

