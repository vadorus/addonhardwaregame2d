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

## Relecture complémentaire du 09/10 — modifications locales après 17f3b89

- Prérequis C4 vérifié : `v013/demo-octobre` et `codex/c4-sales-row-reuse` distantes
  pointent déjà toutes deux sur `3a41022`. Ce commit remplace la sauvegarde locale
  par trois CPU factices dans le test. Aucune nouvelle fusion C4 nécessaire.
- Un clone local propre de `3a41022`, créé avec `git clone --no-local`, sans copie
  des fichiers ignorés ni du cache Godot, passe l'import puis
  `res://tests/sales_portfolio_row_reuse_test.tscn` (codes 0, aucune erreur).
  `build/p0_reference_candidate.json` est absent avant et après ces commandes.
- Défaut trouvé dans C3 : `SimulationManager.reset_all()` émet le changement de
  date avant de créer l'entreprise. À la première nouvelle partie en pause,
  le bandeau gardait son texte initial incomplet. Test ajouté : échec reproduit
  (code 1), puis succès après connexion de `company_changed` à `_refresh_clock_date`.
- Le test C3 utilise maintenant le dossier de sauvegarde de test, écrit toujours
  zéro sauvegarde et couvre aussi les signaux recherche, fabrication et produit
  prêt, l'absence de pause sans blocage, la date chargée en pause et les deux
  présentations de date. Aucun parcours supplémentaire par image.
- Les chiffres principaux du bilan Pixel C4 ont été recalculés depuis les CSV :
  12 mois par écran ; pics moyens QG 115,599 ms, Entreprise 136,975 ms,
  Produits 112,233 ms ; maxima respectifs 156,040 / 327,431 / 138,436 ms.
  La série QG x1 conserve 3 images > 50 ms dont 2 > 100 ms : la validation
  globale des performances reste donc ouverte. Ce sont des traces historiques,
  pas de nouvelles mesures sur le téléphone.
- Les résultats détaillés de cette relecture sont dans `.agent-output/report.md`
  et les journaux locaux `review-c3-*.log`. C3 reste sur sa branche séparée pour
  relecture avant fusion dans la démo.
- Publication demandée par Alexandre : le complément C3 et le `.uid` de son test
  sont enregistrés sur `codex/c3-event-driven`. L'import, le démarrage
  `--quit-after 2`, le smoke test et le test C3 renforcé sont relancés avant
  publication ; leurs journaux `c3-publish-*.log` restent locaux.
