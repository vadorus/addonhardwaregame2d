# Consignes agents — Tech Empire

Ces règles s'appliquent à tout le dépôt.

## Source de vérité

- Moteur cible : **Godot 4.7.2**, GDScript, sans dépendance .NET.
- Version preview actuelle : **0.2.12-preview.7**.
- Le dépôt GitHub est la source de vérité.
- Ne pas considérer une modification comme validée uniquement parce qu'un fichier a été écrit : le parse, le boot et les tests doivent passer.

## Priorité produit

- La seule **gamme produit** jouable actuellement est **CPU**.
- Ne pas développer GPU, RAM, mobile, spatial, militaire ou d'autres gammes avant validation explicite de la vertical slice CPU.
- La simulation Godot doit rester fonctionnelle sans service IA, API payante ni connexion Internet.
- Favoriser une boucle amusante, lisible et testable plutôt qu'une accumulation de paramètres.
- Priorités actuelles : boucle CPU, UX PC/Android, progression visuelle, équilibre économique et stabilité.

## Terminologie canonique

Ne pas réintroduire l'ancienne ambiguïté du mot « secteur ».

- **Gamme produit** : CPU, futures GPU, RAM, cartes mères, etc.
- **Pôle** : Laboratoire, Production, Marché, Équipe.
- **Département** : unité interne de management/délégation (R&D, Production, Marketing, Support, Finance).
- **Écran** : vue de l'interface.

Les anciennes clés internes `sector`, `SECTORS`, `SECTOR_ORDER` et fonctions legacy restent temporairement disponibles pour la compatibilité des sauvegardes. Le nouveau code doit préférer les API canoniques :

- `GameData.get_product_family_keys()`
- `GameData.get_active_product_family_keys()`
- `GameData.is_product_family_active()`
- `GameData.get_product_family()`
- `DepartmentProgression.get_pole_ids()`
- `DepartmentProgression.get_pole_state()`
- `DepartmentProgression.get_all_pole_states()`

## Boucle CPU à préserver

La boucle actuelle comprend notamment :

1. choix du brief et de l'architecture ;
2. comparaison de trois plans de génération ;
3. R&D multi-phases ;
4. arbitrages obligatoires entre les phases ;
5. création d'une gamme Essentiel / Signature / Apex ;
6. investissement d'industrialisation et choix de capacité ;
7. prévision avant lancement ;
8. ventes, concurrence, B2B, SAV et réputation ;
9. obsolescence et nouvelles générations concurrentes ;
10. préparation de la génération suivante.

Ne pas contourner ces systèmes avec des valeurs codées en dur uniquement pour rendre un test vert.

## Économie

- Capital initial : 500 000 €.
- Le financement bancaire existe et produit des intérêts.
- Une trésorerie durablement inférieure ou égale à -1 000 000 € pendant 3 mois déclenche la faillite.
- Le smoke test vérifie qu'une première génération CPU peut être terminée et industrialisée avec le financement disponible.
- Toute modification des coûts R&D, salaires, capacités, prix, demande ou financement doit conserver ce test ou l'adapter explicitement si le design change.

## UX

- Le QG doit rester l'écran principal et montrer la prochaine décision.
- Le menu Actions possède une priorité contextuelle ; ne pas revenir à une simple table des matières.
- Les informations comparables doivent préférer des cartes aux murs de texte.
- Réutiliser `ui/EntityCard.gd` avant de créer un nouveau composant similaire.
- Les quatre pôles doivent rester visibles depuis le QG et leur meilleur palier atteint est persistant.
- Sur Android, conserver le layout compact forcé et des cibles tactiles suffisamment grandes.
- Ne pas transformer le jeu en interface de tableur.

## Sauvegardes et compatibilité

- Préserver les anciennes sauvegardes avec une migration explicite lors de toute évolution de schéma.
- `SaveManager.SAVE_VERSION` doit être augmenté uniquement lorsqu'une évolution de format le justifie.
- Les anciens champs legacy ne doivent pas être supprimés sans migration testée.
- Autosave : changement de mois, pause/perte de focus et sortie Android.

## Builds

- Windows x86_64 et Android arm64 sont les plateformes de preview.
- `tests/`, `docs/` et `tools/` sont exclus des exports distribués.
- `Preview Builds V2` est le workflow automatique de preview.
- Le workflow de signature Android permanente reste manuel tant que les secrets définitifs ne sont pas validés.
- Ne jamais versionner de secret, jeton, mot de passe, keystore, APK, AAB, cache Godot ou build local.

## Validation obligatoire

Après une modification de code, exécuter autant que possible :

```bash
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . res://tests/smoke_test.tscn
godot --headless --path . res://tests/department_progression_test.tscn
```

Toute nouvelle mécanique doit ajouter ou adapter un test déterministe dans `tests/`.

La CI de la PR doit idéalement rester verte pour :

- Godot CI ;
- Bug Reporter CI ;
- Preview Probe ;
- Preview Builds V2.

## Exigences pour le pilote Agents API

- Lire la documentation pertinente dans `docs/` avant de modifier le gameplay.
- Travailler uniquement dans la copie de travail fournie.
- Ne jamais lancer `git commit`, `git push`, `gh` ou modifier un remote.
- Ne pas modifier `.github/`, `tools/agents/`, `AGENTS.md`, `.gitignore`, `.gitattributes` ou tout fichier secret.
- Ne pas utiliser le réseau depuis une commande du projet.
- Ne pas démarrer de sous-agent sauf si la tâche l'exige explicitement.
- À la fin, écrire `.agent-output/report.md` avec : résumé, fichiers touchés, tests réellement exécutés, résultats, limites et points à vérifier humainement.

Une tâche n'est terminée que si le rapport distingue clairement ce qui a été vérifié de ce qui reste supposé.
