# Retour Codex — P0 (8 octobre 2026)

## Périmètre et sécurité
- Base : v013/demo-octobre, commit 1326476.
- Worktree isolé : TechEmpire-p0-probe ; branche codex/p0-perf-probe-20261008.
- Étape traitée : **P0 uniquement** ; aucune optimisation C2/C3.
- Auteur du commit : vadorus et adresse GitHub noreply, jamais Gmail.
- Aucune installation APK, aucune publication Play Store, aucune modification de la sauvegarde Pixel.
- Aucune modification des worktrees contenant les travaux C2/C3 en cours.

## Réalisation
- scripts/PerfProbe.gd, autoload inactif par défaut, activable via cinq appuis sur la version du menu ou via --perf-probe.
- Tableau de bord local P0 : copie de sauvegarde de référence, choix d'une cadence 30/60 FPS, séries de 12 fins de mois à x3 sur QG / Entreprise / Produits, repos 30 s, jeu x1 60 s, trois tours des sept onglets.
- Sécurité de la sauvegarde : copie de référence séparée (user://perf_reference.json), rechargement en sandbox (user://perf_sandbox/), sauvegardes automatiques désactivées dans ce mode ; aucune décision prise par l'outil.
- Interruption avec message dès qu'une décision bloque le temps, sans comptabiliser la série comme terminée.
- Mesures en mémoire pendant la série : intervalles entre images, temps de processus Godot, percentiles, pics >50 ms et >100 ms ; durée de la simulation et des rafraîchissements d'écrans, temps de changements d'onglet jusqu'à la première image présentée.
- CSV local écrit uniquement à la fin d'une série ; récapitulatif affiché ; pas de transmission réseau.
- Empreinte de la sauvegarde de référence et vérification de cohérence de l'état de fin de série (horodatage de sauvegarde et fraction de temps neutralisés). Les écarts sont signalés.
- Champs de sortie : série, type, index, écran, statistiques d'image, temps simulation, temps UI, résidu, écran ralenti, transition, checkpoint, résultat, FPS et version/commit.
- Aucun changement du schéma des sauvegardes.
- Fichiers intégrés : scripts/PerfProbe.gd (+ uid), main.gd, project.godot, scripts/SimulationManager.gd ; tests/perf_probe_test, tests/perf_probe_integration_test et tests/perf_probe_overhead_test avec leurs scènes.

## Validations exécutées — Godot 4.7.2 sur PC home
- Import : PASS ; démarrage sans interface (--quit-after 2) : PASS.
- perf_probe_test : PASS, trois protections (contenu du CSV et séparation, arrêt au blocage, aucune écriture prématurée).
- perf_probe_integration_test : PASS, vraie fin de mois sur une copie isolée, blocage et sauvegarde source inchangée.
- perf_probe_overhead_test : PASS.
- smoke_test : PASS.
- branding_config_test : PASS.
- garage_layout_test : PASS.
- workshop_layout_test : PASS.
- balance_ceiling_test : PASS.
- screen_refresh_test : PASS.
- cpu_journey_test : PASS.
- Journaux de la suite relus : aucune ligne ERROR:, SCRIPT ERROR ni Parse Error.

Microbenchmark (20 000 paires de crochets, PC home) :
- Inactif : 0,351 microseconde par paire début/fin.
- Actif : 1,044 microseconde par paire début/fin.
- Surcoût : +0,693 microseconde par paire.
Ce résultat ne mesure ni les FPS de l'application ni la consommation électrique.

## Utilisation lors de l'APK témoin
1. Relecture de ce commit par Claude. APK construit sur le PC ayant la bonne clé de debug ; sauvegarde préalable obligatoire du Pixel, sans désinstallation.
2. Pour que le CSV indique le SHA exact du build, créer temporairement perf_build_commit.txt à la racine de la copie d'export avec le SHA de HEAD. Ce fichier n'est pas versionné. Sinon le CSV indique explicitement « SHA export non renseigné ».
3. Préparer une copie de sauvegarde de référence dont la simulation des douze prochains mois ne rencontre aucun choix bloquant. Ne pas utiliser la partie personnelle comme terrain d'essai.
4. Menu puis cinq appuis sur la version ; choisir 30 FPS pour pouvoir comparer avec le futur APK optimisé, et reprendre les mêmes conditions.
5. Exécuter repos 30 secondes, jeu x1 60 secondes, douze fins de mois à x3 sur QG, Entreprise et Produits, puis trois tours des sept onglets.
6. Comparer les CSV. Ne pas rejouer de choix dans P0. Quitter et relancer l'application pour revenir au comportement normal.

## Limites et contrôles restants
- L'outil a été testé en Godot headless, pas visuellement sur le Pixel. Aucun APK n'a été créé.
- La durée résiduelle de l'image ne mesure pas directement le GPU ; elle englobe aussi l'ordonnancement système et d'autres travaux.
- L'identité de fin de série doit être confirmée sur deux simulations complètes depuis la même copie réelle de référence.
- La latence des onglets doit être comparée au ressenti humain sur le Pixel.
- Toute série interrompue (décision, blocage) est exclue de la comparaison et doit être signalée.
- P0 doit être revu avant toute construction, puis l'APK témoin mesuré avant de commencer C3 et C2.

## Verdict
P0 prêt pour relecture technique et premier APK témoin ; validation sur Pixel encore nécessaire.

## Correctif P0 après premier essai Pixel

- L'APK initial au commit `498466b` était correctement signé, installé et sa sauvegarde sauvegardée, mais l'activation P0 affichait seulement le voile sombre : le `ScrollContainer` du panneau avait une hauteur minimale nulle en paysage.
- Le correctif fixe une hauteur de fenêtre bornée par la taille du viewport, une largeur explicite et un fond de panneau lisible. Les contrôles restent défilables sur petit écran.
- Nouveau `tests/perf_probe_panel_test.tscn` : contrôle, après construction réelle, la visibilité du panneau, sa hauteur non nulle, sa présence dans la fenêtre et les dix commandes.
- Test PC : PASS (hauteur scroll 650 px, panneau 601 px, dix boutons). La confirmation visuelle sur Pixel est à effectuer après reconstruction du correctif.
- Lors de la première vérification de la version P0, un appui automatisé mal positionné a déclenché la vitesse x3 au lieu d'ouvrir le menu. Les sauvegardes d'origine ont été restaurées depuis la copie avant installation et vérifiées en SHA-256 octet par octet ; la référence P0 existe séparément.

## Correctif des trois tours d'onglets (validation Pixel)

- La première série QG au repos sur Pixel, plafonnée à 30 FPS, a créé son CSV avec une moyenne de 33,24 ms par image, p95 de 34,18 ms, p99 de 34,55 ms, pire image de 34,99 ms, zéro image au-dessus de 50 ms. Cette série ne mesure pas les fins de mois.
- La première série des trois tours s'arrêtait au huitième appui, car `_tab_step` était utilisé directement comme index (valeur 7 hors limites). Le correctif utilise un index modulo sept, sans changer la limite de 21 transitions.
- Le test d'intégration rejoue les 21 transitions ; en headless, il simule le signal de présentation d'image qui n'est pas émis par le serveur de rendu désactivé.
- L'export Android inclut maintenant explicitement `perf_build_commit.txt` pour que le CSV connaisse la révision exacte. Ce fichier est généré localement lors de la construction, jamais versionné.
- La nouvelle version doit encore être construite, installée avec la clé commune et revalidée en réel avant de déclarer la mesure des transitions acquise.
