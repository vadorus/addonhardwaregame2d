# Rapport de validation Android V0.8

## Atelier CPU harmonisé — 27 septembre 2026

- Atelier guidé premier CPU refait en contrôles natifs : fenêtre blanche à bord bleu, bandeau bleu avec repère d'étape, quatre cartes d'objectif avec icônes, saisie claire, estimations bleues, avis de l'équipe crème, action principale verte. Garage existant conservé derrière le voile modal.
- Aucun nouveau décor généré dans cette passe. Aucune modification des règles CPU, budgets, estimations ou sauvegardes ; textes et disposition uniquement. Année du bandeau issue de TimeManager.
- Fichiers touchés : `ui/FirstCpuWorkshop.gd`, nouveau `ui/WorkshopStyle.gd`, nouveaux `tests/workshop_layout_test.gd` et `.tscn`, ce rapport. Les autres changements de la copie V0.8 sont conservés.
- Vérifié : import Godot 4.7.2, boot headless, smoke test complet et test garage existant réussis. Nouveau test atelier réussi aux formats 1616×720, 1280×720 et 700×720 : largeur contenue, choix tactiles, quatre configurations, lancement visible en paysage, signal portant exactement le spec attendu et erreurs non coupées. La vue étroite utilise le défilement vertical.
- Export Android debug réussi, installation en mise à jour sans effacement des données sur Pixel 10 63140DLCR0040K, lancement à froid OK. APK : `build/android/TechEmpire-v0.8-workshop-ui-debug.apk`, SHA256 `30518BC32B43B70492C7E49057DD9C280BD47106E9FBC76175638636FE98135D`.
- Vérifié physiquement par touches ADB : accueil, création de l'entreprise de test, ouverture atelier, choix Simple & économique, affichage de la préparation, retour aux objectifs. Captures inspectées : `diagnostics/workshop-choice-pixel.png`, `diagnostics/workshop-config-pixel.png`.
- Logcat du processus 24968 : aucune correspondance SCRIPT ERROR/FATAL EXCEPTION/ERROR/ANR pendant ce parcours ; buffer crash vide. Téléphone laissé sur le choix CPU, simulation en pause. Le lancement effectif du projet n'a pas été déclenché sur le téléphone ; émission du signal validée automatiquement.
- Limites : cette passe concerne uniquement le parcours guidé du premier CPU. Conception avancée, Équipe, Entreprise, Produits et Marché gardent encore leur présentation antérieure. Pas de nouvelle animation ni d'illustration par écran. Pas de commit, push ou modification de la copie source synchronisée.

## Interface adaptée à la maquette fournie

- Décor illustré créé depuis la référence utilisateur avec image_gen intégré, puis copié dans `assets/ui/garage_reference_v09.png`. Prompt complet dans `.agent-output/image-prompt.md`.
- Les boutons, indicateurs, textes et cartes sont des contrôles Godot indépendants de l'image : barre de trésorerie/date/réputation/vitesse, carte projet blanche et bleue, étapes de développement, action verte, tâches et actualités réelles.
- Repères ronds natifs sur les postes de travail. Colonne gauche visible ; Améliorations, Recrutement, Produits et Marché restent désactivés jusqu'à leur déblocage réel. Pas de fausse boutique ni de valeurs de hype inventées.
- Le garage occupe la hauteur disponible ; les cartes de projet, tâches et actualités ne débordent plus sous l'écran. Leur taille se recalcule après le retour à la ligne des textes.
- Les fenêtres d'accueil et d'atelier sont dessinées au-dessus du garage et de ses panneaux.
- Fichiers de code modifiés : `main.gd`, `ui/GarageHub.gd`, `ui/screens/DashboardScreen.gd`, `tests/scenarios/GarageScenario.gd`. Ajouts : `ui/GarageBadge.gd`, `tests/garage_layout_test.gd`, `tests/garage_layout_test.tscn`, asset PNG et `diagnostics/.gdignore` pour exclure les captures des exports.
- Tests : import, démarrage headless, smoke test complet, test de disposition aux formats 1616×720 et 1280×720. Contrôle du confinement des cartes, de leur non-chevauchement, de la taille de la carte tâches, des fonctions verrouillées et de la priorité des fenêtres.
- La date 1971, la devise et les valeurs proviennent toujours de la simulation. Le décor reste une illustration statique ; les animations de personnages et des décors distincts pour chaque palier ne sont pas ajoutés dans cette passe.
- Développement local dans cette copie V0.8 ; aucun commit ni push.
- Validation physique sur Pixel 10 : accueil propre, création d'entreprise, entrée au garage, bouton vert ouvrant l'atelier, retour au garage et repère d'établi ouvrant le menu contextuel. Aucun crash ni erreur de script relevé dans les journaux du processus de ce parcours.
- Un dernier défaut de hauteur du menu contextuel a été corrigé et ajouté au test de disposition (menu entièrement contenu dans l'écran).
- APK : `build/android/TechEmpire-v0.8-reference-ui-debug.apk`. Capture du garage interactif : `diagnostics/reference-ui-pixel.png` ; capture d'ouverture de l'atelier : `diagnostics/reference-workshop-pixel.png`.

## Correctif accueil — validation suivante

- Défaut confirmé : les panneaux du garage restaient visibles derrière et au-dessus de l'accueil avant la création de l'entreprise.
- `main.gd` masque maintenant le conteneur de jeu entier tant que l'accueil ou le formulaire de création est ouvert, puis le réaffiche quand cet écran se ferme.
- `tests/scenarios/NewPlayerEntryScenario.gd` vérifie l'absence du garage à l'accueil et dans le formulaire, puis sa visibilité à l'entrée en jeu. Ce test échoue avant correction et passe après.
- Import Godot 4.7.2, démarrage headless, smoke test complet et export Android : réussis.
- APK corrigée : `build/android/TechEmpire-v0.8-onboarding-fix-debug.apk`, installée avec succès sur le Pixel 10 en conservant les données existantes.
- Parcours réel vérifié par toucher ADB : accueil sans panneau parasite → Nouvelle entreprise → formulaire sans panneau parasite → Entrer dans le garage → garage visible, partie en pause au jour 1.
- Captures vérifiées : `diagnostics/pixel-v08-fixed-title.png`, `diagnostics/pixel-v08-fixed-form.png`, `diagnostics/pixel-v08-fixed-garage.png`.
- Processus Android 19331 actif, boucle principale Godot démarrée, aucune erreur détectée dans ses journaux au cours du parcours.
- La limite ADB mentionnée dans le premier rapport ci-dessous est levée : les anciens essais utilisaient des coordonnées issues de la capture réduite, au lieu des coordonnées natives 2424 × 1080.
- Correctif local uniquement dans cette copie V0.8 ; aucun commit, push ou changement de règles de gameplay.

Le reste du rapport décrit la validation initiale, avant ce correctif.

## Résumé

- Validation effectuée depuis un instantané propre de `origin/prototype/v08-garage-first` au commit `03c662746b69db76fa1faed367ad13c0b11dead3`.
- Le Pixel 10 connecté a été détecté par ADB sous le numéro de série `63140DLCR0040K`.
- L'APK V0.8 absente du dépôt actif a été reconstruite avec Godot 4.7.2, installée en mise à jour de la V0.7, puis lancée deux fois à froid.
- L'application est restée active au premier plan. L'écran affiche `V0.8 - GARAGE FIRST` et le garage en arrière-plan.
- Aucun crash Android, signal fatal, ANR ou erreur de script Godot n'a été détecté.

## Fichiers touchés

- Aucun fichier de gameplay ou source n'a été modifié.
- Fichiers générés uniquement dans cette copie de test : cache `.godot/`, APK sous `build/android/`, captures sous `diagnostics/` et ce rapport.

## Vérifications exécutées

- Godot 4.7.2 : import du projet, démarrage headless et `res://tests/smoke_test.tscn` — succès.
- Export Android debug `TechEmpire-v0.8-debug.apk` — succès.
- APK : 29 800 833 octets, SHA-256 `D8C8AB001FE88B47CF62F8F85DB8556681005055968F1AB15A0D3255593F70E7`.
- Installation ADB avec conservation des données — succès ; package `com.vadorus.techempire`, `versionCode=8`, `versionName=0.8`.
- Deuxième lancement à froid — succès en 456 ms ; boucle principale Godot démarrée ; processus encore vivant après 25 secondes.
- Buffer crash Android vide et recherche ciblée d'erreurs fatales : zéro correspondance.
- Capture réelle du Pixel : `diagnostics/pixel-v08-final.png`.

## Limites et vérification humaine

- La capture confirme le démarrage de l'accueil garage-first et du shell garage sous-jacent.
- Les commandes de toucher injectées par ADB n'ont pas activé le bouton `Nouvelle entreprise`; le parcours après ce bouton n'a donc pas été validé dans ce test. Un toucher manuel sur le téléphone reste conseillé pour cette interaction précise.
