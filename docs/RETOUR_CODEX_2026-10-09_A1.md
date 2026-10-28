# A1 — bus audio et atténuation temporaire

Date : 9 octobre 2026. Branche locale : `codex/a1-audio-buses`.
Base : R1 `55d689e6ceca309dfc9394d05e439028af08bcf2`, incluant C2 `19ce361`.
Dossier : `C:\Users\Admin\.codex\worktrees\a1-audio-buses\TechEmpire-v031-validation`.
Aucune fusion dans `v013/demo-octobre`. La validation Pixel de C2/R1 reste attendue.

## Modifications pour Claude

- `default_bus_layout.tres` : Master avec `AudioEffectHardLimiter`, plafond −1 dB,
  puis Musique, Ambiances, Effets, envoyés vers Master. Chargement explicite dans
  `project.godot`. Le choix du type de limiteur suit la
  [documentation Godot](https://docs.godotengine.org/en/4.4/classes/class_audioeffecthardlimiter.html).
- `SoundManager.gd` : les six lecteurs d'effets sont sur Effets, le lecteur
  musical sur Musique et les sept lecteurs d'ambiance sur Ambiances.
- Les préférences pilotent les bus. Aucun double gain sur les lecteurs : ils
  conservent seulement les fondus et les niveaux des couches. Le gain ambiance
  reste `clamp(music_volume * 1.2, 0, 1)`, comme auparavant.
- Interface et clés de préférences inchangées : `[audio] sfx` et `music` dans
  `user://settings.cfg`. Aucun changement du schéma des parties.
- `duck(bus, db, duree)` : dB négatifs, baisse immédiate, maintien pendant `duree`
  secondes, remontée linéaire en dB sur 1,5 seconde. Fonctionne aussi en pause.
  Exemple : `SoundManager.duck("Musique", -12.0, 2.0)`.
- Les appels superposés sont indépendants : l'atténuation la plus forte encore
  active gagne ; finir un appel n'annule pas les autres. Le volume final utilise
  la préférence courante, y compris si elle change pendant l'atténuation.
  Un bus réglé à zéro reste muet. Les demandes invalides sont ignorées.
- Aucun événement ne déclenche encore cette fonction : ces branchements relèvent
  d'A2/G2. Banque sonore, formats, pool de six lecteurs, playlists, synthèse de
  secours et durée des fondus de morceaux restent ceux du jeu existant.

## Test déterministe

`tests/scenarios/AudioBusScenario.gd`, scène isolée
`res://tests/audio_bus_test.tscn`, également exécuté dans le smoke.
Le test vérifie le layout chargé par AudioServer, le limiteur activé et son
plafond, le routage de tous les lecteurs, les gains sans double application,
le plafond du gain ambiance et la préservation du niveau de fondu musical lors
d'un changement de préférence. Il avance les vrais Tween à la main pour vérifier
l'atténuation, la remontée, la superposition, le changement de réglage en cours,
le silence et les entrées invalides. Les réglages sont restaurés sans écriture
des préférences personnelles. Les deux scripts nouveaux ont leurs fichiers `.uid`.

## Limites et contrôles humains

Validation locale sous Godot `4.7.2.stable.official.ed1daf0bf` : **15 contrôles
réussis, codes retour 0, aucune erreur Godot**. Premier import du dossier réussi.
Import, démarrage `--quit-after 2`, smoke, branding, garage, atelier, balance,
screen refresh, parcours CPU, C3, R1, C2, P0 unitaire, P0 intégration et A1 isolé.
Le smoke conserve ses deux avertissements d'ancres déjà présents sur la base R1.
`git diff --check` passe. Ce sont des contrôles locaux ; aucune nouvelle
exécution de GitHub Actions n'est revendiquée.

Le test logiciel vérifie la configuration du limiteur, pas des crêtes audio
capturées ni l'absence de distorsion audible. Aucun essai Pixel, APK, installation,
mesure de chauffe/autonomie ou nouvelle mesure P0 n'est réalisé dans ce lot.
Les résultats de validation réellement exécutés sont consignés dans
`.agent-output/report.md` et les journaux locaux associés.

Pour C2/R1 ce soir, conserver les contrôles déjà donnés dans le rapport R1 :

1. Sans choix antérieur de Fluidité, le menu affiche 30 images/s sur mobile.
2. Choisir 60, fermer complètement et rouvrir : le menu doit conserver 60.
3. Jouer cinq minutes à 60, noter chauffe et baisse de batterie observées.
4. Observer les animations du garage et la réactivité des menus, boutons et listes
   en pause, aux deux plafonds.
5. Revenir à 30 avant toute mesure P0. Documenter le mode économie C2, le battement
   de 20 Hz et le commit de la version dans la comparaison des 30 secondes au repos.
6. Si le garage saccade, passer `AnimationClock.INTERVAL` à `1.0 / 30.0` avant
   fusion, adapter les attentes du test C2 et relancer les contrôles.

Si A1 est inclus dans la version essayée, ajouter une écoute : effets, musique
et météo ensemble ; changer séparément les deux volumes existants ; mettre
chacun à zéro puis le rétablir ; vérifier les transitions musicales et l'absence
de saturation audible. Le ducking des événements sera à écouter après A2.
Ne pas ajouter une seconde installation à la validation prévue sans coordination.

## Livraison

L'utilisateur a explicitement autorisé, pour ce lot uniquement, le commit A1
et `git push origin codex/a1-audio-buses`. Seuls les fichiers du lot sont inclus,
sans journal, build, `.agent-output/`, secret ou `commit_msg.txt`.
Aucune fusion ni publication sur la branche démo, aucun usage de `gh` et aucune
modification de remote ne sont autorisés ou effectués.
