# Lot G3 — Passe Android / Pixel 10

Date : 30/09/2026

## Objectif

Valider l'interface sur téléphone en paysage, avec de vraies zones tactiles, sans sacrifier la profondeur du jeu.

## Correctifs

- Carte Nora du garage simplifiée pendant le tutoriel : plus de doublon entre conseil et objectif.
- Hauteur de la carte Nora sur 1616×720 : **182 px → 135 px**.
- Contrôles interactifs UI normalisés à **44 px minimum** au lieu de 40–42 px.
- Aucun contenu ou réglage n'est retiré sur mobile ; les écrans restent scrollables.

## Tests automatiques

- Garage : 1616×720, 1280×720, 1067×600, 1333×600, 1067×800, 1706×720.
- Atelier premier CPU : 1616×720, 1280×720, 700×720.
- Smoke complet Godot 4.7.2 : vert.

## Pixel 10 réel

- Appareil ADB : `Pixel_10` (`frankel`).
- Résolution physique : **1080×2424**, jeu lancé en paysage **2424×1080**.
- APK debug G3 exportée et installée avec succès.
- Activité `GodotAppLauncher` confirmée au premier plan.
- `OnGodotMainLoopStarted` atteint.
- Aucun `FATAL EXCEPTION`, `SCRIPT ERROR` ou `ERROR:` applicatif au démarrage.

Pendant la phase de développement interne, les tests Android utilisent une nouvelle partie ; la migration de sauvegardes n'est plus un prérequis à chaque lot.
