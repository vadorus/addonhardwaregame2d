# T-8 — scène de trésorerie : finition après relecture

Tâche: #138
Auteur-IA: Codex
Relecteur-IA: Claude
État: finitions corrigées, à relire avant fusion
Base: v013/demo-octobre @ 798daec91b14da2eae776685839a4a89ae111fe3
Branche: codex/t8-cash-scene
Tests: 3 validations locales PASS (import, démarrage, smoke) sous Godot 4.7.2 ; test ciblé et captures locales PASS.

Le fond a été approuvé par Claude selon le retour transmis par Alexandre. Les sept finitions demandées sont traitées ; aucune approbation de la nouvelle tête n’est revendiquée.

## Résultat

- Jauge : trace ambre pâle permanente entre zéro et caisse de départ, montant de départ sous CAISSE ACTUELLE, montant animé et « Point bas prévu » au-dessus du curseur. Police obtenue par get_theme_default_font ; alignement calculé à partir des métriques du texte.
- Carte et bulle à la hauteur naturelle de leur contenu, plafond de 80 % avec défilement. Nora repose au bas de la carte ; en étroit, le buste est au-dessus. Les boutons restent fixes, tactiles, actifs dès l’entrée.
- Trois pastilles de même hauteur, contenu centré verticalement : libellé muted, valeur en gras à 20, détail en petit ; triangle aligné sur la valeur.
- Finance : pièce cerclée avec un véritable € dessiné avec la police du jeu.
- Conseil : libellés ProductionPreview.BINNING_LABELS (« Plus de X », etc.), prix et point bas de l’alternative expliquant sa recommandation. Une priorité non équilibrée est indiquée explicitement.
- Atelier : fondeurs × trois tris en stratégie BALANCED d’abord ; recherche toutes stratégies seulement si aucune option équilibrée n’est finançable. La note d’une option de Nora reste visible au rafraîchissement. Un clic manuel remplace l’option, revient à BALANCED et affiche « Option de Nora remplacée par votre choix » pendant 2,5 s.
- En-tête : voile brun léger, moins sombre que le corps, cohérent avec son blocage pendant la décision.

Les calculs de devis et la recherche de rentabilité restent ceux de GarageBusiness ; le paramètre balanced_first est optionnel et ne change pas le comportement du parcours IndustrializationPanel. L’alternative ne dépense ni ne lance : un autre clic reste nécessaire. Annulation commune au voile, bouton, Échap et Retour Android ; double toucher ignoré.

## Validation réellement exécutée

Windows local, Godot 4.7.2.stable.official.ed1daf0bf, sans .NET.

- `godot --headless --path . --import` : code 0, zéro ERROR/SCRIPT ERROR.
- `godot --headless --path . --quit-after 2` : code 0, zéro ERROR/SCRIPT ERROR.
- `godot --headless --path . res://tests/smoke_test.tscn` : code 0, [CI] Smoke test passed, zéro ERROR/SCRIPT ERROR.
- `godot --headless --path . res://tests/t8_cash_scene_test.tscn` : code 0, zéro ERROR/SCRIPT ERROR.
- `git diff --check` : code 0.

Tests : les deux parcours de fabrication ; alternative et aperçu exacts sans engagement ; préférence équilibrée même face à une autre stratégie moins chère ; recours quand aucune option équilibrée ne tient ; persistance de la note, message manuel et disparition après délai ; double toucher ; annulations ; valeur finale exacte et mode réduit ; focus ; rectangles après mise en page, hauteurs naturelles, pastilles égales, bas du portrait aligné à la carte, défilement en étroit.

```
[CI] T8 responsive: screen=(1405.217, 626.087) scene=[P: (162.6087, 170.0435), S: (1080.0, 396.0)] card=[P: (482.6087, 170.0435), S: (760.0, 396.0)] narrow=false
[CI] T8 responsive: screen=(469.5652, 633.9131) scene=[P: (23.47826, 122.0), S: (422.6087, 499.9131)] card=[P: (23.47826, 258.0), S: (422.6087, 363.9131)] narrow=true
[CI] T8 review: PASS (balanced option preferred over cheaper hidden strategy; fallback note survives refresh; manual replacement explained; content heights, equal chips, gauge and header checked)
```

Deux WARNING d’ancres préexistants dans smoke : MomentsScenario.gd:65 et LiveThemeScenario.gd:64, hors T-8.

## Captures refaites — toutes à 1080 px de haut

Pour chaque MODE :
`godot --path . --audio-driver Dummy --rendering-method gl_compatibility res://tests/t8_cash_scene_test.tscn -- MODE`

- [wide](wide.png) : 2424×1080 ; point bas −2 503 € ; carte 760×485 unités, bulle 300×126, aucun vide imposé ; conseil complet et boutons visibles.
- [animation](animation.png) : 2424×1080 ; valeur intermédiaire capturée pendant le déplacement du curseur, caisse initiale toujours affichée.
- [alternative](alternative.png) : 2424×1080 ; cas réellement calculé où la priorité non équilibrée est le recours, avec son prix et son point bas expliqués.
- [narrow](narrow.png) : 800×1080 ; buste au-dessus, carte 422,609×363,913 unités ; contenu défilant et actions fixes.
- [no-alternative](no-alternative.png) : cas complémentaire réellement calculé avec caisse nulle ; carte naturellement réduite à 396 unités de haut.

Rendu OpenGL de compatibilité sur Intel UHD 630, audio Dummy. Les captures wide/animation/narrow reprennent explicitement les chiffres du cas Pixel T7 dans un devis de présentation ; les alternatives sont calculées par le moteur. Les cas alternative/no-alternative utilisent des devis intégralement calculés. Aucun de ces visuels ne constitue une capture Android.

## Portée et coordination

Réservation #138, zones inchangées et contrôlées. Reprise à la tête de #139 fdf7eae, inventaire paginé et précontrôle avec resume-pr réussis avant édition : PR concurrentes #82/#89 sans conflit. #136 est terminée et fermée selon l’arbitrage d’Alexandre.

Fichiers repris pour la finition : CashRiskDialog.gd, ProductionBoard.gd, GarageBusinessManager.gd, GarageBadge.gd, CashSafetyScenario.gd, t8_cash_scene_test.gd, captures et passation. Les autres fichiers de T-8 restent dans le diff initial de #139.

Pas de skip ci, fusion, build stable, installation, nouvelle PR, modification de version ou de schéma de sauvegarde. Aucun fichier personnel ni donnée du Pixel touché. Les captures désactivent l’écriture des sauvegardes.

À faire : relecture indépendante des finitions par Claude, puis essai tactile Android après autorisation séparée de build/installation. Les formateurs historiques hors Interactions et de ses consommateurs ne sont pas réécrits.
