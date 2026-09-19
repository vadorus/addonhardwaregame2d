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

