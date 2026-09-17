# Tech Empire / Tycoon Hardware

> **Nom de travail.** Simulation de gestion d'entreprise technologique couvrant progressivement hardware, software, services, infrastructures, IA, télécoms, spatial et autres secteurs technologiques.

## Statut

**Projet actif — prototype V0.2.8 sous Godot 4.7.2.**

La vraie source Godot est maintenant versionnée dans ce dépôt. Une CI GitHub lance Godot 4.7.2 en mode headless à chaque push / Pull Request pour vérifier l'import du projet, le chargement de la scène principale et un smoke test de simulation.

État actuellement validé :

- Godot **4.7.2**, GDScript, 2D / interface de gestion ;
- cible Windows / PC + Android ;
- temps avec pause et vitesses x1/x2/x3 ;
- économie mensuelle et rapports de clôture ;
- création d'entreprise avec division CPU active ;
- socle générique de divisions, maturité et progression par génération ;
- conseil d’architecture CPU : plans prudent, équilibré et audacieux calculés par l’équipe ;
- prévisions de budget, délai, risque, confiance, durée de compétitivité et potentiel de gamme ;
- déclinaison automatique d’une architecture terminée en gamme Essentiel, Signature et Apex ;
- rendement de génération, binning, allocation des puces, capacités et coûts propres à chaque modèle ;
- demande plafonnée à l’échelle du portefeuille pour éviter de vendre plusieurs fois le même marché ;
- personnel, expérience, équipes, départements et délégation ;
- laboratoire CPU interactif : cœurs, fréquence, cache, gravure et enveloppe thermique ;
- R&D en plusieurs phases avec rapports techniques ;
- développement interne / hybride / externe ;
- technologies et savoir-faire ;
- produits, prix, capacité de production, ventes et parts de marché ;
- segments clients, benchmarks et satisfaction ;
- SAV, garanties, réputation, marketing et environnement ;
- presse / médias, contrats B2B, brevets, licences et premières filiales ;
- sauvegarde / chargement ;
- nouvelle identité visuelle, navigation dédiée et QG centré sur le projet CPU prioritaire ;
- aperçu en direct des compromis performance, efficacité, fiabilité, coût, risque et durée.

## Périmètre jouable actuel

La vertical slice est volontairement limitée à la branche **CPU**. Les autres secteurs restent paramétrés dans les données afin de préparer les futures extensions, mais ils sont affichés comme « à venir », désactivés dans l’interface et refusés par le moteur de R&D. Ils ne doivent pas être développés avant que la boucle CPU soit profonde, équilibrée et amusante.

L’interface V0.2.8 propose un véritable laboratoire CPU : le joueur définit son brief, demande trois plans générationnels à l’équipe, choisit une recommandation puis peut encore régler les cœurs, la fréquence, le cache, la finesse de gravure et le TDP. Une architecture terminée devient ensuite une famille de trois références aux performances, coûts, rendements, capacités et clientèles distincts. Le QG réutilise le design choisi dans son aperçu graphique.

## Vision

Le joueur crée une entreprise technologique et la fait évoluer d'une petite société spécialisée vers un groupe mondial pouvant opérer dans de nombreux secteurs :

- semi-conducteurs et composants ;
- PC, smartphones, TV, consoles et objets connectés ;
- logiciels, systèmes d'exploitation et services ;
- cloud, datacenters et réseaux ;
- IA, robotique et automatisation ;
- télécoms ;
- mobilité ;
- satellites et technologies spatiales ;
- technologies futures.

Le cœur du jeu est la gestion d'une **entreprise complète** : stratégie, finances, R&D, recrutement, production, fournisseurs, marketing, distribution, SAV, réputation, concurrence, acquisitions, filiales, réglementation et intégration verticale.

La boucle centrale visée est :

**observer le marché → décider → investir → rechercher → concevoir → produire → vendre → analyser → réinvestir / pivoter / acquérir.**

## Philosophie de gestion

Le jeu doit proposer **une seule simulation**, pas plusieurs jeux séparés selon la difficulté. La complexité ressentie dépendra surtout de la délégation : le joueur pourra gérer directement un département, le superviser ou confier davantage d'autonomie à un responsable.

L'expérience individuelle, l'expérience d'équipe, les spécialisations et la qualité du management devront influencer les résultats sans transformer l'interface en tableur illisible.

## IA et immersion

La simulation reste calculée par Godot. L'IA générative pourra être ajoutée comme couche d'immersion pour :

- un assistant / conseiller du joueur ;
- des rapports et réunions ;
- des concurrents avec personnalités cohérentes ;
- des négociations ;
- des médias, analystes et réactions du marché.

Le jeu devra rester fonctionnel même sans LLM.

## Validation automatique

Le workflow `.github/workflows/godot-ci.yml` utilise Godot 4.7.2 et vérifie :

1. import et parsing du projet ;
2. démarrage headless de la scène principale ;
3. smoke test : verrou CPU/divisions → comparaison de trois plans générationnels → lancement d’une architecture → création d’une gamme de trois modèles → rendement/binning → demande portefeuille → migrations d’anciennes sauvegardes.

La CI ne remplace pas les tests de gameplay visuels sur Windows / Android, mais elle évite de transmettre une version contenant une erreur GDScript évidente.

## Documentation

- [`docs/VISION.md`](docs/VISION.md) — vision globale ;
- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — piliers et systèmes ;
- [`docs/DESIGN_BIBLE.md`](docs/DESIGN_BIBLE.md) — décisions canoniques issues de la conception ;
- [`docs/CPU_VERTICAL_SLICE.md`](docs/CPU_VERTICAL_SLICE.md) — boucle CPU complète à implémenter ;
- [`docs/UX_ART_DIRECTION.md`](docs/UX_ART_DIRECTION.md) — interface chaleureuse et progression des bureaux ;
- [`docs/AI_IMMERSION.md`](docs/AI_IMMERSION.md) — architecture IA / immersion ;
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — ordre de développement ;
- [`docs/PROTOTYPE_V02.md`](docs/PROTOTYPE_V02.md) — contenu du prototype actuel ;
- [`docs/IMPORT_FROM_PC.md`](docs/IMPORT_FROM_PC.md) — historique / procédure d'import du projet local.

## Organisation actuelle

```text
Tech-Empire/
├─ project.godot
├─ main.tscn
├─ main.gd
├─ scripts/
├─ tests/
├─ docs/
└─ .github/workflows/
```

La structure sera raffinée progressivement sans réorganisations inutiles qui casseraient le prototype.

## Workflow de développement

- dépôt GitHub = source de vérité ;
- branche stable actuelle : `master` (normalisation vers `main` prévue plus tard) ;
- branches courtes pour les évolutions importantes ;
- Pull Requests quand utile ;
- CI Godot obligatoire avant de considérer une modification comme techniquement validée ;
- aucun secret, build, cache `.godot/` ou fichier `*.import` versionné ;
- commits courts et explicites (`feat:`, `fix:`, `docs:`, `chore:`).

## Plateformes visées

- Windows / PC ;
- Android ;
- autres plateformes éventuellement plus tard si l'architecture le permet.

## Licence

Aucune licence publique définie pour le moment. Le dépôt reste privé pendant le développement.
