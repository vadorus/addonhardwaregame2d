# Construire la version Play Store (AAB)

Deux réglages d'export Android existent :

| Réglage | Fichier | Usage |
|---|---|---|
| `Android APK` | `build/android/TechEmpire-v0.9.0-debug.apk` | test sur le Pixel (clé de debug du PC) |
| `Android Play Store (AAB)` | `build/android/TechEmpire-playstore.aab` | envoi sur Google Play, signé avec la clé de publication |

Le réglage Play Store utilise la construction Gradle de Godot 4.7.2 : Android 16 visé (API 36, exigé par
Google depuis le 31/08/2026), Android 7 minimum (API 24), arm64 seulement.

## La clé de publication

- Créée le 01/10/2026 sur le PC de la maison : `Documents\TechEmpire-signature\techempire-upload.keystore`,
  alias `techempire`. Le mot de passe est dans le fichier texte à côté, **jamais dans le dépôt**.
- C'est la **clé d'importation** de Google Play (signature des applis gérée par Google) : si elle est perdue,
  Google peut la remplacer sur demande, mais il faut attendre.
- Empreinte SHA-256 du certificat :
  `F9:3D:23:67:77:AB:4F:61:65:DC:9E:D1:35:02:8C:15:38:5E:55:89:E6:29:D5:B6:1A:D6:A9:FA:30:B3:60:AF`
- Pour construire sur un autre PC, copier le dossier `TechEmpire-signature` (clé USB), jamais par GitHub ni mail.

## Construire

Une fois par PC, puis à chaque construction (le modèle Gradle s'installe dans `android/`, ignoré par git) :

```bat
set GODOT_ANDROID_KEYSTORE_RELEASE_PATH=%USERPROFILE%\Documents\TechEmpire-signature\techempire-upload.keystore
set GODOT_ANDROID_KEYSTORE_RELEASE_USER=techempire
set GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<mot de passe du fichier texte>
godot --headless --path . --install-android-build-template --export-release "Android Play Store (AAB)" build/android/TechEmpire-playstore.aab
```

`--install-android-build-template` ne s'utilise qu'avec `--export-…` : seul, il lance le jeu en arrière-plan.

## Avant chaque envoi sur Google Play

- Augmenter `version/code` (Google refuse deux envois avec le même numéro) et, si besoin, `version/name`,
  dans les **deux** réglages Android pour qu'ils restent alignés.
- Vérifier la signature : `jarsigner -verify -certs build\android\TechEmpire-playstore.aab`
  doit afficher `CN=Tech Empire, O=vadorus, L=Tourcoing, C=FR`.

## Encore à faire pour la fiche Play Store

- Politique de confidentialité (URL publique), questionnaire de classification du contenu, section
  « Sécurité des données ».
- Icône 512 × 512, bannière 1024 × 500, captures d'écran téléphone (au moins 2).
- Test fermé : 12 testeurs inscrits pendant 14 jours d'affilée avant la production (nouveau compte personnel).
