# Tech Empire (Godot) — consignes des agents

Ce fichier est la **seule source** des consignes. `CLAUDE.md`, `GEMINI.md` et la règle Antigravity ne font que renvoyer ici. Le garder court : une règle à un seul endroit.

## Lire au démarrage (rien d'autre)
1. Ce fichier.
2. `docs/ETAT.md` : vision, décisions de jeu et leurs raisons.
3. L'issue de ta tâche, puis le tableau de bord **Jade #93** et les étiquettes `orch:*` pour savoir ce qui est déjà pris.

À lire **avant toute écriture** (réservation, modification, PR) :
- `docs/AI_ENFORCEMENT.md`.

À lire **seulement quand c'est utile** :
- `docs/AI_COORDINATION.md` et `docs/AI_TASK_TEMPLATE.md` : en cas de doute sur le protocole ou pour rédiger une passation.

## Le projet
- **Avant de modifier le gameplay**, lire la documentation de jeu concernée dans `docs/` (`DESIGN_BIBLE.md`, `CPU_VERTICAL_SLICE.md`, `UX_ART_DIRECTION.md`…).
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

## Avant d'écrire quoi que ce soit
1. **Sans tâche attribuée par Alexandre** (ou issue nommant un écrivain unique et ses `Zones`) : **lecture seule**. Aucune modification, commit, push ni fusion.
2. **GitHub ou le précontrôle indisponible : lecture seule.**
3. Inventorier **toutes les PR ouvertes, brouillons compris**, les issues réservées et les derniers commits de `v013/demo-octobre`. Une PR existante vaut réservation. Recommencer avant toute reprise et avant fusion.
4. Relever la branche ouverte et l'**état Git local** (`git status`) avant d'intervenir.
5. Travailler dans une **copie ou un `git worktree` isolé**, jamais dans le dossier d'un autre agent. Ne jamais écraser des modifications locales ; préserver sauvegardes et secrets.

## Règles qui ne bougent jamais
- **Un seul écrivain par tâche**, un relecteur **différent**. Une PR ou une issue `Réservée` / `En cours` / `En revue` réserve ses `Zones`. Chevauchement : s'arrêter et demander l'arbitrage d'Alexandre.
- **Aucun commit, push, fusion, publication Play Store, build signé ni appel d'API payant sans autorisation explicite d'Alexandre**, propre à l'opération. Ni ce fichier, ni un inventaire, ni un CI vert ne crée une autorisation, un verrou ou une preuve de relecture. **Seul Alexandre écrit `/autoriser`** : aucune IA ne le publie, ne le prépare dans un commentaire ni ne le recopie.
- Ne jamais modifier la sauvegarde réelle du Pixel : travailler sur une copie.
- Si un document cité ici manque dans la branche ouverte : ne pas inventer son contenu, demander la bonne branche.
- Un CI vert ne prouve pas un build : vérifier compilation réelle, version de l'APK et signature.
- Passation : tâche, auteur, relecteur, branche et SHA de départ, fichiers modifiés, tests **réellement** exécutés, tests non faits. Aucun PASS sans preuve. Modèle : `docs/AI_TASK_TEMPLATE.md`.

## Pilote Agents API (prioritaire quand il s'applique)
- Travailler uniquement dans la copie fournie ; pas de `git commit`, `git push`, `gh` ni de modification de remote.
- Ne pas modifier `.github/`, `tools/agents/`, `AGENTS.md`, `.gitignore`, `.gitattributes` ni aucun fichier secret.
- Pas de réseau depuis une commande du projet ; pas de sous-agent sauf demande explicite.
- À la fin, écrire `.agent-output/report.md` : résumé, fichiers touchés, tests réellement exécutés, résultats, limites, points à vérifier humainement.

## Qui relit quoi
Le relecteur est toujours celui nommé dans l'issue, et jamais l'auteur.

**Relecture Claude obligatoire** pour : économie et équilibrage structurant, sauvegardes et migrations, découpage de `main.gd`, signature Android et secrets, workflows, et tous les fichiers de consignes (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `docs/AI_*.md`, `docs/ETAT.md`). **Quand Claude en est l'auteur**, c'est Codex qui relit.

**Relecture Gemini possible** (quand Claude n'a plus de quota) uniquement pour la documentation et les tests à faible risque, dans les mêmes limites que l'orchestration de Jade (phase A).

## Garder l'état à jour
- **Ce qui est en cours** vit dans le tableau de bord Jade #93 et les étiquettes `orch:*`, pas dans un fichier.
- **Une décision d'Alexandre** s'ajoute à `docs/ETAT.md` avec sa raison, en une ligne. On ne modifie `docs/ETAT.md` que dans une PR consacrée aux consignes ou à l'état, jamais dans une PR de fonctionnalité, pour ne pas bloquer les autres PR sur ce fichier.
