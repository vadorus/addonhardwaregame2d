# Lot G4 — Textes et finition V0.9

Date : 30/09/2026

## Objectif

Retirer les formulations de développement ou les anglicismes inutiles des textes vus par le joueur, sans simplifier le vocabulaire matériel qui fait l'identité de Tech Empire.

## Nettoyage joueur

- Le titre interne `V0.8.1 - GARAGE FIRST` disparaît de l'écran d'accueil.
- `B2B` devient `professionnel` dans les contrats et profils publics.
- `CEO` devient `dirigeant` ou `direction` dans l'interface.
- `Sourcing` devient `Approvisionnement`.
- `IP` devient `propriété intellectuelle`.
- `royalty` devient `redevance`.
- `perf` devient `performance` dans les cahiers des charges.
- `process` devient `méthodes` dans les fiches RH.
- `passe de correction` devient `phase de correction`.

## Vocabulaire volontairement conservé

Gravure, architecture, cache, binning, benchmark, firmware, microcode, rendement et fonderie restent affichés : ce sont des notions de gameplay, pas du jargon de développement logiciel.

Les identifiants internes (`CEO:`, `EMBEDDED`, `PERF`, `sourcing`, etc.) restent dans le code quand ils ne sont jamais présentés au joueur.

## Version

- Projet : **Tech Empire V0.9.0**.
- Windows : version fichier / produit **0.9.0.0**.
- Android : `versionCode 11`, `versionName 0.9.0`.
- APK de développement : `TechEmpire-v0.9.0-debug.apk`.

Pendant le développement interne, une nouvelle partie de test est autorisée ; la compatibilité de sauvegarde est contrôlée à des jalons dédiés plutôt qu'à chaque lot.

## Validation finale

- Smoke complet Godot 4.7.2 : **vert**.
- Export Android V0.9.0 : **réussi et signé**.
- Pixel 10 : `versionCode=11`, `versionName=0.9.0` confirmés par Android.
- Application confirmée au premier plan en paysage, processus actif.
- `OnGodotMainLoopStarted` atteint sans `FATAL EXCEPTION`, `SCRIPT ERROR` ni `ERROR:` applicatif au démarrage.
