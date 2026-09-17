# Consignes agents — Tech Empire

Ces règles s'appliquent à tout le dépôt.

## Priorité produit

- Le périmètre jouable actuel reste la branche **CPU**.
- Ne pas développer GPU, mobile, spatial, militaire ou d'autres secteurs avant validation de la vertical slice CPU.
- La simulation Godot doit rester fonctionnelle sans service IA ni connexion Internet.
- Favoriser une boucle amusante, lisible et testable plutôt qu'une accumulation de paramètres.

## Architecture et compatibilité

- Moteur cible : Godot 4.7.2, GDScript, sans dépendance .NET.
- Préserver les anciennes sauvegardes avec une migration explicite lors de toute évolution de schéma.
- Réutiliser les managers et modèles existants avant d'introduire un nouveau système.
- Ne pas réorganiser massivement le projet sans demande explicite.
- Ne jamais versionner de secret, jeton, cache Godot, APK, AAB ou build local.

## Validation obligatoire

Après une modification de code, exécuter autant que possible :

```bash
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . res://tests/smoke_test.tscn
```

Toute nouvelle mécanique doit ajouter ou adapter un test déterministe dans `tests/`.

## Exigences pour le pilote Agents API

- Lire la documentation pertinente dans `docs/` avant de modifier le gameplay.
- Travailler uniquement dans la copie de travail fournie.
- Ne jamais lancer `git commit`, `git push`, `gh` ou modifier un remote.
- Ne pas modifier `.github/`, `tools/agents/`, `AGENTS.md`, `.gitignore`, `.gitattributes` ou tout fichier secret.
- Ne pas utiliser le réseau depuis une commande du projet.
- Ne pas démarrer de sous-agent sauf si la tâche l'exige explicitement.
- À la fin, écrire `.agent-output/report.md` avec : résumé, fichiers touchés, tests réellement exécutés, résultats, limites et points à vérifier humainement.

Une tâche n'est terminée que si le rapport distingue clairement ce qui a été vérifié de ce qui reste supposé.
