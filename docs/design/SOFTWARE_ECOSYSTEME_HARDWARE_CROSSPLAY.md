# Tech Empire — Écosystème Software × Hardware (vision et spécification de conception)

> **Statut : proposition de design, non implémentée, non équilibrée.**
> Cible : extension progressive après validation de la tranche verticale CPU / démo d'octobre.
> Base analysée : `v013/demo-octobre` au commit `7f9228b`, 8 octobre 2026.
> Ne pas confondre ce document avec une promesse que le gameplay est déjà présent.

## 1. Intention du joueur

Le joueur doit pouvoir bâtir une société qui programme presque tout ce qu'une entreprise informatique peut développer, **dans les limites de son époque, de son savoir-faire, de son budget et de son matériel**. Software et Hardware sont deux divisions qui peuvent exister seules ou se renforcer mutuellement.

Le mot **public** ne désigne pas deux boutons Particuliers/Professionnels ; c'est un marché multidimensionnel. Le joueur distingue :
- **Produit / problème** (ce qu'il développe) ;
- **Public et industrie** (pour qui) ;
- **Plateforme / architecture** (sur quoi) ;
- **Modèle économique / distribution** (comment cela vit) ;
- **Relations avec les produits du groupe** (compatibilité, couplage, clients, savoir-faire).

Objectif de design : énormément de combinaisons pertinentes, mais jamais un formulaire de 40 paramètres ni une attente passive devant une barre.

## 2. Taxonomie extensible, fondée sur des capacités et des archétypes

Ne pas tenter de coder un gestionnaire différent pour chaque logiciel. Catalogue **piloté par données** :
`SoftwareDefinition` (ID stable, nom, archétype, sous-type, technologies, période de marché, plateforme, audiences, fonctionnalités, compétences, coût/temps, risques, événements, modèle de revenu, leviers de qualité et d'évolution).

| Archétype | Sous-types possibles | Défis distinctifs |
|---|---|---|
| Utilitaires | Compression/décompression, sauvegarde, fichiers, archivage, antivirus, récupération, monitoring, recherche, synchronisation | Rapidité, ergonomie, fiabilité, intégration |
| Création & médias | Retouche, CAO, graphisme, son, vidéo, encodage, lecture multimédia, diffusion/streaming | Formats, codecs, performance, ergonomie, licences |
| Productivité & métier | Texte, tableur, comptabilité, gestion, CRM, ERP, stocks, logistique, santé, éducation, vertical métier | Adéquation aux besoins, import de données, support, fidélisation |
| Outils développeurs | Éditeur, compilateur, SDK, bibliothèque, moteur de jeu, IDE, tests, débogage, CI, virtualisation | Écosystème, compatibilité, documentation, extensions |
| Systèmes | OS, installation, démarrage, outils système, pilotes, BIOS/UEFI, firmware, microcode, gestion énergétique | Compatibilité précise, correctifs, fiabilité, versions |
| Serveurs & réseau | Base de données, serveur web, messagerie, DNS, proxy, stockage, sécurité, supervision, orchestration | Disponibilité, sécurité, charge, coûts d'exploitation |
| Web & services connectés | Site vitrine, site marchand, portail, navigateur, recherche, hébergement, réseaux sociaux, vidéo/streaming, SaaS | Acquisition, trafic, bande passante, modération si pertinente, rétention |
| Logiciels embarqués | Contrôle industriel, périphériques, réseau, véhicules, électronique grand public | Fiabilité, validation, contraintes matérielles et clients |
| Outils internes | Bancs de tests, simulateurs CPU, analyse de traces, compilateur interne, optimisation firmware, pilotage fabrication, QA/SAV | Retour sur investissement, formation équipe, maintenance |
| Contrats sur mesure | Tous les archétypes précédents, appliqués au cahier des charges d'un client | Délais, exigences, renégociation, réception, pénalités |

Les **sites web** font partie du logiciel, mais ne doivent pas se jouer exactement comme une licence vendue en boîte. Un site interne/vitrine, une plateforme e-commerce et un service de streaming ont des tailles de marché, revenus et contraintes très différents.

Une **branche GPU future** pourra utiliser les mêmes systèmes de pilotes et logiciels graphiques. Ne pas ouvrir la branche hardware GPU avant validation de la tranche CPU, conformément à `AGENTS.md`.

## 3. Publics et marchés combinables

Audiences initiales à modéliser selon les années et l'archétype :
- grand public/familles, étudiants, enseignants, joueurs, créateurs de contenu ;
- professionnels indépendants, développeurs, PME, grands comptes ;
- administrations/éducation, laboratoires/recherche, industriels ;
- fabricants/OEM, intégrateurs, hébergeurs/datacenters, éditeurs de logiciels.

Ces segments ne sont ni tous pertinents ni ouverts dès 1971. Un même produit peut cibler un **public principal** puis un second public, éventuellement via une édition dédiée. Chaque public évalue différemment prix, fiabilité, fonctions, intégration, performance, ergonomie et support. Les revenus doivent découler d'un **marché cohérent** et non d'un multiplicateur universel arbitraire.

À ajouter progressivement : taille de marché par ère, équipement hardware, concurrence, budget d'achat, attentes, compatibilité, fidélité, distribution, réputation par segment et installations actives.

## 4. Boucle commune de développement — 3 décisions intéressantes, pas 30 clics

1. **Concept** : sous-type, destinataires, promesse, fonctionnalités clés et stratégie prix/contrat.
2. **Construction** : allocation de spécialistes, choix d'architecture, compromis vitesse/coût/qualité ; événement contextuel relié aux décisions antérieures.
3. **Stabilisation** : tests, beta, compatibilité, sécurité et calendrier de sortie.
4. **Exploitation** : correctifs, nouvelles fonctionnalités, support, versions, partenariats, fin de vie.
5. **Succession** : migration utilisateurs, nouvelle génération, compatibilité ascendante, risque de cannibalisation.

En développement : choix significatif environ à chaque phase, avec possibilité de petites urgences, sans interruption systématique de tous les mois. Des décisions ont un **effet mesurable immédiatement et dans le futur**. Le QG affiche l'équipe et ses projets actifs ; le détail est à un clic, utilisable au doigt sur Pixel.

### Variantes de boucle par sous-type
- Compression : algorithme vitesse/taille/compatibilité, formats, tests de fichiers corrompus, concurrence.
- Streaming : qualité encodage, latence, capacité, trafic, coût CDN/datacenters, droits/licences lorsque pertinent.
- Site marchand : catalogue/paiement/fiabilité, trafic, conversion, fraude et support.
- Base de données : robustesse/transferts, débit, concurrence et support entreprise.
- OS : pilotes, compatibilité des applications, OEM, adoption, mises à jour et fragmentation.
- Microcode : erratum identifié, reproduction, développement, validation par stepping, déploiement et adoption.
- Logiciel interne CPU : fonctionnalités de banc/simulation, intégration au labo, gains limités à certains processus.

## 5. Traitement impératif du CPU ancien : exemple BSM3

### Mission
Un CPU BSM3 a été commercialisé, et des clients en possèdent encore. L'équipe identifie une révision microcode, un correctif BIOS/firmware, un pilote, une optimisation compilateur ou une meilleure ordonnance logicielle.

**Ne pas confondre les couches :**
- `microcode` : corrige/ajuste certains comportements internes et errata de la génération/du stepping supportés, parfois mesures de sécurité et de performance ;
- `BIOS/UEFI/firmware plateforme` : initialisation, réglages, stabilité et déploiement du microcode ;
- `pilote + OS + compilateur` : permet d'exploiter efficacement des caractéristiques existantes ; performances dépendent des applications ;
- `nouvelle révision silicium` : requiert une nouvelle fabrication et n'est **pas** un simple téléchargement ;
- `optimisation de logiciel utilisateur` : gain local aux charges de travail ciblées.

### Données nécessaires par génération CPU
`cpu_family_id`, `generation_id`, `stepping_ids`, `launch_month`, `base_performance_profile`, `reliability`, `security_state`, `active_install_base`, `support_until`, `software_revision`, `optimization_opportunities`, `supported_platforms`. Préserver l'état du CPU d'origine pour mesurer le gain **avant/après** et éviter tout empilement infini.

La population installée doit survivre à la fin des ventes (décroissance/migrations). Une correction peut toucher d'anciens clients sans vendre une seule puce nouvelle.

### Parcours jouable BSM3
1. Signalement SAV, analyse de laboratoire, télémétrie autorisée, benchmark ou retour OEM.
2. Choix du projet : correction stabilité, vulnérabilité, optimisation ciblée ou support plateforme.
3. Spécialistes assignés : firmware, validation, OS/pilotes, CPU.
4. Arbitrage : corriger prudemment, expérimenter une optimisation, publier une beta fermée, différer.
5. Validation par génération/stepping et charge de travail ; effets secondaires possibles.
6. Publication : via OS/BIOS/OEM lorsque techniquement plausible ; adoption progressive, non instantanée.
7. Bilan : clients effectivement mis à jour, correctifs, gain par usage, incidents, coût et variation de réputation/confiance.

### Exemples de réglages à prototyper, **illustratifs et non validés**
- Gain moyen global ordinaire : souvent faible ; une amélioration de sécurité/stabilité peut être plus précieuse que les FPS.
- Une optimisation très ciblée peut donner **+10 à +20 % sur un type de charge** si un vrai goulot est identifié, sans supposer +20 % d'IPC ni +20 % sur tous les logiciels.
- La nouvelle performance ressentie est pondérée par la répartition réelle des charges et par le **taux de déploiement** : +15 % dans une tâche, 20 % de poids de cette tâche et 60 % de clients mis à jour ⇒ effet agrégé approximatif +1,8 % sur la base active, pas +15 % général.
- Potentiel limité par le design de la puce, la qualité du diagnostic, les équipes, les tests et les risques de régression.
- Certains correctifs peuvent dégrader légèrement certains scénarios pour résoudre un problème de sécurité ou de stabilité.

### Retombées sur la société
- Réputation SAV/support auprès des **clients existants**, plus confiance OEM/entreprises, fidélisation et intérêt pour la nouvelle génération.
- Coût ingénieurs/support/validation et parfois litiges si mise à jour défectueuse.
- Opportunité de maintenir la relation avec anciens utilisateurs même si BSM3 n'est plus vendu.
- Choix stratégique réel : budget anciens clients **contre** budget prochain CPU.

**Antiexploit** : ne jamais appliquer un bonus cumulatif au score de fabrication de tous les CPU ; ne jamais régénérer la même « découverte » indéfiniment ; plafonds par génération, compatibilité par stepping, conservation des métriques d'origine, suivi adoption/version.

## 6. Outils internes à avantage propriétaire

Un outil générique acheté/développé offre des améliorations accessibles à toute société. Un outil interne dédié à **nos CPU** peut faire mieux dans son périmètre car l'équipe connaît mieux l'architecture ; il demande du temps, de l'expertise, des données et un coût de maintenance.

| Outil | Avantage conditionnel | Limite et contrepartie |
|---|---|---|
| Simulateur CPU / profiler interne | Détection des goulots, qualité des choix R&D, optimisation des logiciels de la marque | Précision liée à expertise, génération, coût de calcul et maintenance |
| Banc de validation automatisé | Détection des errata/bugs avant et après lancement | Besoin de tests, coût initial, faux négatifs |
| Compilateur/SDK optimisé | Meilleurs résultats sur des applications **compatibles** | Marché/plateformes visés, effort développeur, adoption |
| Atelier firmware/microcode | Délais de correction et risques réduits, diagnostics plus précis | Ne change pas les limites du silicium |
| Logiciel pilotage production/QA | Améliore rendement, rebuts, traçabilité ou délais dans la limite des processus physiques | Coût opérationnel, intégration aux fonderies |
| Plateforme SAV/télémétrie | Diagnostic rapide, réputation et prévention d'incidents | Coût support, couverture d'installation, consentement quand nécessaire |

**Synergie croisée** : Division CPU apporte données/prototypes/domain expertise ; division Software apporte compétences et outils. La synergie ne doit pas rendre chaque partie *obligatoirement* bi-branche : contrats, licences et prestataires tiers sont des alternatives crédibles, plus chères ou moins spécialisées.

## 7. Internet : infrastructure et marché, pas sixième catégorie rigide

Internet est à la fois une **capacité de réseau**, une **distribution**, une **famille de débouchés** et un **coût de service**. Il débloque sites, commerce, navigateurs, messagerie, diffusion, hébergement, abonnements, services connectés au fil des époques, sous conditions de marché et technologies. Le réseau réel n'est **jamais requis** pour jouer hors ligne ; trafic, serveurs, disponibilité et utilisateurs sont **simulés localement**.

Repères de progression indicatifs (à affiner historiquement selon segment/pays) :
- 1970s : systèmes centraux, réseaux privés et contrats spécialisés ;
- 1980s : réseaux d'entreprises, client/serveur et logiciels personnels ;
- 1990s : accès Internet et Web public, sites, messagerie, navigateurs, hébergement ;
- 2000s : haut débit, plateformes, distribution dématérialisée, premières grandes infrastructures en ligne ;
- 2010s+ : mobile/cloud, streaming massif, abonnements/SaaS, services distribués.

Exemple : un site vitrine n'a pas besoin du même serveur ni du même personnel qu'un service vidéo avec un million d'utilisateurs.

## 8. Les produits forment des chaînes de valeur, pas des bonus isolés

Exemples :
- CPU BSM3 → chipset/carte/BIOS compatible → OS compatible → pilotes → compilateur optimisé → utilitaires bénéficiaires → réputation performance, compatibilité et SAV.
- Création logiciel streaming → codecs internes → charge CPU/serveurs → investissements infra → acquisition clients → abonnements → maintenance.
- Simulateur CPU interne → R&D moins risquée → meilleurs prototypes → microcode/firmware mieux validé → moins de retours SAV.
- OS interne → besoin de pilotes, de SDK et d'applications → marché potentiel des propres logiciels, partenaires OEM, dépendance à l'écosystème.
- Outil compression → usage individuel ou B2B, SDK concédé en licence, optimisation pour serveurs/CPU de l'entreprise.

Les synergies sont plafonnées par la compatibilité, la maturité, le taux d'adoption, les spécialités de l'équipe et le coût. Ne jamais faire de bonus global automatique « CPU + Software = +20 % ».

## 9. Équipe, compétences et découvertes

Spécialités : programmation généraliste, algorithmique/compression, interface, web/back-end, réseaux et sécurité, systèmes/OS, pilotes/firmware/microcode, validation/QA, optimisation/performance, outils R&D. Progression par projets réellement effectués, mentorat et recrutements. La taille du studio n'est pas équivalente à la maîtrise d'un domaine.

Découvertes plausibles depuis l'expérience, liées à des erreurs, architectures, incidents et tests précédents ; générer par simulation déterministe (graine sauvegardée), pas évènement magique permanent. Chaque spécialité ouvre un **choix concret** ou réduit un risque.

## 10. UI : une entrée, exploration en profondeur facultative

`Nouveau projet` → **Hardware / Software** → pour Software :
1. **Produit à commercialiser** (catalogue filtrable : objectif, catégorie, sous-type, période, public, plateforme) ;
2. **Développer sur commande** (cahier des charges réel et négociation) ;
3. **Outil pour l'entreprise** (choix de division et de système à améliorer) ;
4. **Maintenance et optimisation** (choix de produit existant, génération BSM3, type mise à jour).

Sur Android : choix simples et recherche, éléments verrouillés expliqués (pas disparus arbitrairement), aperçu *avant* confirmation (temps, coûts, risque, marché, liens CPU), suivi compact dans le garage. Les 3–4 étapes du développement doivent être lisibles et avoir du jeu.

Les intitulés de sous-types peuvent être nombreux ; les mécaniques centrales restent peu nombreuses, profondes et réutilisables.

## 11. Architecture d'intégration au jeu actuel

**Existants à réutiliser** (inspection statique, ne pas présenter comme features finies) :
- `scripts/SoftwareCatalog.gd` : 5 familles et segments, calculs coûts/qualité/marché/support ;
- `scripts/SoftwarePlayCatalog.gd` : projets utilitaires et approches de petits contrats ;
- `scripts/SoftwareManager.gd` : pipeline, ventes, versions, correctifs et boucle interactive `UTILITY_SLICE` ;
- `ui/SoftwareWorkshop.gd` : entrée projets ;
- `scripts/MarketManager.gd`, `scripts/AfterSalesManager.gd`, `scripts/ExecutiveManager.gd` et managers CPU : marchés, SAV, décisions, projets ;
- `tests/software_gameplay_test.gd`, `tests/software_integration_test.gd` : fondations des tests.

**Approche progressive** :
A. Ajouter des données/IDs stables de `SoftwareDefinition`, `SoftwareAudience`, `SoftwarePlatform`, `SoftwareCapability`; conserver l'adaptateur des cinq familles pour les sauvegardes anciennes.
B. Généraliser les phases interactives de `UTILITY_SLICE` à quelques archétypes sélectionnés (un utilitaire, un logiciel métier, un serveur/site), avec tests et ergonomie Pixel.
C. Introduire maintenance CPU ancienne + registre révisions de microcode/firmware/compatibilité, via les managers CPU et SAV existants, **sans toucher aux anciens scores hardware**.
D. Implémenter un premier outil interne CPU et son ROI mesurable dans R&D/QA ; équilibrer la synergie sans branche Software obligatoire.
E. Étendre familles, publics, sites, distribution Internet et modèles économiques selon l'époque.
F. Accroître catalogue via données sans ajouter 1 manager par sous-type.

**Démarcation de périmètre** : démo d'octobre = CPU vertical slice prioritaire. Garder ceci sur branche de design séparée en attendant feu vert d'implémentation et jalons de tests. Pas d'ajout soudain de GPU, mobile, spatial, etc.

## 12. Critères de validation obligatoires (à automatiser)

- Marché : un produit peut cibler plusieurs segments avec pondérations distinctes et des années d'accès cohérentes.
- Catégorie : deux logiciels de sous-types différents produisent des situations de jeu réellement différentes, pas uniquement un prix ou un nom.
- CPU supporté : patch BSM3 n'affecte que génération/stepping compatibles ; n'altère pas la génération suivante ni le score de silicium brut.
- Adoption : gain client réellement ressenti dépend des installations mises à jour, même quand ventes de BSM3 = 0.
- Performance : benchmark par charge ; pas de gain absolu multiplié indéfiniment en appliquant une mise à jour répétée.
- Bénéfice : correctif peut améliorer SAV/réputation avec coût réel ; si régression, réputation et tickets SAV se détériorent.
- Synergie : outil interne spécialisé bat une solution générique sur un périmètre limité et exige coût, maintenance et expertise ; le joueur CPU seul peut progresser.
- Stabilité : sauvegarde ancienne chargée sans perdre projets CPU ou logiciels ; migration explicite, simulation hors ligne.
- Gameplay : phases/décisions visibles dans le garage et jouables au doigt, effets vérifiables dans rapports avant/après.
- Tests : Godot import, démarrage, `tests/smoke_test.tscn`, scénarios déterministes spécifiques, essai Android après étapes pertinentes.

## 13. Conditions de lancement

Ne lancer le chantier code complet **qu'après découpage en incréments testables**. Ce fichier est une spécification de conception, **pas une implémentation** et aucune validation Godot/Pixel ne lui est attachée. La précédente tentative d'import Godot dans une copie d'audit a échoué ; ne pas la présenter comme PASS. Le branchement des systèmes et leur équilibrage devront être démontrés en jeu.
