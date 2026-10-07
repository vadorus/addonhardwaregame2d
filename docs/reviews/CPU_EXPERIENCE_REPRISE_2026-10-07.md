# Reprise du chantier CPU — 7 octobre 2026

## Point de reprise vérifié
- PC bureau DESKTOP-S47NP0P accessible par Desktop Commander ; Pixel 10 63140DLCR0040K accessible par ADB.
- PC home hors ligne : son worktree, ses commits et ses tests non poussés restent non vérifiés.
- Dernière base Git disponible : eb7964d, origin/codex/p0-p1-project-reliability.
- Le Pixel portait déjà 0.11.1-reboot-r1 (versionCode 20), mise à jour le 06/10 à 23:02:15.
- Cette APK a été copiée puis récupérée avec GDRE 2.7 ; code de refonte CPU réellement présent.
- Worktree de reprise : C:\Users\Admin\Documents\TechEmpire-cpu-experience-20261007.
- Branche locale : v012/cpu-experience-recovery. Aucun commit/push effectué.
- Ne pas écraser les autres worktrees du bureau ni le worktree home lors de la future réconciliation.

## Source et récupération
L'APK sert à récupérer des comportements exécutables, pas les commentaires, l'historique Git ni les tests d'hier.
Récupérés : CpuExperience, cartes CPU/prototype, visuel de puce lié au design, éléments garage,
présentation premier CPU et formulaires Software, retour Software vers CPU.
Les managers financiers et de migration de la base poussée ont été conservés :
la version reboot-r1 récupérée ne contenait pas tous leurs correctifs récents.
Les différences de formatting issues de la décompilation ne représentent pas toutes des changements fonctionnels.

## Changements de ce lot
- Décisions contextualisées par le besoin électrique calculé et les marges du design.
- Réduction/augmentation réelle de fréquence ; révision réelle de l'enveloppe électrique.
- Recalcul des estimations de design, des objectifs, de la complexité et du plan de génération.
- Aperçus des choix par le même calcul de métriques finales, sans tirer de RNG.
- Affichage avant/après et coûts immédiats/délai/coût de développement pendant le délai.
- Copie du projet pour tout aperçu ; aucune écriture dans le projet réel.
- Migration à la lecture des anciennes décisions de phase, IDs conservés.
- Décisions gratuites de compromis, pour éviter une impasse financière.
- Coûts de corrections proportionnés ; tarifs de départ préservés pour une équipe de deux et
  un programme <= 55 000 de budget mensuel, après régression économique observée.
- Indices explicitement présentés comme estimations, sans inventer des mesures de température.
- Carte prototype récupérée fondée sur le déficit électrique / indices du design, plutôt que
  sur une faiblesse aléatoire du rapport.
- Contrôles d'équipe repliables, sélecteur masqué s'il n'existe qu'un projet et suppression du doublon
  de contexte : les trois options restent visibles dans la capture PC 1280×720.

## Vérifications déjà exécutées
- Import Godot 4.7.2 et lancement headless : PASS.
- cpu_prototype_test : PASS (RNG, absence de mutation, avant/après, design réel, sauvegarde,
  coût, refus atomique, répétition de choix, délai, ouverture du cockpit).
- project_cockpit_test : PASS.
- software_gameplay_test / software_integration_test : PASS.
- garage_layout_test / workshop_layout_test : PASS.
- Sauvegarde réelle Pixel chargée sur PC, écritures désactivées : PASS.
  16 017 713 €, octobre 1987, PRJ-008 bsm 3 ; aperçu et cockpit conservent le projet et le RNG.
- Sept parcours CPU interactifs jusqu'à une gamme vendable : PASS.
  Réserves au lancement : Accessible pionnier qualité 55 971 ; Standard prudent 18 533 ;
  Standard qualité payante 5 499 ; Standard pionnier sécurisé 4 592 ;
  Réaliste prudent 11 219 ; Réaliste polyvalent guidé 5 086 ; Réaliste pionnier prudent 3 186 €.
- Capture PC du cas de déficit électrique inspectée.
- Première exécution du smoke test après récupération a révélé une régression de réserve puis
  une faillite en industrialisation. Tarifs débutants corrigés ; seuils des tests non abaissés.
- Une attente littérale du kicker de prototype a été conservée pour la compatibilité des contrôles du Labo.
- Build officiel complet : PASS import, smoke, garage_layout, workshop_layout, balance_ceiling,
  exports Windows et Android, signature de test commune vérifiée.
- Mise à jour Pixel par tools/build_all.ps1 -SkipTests -Install après le build testé : PASS.
  versionCode 21 / 0.11.1-reboot-r2 ; sauvegarde copiée et identique à l'octet près après installation.
- Vérification visuelle Pixel : écran titre, Continuer, QG et cockpit bsm 3 ouverts ;
  partie en pause, 16 017 713 €, octobre 1987. Trois choix avant/après lisibles après défilement.
  Aucun choix réel validé et aucun temps avancé. Pas d'erreur GDScript/fatale dans les 500 lignes
  de logcat examinées du processus. Le cas de déficit électrique a été joué dans les tests PC,
  pas provoqué dans la sauvegarde réelle du téléphone.
- Captures : build/pixel-r2-check.png, pixel-r2-game.png, pixel-r2-cpu.png, pixel-r2-choices.png.
- Source conservée dans le worktree et build/checkpoints/reboot-r2-source avec manifeste SHA-256.

## Limites du verdict
Ce lot ne clôt pas la refonte verticale CPU. Il ne valide pas l'intérêt d'une carrière entière.
La surnotation presse observée dans l'audit n'est pas corrigée par ce lot.
À poursuivre : retours benchmark/presse compréhensibles, comparaison au prédécesseur,
rythme et décisions pendant toute la production, lancement/clients/vieillissement/successeur.
L'original exact du worktree home reste nécessaire pour réconcilier les fichiers non embarqués
et les essais d'hier ; aucun état de ce worktree n'est déclaré récupéré intégralement.
