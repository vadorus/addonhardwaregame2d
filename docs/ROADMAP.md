# Roadmap — Tycoon Hardware / Tech Empire

Cette roadmap fixe l'ordre de construction du jeu. La vision finale est très large, mais chaque phase doit s'appuyer sur un moteur commun réutilisable.

## Lot immédiat — V0.2.6 et suites CPU

- [x] Documenter les décisions de conception dans une bible versionnée.
- [x] Ajouter un socle générique de divisions avec CPU seul actif.
- [x] Sauvegarder la maturité et le nombre de générations d’une division.
- [x] Proposer trois plans d’architecture pour une nouvelle génération CPU.
- [x] Décliner une architecture en plusieurs modèles de gamme.
- [x] Ajouter procédé, packaging, rendement et contrat industriel simplifiés.
- [x] Ajouter microcode, compatibilité et correctifs post-lancement.
- [x] Ajouter incidents qualité et réponses SAV.
- [x] Ajouter découvertes d’équipe et recherches dérivées.
- [x] Ajouter évolution visuelle du bureau.
- [ ] Finaliser une taxonomie d’icônes cohérente.

Documents de référence : `DESIGN_BIBLE.md`, `CPU_VERTICAL_SLICE.md` et `UX_ART_DIRECTION.md`.

## Phase 0 — Récupération et stabilisation

- [x] Importer le projet Godot réel et utiliser GitHub comme source de vérité.
- [x] Vérifier la version Godot cible : 4.7.2.
- [x] Vérifier le démarrage PC et le boot headless.
- [x] Vérifier l'export Android et l'installation d'une preview réelle.
- [x] Cartographier scènes, scripts, autoloads et données.
- [x] Identifier et exclure les fichiers locaux/générés des exports et de Git.
- [x] Établir une version de référence reproductible via CI.

## Phase 1 — Vertical slice entreprise + CPU

Objectif : prouver une boucle de jeu complète, pas seulement un écran de conception.

- [x] Création de l'entreprise.
- [x] Trésorerie et coûts fixes.
- [x] Marché CPU de départ.
- [x] Première équipe technique.
- [x] R&D CPU.
- [x] Étendre les paramètres avancés de conception avec IPC et compatibilité de plateforme explicites.
- [x] Paramètres essentiels : architecture, cœurs, fréquence, cache, TDP et gravure.
- [x] Phases de développement simplifiées avec arbitrages.
- [x] Rapport du chef d'équipe avec forces, faiblesses et risques.
- [x] Validation du design.
- [x] Production / sous-traitance simple.
- [x] Contrat industriel, packaging et niveau de test.
- [x] Coût unitaire, capacité et volume.
- [x] Prix de vente et ajustement post-lancement.
- [x] Demande et ventes mensuelles.
- [x] Premier benchmark public.
- [x] Avis clients simplifiés par segment.
- [x] Marge et trésorerie.
- [x] Réputation.
- [x] Parts de marché.
- [x] SAV avec plans, retours, incidents et réponses joueur.
- [x] Génération suivante, vieillissement et fin de vente.

**Critère de fin :** une partie permet de créer une société, développer un premier CPU avec son équipe, le commercialiser, recevoir des retours mesurables et observer des conséquences financières et concurrentielles.

## Phase 2 — Moteur industriel générique

- [ ] Technologies réutilisables.
- [ ] Composants.
- [ ] Produits.
- [ ] Services.
- [ ] Infrastructures.
- [ ] Fournisseurs.
- [ ] Développer / acheter / licencier / co-développer.
- [x] Capacité de production.
- [x] Rendement de fabrication.
- [x] Qualité et taux de panne simplifiés.
- [ ] Stocks.
- [x] SAV / retours / garanties.
- [ ] Pièces détachées et capacité de réparation.
- [ ] Logistique.

Objectif : permettre à plusieurs familles de produits d'utiliser le même moteur.

## Phase 3 — Marché, clients, médias et concurrence

- [x] Segments de marché.
- [x] Critères d'évaluation par segment.
- [x] Attentes selon prix, marque et promesses marketing.
- [x] Élasticité prix / performance / marque.
- [ ] Tendances technologiques.
- [x] Benchmarks multi-critères.
- [ ] Presse hardware / software / économique.
- [ ] Médias web, vidéo, livestream et influenceurs.
- [x] Avis clients simplifiés ; bouche-à-oreille à approfondir.
- [ ] Concurrents avec profils durables.
- [ ] Budget et stratégie concurrents.
- [x] Parts de marché.
- [ ] Guerre des prix.
- [ ] Entrées / sorties de marché.
- [ ] Journal d'événements structuré.

## Phase 4 — Gestion d'entreprise avancée

- [x] Départements.
- [x] Employés et compétences.
- [x] Chefs d'équipe et responsables de département.
- [x] Progression des équipes par expérience réelle.
- [x] Recrutement, salaires et licenciements ; turnover automatique à approfondir.
- [x] Progression visuelle des bureaux et pôles ; centres R&D spécialisés à approfondir.
- [ ] Marques et filiales.
- [ ] Société mère / groupe.
- [x] Financement / dette.
- [ ] Publicité et marketing multicanal.
- [ ] Distribution.
- [x] Contrats B2B.
- [ ] Brevets, licences, cross-licensing et secrets industriels.
- [ ] Expansion internationale.
- [ ] Acquisitions et participations.
- [ ] Fusion / cession / spin-off de filiales.
- [ ] Intégration verticale.

## Phase 5 — Délégation et profondeur configurable

- [ ] Preset Accessible.
- [ ] Preset Standard.
- [ ] Preset Simulation.
- [ ] Automatisation par département plutôt qu'un mode global rigide.
- [ ] Politiques automatiques de SAV.
- [ ] Politiques automatiques RH.
- [ ] Politiques automatiques production/logistique.
- [ ] Politiques automatiques marketing.
- [ ] Alertes et exceptions qui remontent au joueur.
- [ ] Possibilité de reprendre manuellement un département à tout moment.

Objectif : offrir la même simulation de fond aux joueurs casual et experts, avec un niveau de microgestion choisi par le joueur.

## Phase 6 — Première diversification

Après stabilisation du moteur commun :

- [ ] GPU.
- [ ] RAM / stockage.
- [ ] Cartes mères / chipsets.
- [ ] PC fixes / portables.
- [ ] Smartphones / tablettes.
- [ ] TV / écrans.
- [ ] Logiciels / système d'exploitation.
- [ ] Synergies hardware / software.
- [ ] Optimisation d'écosystème interne.

L'ordre exact dépendra de la qualité de la vertical slice et des synergies disponibles.

## Phase 7 — IA et monde vivant

- [ ] Assistant du joueur basé sur les données réelles de la partie.
- [ ] Conseillers spécialisés (finance, technologie, production, marketing, SAV...).
- [ ] Personnalités concurrentes.
- [ ] Réactions médias / analystes.
- [ ] Négociations enrichies.
- [ ] Mémoire d'événements importants.
- [ ] Mode sans LLM avec templates et logique locale.

Voir `docs/AI_IMMERSION.md`.

## Phase 8 — Nouveaux secteurs technologiques

Extension progressive du moteur vers :

- [ ] cloud et datacenters ;
- [ ] réseaux et télécoms ;
- [ ] IA et accélérateurs ;
- [ ] robotique ;
- [ ] objets connectés ;
- [ ] automobile / systèmes embarqués ;
- [ ] drones ;
- [ ] satellites ;
- [ ] communications orbitales ;
- [ ] autres technologies futures.

## Phase 9 — Réalisme avancé

- [ ] Chaînes d'approvisionnement multi-niveaux.
- [ ] Géographie des marchés.
- [ ] Réglementation.
- [ ] Antitrust.
- [ ] Crises et pénuries.
- [ ] Rappels produit.
- [ ] Dépendances stratégiques.
- [ ] Fiscalité simplifiée ou avancée selon niveau de délégation.
- [ ] Gouvernance / actionnaires si pertinent.
- [ ] Environnement, énergie, ressources, recyclage et réparabilité.

## Phase 10 — Multijoueur économique optionnel

Ne démarrer cette phase qu'après validation du solo.

- [ ] Monde économique partagé asynchrone.
- [ ] Temps serveur indépendant de la vitesse locale du solo.
- [ ] Entreprises de joueurs visibles dans benchmarks et marchés.
- [ ] Contrats B2B entre joueurs.
- [ ] Vente de composants.
- [ ] Licences technologiques / brevets.
- [ ] Partenariats et co-développement.
- [ ] Joint-ventures.
- [ ] Appels d'offres.
- [ ] Prises de participation.
- [ ] Vente de marques ou filiales.
- [ ] Fusions et acquisitions volontaires.
- [ ] Protections empêchant la perte forcée d'une partie hors mode compétitif explicitement accepté.
- [ ] Gestion automatique de l'entreprise pendant l'absence du joueur selon ses politiques.

Objectif : confronter les stratégies des joueurs sans transformer le jeu en MMO temps réel permanent ni rendre le solo dépendant d'un serveur.

## Phase 11 — Mobile, PC et finition

- [x] UI responsive de base.
- [x] Contrôles tactiles et tailles minimales renforcées.
- [x] Densité d'information adaptative.
- [x] Sauvegardes, migrations et autosave.
- [ ] Performances Android.
- [ ] Accessibilité.
- [x] Onboarding léger jusqu'au premier lancement.
- [x] Build Windows reproductible.
- [x] Build Android reproductible.
- [x] GitHub Actions pour tests/builds.

## Hors scope immédiat

Ne pas lancer avant une vertical slice stable :

- multijoueur ;
- backend en ligne obligatoire ;
- boutique / monétisation ;
- dizaines de secteurs simultanément ;
- LLM indispensable au fonctionnement ;
- polish graphique lourd ;
- simulation ultra-détaillée de tous les pays et acteurs.

La priorité est toujours : **une boucle complète, fun et stable avant l'élargissement du contenu.**
