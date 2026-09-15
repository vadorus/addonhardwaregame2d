# Tycoon Hardware

> Nom de travail. Le projet évolue vers une simulation complète d'entreprise technologique couvrant hardware, software, services, infrastructures, IA, télécoms, spatial et autres secteurs technologiques.

## Statut

**Projet actif — dépôt en préparation.**

Le vrai projet Godot est encore sur le PC de développement et n'a pas encore été importé ici. Ce dépôt est donc préparé pour recevoir la source réelle sans reconstruire ni écraser ce qui existe déjà.

État fonctionnel connu à confirmer après import :

- Godot 4.x, 2D ;
- cible Windows / PC + Android ;
- système de temps avec jours, mois, années et vitesses x1/x2/x3 ;
- économie de base avec trésorerie, revenus et dépenses mensuelles ;
- première UI de gestion.

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

## IA et immersion

La simulation reste calculée par Godot. L'IA générative pourra être utilisée comme couche d'immersion pour :

- un assistant / conseiller du joueur ;
- des rapports et réunions ;
- des concurrents avec personnalités cohérentes ;
- des négociations ;
- des médias, analystes et réactions du marché.

Le jeu devra rester fonctionnel même sans LLM.

## Première vertical slice

La vision est volontairement vaste, mais le développement restera progressif.

Premier objectif jouable :

**créer une entreprise → rechercher un CPU → concevoir → produire → fixer le prix → vendre → mesurer marge, réputation et part de marché → financer la génération suivante.**

Cette boucle servira ensuite de base générique pour les autres secteurs technologiques.

## Documentation

- [`docs/VISION.md`](docs/VISION.md) — vision globale du jeu ;
- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — piliers et systèmes de game design ;
- [`docs/AI_IMMERSION.md`](docs/AI_IMMERSION.md) — architecture IA / immersion ;
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — ordre de développement ;
- [`docs/IMPORT_FROM_PC.md`](docs/IMPORT_FROM_PC.md) — procédure d'import du vrai projet Godot.

## Organisation prévue

```text
TycoonHardware/
├─ project.godot
├─ assets/
├─ scenes/
├─ scripts/
├─ data/
├─ ui/
├─ tests/
├─ docs/
└─ .github/
```

Cette structure sera adaptée au projet réel après son import ; aucun fichier existant du PC ne doit être écrasé uniquement pour respecter ce schéma.

## Prochaine étape obligatoire

Avant de coder de nouvelles fonctionnalités :

1. récupérer le dossier Godot réel depuis le PC de développement ;
2. faire une sauvegarde locale ;
3. comparer son contenu au dépôt ;
4. importer sans inclure `.godot/`, builds, secrets ou fichiers temporaires ;
5. lancer le projet depuis un clone propre ;
6. vérifier PC et Android ;
7. seulement ensuite reprendre le gameplay.

## Règles Git

- `main` devra devenir la branche stable quand le dépôt sera normalisé ;
- développement par branches courtes (`feature/...`, `fix/...`) ;
- Pull Request pour les changements importants ;
- aucun secret, build ou cache Godot versionné ;
- commits courts et explicites (`feat:`, `fix:`, `docs:`, `chore:`).

## Plateformes visées

- Windows / PC ;
- Android ;
- autres plateformes éventuellement plus tard si l'architecture le permet.

## Licence

Aucune licence publique définie pour le moment. Le dépôt reste privé pendant le développement.
