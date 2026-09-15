# Import du projet réel depuis le PC

But : faire de GitHub la source versionnée de Tycoon Hardware **sans écraser ni perdre l'état du projet Godot présent sur le PC**.

## Avant l'import

- [ ] Fermer Godot.
- [ ] Faire une copie de sauvegarde complète du dossier du jeu.
- [ ] Identifier le dossier racine contenant `project.godot`.
- [ ] Vérifier la version de Godot utilisée.
- [ ] Vérifier s'il existe des fichiers locaux sensibles (`.env`, clés, tokens, certificats, credentials Android).
- [ ] Vérifier les gros fichiers et assets avant le premier push.

## À ne pas importer

Le `.gitignore` du dépôt exclut déjà notamment :

- `.godot/` ;
- `.import/` ;
- builds / exports ;
- APK / AAB ;
- fichiers temporaires et logs ;
- `.env` et configurations locales.

Avant tout push, contrôler quand même `git status` pour vérifier qu'aucun secret ou build n'est suivi par erreur.

## Procédure recommandée

1. Cloner le dépôt privé dans un nouveau dossier.
2. Copier le contenu du vrai projet Godot dans ce clone, **sans copier son éventuel ancien dossier `.git`**.
3. Comparer les fichiers déjà présents (`README.md`, `.gitignore`, `.gitattributes`, `docs/`) avant tout remplacement.
4. Lancer Godot depuis le clone.
5. Vérifier que les scènes se chargent et que le jeu démarre.
6. Vérifier le système de temps, l'économie et l'UI existants.
7. Contrôler `git status`.
8. Faire un premier commit d'import clairement identifié.
9. Push sur une branche d'import et vérifier la différence sur GitHub avant intégration.

## Contrôles après import

- [ ] `project.godot` présent.
- [ ] scène principale identifiable.
- [ ] autoloads documentés.
- [ ] scripts principaux identifiés.
- [ ] aucune ressource manquante au démarrage.
- [ ] aucune donnée sensible versionnée.
- [ ] aucun cache Godot versionné.
- [ ] build PC fonctionnel.
- [ ] état Android documenté.

## Après validation

Créer ou mettre à jour :

- `docs/ARCHITECTURE.md` avec la vraie architecture ;
- la roadmap selon ce qui existe déjà ;
- une CI minimale de validation Godot ;
- les premières Issues de gameplay ;
- la branche stable `main` lorsque le dépôt est prêt.
