# Obtenir la version PC et la version Android

Mis à jour le 28 septembre 2026 — version **0.8.1** (branche `feature/etape1-sensation`, construite sur `fix/v081-claude-platform`).

Le jeu est un seul projet Godot 4.7.2 qui s'exporte en deux versions : **Windows (PC)** et **Android (APK)**. Même code, même sauvegarde, même contenu ; seule l'interface s'adapte à l'écran.

## Le plus simple : une commande

Depuis PowerShell, à la racine du projet :

```powershell
powershell -ExecutionPolicy Bypass -File tools\build_all.ps1
```

Le script lance les tests, puis produit :

| Version | Fichier | Taille indicative |
| --- | --- | --- |
| PC Windows | `build/windows/TechEmpire.exe` | ~107 Mo (un seul fichier, rien à installer) |
| Android | `build/android/TechEmpire-v0.8.1-debug.apk` | ~30 Mo |

Options utiles :

- `-Install` : installe aussi l'APK sur le téléphone branché en USB (mise à jour, les parties sont conservées).
- `-SkipTests` : saute les tests (déconseillé).
- `-Godot "C:\chemin\Godot_v4.7.2-stable_win64_console.exe"` : si Godot n'est pas à l'emplacement par défaut.

Le dossier `build/` n'est pas versionné (voir `.gitignore`) : on régénère les fichiers à chaque version.

## Prérequis (une seule fois par PC)

1. **Godot 4.7.2** (console) — par défaut `C:\Users\alexa\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
2. **Modèles d'export 4.7.2** installés (`%APPDATA%\Godot\export_templates\4.7.2.stable`). Dans l'éditeur : *Éditeur → Gérer les modèles d'export → Télécharger*.
3. **Pour Android** (déjà configuré sur le PC d'Alexandre) :
   - JDK 17 (`C:\Program Files\Eclipse Adoptium\jdk-17...`) ;
   - Android SDK (`%LOCALAPPDATA%\Android\Sdk`) avec `platform-tools` (adb) ;
   - clé de debug `C:\Users\alexa\debug.keystore` (mot de passe `android`) ;
   - ces chemins sont renseignés dans *Éditeur → Paramètres de l'éditeur → Export → Android*.
4. **Téléphone** : options développeur + débogage USB activés, autoriser le PC au premier branchement.

### Deuxième PC (PC du travail) — attention à la clé de signature

Le PC du travail (compte `Admin`) a ses outils dans `C:\Users\Admin\Tools` (`Godot\…console.exe`, `Android\Sdk\platform-tools\adb.exe`, `Java`, `PortableGit`) et **seulement les modèles d'export Android** (pas d'export Windows depuis ce PC).
Chaque PC signe l'APK de debug avec **sa propre clé**. Android refuse alors la mise à jour (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) quand on passe d'un PC à l'autre, et `adb uninstall` **efface les sauvegardes**. Procédure sûre :

```powershell
$adb = "C:\Users\Admin\Tools\Android\Sdk\platform-tools\adb.exe"   # ou le chemin du PC maison
# 1. sauvegarder la partie du téléphone sur le PC (via cmd : le « > » de PowerShell 5 abîmerait le fichier)
cmd /c "`"$adb`" exec-out run-as com.vadorus.techempire cat files/tech_empire_save.json > save.json"
# 2. réinstaller
& $adb uninstall com.vadorus.techempire
& $adb install build/android/TechEmpire-v0.8.1-debug.apk
# 3. remettre la partie
& $adb push save.json /data/local/tmp/te_save.json
& $adb shell run-as com.vadorus.techempire sh -c "'mkdir -p files && cp /data/local/tmp/te_save.json files/tech_empire_save.json'"
```

Faire de même pour `tech_empire_slot_1.json` … `_3.json` s'ils existent (`run-as com.vadorus.techempire ls files`). Pour ne plus avoir à le faire : copier la même `debug.keystore` sur les deux PC.

## Faire les exports à la main

```powershell
$g = "C:\Users\alexa\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
& $g --headless --path . --import
& $g --headless --path . res://tests/smoke_test.tscn                      # doit finir par « Smoke test passed »
& $g --headless --path . --export-release "Windows Desktop" build/windows/TechEmpire.exe
& $g --headless --path . --export-debug "Android APK" build/android/TechEmpire-v0.8.1-debug.apk
```

Installer sur le téléphone sans effacer les parties :

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build/android/TechEmpire-v0.8.1-debug.apk
```

## Ce qui est réglé pour chaque plateforme

| Réglage | PC | Android |
| --- | --- | --- |
| Rendu | Forward+ | Compatibility (OpenGL ES 3, fonctionne sur presque tous les téléphones) |
| Orientation | fenêtre libre, plein écran dans le menu ☰ | paysage, les deux sens |
| Taille de l'interface | 100 % par défaut | 115 % par défaut ; réglable de 90 à 150 % dans le menu ☰ |
| Encoches / caméra | — | marges de zone sûre automatiques |
| Bouton Retour / Échap | Échap ferme ce qui est ouvert, puis ouvre le menu | Retour ferme ce qui est ouvert, puis « appuyez encore pour quitter » |
| Sauvegarde automatique | chaque mois + à la fermeture | chaque mois + dès que l'appli passe en arrière-plan |
| Dossier des sauvegardes | `%APPDATA%\TechEmpire` (fixe, ne change plus à chaque version) | stockage interne de l'appli (conservé par `adb install -r`) |

Sauvegardes : 1 automatique + 3 emplacements manuels ; « Continuer » charge la plus récente.

## Numéro de version

À chaque nouvelle version Android, augmenter dans `export_presets.cfg` :

- `version/code` (entier, **doit augmenter** sinon Android refuse la mise à jour) — actuellement `10` ;
- `version/name` (texte affiché) — actuellement `0.8.1` ;
- le nom de l'APK dans `export_path`.

Mettre aussi à jour le libellé de l'écran d'accueil (`main.gd`, `V0.8.1 - GARAGE FIRST`) et `config/name` dans `project.godot`.

## Ce qui n'est pas embarqué dans les exports

Les dossiers `docs/`, `tests/` et `build/` sont exclus (filtres d'export + fichiers `.gdignore`). Sans ça, des captures d'écran de travail finissaient dans l'APK (270 Mo au lieu de 30).

## Intégration continue (GitHub)

- `godot-ci.yml` : import, démarrage, `smoke_test`, puis tests de disposition du garage et de l'atelier sur 6 formats d'écran — à chaque push.
- `android-build.yml` : construit un APK de debug sur `master`/`main` et sur les Pull Requests.
- `windows-build.yml` : construit la version Windows.

## Vérifié sur appareil réel

Pixel 10 (2424×1080, GPU PowerVR) le 28 septembre 2026 avec l'APK 0.8.1 : démarrage en rendu Compatibility sans erreur, création d'entreprise (le clavier ne cache plus le bouton), garage, menu ☰, bouton Retour (ferme le menu puis demande confirmation pour quitter), passage en arrière-plan et reprise, relance complète avec « Continuer — Nova Technologies, janvier 1971 ».
