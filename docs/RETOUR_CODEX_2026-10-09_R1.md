# R1 — plafond de cadence et réglage Fluidité

Date : 9 octobre 2026. Branche : `codex/r1-fluidity`, basée sur C2 `19ce361`.
Dossier dédié : `C:\Users\Admin\.codex\worktrees\r1-fluidity\TechEmpire-v031-validation`.
La branche inclut C2. Ni C2 ni R1 ne sont fusionnés dans la démo : sa référence
reste `0b42926`, après C3. L'attente du Pixel ne bloque plus le travail de phase 1.

## Comportement

- Plafond au démarrage : **60 images/s sur PC**, **30 sur mobile**. Configuration
  `application/run/max_fps`, avec surcharge mobile et application de la préférence
  dans `main.gd`. Ce sont des plafonds, pas une garantie de cadence minimale.
- Menu : bouton **Fluidité : 30 images/s / 60 images/s**. Un appui alterne le choix,
  l'applique immédiatement et l'enregistre dans `user://settings.cfg`, section
  `[display]`, clé `max_fps`. Il se recharge au prochain démarrage.
- Le bouton partage la ligne des informations du menu : pas de ligne verticale
  supplémentaire, pour conserver la hauteur du menu en paysage.
- Ancien fichier sans cette clé : valeur par défaut de la plateforme. Valeur
  invalide : même repli. Les autres préférences (échelle, sons…) sont préservées.
- Échec de lecture/écriture lors d'un changement : pas d'écrasement d'une
  configuration illisible, plafond conservé, message dans la ligne de statut.
- Aucun traitement par image ne réapplique le plafond : les plafonds temporaires
  de comparaison P0 à 30/60 restent utilisables, sans modifier la préférence.
- C2 conserve `INTERVAL = 1.0 / 20.0`. Cette cadence des animations est distincte
  du plafond de rendu R1. Aucun changement du schéma des sauvegardes de partie.

## Vérification PC

- Test déterministe `FrameRateSettingsScenario`, intégré au smoke, et scène isolée
  `res://tests/frame_rate_settings_test.tscn` : valeurs par défaut PC/mobile,
  chargement d'un ancien fichier, application immédiate, persistance des deux
  choix, préservation des autres clés, valeurs invalides, plafond non accepté,
  bouton réel du menu en pause C2, rechargement à la création de la scène et
  plafond temporaire P0. Les fichiers de test sont dans `user://ci_tests/`.
- Import, boot, smoke, branding, garage, atelier, plafonds d'équilibrage,
  screen refresh, parcours CPU, tests C3/C2/R1 et P0 (unitaire/intégration)
  relancés. Résultats : `.agent-output/r1-final-results.json` et journaux associés.
- Les 14 contrôles passent : codes retour 0, aucune erreur Godot. Deux
  avertissements d'ancres préexistants dans le smoke. `git diff --check` : OK.
- Captures OpenGL 3.3 / Intel UHD 630, 1280×720, audio Dummy, relues :
  `.agent-output/r1-before-menu.png`, `r1-after30-menu.png`, `r1-after60-menu.png`.
  Le nouveau libellé est lisible, toutes les commandes du menu restent visibles.
- Le tout premier import de ce nouveau worktree a fini avec une violation
  mémoire Windows (`-1073741819`), après l'importation des ressources. Il n'est
  pas compté comme réussi. La relance puis les imports de validation réussissent.
- Aucun test sur appareil Android, aucune mesure de chauffe/autonomie/FPS réel,
  aucun APK construit ou installé. La branche mobile est exercée dans le test
  via son paramètre de plateforme ; cela ne remplace pas l'essai Android.

## Ce soir sur le Pixel — une seule version C2 + R1

Alexandre et Claude construisent et installent une seule version depuis
`codex/r1-fluidity`, après sauvegarde de la partie. Noter le commit de cette
version, le réglage de fluidité et l'échelle d'interface pour chaque observation.

1. **Garage** : personnages, particules et météo paraissent-ils fluides à 20 Hz ?
   Essayer le plafond 30, puis 60. Le changement R1 ne change pas le battement C2.
2. **Pause et menu** : ouvrir/fermer le menu, toucher les boutons et faire défiler
   une liste. Les réactions doivent rester immédiates aux deux plafonds.
3. **Défaut mobile** : sans choix R1 antérieur, le menu affiche 30 images/s.
   Ne pas effacer les données de l'application ou la partie pour ce contrôle.
4. **Changement** : un appui sur Fluidité affiche 60, un autre 30 ; les autres
   commandes du menu restent accessibles et la simulation reste en pause.
5. **Persistance** : choisir 60, fermer complètement puis relancer l'application,
   vérifier 60 ; refaire à 30 et vérifier 30. L'échelle/volume doivent être conservés.
6. **Reprise** : revenir au jeu à ×1 puis ×3 ; vérifier la fluidité et l'absence
   de blocage nouveau. Le réglage de rendu ne doit pas changer la vitesse du jeu.
7. **Comparaison P0** : revenir à 30 avant les séries officielles, pour correspondre
   à la référence historique. Vérifier `fps_setting=30` dans les CSV. Ne pas
   changer le plafond pendant une série.

Pour la série **30 secondes au repos**, préciser dans la comparaison : C2 actif,
mode basse consommation actif, battement des animations 20 Hz (ou 30 si corrigé),
plafond R1 choisi et commit de l'APK. Une cadence réelle plus basse au repos est
intentionnelle ; elle ne constitue pas seule une régression. Examiner séparément
les temps d'image, les interruptions et la réactivité des entrées.

**Si les animations saccadent** : passer `AnimationClock.INTERVAL` à `1.0 / 30.0`
avant toute fusion, adapter les attentes 20/40/41/42 du test C2 à la nouvelle
cadence, relancer les validations et noter ce changement pour P0.
Après retour des essais et relecture, C2/R1 pourront être fusionnés ; aucune
fusion n'est effectuée dans ce lot. Les autres étapes restent hors périmètre.

## Fichiers du lot

`main.gd`, `project.godot`, `scripts/FrameRateSettings.gd` et `.uid`,
`tests/scenarios/FrameRateSettingsScenario.gd` et `.uid`,
`tests/frame_rate_settings_test.gd` et `.uid` / `.tscn`, `tests/smoke_test.gd`,
ce rapport. Aucun journal, build local, secret ou fichier `commit_msg.txt` ajouté.
