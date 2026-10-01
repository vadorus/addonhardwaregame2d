# C1 — Sauvegarder et mettre à jour sans perte

Étape 1 du plan décidé le 01/10/2026 (`docs/design/concurrence/decision.md`, `docs/ROADMAP_V010.md`).
Réalisée par Claude le 01/10 au soir, sur le PC maison, Pixel 10 branché. Preuves à contrôler par Codex.

## Ce qui a été trouvé

1. **Cause de l'incident du 01/10 (21 h 40)** : la clé de test commune existait depuis le 30/09 (lot Q0,
   `tools/android/techempire-debug.keystore`, SHA-256 `99:77:47:A4…49:A4:BB`), mais l'éditeur du PC maison n'avait pas été
   réglé, et l'installation a été faite à la main (sans `build_all.ps1`). L'APK a été signé avec la clé personnelle du PC
   (`CC:61:D2…`), Android a refusé la mise à jour et la partie a été effacée, puis restaurée depuis la copie.
   Vérifié par les certificats : Pixel en `CC:61:D2…` jusqu'à 23 h 14, clé commune `99:77:47:A4…` depuis.
2. **Les tests effaçaient les vraies parties du PC** : `smoke_test` écrivait et supprimait les sauvegardes dans le dossier
   du joueur (`%APPDATA%\TechEmpire`). Sur un PC où l'on joue, lancer les tests aurait supprimé la partie.
3. **Deux trous dans la reprise** :
   - fichier principal abîmé : le chargement prenait bien la copie de secours, mais l'écran d'accueil ne la voyait pas
     (« Continuer » pouvait disparaître) ;
   - appli tuée entre l'écriture du fichier temporaire et son remplacement : la sauvegarde la plus récente, complète, restait
     dans le temporaire et était ignorée (perte d'un mois de jeu au plus).
4. Déjà en place et vérifié : sauvegarde à la mise en arrière-plan (`NOTIFICATION_APPLICATION_PAUSED`), à la fermeture et
   chaque mois ; écriture atomique avec copie de secours.

## Ce qui a changé

| Fichier | Changement |
|---|---|
| `scripts/SaveManager.gd` | dossier de sauvegarde paramétrable (`use_test_folder()` → `user://ci_tests/`) ; `_best_state()` : la plus récente des sauvegardes principale/temporaire qui se relit en entier, sinon la copie de secours, utilisée par « Continuer » **et** par le chargement ; `writes_enabled` (outils de capture) ; lecture JSON silencieuse pour les fichiers abîmés |
| `tests/smoke_test.gd` | les tests passent dans `ci_tests/` dès le départ |
| `tests/scenarios/PlatformScenario.gd` | nouveaux contrôles : dossier de test, appli tuée pendant le remplacement, temporaire coupée, principale abîmée, écriture interdite, sauvegarde au passage en arrière-plan |
| `tests/tools/capture_qg.gd` | ne peut plus rien écrire (il modifiait la date et la vitrine de la partie chargée) |
| `tools/build_all.ps1` | `-Install` refuse si le jeu est ouvert, vérifie la partie à l'octet près après installation, journal `build\pixel_saves\journal-installations.csv` ; `-AllowReinstall` : copie → désinstallation → réinstallation → restauration automatique |
| `tools/android_interrupt_test.ps1` | nouveau : N cycles lancer / Continuer / arrière-plan / vérifier / tuer |
| `.gitignore` | fichiers de clé ignorés, sauf la clé de test commune |
| `docs/BUILD_PC_ANDROID.md` | incident, nouvelles options, test d'interruptions |

Éditeur Godot du PC maison réglé sur la clé commune (`tools/setup_debug_keystore.ps1`, 01/10, 23 h 08).

## Preuves

- **Tests** : `smoke_test`, `garage_layout_test`, `workshop_layout_test`, `balance_ceiling_test` verts (passe de `build_all.ps1`, 23 h 13).
- **20 interruptions/reprises sur le Pixel 10** (`android_interrupt_test.ps1 -Cycles 20`, 23 h 06 → 23 h 11) : **20/20 OK**.
  À chaque cycle : sauvegarde écrite au passage en arrière-plan (date de sauvegarde plus récente), partie identique
  (Nova Technologies, avril 1972, 77 329 €), aucun fichier temporaire laissé. Copie avant test : `Documents\TechEmpire-backups`.
- **Mise à jour sans désinstallation** depuis le PC maison : 23 h 02 (même clé, partie identique, MD5 `a558db19…`).
- **Passage du Pixel sur la clé commune** (`build_all.ps1 -Install -AllowReinstall`, 23 h 14) : réinstallation et restauration,
  MD5 avant = après (`3a4424fe…`), journal « OK ».
- **Référence de démarrage** : 298 ms en moyenne côté Android sur 20 lancements (`am start -W`, TotalTime) ; le jeu est
  utilisable avant 8 s (attente fixe du test). Mesure fine (écran d'accueil, images/s) : étape C4.

## Reste à faire pour clore C1

- **Mise à jour depuis le PC du bureau** sans désinstallation : `git pull`, puis `tools\build_all.ps1 -Install`
  (le Pixel porte maintenant la clé commune : la mise à jour doit passer, partie vérifiée par le script).
- **Appareil plus modeste** : pas disponible ce soir ; à faire en C4.
