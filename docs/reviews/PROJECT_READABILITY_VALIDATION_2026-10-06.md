# RC3 — création lisible et projets visibles au garage

Cette étape prolonge P0/P1 sur `codex/p0-p1-project-reliability`, PR #81 en
brouillon. Version 0.11.1-rc3, code Android 19 ; schéma de sauvegarde 34.

## Changement vérifié

Le premier atelier CPU et le produit logiciel mettent en avant coût mensuel,
coût total estimé, délai et promesse du produit. Les estimations CPU conservent
leur incertitude. Les calculs détaillés sont facultatifs ; le comparatif logiciel
reste disponible avec sa référence gardée et ses niveaux exacts.

Sur le logiciel, résumé, financement minimum et refus éventuel restent visibles
avec le bouton de lancement pendant le défilement. Le coût total est distinct
du financement minimum. Les exclusions (salaires, locaux et dépenses ultérieures)
restent affichées. Aucune simulation ni dépense ne se produit en ouvrant les détails.

Les repères du garage suivent les projets réels : plan CPU à l'établi, puce de
l'époque du design au banc de test à partir de Prototype, puis inspection en
Validation ; plan logiciel, construction puis tests, bêta comprise. Leur cercle
montre l'avancement réel et les décisions gardent leur pastille. Les repères
reprennent leur aspect initial après disparition du projet.

Les règles de simulation et de sauvegarde restent celles de P0/P1. Aucun marché,
système de progression ou champ de sauvegarde supplémentaire n'est introduit.

## Validation locale

- Import et démarrage de la scène principale, sans erreurs de script.
- `software_choice_preview_test` : trois difficultés, prévisions du manager,
  comparaison sans effets de bord ; résumé et lancement sans défilement sur cinq
  formats, détails ouvrables, financement insuffisant toujours visible.
- `project_brief_world_test` : devis CPU fidèle, détails et refus, phases CPU/SW,
  illustration fidèle au procédé, progression fractionnaire, pause sans effets de
  bord, reprise des marqueurs après fin du projet, cinq formats.
- `workshop_layout_test`, `complete_layout_test`, `garage_layout_test`,
  `branding_config_test` et `smoke_test` : réussis aux étapes concernées.
- Captures rendues dans Godot avec OpenGL, GTX 1660 Ti, à 1280×720 et 800×480.
  Le probe utilise une partie de test sans écritures ; les transitions de phase
  sont des fixtures de présentation, pas une carrière complète.

Les premières exécutions ont détecté une variable CPU redéclarée et une bêta
affichée comme construction ; ces défauts ont été corrigés et les suites concernées
relancées. Les journaux d'échec initiaux ne sont pas des preuves de réussite.
Deux avertissements d'ancrage préexistants subsistent dans le smoke test.

## Limites

Les fichiers Windows et Android sont exportés, mais un export ne constitue pas
un test tactile. Le PC est vérifié dans Godot ; le lancement autonome de l'EXE
reste distinct de cette preuve. Aucun nouveau test tactile ni installation Pixel
ne fait partie de cette étape. Le dernier essai Pixel concernait la RC1.

Les captures à 800×480 montrent l'accès aux actions ; elles ne prouvent pas que
le texte est confortable sur tous les téléphones. Le [protocole novice](../design/NOVICE_15_MIN_PLAYTEST.md)
est prêt, mais aucun joueur novice n'a été observé. L'équilibrage d'une carrière
CPU + Software doit encore être mesuré.

Les résultats GitHub doivent être associés à la tête finale de cette étape. La
réussite locale ne remplace pas les contrôles distants ; leur état final est
consigné dans le rapport livré avec les fichiers.
