# Tech Empire / Tycoon Hardware

> **Nom de travail.** Jeu de gestion d'entreprise technologique sous Godot 4.7.2. Le joueur part d'un petit QG, conçoit ses propres composants et fait évoluer progressivement l'entreprise, ses équipes, ses locaux, sa production et sa présence sur le marché.

## Statut

**Projet actif — Tech Empire 0.2.12-preview.7.**

La vertical slice jouable est volontairement centrée sur la **gamme CPU**. Les futures gammes (GPU, RAM, cartes mères et autres produits technologiques) restent hors périmètre tant que la boucle CPU n'est pas suffisamment profonde, lisible et équilibrée.

Cibles actuelles :

- Windows x86_64 ;
- Android arm64 ;
- Godot **4.7.2**, GDScript, 2D.

## Boucle jouable actuelle

La boucle principale est désormais :

**observer → choisir une architecture → financer la R&D → arbitrer les phases → industrialiser → fixer prix/capacité → lancer → observer le marché → préparer la génération suivante.**

Fonctionnalités déjà intégrées :

- temps avec pause et vitesses x1/x2/x3 ;
- économie mensuelle, dette, intérêts, financement et faillite durable ;
- sauvegarde manuelle + autosave mensuel / pause / perte de focus ;
- création d'entreprise et division CPU active ;
- laboratoire CPU : cœurs, fréquence, cache, gravure et TDP ;
- trois plans de génération proposés par l'équipe : prudent, équilibré et audacieux ;
- estimation coût / délai / risque / confiance / durée de compétitivité ;
- arbitrages R&D entre les phases avec effets réels sur le projet ;
- gamme automatique **Essentiel / Signature / Apex** ;
- rendement de génération, binning, coûts et capacités par modèle ;
- investissement initial d'industrialisation et frais fixes de capacité ;
- prévision avant lancement : demande, ventes, utilisation, part de marché et résultat mensuel ;
- concurrents qui renouvellent leurs générations ;
- obsolescence et perte progressive de pertinence des anciens produits ;
- contrats B2B, retours SAV, garanties et satisfaction ;
- réputation, marketing, support et environnement ;
- personnel, recrutement, expérience, leadership et délégation ;
- brevets, licences, presse et premières filiales.

## UX et progression

Le jeu cherche une interface de gestion lisible et visuelle plutôt qu'un tableur.

Éléments actuels :

- QG central avec prochaine décision ;
- menu **Actions** contextuel avec une priorité dynamique ;
- onboarding léger jusqu'au premier CPU lancé ;
- progression persistante des quatre **pôles** :
  - Laboratoire ;
  - Production ;
  - Marché ;
  - Équipe ;
- mini-scènes des pôles directement sur le QG ;
- notification lorsqu'un pôle franchit un palier ;
- salariés visibles dans le bureau ;
- trophées des générations CPU lancées ;
- cartes interactives pour Produits, Marché, Personnel, plans R&D, réputation et Presse ;
- interface compacte et cibles tactiles renforcées sur mobile.

### Terminologie canonique

Pour éviter l'ancienne ambiguïté du mot « secteur » :

- **Gamme produit** = CPU, futures GPU, RAM, cartes mères, etc. ;
- **Pôle** = Laboratoire, Production, Marché, Équipe ;
- **Département** = unité de management/délégation interne (R&D, Production, Marketing, Support, Finance) ;
- **Écran** = vue de l'interface.

Les anciennes clés internes utilisant `sector` restent temporairement disponibles pour conserver la compatibilité avec les sauvegardes existantes.

## Première session

Le joueur démarre avec 500 000 € et une équipe initiale. Le jeu doit permettre de terminer une première génération CPU et de l'industrialiser en utilisant, si nécessaire, le financement disponible.

Un smoke test dédié joue désormais cette première génération automatiquement afin d'éviter qu'un changement d'équilibrage rende la partie impossible avant le premier lancement.

## Android / PC

Android :

- layout compact forcé sur mobile ;
- tailles tactiles minimales renforcées ;
- bouton Retour géré par le jeu ;
- mode immersif / edge-to-edge ;
- APK arm64.

PC :

- fenêtré / plein écran ;
- résolutions sélectionnables ;
- VSync ;
- limitation FPS configurable.

Les paramètres communs incluent le volume, l'échelle UI et la limite FPS.

## Builds et version

Version courante :

- jeu : **0.2.12-preview.7** ;
- Android : versionCode **33** ;
- Windows : file version **0.2.12.2**.

Les exports excluent les répertoires de développement `tests/`, `docs/` et `tools/`.

Le workflow automatique `.github/workflows/preview-builds-v2.yml` produit :

- `TechEmpire-Windows-v0.2.12-preview.7` ;
- `TechEmpire-Android-v0.2.12-preview.7`.

Le workflow de future signature Android permanente est conservé séparément en déclenchement manuel.

## Bug reports et mises à jour

`BugReporter.gd` :

- collecte uniquement des diagnostics techniques minimaux ;
- demande un consentement explicite ;
- n'envoie ni sauvegarde, ni nom d'entreprise, ni IP ;
- conserve les rapports localement tant que le collecteur VPS n'est pas configuré.

`UpdateManager.gd` :

- attend un manifeste HTTPS ;
- compare la version installée ;
- affiche la mise à jour disponible ;
- ne fait aucune installation silencieuse.

Les endpoints VPS sont volontairement vides tant que le service isolé Tech Empire n'est pas déployé.

## Validation automatique

La CI vérifie à chaque évolution importante :

1. import et parsing Godot 4.7.2 ;
2. boot headless de la scène principale ;
3. smoke test de la boucle CPU ;
4. première génération financièrement survivable ;
5. migrations de sauvegardes ;
6. progression persistante des pôles ;
7. Bug Reporter ;
8. démarrage GitHub Actions ;
9. exports Windows et Android.

La CI ne remplace pas les tests visuels et tactiles sur de vrais appareils.

## Vision

À long terme, Tech Empire doit permettre de faire évoluer une petite entreprise spécialisée vers un groupe technologique mondial : composants, PC, logiciels, cloud, IA, robotique, télécoms, spatial et autres technologies.

Le cœur restera une seule simulation cohérente :

**observer le marché → décider → investir → rechercher → concevoir → produire → vendre → analyser → réinvestir / pivoter / acquérir.**

La complexité doit pouvoir être réduite par la délégation plutôt que par la suppression des systèmes.

Une éventuelle IA générative pourra renforcer l'immersion (conseiller, concurrents, médias, négociations), mais le jeu doit rester entièrement fonctionnel sans API payante ni LLM.

## Documentation

- [`docs/VISION.md`](docs/VISION.md) — vision globale ;
- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — piliers et systèmes ;
- [`docs/DESIGN_BIBLE.md`](docs/DESIGN_BIBLE.md) — décisions canoniques ;
- [`docs/CPU_VERTICAL_SLICE.md`](docs/CPU_VERTICAL_SLICE.md) — boucle CPU ;
- [`docs/UX_ART_DIRECTION.md`](docs/UX_ART_DIRECTION.md) — direction UX / visuelle ;
- [`docs/AI_IMMERSION.md`](docs/AI_IMMERSION.md) — couche IA / immersion ;
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — ordre de développement ;
- [`docs/PROTOTYPE_V02.md`](docs/PROTOTYPE_V02.md) — historique du prototype.

## Workflow de développement

- GitHub est la source de vérité ;
- branche stable : `master` ;
- branche active actuelle : `feat/preview-builds-bug-reporter` ;
- PR #11 porte la preview 0.2.12 ;
- CI Godot obligatoire avant de considérer une modification validée ;
- aucun merge vers `master` sans validation explicite ;
- aucun secret, build, cache `.godot/`, keystore ou fichier sensible versionné.

## Licence

Aucune licence publique définie pour le moment. Le dépôt reste privé pendant le développement.
