# C2 — battement partagé des animations et consommation en pause

Date : 9 octobre 2026. Branche : `codex/c2-animation-clock`.
Base : `0b42926`, après fusion validée de C3 dans `v013/demo-octobre`.
Périmètre : uniquement C2 du plan `PLAN_CODEX_2026-10-08.md` et de la reprise §5.

## Prérequis C3 terminé

- `7ed580c` : les reprises depuis l'atelier logiciel, le stepper CPU et le premier
  atelier CPU passent par `_request_time_scale()`. Une décision bloque la reprise
  immédiatement, y compris la première orientation du CPU nouvellement créé.
- Test C3 étendu aux trois vrais parcours, avec et sans décision logicielle.
  L'ancien test d'entrée est adapté : le lancement attend l'orientation initiale.
- Import, boot, smoke, branding, garage, atelier, plafonds, refresh, parcours CPU
  et test C3 passent. L'échec initial du smoke venait de l'ancienne attente de
  reprise avant orientation ; le smoke relancé après correction passe.
- Fusion `0b42926` poussée sur `v013/demo-octobre` ; boot et test C3 passent aussi
  sur le résultat de fusion. Les branches distantes ont été vérifiées.

## Modification C2

- Nouveau autoload léger `ui/AnimationClock.gd` : un seul battement à environ
  20 Hz, avec conservation du temps écoulé et du reste de cadence. Il fonctionne
  indépendamment de l'horloge de simulation ; les animations ambiantes conservées
  en pause restent vivantes à cette cadence.
- Une image lente émet un seul battement avec son temps écoulé, sans rafale de
  rattrapage. Le reste de cadence évite de tomber à 15 Hz lorsque le rendu est à 30 FPS.
- `CrewMember`, `CpuBench`, `ProjectVisual`, `ComponentArt`, `GarageLife` et
  `LiveThemeOverlay` n'ont plus de `_process()` par image. Ils s'abonnent au
  battement lorsqu'ils sont visibles et se désabonnent lorsqu'ils sont cachés,
  y compris par un parent, ou quittent l'arbre de scène.
- Les conditions existantes restent appliquées : pause pour les illustrations
  CPU/projets, mouvement réduit pour l'équipier/projet, composant verrouillé,
  entreprise créée pour la vie du garage. Les fonctions de dessin restent identiques.
- `OS.low_processor_usage_mode` est activé lorsque le temps est en pause,
  qu'aucune entreprise n'est créée ou que le menu enregistré dans `main.gd`
  couvre l'écran. Le mode suit la reprise au prochain traitement du battement.
  Les menus sont référencés faiblement, sans conserver de scène détruite.
- Aucun champ de sauvegarde ajouté, aucune migration nécessaire. Aucun réglage
  de cadence de rendu ajouté : cette partie appartient à R1.

## Tests et vérifications effectués

Godot 4.7.2 officiel, Windows, même copie de travail fournie.

- `tests/scenarios/AnimationClockScenario.gd`, aussi intégré au smoke :
  compteur de redessins demandés de l'équipier (20 pour 120 images simulées
  sur une seconde, puis 20 supplémentaires pour 30 images sur une seconde) ;
  les six nœuds cachés ne mettent plus leur animation à jour ; la réapparition
  rétablit l'abonnement ; une image de 500 ms ne produit qu'un battement ;
  mouvement réduit ; pause/reprise et ouverture/fermeture d'un menu ;
  désabonnement lorsque le nœud est libéré.
- `res://tests/animation_clock_test.tscn` : PASS, code 0, zéro erreur Godot.
- Import, `--quit-after 2`, smoke, branding, garage, atelier, plafonds,
  screen refresh, parcours CPU et test C3 relancés après C2. Les résultats
  détaillés sont conservés localement dans `.agent-output/c2-final-results.json`.
- Deux avertissements d'ancres déjà présents dans le smoke, aucune erreur Godot.
- `git diff --check` : OK. Aucun journal, build ou fichier de message de commit
  n'est ajouté au lot. Les `.uid` des nouveaux scripts sont inclus.

## Captures et limites

- Captures réelles du QG 1280×720, OpenGL 3.3 / Intel UHD 630, audio Dummy,
  dossier de sauvegarde de test, écritures désactivées :
  `.agent-output/c2-before-qg.png` et `.agent-output/c2-after-qg.png`.
- Captures relues : même disposition, textes et illustrations ; positions de
  quelques particules mobiles différentes. Les fichiers ne sont pas identiques
  octet pour octet. Aucun changement du dessin des six composants.
- Le premier outil local de capture avait une erreur d'inférence de type :
  corrigée dans l'outil non versionné, puis captures avant/après réussies.
- Les tests démontrent la diminution des demandes de redessin et le changement
  du mode de traitement. Ils ne démontrent pas un gain de FPS, d'autonomie ou
  de chauffe matériel. Aucune nouvelle mesure Pixel, aucun APK construit.
- À vérifier humainement : fluidité perçue à 20 Hz (personnages, ventilateur,
  neige et pluie) et coût réel via P0, dans le protocole comparatif prévu.
- C2 reste sur sa branche de relecture ; R1 n'est pas entamé dans ce lot.

## Fichiers du lot

`project.godot`, `main.gd`, `ui/AnimationClock.gd` et `.uid`, les six composants
listés ci-dessus, `tests/scenarios/AnimationClockScenario.gd` et `.uid`,
`tests/animation_clock_test.gd` et `.uid` / `.tscn`, `tests/smoke_test.gd`,
ce document. Les UID locaux préexistants restent hors du commit.
