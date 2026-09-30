# Lot Q0 — clé de signature de test commune (30/09/2026, Claude)

**But** : ne plus jamais effacer les parties du téléphone en passant d'un PC à l'autre.

## Fait
- Clé de test du PC du travail (celle qui a signé la version installée sur le Pixel le 30/09) copiée dans
  `tools/android/techempire-debug.keystore`. Empreinte SHA-256 : `997747a416da98eb1f09f371a922365203a71addea7ee8544b4102e74f49a4bb`.
- `tools/build_all.ps1` :
  - signe toujours avec cette clé (`GODOT_ANDROID_KEYSTORE_DEBUG_*`), sur n'importe quel PC ;
  - vérifie l'empreinte de l'APK avec `apksigner` avant d'installer ;
  - copie les parties du téléphone dans `build\pixel_saves\<date>` avant chaque installation (emplacements vides ignorés) ;
  - s'arrête au lieu de désinstaller si le téléphone porte une autre clé ;
  - trouve Godot et le SDK Android sur les deux PC ; saute la version PC là où le modèle d'export Windows manque ;
  - n'est plus interrompu par un simple avertissement de Godot.
- `tools/setup_debug_keystore.ps1` : règle l'éditeur Godot d'un PC pour utiliser la même clé (exports depuis l'éditeur
  ou par une autre IA). Lancé sur le PC du travail. **Reste à le lancer sur le PC maison** (Godot fermé).
- `docs/BUILD_PC_ANDROID.md` mis à jour.

## Vérifié
- Tests : smoke, garage, atelier verts.
- Build sur le PC du travail : signature « clé commune OK », APK installé **par mise à jour** sur le Pixel
  (date de première installation inchangée : 09:38), sauvegarde toujours présente après l'installation.

## Reste à faire
- PC maison : lancer `tools\setup_debug_keystore.ps1`, puis un build avec `-Install` pour confirmer.
- Intégration continue GitHub : utiliser la même clé si le workflow produit un APK de test.
