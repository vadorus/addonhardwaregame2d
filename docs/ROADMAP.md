# Roadmap — Tycoon Hardware / Tech Empire

Cette roadmap fixe l'ordre de construction du jeu. La vision finale est très large, mais chaque phase doit s'appuyer sur un moteur commun réutilisable.

## Lot immédiat — V0.2.6 et suites CPU

- [x] Documenter les décisions de conception dans une bible versionnée.
- [x] Ajouter un socle générique de divisions avec CPU seul actif.
- [x] Sauvegarder la maturité et le nombre de générations d’une division.
- [x] Proposer trois plans d’architecture pour une nouvelle génération CPU.
- [ ] Décliner une architecture en plusieurs modèles de gamme.
- [ ] Ajouter procédé, packaging, rendement et fournisseur simplifiés.
- [ ] Ajouter microcode, compatibilité, incidents et correctifs.
- [ ] Ajouter découvertes d’équipe et recherches dérivées.
- [ ] Ajouter évolution visuelle du bureau et taxonomie d’icônes.

Documents de référence : `DESIGN_BIBLE.md`, `CPU_VERTICAL_SLICE.md` et `UX_ART_DIRECTION.md`.

## Phase 0 — Récupération et stabilisation

- [ ] Importer le projet Godot réel depuis le PC.
- [ ] Vérifier la version Godot et les plugins utilisés.
- [ ] Vérifier que le projet démarre sur PC.
- [ ] Vérifier l'état Android/export mobile existant.
- [ ] Cartographier scènes, scripts, autoloads et données.
- [ ] Identifier les fichiers locaux/générés à exclure de Git.
- [ ] Établir une version de référence reproductible.

## Phase 1 — Vertical slice entreprise + CPU

Objectif : prouver une boucle de jeu complète, pas seulement un écran de conception.

- [ ] Création de l'entreprise.
- [ ] Trésorerie et coûts fixes.
- [ ] Marché CPU de départ.
- [ ] Première équipe technique.
- [ ] R&D CPU.
- [ ] Paramètres de conception : architecture, cœurs, fréquence, IPC, cache, TDP, gravure.
- [ ] Phases concept / prototype / bêta / validation simplifiées.
- [ ] Rapport du chef d'équipe avec forces, faiblesses et risques.
- [ ] Validation du design.
- [ ] Production / sous-traitance simple.
- [ ] Coût unitaire et volume.
- [ ] Prix de vente.
- [ ] Demande et ventes mensuelles.
- [ ] Premier benchmark public.
- [ ] Avis clients simplifiés par segment.
- [ ] Marge et trésorerie.
- [ ] Réputation.
- [ ] Parts de marché.
- [ ] SAV simplifié avec budget/politique.
- [ ] Génération suivante.

**Critère de fin :** une partie permet de créer une société, développer un premier CPU avec son équipe, le commercialiser, recevoir des retours mesurables et observer des conséquences financières et concurrentielles.

## Phase 2 — Moteur industriel générique

- [ ] Technologies réutilisables.
- [ ] Composants.
- [ ] Produits.
- [ ] Services.
- [ ] Infrastructures.
- [ ] Fournisseurs.
- [ ] Développer / acheter / licencier / co-développer.
- [ ] Capacité de production.
- [ ] Rendement de fabrication.
- [ ] Qualité et taux de panne.
- [ ] Stocks.
- [ ] SAV / retours / garanties.
- [ ] Pièces détachées et capacité de réparation.
- [ ] Logistique.

Objectif : permettre à plusieurs familles de produits d'utiliser le même moteur.

## Phase 3 — Marché, clients, médias et concurrence

- [ ] Segments de marché.
- [ ] Critères d'évaluation par segment.
- [ ] Attentes selon prix, marque et promesses marketing.
- [ ] Élasticité prix / performance / marque.
- [ ] Tendances technologiques.
- [ ] Benchmarks multi-critères.
- [ ] Presse hardware / software / économique.
- [ ] Médias web, vidéo, livestream et influenceurs.
- [ ] Avis clients et bouche-à-oreille.
- [ ] Concurrents avec profils durables.
- [ ] Budget et stratégie concurrents.
- [ ] Parts de marché.
- [ ] Guerre des prix.
- [ ] Entrées / sorties de marché.
- [ ] Journal d'événements structuré.

## Phase 4 — Gestion d'entreprise avancée

- [ ] Départements.
- [ ] Employés et compétences.
- [ ] Chefs d'équipe et responsables de département.
- [ ] Progression des équipes par expérience réelle.
- [ ] Recrutement / salaires / turnover.
- [ ] Bureaux et centres R&D.
- [ ] Marques et filiales.
- [ ] Société mère / groupe.
- [ ] Financement / dette.
- [ ] Publicité et marketing multicanal.
- [ ] Distribution.
- [ ] Contrats B2B.
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

- [ ] UI responsive.
- [ ] Contrôles tactiles.
- [ ] Densité d'information adaptative.
- [ ] Sauvegardes robustes.
- [ ] Performances Android.
- [ ] Accessibilité.
- [ ] Tutoriel / onboarding.
- [ ] Build Windows reproductible.
- [ ] Build Android reproductible.
- [ ] GitHub Actions pour tests/builds quand le projet est prêt.

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
