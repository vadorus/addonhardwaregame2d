# C3 — événements plutôt qu'un contrôle à chaque image

**Date :** 9 octobre 2026
**Branche :** codex/c3-event-driven
**Base :** v013/demo-octobre, commit 3a41022, après fusion du test SalesPortfolio autonome.

## Modification

- main.gd : _process() ne parcourt plus, à chaque image, les projets et travaux à la recherche d'une décision bloquante.
- Lors d'un changement de jour (TimeManager.day_changed), vérification des décisions bloquantes et mise à jour de la date.
- Lors des changements de projet de recherche, de logiciel, de production et de produits (signaux existants), vérification immédiate d'un éventuel blocage lorsque le temps avance.
- Lancement ou reprise manuelle déjà protégés par _request_time_scale(), et décision de fin de mois déjà vérifiée par _on_month_closed() : ces gardes restent inchangées.
- Changement de présentation compact/normal : le bandeau de date est reformatté uniquement quand la présentation change, pas à chaque image.
- Les boutons de vitesse et le score de réputation restent inchangés en _process() : ce lot cible précisément les deux coûts annoncés par C3.
- Aucun champ de sauvegarde modifié, aucune nouvelle règle de simulation et aucune extension de gameplay.

## Tests exécutés sur Windows, Godot 4.7.2

- PASS — res://tests/c3_event_driven_main_test.tscn : un changement de jour met à jour la date, le mode compact l'adapte ; un appel manuel à _process() seul ne recalcule pas la date et ne cherche pas de décision bloquante ; software_changed et day_changed stoppent le temps lorsqu'une décision logicielle factice est en attente.
- PASS — res://tests/screen_refresh_test.tscn.
- PASS — res://tests/perf_probe_test.tscn.
- PASS — res://tests/perf_probe_integration_test.tscn.
- PASS — res://tests/smoke_test.tscn.
- PASS — lancement Godot --headless --quit-after 2 pour chargement/parsing.
- Limite d'environnement : un premier Godot --headless --import dans ce nouveau worktree a quitté avec un code de violation mémoire Windows ; le lancement headless et les tests ultérieurs ont réussi. Le résultat de cet import initial n'est **pas** compté comme PASS.

## Validations restantes

Le gain de temps par image n'a pas encore été chronométré sur le Pixel avec P0. Les tests prouvent le comportement et la non-régression ciblée sur PC ; ils ne justifient pas d'affirmer un gain de FPS matériel.

**Consigne :** relire le commit C3 avant toute fusion dans la démo ; C2 et R1 ne sont pas entamés.
