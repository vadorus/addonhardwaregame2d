# T3 — Démarrage des infobulles tactiles (9 octobre 2026)

**Branche locale :** `codex/t3-mobile-tooltips`, fondée sur `v013/demo-octobre` au commit `d014aee`. Aucune fusion, aucun push T3.

## Objectif du plan

Sur mobile, maintenir 450 ms un contrôle ayant `tooltip_text` pour afficher son explication ; un appui court doit rester inchangé. Garder les 26 explications du jeu accessibles, y compris celles générées dynamiquement.

## Premier lot isolé

- `ui/TouchTooltip.gd` : écoute les événements tactiles et souris simulés, programme l'ouverture après 450 ms, annule si le doigt glisse de plus de 16 px, conserve la bulle 3 s après relâchement et l'empêche de sortir de l'écran.
- Lors d'un appui long sur un bouton actif, désactive temporairement le bouton pour éviter qu'il ne valide une action au relâchement, puis le réactive.
- `main.gd` : instancie le système seulement en mode mobile (ou simulation mobile du test) et enregistre une fois les boutons, curseurs et autres contrôles dont l'explication existe déjà.
- `tests/touch_tooltip_scenario.tscn` : tests déterministes headless d'appui court, appui long, bon texte, blocage de la validation, relâchement et glissement ; aucune sauvegarde du joueur.

## Vérifications

Godot 4.7.2 :
- `--import` : PASS.
- `--quit-after 2` : PASS.
- `touch_tooltip_scenario.tscn` : PASS.
- `touch_target_scenario.tscn` : PASS.
- `smoke_test.tscn` : PASS.

Le premier appel au smoke utilisait un mauvais chemin (`tests/smoke.tscn` inexistant) ; il a été relancé sur le chemin correct et a réussi.

## À valider avant livraison

- Pixel 10 : lecture de toutes les explications accessibles, taille et placement des bulles en 1280×720 et 1600×720.
- Vérifier les contrôles désactivés et les panneaux non interactifs ayant un tooltip, ainsi que le comportement en cas de fermeture d'une fenêtre pendant l'appui.
- Essayer au doigt que maintenir un bouton `Confirmer` ne déclenche **aucune action** après relâchement.
- Captures et comparaison visuelle. Ces validations **ne sont pas réalisées** dans le présent lot.

Le jeu du Pixel n'a pas été modifié pour T3. La démo fusionnée T2 reste inchangée sur GitHub.
