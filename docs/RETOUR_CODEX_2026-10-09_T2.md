# Tech Empire — T2 : cibles tactiles mobiles

**Date :** 9 octobre 2026
**Base :** codex/a1-audio-buses, 55a92e3 (C2, R1, A1 déjà inclus).
**Branche :** codex/t2-touch-targets
**Statut :** implémenté et vérifié sur PC ; validation Android encore requise.

## Modifications

- ui/UiKit.gd : fonction UI.touch_target(control, kind), active uniquement sous Android/mobile. Elle relève la zone logique à 58 px minimum de large et de haut pour une action secondaire, et 77 px de haut pour une action principale. C'est la calibration Pixel 10 du plan (~6 et ~8 mm à l'échelle de référence), et non une mesure physique universelle.
- ui/UiKit.gd : les libellés commençant par Lancer, Valider ou Confirmer sont considérés comme des actions principales. L'espacement des conteneurs de commandes est porté à au moins 8 px.
- main.gd : application différée aux boutons, curseurs et champs ajoutés en cours de partie ; nouvelle adaptation si un composant réduit ensuite sa taille ; boutons de vitesse protégés dans le format compact.
- ui/SectionPager.gd : adaptation explicite des sous-onglets, même s'ils sont utilisés hors main.gd.
- ui/components/BottomDock.gd : adaptation de la navigation inférieure après passage au format compact.
- tests/touch_target_scenario.gd : test indépendant de toute sauvegarde, simulant le mobile sur les deux résolutions paysage. La métadonnée de simulation n'est utilisée que par les tests.

Aucun changement de gameplay, calcul économique ou schéma de sauvegarde.

## Tests exécutés — Godot 4.7.2 headless

| Test | Résultat |
| --- | --- |
| touch_target_scenario.tscn | PASS ; 55 contrôles visibles uniques par résolution, navigation à travers les sept onglets dans l'état initial ; aucun sous 58 px ou sous 77 px si principal, en 1280×720 et 1600×720 ; bandeau et dock contenus |
| Test de rétrécissement tardif d'un bouton de vitesse | PASS ; son minimum est rétabli automatiquement |
| garage_layout_test.tscn | PASS |
| workshop_layout_test.tscn | PASS |
| screen_refresh_test.tscn | PASS |
| perf_probe_test.tscn | PASS |
| smoke_test.tscn | PASS |

L'import Godot a terminé avec code 0. Une erreur de typage GDScript dans la première version a été corrigée avant les tests finaux.

## Limites et validation à faire

- Il s'agit d'un balayage des contrôles affichés en **début de partie**, pas d'une garantie sur tous les écrans tardivement déverrouillés.
- Les tailles sont des pixels logiques calibrés d'après le plan. Il faut confirmer les millimètres réels et l'ergonomie au doigt sur Pixel 10.
- Les captures avant/après Android et une revue des onglets Marché, Équipe, Presse, Entreprise, de la barre des vitesses et des boutons Lancer/Valider/Confirmer restent à faire.
- La couche globale gère les contrôles descendants du jeu principal ; les scènes indépendantes doivent utiliser UI.touch_target explicitement.
- Pas d'APK construit ou installé par ce lot. Aucun travail T3 ou T4.

## Livraison

Le lot est poussé dans codex/t2-touch-targets pour revue séparée. Ne pas l'ajouter à la version C2 + R1 + A1 prévue ce soir tant que le test sur Pixel et les captures comparatives ne sont pas validés.
