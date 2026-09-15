# Tycoon Hardware

Jeu de gestion 2D sous Godot autour de la création d'une entreprise de matériel informatique.

## Statut

**Projet actif — préparation du dépôt GitHub.**

Le vrai projet Godot est encore sur le PC de développement et n'a pas encore été importé ici. Le dépôt est donc préparé pour recevoir la source réelle sans reconstruire inutilement ce qui existe déjà.

État fonctionnel connu à confirmer après import :

- Godot 4.x, 2D ;
- cible PC + Android ;
- système de temps avec jours, mois, années et vitesses x1/x2/x3 ;
- économie de base avec trésorerie, revenus et dépenses mensuelles ;
- première UI de gestion ;
- prochaine grande étape : boucle de conception / R&D / production / vente d'un premier processeur.

## Vision du jeu

Le joueur dirige une entreprise hardware et développe progressivement plusieurs familles de composants :

- CPU ;
- GPU ;
- RAM ;
- cartes mères.

La boucle long terme doit relier :

**R&D → conception → production → qualité → prix → ventes → réputation → parts de marché → nouvelle génération.**

Des systèmes plus avancés pourront ensuite couvrir la gravure, l'IPC, le cache, le TDP, les fonderies, le taux de panne, le SAV, les concurrents IA et différents niveaux de réalisme.

## Organisation prévue

```text
TycoonHardware/
├─ project.godot
├─ assets/          # graphismes, audio, polices
├─ scenes/          # scènes Godot
├─ scripts/         # logique de jeu
├─ data/            # données d'équilibrage
├─ ui/              # ressources/interface si séparées
├─ tests/           # tests automatisés si ajoutés
├─ docs/            # architecture, roadmap, décisions
└─ .github/         # templates et automatisation GitHub
```

Cette structure sera adaptée au projet réel après son import ; aucun fichier existant du PC ne doit être écrasé juste pour respecter ce schéma.

## Prochaine étape obligatoire

Avant de coder de nouvelles fonctionnalités :

1. récupérer le dossier Godot réel depuis le PC de développement ;
2. faire une sauvegarde locale ;
3. comparer son contenu au dépôt ;
4. importer le projet sans inclure `.godot/`, builds, secrets ou fichiers temporaires ;
5. lancer le projet et vérifier que l'état GitHub reproduit bien la version locale ;
6. seulement ensuite reprendre le gameplay.

Voir [`docs/IMPORT_FROM_PC.md`](docs/IMPORT_FROM_PC.md) et [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Règles Git

- `main` devra devenir la branche stable quand le dépôt sera normalisé ;
- développement par branche courte (`feature/...`, `fix/...`) ;
- une Pull Request pour les changements importants ;
- ne jamais versionner de secrets, builds ou caches Godot ;
- commits courts et explicites (`feat:`, `fix:`, `docs:`, `chore:`).

## Plateformes visées

- Windows / PC ;
- Android.

## Licence

Aucune licence publique définie pour le moment. Le dépôt reste privé pendant le développement.
