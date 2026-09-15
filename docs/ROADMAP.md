# Roadmap — Tycoon Hardware / Tech Empire

Cette roadmap fixe l'ordre de construction du jeu. La vision finale est très large, mais chaque phase doit s'appuyer sur un moteur commun réutilisable.

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
- [ ] R&D CPU.
- [ ] Paramètres de conception : architecture, cœurs, fréquence, IPC, cache, TDP, gravure.
- [ ] Validation du design.
- [ ] Production / sous-traitance simple.
- [ ] Coût unitaire et volume.
- [ ] Prix de vente.
- [ ] Demande et ventes mensuelles.
- [ ] Marge et trésorerie.
- [ ] Réputation.
- [ ] Parts de marché.
- [ ] Génération suivante.

**Critère de fin :** une partie permet de créer une société, lancer un premier CPU, le commercialiser et observer des conséquences financières et concurrentielles.

## Phase 2 — Moteur industriel générique

- [ ] Technologies réutilisables.
- [ ] Composants.
- [ ] Produits.
- [ ] Services.
- [ ] Infrastructures.
- [ ] Fournisseurs.
- [ ] Capacité de production.
- [ ] Rendement de fabrication.
- [ ] Qualité et taux de panne.
- [ ] Stocks.
- [ ] SAV / retours.
- [ ] Logistique.

Objectif : permettre à plusieurs familles de produits d'utiliser le même moteur.

## Phase 3 — Marché et concurrence

- [ ] Segments de marché.
- [ ] Élasticité prix / performance / marque.
- [ ] Tendances technologiques.
- [ ] Concurrents avec profils durables.
- [ ] Budget et stratégie concurrents.
- [ ] Parts de marché.
- [ ] Guerre des prix.
- [ ] Entrées / sorties de marché.
- [ ] Journal d'événements structuré.

## Phase 4 — Gestion d'entreprise avancée

- [ ] Départements.
- [ ] Employés et compétences.
- [ ] Recrutement / salaires.
- [ ] Bureaux et centres R&D.
- [ ] Marques et filiales.
- [ ] Financement / dette.
- [ ] Marketing et distribution.
- [ ] Contrats.
- [ ] Brevets et licences.
- [ ] Expansion internationale.
- [ ] Acquisitions et participations.
- [ ] Intégration verticale.

## Phase 5 — Première diversification

Après stabilisation du moteur commun :

- [ ] GPU.
- [ ] RAM / stockage.
- [ ] Cartes mères / chipsets.
- [ ] PC fixes / portables.
- [ ] Smartphones / tablettes.
- [ ] TV / écrans.
- [ ] Logiciels / système d'exploitation.

L'ordre exact dépendra de la qualité de la vertical slice et des synergies disponibles.

## Phase 6 — IA et monde vivant

- [ ] Assistant du joueur basé sur les données réelles de la partie.
- [ ] Conseillers spécialisés (finance, technologie, production, marketing...).
- [ ] Personnalités concurrentes.
- [ ] Réactions médias / analystes.
- [ ] Négociations enrichies.
- [ ] Mémoire d'événements importants.
- [ ] Mode sans LLM avec templates et logique locale.

Voir `docs/AI_IMMERSION.md`.

## Phase 7 — Nouveaux secteurs technologiques

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

## Phase 8 — Réalisme avancé

- [ ] Chaînes d'approvisionnement multi-niveaux.
- [ ] Géographie des marchés.
- [ ] Réglementation.
- [ ] Antitrust.
- [ ] Crises et pénuries.
- [ ] Rappels produit.
- [ ] Dépendances stratégiques.
- [ ] Fiscalité simplifiée ou avancée selon mode.
- [ ] Gouvernance / actionnaires si pertinent.

## Phase 9 — Mobile, PC et finition

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
