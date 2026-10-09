# T3 — Appuis longs sur les actions : dossier de relecture Claude

9 octobre 2026. Dépôt `vadorus/addonhardwaregame2d`, branche exclusive `codex/t3-mobile-tooltips`. Aucune fusion effectuée. La seule commande Git distante utilisée pour livrer ce lot est `git push origin codex/t3-mobile-tooltips` ; son résultat figure dans le dossier local de livraison.

**Mise à jour focus :** les preuves Pixel ci-dessous concernent le lot `2371e06`. Le correctif ultérieur de perte de focus et ses nouveaux tests PC sont décrits dans le complément à la fin de ce rapport. Le Pixel n'a pas été retesté pour ce complément, conformément à la demande.

## Changement et provenance

La reprise commence à `054222c041e9efdb14c9c1405b6ca24ecbcb60d0`, copie de travail propre. Les commits T3 `b3612b1` (infobulles) et `054222c` (premiers tests Valider/Lancer/Confirmer) existaient déjà, au-dessus de la base T2 `d014aee`. Ils ne sont pas présentés comme du travail nouvellement réalisé.

Le test obligatoire existant est renforcé dans `tests/touch_tooltip_scenario.gd` :

- Valider, Lancer et Confirmer passent par `SubViewport.push_input`, avec un compteur connecté à leur vrai signal `pressed` et le mode de validation au relâchement.
- Deux chemins : souris seule et événements tactiles accompagnés de souris émulée, soit six cas.
- Premier appui court : exactement un `pressed`, aucune bulle.
- Maintien au-delà des 450 ms : explication exacte, aucun `pressed` pendant le maintien, au relâchement immédiat ou après deux frames.
- Appui court suivant : exactement un signal supplémentaire ; le bouton est réactivé et reste utilisable.

Le contrôle Pixel a révélé une première bulle démesurément haute, avec son texte hors écran. `ui/TouchTooltip.gd` donne maintenant sa largeur au Label **avant** de lui affecter le texte. Le calcul des lignes utilise ainsi la bonne largeur dès la première ouverture. Deux assertions géométriques couvrent cette régression dans le scénario T3.

Fichiers du complément : `ui/TouchTooltip.gd`, `tests/touch_tooltip_scenario.gd`, lien de reprise dans `docs/reviews/T3_DEMARRAGE_2026-10-09.md`, ce rapport et `docs/reviews/t3_pixel_actions_2026_10_09.json`. Aucun autre fichier suivi n'est modifié.

## Tests PC réellement exécutés sur le code final

Godot `4.7.2.stable.official.ed1daf0bf`, copie `C:/Users/alexa/Documents/TechEmpire-T3-LongPress-20261009` :

| Contrôle | Résultat |
| --- | --- |
| `--headless --path . --import` | Code de sortie 0 ; aucune erreur de parse/script |
| `--headless --path . --quit-after 2` | Code de sortie 0 ; journal sans erreur |
| `res://tests/touch_tooltip_scenario.tscn` | PASS, six cas `short=1, hold=0, next_short=1`, journal sans erreur |
| `res://tests/touch_target_scenario.tscn` | Assertions PASS ; 55 contrôles, 0 sous-dimensionné, à 1280×720 et 1600×720 ; **erreurs de libération à la sortie**, voir ci-dessous |
| `res://tests/smoke_test.tscn` | `Smoke test passed`, code 0 ; deux avertissements d'ancres |

Le journal T2 contient les mêmes erreurs de sortie que les journaux préexistants de cette branche : 16 RID textures, 7 RID texte et 1 RID police non libérés, plus des avertissements CanvasItem/ObjectDB. Le fichier T2 n'a pas changé. Ce résultat établit le succès de ses assertions de layout ; il ne constitue pas un journal moteur entièrement propre. Les avertissements d'ancres du smoke existaient également dans le journal de reprise antérieur.

Deux contrôles négatifs prouvent que les tests détectent réellement les défauts : retirer temporairement la protection du bouton provoque les erreurs `pressed emis ... relachement`, et retirer temporairement la largeur initiale du Label provoque les deux erreurs de débordement. Ces mutations ont été restaurées octet pour octet ; T3 a ensuite été relancé et passe.

## Pixel : installation et données isolées

- Pixel 10, USB `63140DLCR0040K`, écran physique paysage 2424×1080.
- Application personnelle : `com.vadorus.techempire`, version `0.12.2-test3`, code 24. Elle affichait déjà le lanceur Android avant l'essai et **n'a été ni remplacée, ni lancée, ni arrêtée** par ce lot.
- Application de contrôle séparée : `com.vadorus.techempire.t3review`, nom « Tech Empire T3 Review », version `0.12.2-test3`, code 24. Export debug local Godot 4.7.2 avec instrumentation temporaire ; aucun APK ni fichier de sonde ajouté au commit.
- SHA-256 de l'APK final contrôlé : `5ae39bd9b38118344ce44ca627c184ec3251cc857f543dd5ff63893793008bfa`.
- `main.tscn` et le composant `TouchTooltip.gd` de la branche sont utilisés. L'instrumentation charge la référence, garde le jeu en pause et fixe `SaveManager.writes_enabled=false` **avant** l'instanciation du jeu. Le compteur de diagnostic est écrit dans un autre fichier de l'application isolée.
- La référence P0 immuable est copiée depuis l'archive vérifiée du PC vers `files/tech_empire_save.json` de l'application isolée. Son SHA-256 avant et après le contrôle est `5b839da1ebf8974ee3cf2251bbeb5960047d54feb94e3f73eb2e6a54db4d472d`.
- Une archive complète des fichiers de l'application personnelle et un inventaire SHA-256 ont été conservés localement avant les essais. Les **34 fichiers** ont le même contenu et le même inventaire après les essais. Aucune restauration n'a été nécessaire.
- Sauvegarde personnelle et `.bak`, avant = après : `ef5948f1c7e6cef1f8d805e552e57ea57788ccb230eb05e4239522024b8913ed`. Il s'agit de la sauvegarde actuelle ; l'ancien SHA personnel des rapports T2 n'a pas été réutilisé.
- `files/perf_reference.json` de l'application personnelle reste lui aussi inchangé, SHA `5b839da1ebf8974ee3cf2251bbeb5960047d54feb94e3f73eb2e6a54db4d472d`.
- Fin : application T3 Review fermée, lanceur Android affiché ; application personnelle laissée dans son état initial en arrière-plan. La copie de test reste disponible dans le stockage isolé.

## Résultats tactiles natifs

Les gestes sont injectés par Android via ADB sur le Pixel, sans appel direct à `gui_input.emit`. Le journal constate les deux types d'événements natifs `MOUSE` et `TOUCH` ainsi que `mobile=true` et `reference_loaded=true`. Les maintiens durent 700 ms, au-delà du seuil de 450 ms.

Sur trois boutons instrumentés utilisant le composant de production au-dessus du QG réel :

| Bouton | Premier appui court | Bulle du maintien | `pressed` supplémentaire au relâchement | Appui court suivant |
| --- | --- | --- | --- | --- |
| Valider | 1 | Texte correct et lisible | 0 | 1 |
| Lancer | 1 | Texte correct et lisible | 0 | 1 |
| Confirmer | 1 | Texte correct et lisible | 0 | 1 |

Les trois compteurs finaux valent 2. Les trois relâchements après maintien montrent `bubble=true` et un compteur encore à 1 pour le bouton concerné. Le JSON a été vérifié pour chaque séquence court → maintien → court.

Contrôle d'intégration supplémentaire : un appui long sur le **vrai bouton Labo** du dock affiche « Labo » et conserve le QG ; l'appui court suivant ouvre le laboratoire. Les captures confirment également le placement d'une bulle près du bas de l'écran.

Les événements et compteurs sont versionnés dans [t3_pixel_actions_2026_10_09.json](t3_pixel_actions_2026_10_09.json). Les captures, journaux, instrumentation reproductible et rapport de livraison sont conservés localement dans le dossier `outputs` du chat de reprise. Aucune sauvegarde de partie et aucune capture personnelle ne sont versionnées.

## Périmètre pour la relecture

Le cas obligatoire de non-validation au relâchement est couvert sur PC et Pixel, et le défaut visuel observé est corrigé et couvert. Le contrôle des trois boutons est une sonde instrumentée ; il ne prouve pas individuellement tous les boutons de décision du gameplay. Le vrai dock est contrôlé en complément.

La lecture exhaustive des 26 explications, les fenêtres fermées pendant un maintien et le ressenti au doigt restent hors de ce contrôle ciblé. Aucun résultat de CI GitHub n'est revendiqué : aucune consultation de GitHub, aucun workflow ni aucune PR n'ont été créés par outil. La fusion attend la relecture de Claude.

## Complément demandé : annulation lors de la perte de focus

Reprise depuis `2371e06`, copie de travail propre, toujours sur `codex/t3-mobile-tooltips`.

`TouchTooltip.gd` définit maintenant `_notification(what: int)`. Pour `NOTIFICATION_APPLICATION_FOCUS_OUT` et `NOTIFICATION_WM_WINDOW_FOCUS_OUT`, elle appelle `_cancel()` puis `_hide_bubble()`. Une interruption ne laisse donc pas le bouton temporairement désactivé ni son explication visible.

Le scénario `touch_tooltip_scenario` teste séparément les notifications 2017 et 1005, envoyées par `Node.notification` : maintien au-delà de 450 ms sur Confirmer, bouton désactivé et bulle visible, perte de focus, bulle masquée immédiatement, puis bouton réactivé après traitement différé **sans envoyer de relâchement tactile**. Un relâchement tardif n'émet aucun `pressed`, et l'appui court suivant émet exactement un signal. Les six cas d'action précédents passent également.

Vérifications exécutées avec Godot 4.7.2 après cette correction :

- Import : code 0, aucune erreur de script/parse.
- Démarrage `--quit-after 2` : code 0, journal sans erreur.
- `touch_tooltip_scenario.tscn` : PASS, six cas d'action et deux cas de perte de focus, journal sans erreur.
- `smoke_test.tscn` : PASS, code 0 ; les deux avertissements d'ancres déjà observés persistent.
- `git diff --check` : PASS.

Fichiers du complément : `ui/TouchTooltip.gd`, `tests/touch_tooltip_scenario.gd` et ce rapport. Aucun contrôle Pixel complet, aucune installation Android, aucune action sur les sauvegardes, aucun pull et aucune fusion n'ont été effectués pour ce complément. Publication uniquement par le push de la branche T3. La correction demandée est couverte par les tests PC ; la fusion elle-même reste à effectuer séparément.
