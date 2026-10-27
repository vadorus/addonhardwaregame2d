# Tech Empire (Godot) — consignes des agents

Ce fichier est la **seule source** des consignes. `CLAUDE.md`, `GEMINI.md` et la règle Antigravity ne font que renvoyer ici. Le garder court : une règle à un seul endroit.

## Lire au démarrage (rien d'autre)
1. Ce fichier.
2. `docs/ETAT.md` : vision, décisions de jeu et leurs raisons.
3. L'issue de ta tâche, puis le tableau de bord **Jade #93** et les étiquettes `orch:*` pour savoir ce qui est déjà pris.

À lire **seulement quand c'est utile** :
- `docs/AI_ENFORCEMENT.md` : avant de réserver des zones ou d'ouvrir une PR.
- `docs/AI_COORDINATION.md` et `docs/AI_TASK_TEMPLATE.md` : en cas de doute sur le protocole ou pour rédiger une passation.
- Les documents de jeu (`docs/DESIGN_BIBLE.md`, `docs/CPU_VERTICAL_SLICE.md`, `docs/UX_ART_DIRECTION.md`…) : seulement ceux qui concernent ta tâche.

## Le projet
- **Branche produit : `v013/demo-octobre`.** Ne jamais partir de `master` (branche GitHub par défaut).
- Godot 4.7.2, GDScript, sans .NET. Le jeu doit tourner sans IA ni Internet.
- Périmètre jouable : la branche **CPU** seulement. Pas de GPU, mobile, spatial ou militaire avant validation de la vertical slice CPU.
- Une boucle amusante, lisible et testable plutôt qu'une accumulation de paramètres.
- Préserver les anciennes sauvegardes : toute évolution de schéma passe par une migration explicite.
- Réutiliser les managers et modèles existants. Pas de réorganisation massive sans demande.
- Ne jamais versionner secret, jeton, cache Godot, APK, AAB ou build local.

## Validation obligatoire après une modification de code
```bash
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . res://tests/smoke_test.tscn
```
Toute nouvelle mécanique ajoute ou adapte un test déterministe dans `tests/`. Pour l'interface, essai réel au doigt sur une **copie** de la sauvegarde Pixel.

## Règles qui ne bougent jamais
- **Un seul écrivain par tâche**, un relecteur **différent**. Une PR ou une issue `Réservée` / `En cours` / `En revue` réserve ses `Zones`. Chevauchement : s'arrêter et demander l'arbitrage d'Alexandre.
- **Aucune fusion, aucune publication Play Store, aucun build signé, aucun appel d'API payant** sans l'accord d'Alexandre. **Seul Alexandre écrit `/autoriser`** : aucune IA ne le publie, ne le prépare dans un commentaire ni ne le recopie.
- Un CI vert ne prouve pas un build : vérifier compilation réelle, version de l'APK et signature.
- Passation : tests **réellement** exécutés, tests non faits, fichiers modifiés, SHA. Aucun PASS sans preuve.

## Pilote Agents API (prioritaire quand il s'applique)
- Travailler uniquement dans la copie fournie ; pas de `git commit`, `git push`, `gh` ni de modification de remote.
- Ne pas modifier `.github/`, `tools/agents/`, `AGENTS.md`, `.gitignore`, `.gitattributes` ni aucun fichier secret.
- Pas de réseau depuis une commande du projet ; pas de sous-agent sauf demande explicite.
- À la fin, écrire `.agent-output/report.md` : résumé, fichiers touchés, tests réellement exécutés, résultats, limites, points à vérifier humainement.

## Qui relit quoi
**Relecture Claude obligatoire** pour : économie et équilibrage structurant, sauvegardes et migrations, découpage de `main.gd`, signature Android et secrets, workflows, et tous les fichiers de consignes (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `docs/AI_*.md`, `docs/ETAT.md`).

**Relecture Gemini possible** (quand Claude n'a plus de quota) uniquement pour la documentation et les tests à faible risque, dans les mêmes limites que l'orchestration de Jade (phase A).

## Garder l'état à jour
- **Ce qui est en cours** vit dans le tableau de bord Jade #93 et les étiquettes `orch:*`, pas dans un fichier.
- **Une décision d'Alexandre** s'ajoute à `docs/ETAT.md` avec sa raison, en une ligne. On ne modifie `docs/ETAT.md` que dans une PR dédiée, pour ne pas bloquer les autres PR sur ce fichier.
