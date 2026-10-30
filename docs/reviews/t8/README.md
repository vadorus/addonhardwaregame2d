# T-8 — scène de risque de trésorerie

Tâche: #138
Auteur-IA: Codex
Relecteur-IA: Claude
État: à relire
Base: v013/demo-octobre @ 798daec91b14da2eae776685839a4a89ae111fe3
Branche: codex/t8-cash-scene
Tests: 3 validations locales PASS sous Godot 4.7.2 ; tests ciblés et 5 captures locales PASS.

## Comportement

La fenêtre système est remplacée par un Control modal sous l’en-tête Atelier/Retour, avec voile brun, portrait Nora existant, bulle f6e3c6 et carte fffaf1 à bordure ambre et ombre. La jauge situe le zéro et le point bas, compte de la caisse actuelle au point bas en 0,6 s ; sous zéro, zone corail et une seule pulsation. Les entrées de voile/carte/Nora et la sortie passent par Juice ; le mode réduit affiche directement la valeur finale.

Revoir mon choix est l’action ambre sélectionnée par défaut ; Lancer quand même est en contour corail. Annulation commune au bouton, voile, Échap et Retour Android. Décision immédiate, fermeture en fondu, double toucher ignoré. Le bouton d’alternative prépare le fondeur, la stratégie et le binning dans les deux parcours, sans engagement, puis les met en évidence. Un nouveau clic de lancement est nécessaire. La sélection manuelle suivante rétablit le comportement équilibré initial.

Les chiffres proviennent des devis GarageBusiness existants. cheapest_affordable_fabrication expose seulement les trois paramètres de l’option déjà calculée. ProductionPreview accepte la stratégie choisie au lieu de toujours simuler BALANCED ; aucun calcul économique ni schéma de sauvegarde modifié. fabrication_cash_text reste la source textuelle complète ; suppression de la question répétant les boutons.

Interactions._money reste le formateur : espaces U+00A0 pour les milliers, option currency pour le même format suivi de U+00A0 puis €. Les libellés existants d’Interactions et de fabrication_cash_text qui ajoutent € utilisent aussi U+00A0. Les autres formateurs historiques du jeu ne sont pas réécrits dans cette tâche.

## Fichiers

- ui/components/CashRiskDialog.gd : composition, jauge, animations, annulation et alternative.
- ui/GarageBadge.gd : pictogrammes finance et risque dessinés, aucun nouvel asset.
- ui/Juice.gd : fade_out et pulse_once respectant reduced_motion.
- ui/components/ProductionBoard.gd et IndustrializationPanel.gd : sélection sans lancement et pause restaurée.
- scripts/GarageBusinessManager.gd : paramètres de l’alternative, format insécable et texte sans question redondante.
- scripts/Interactions.gd : format partagé insécable.
- scripts/ProductionPreview.gd : aperçu conforme à la stratégie sélectionnée.
- main.gd : priorité à la fermeture du modal sur Retour Android, avant de fermer l’atelier.
- tests/scenarios/CashSafetyScenario.gd et tests/smoke_test.gd : contrôles adaptés et tests asynchrones.
- tests/t8_cash_scene_test.gd/.gd.uid/.tscn : test ciblé et outil de capture.
- docs/reviews/t8/ : preuves locales et cette passation.

## Validation exécutée

Windows local ; Godot 4.7.2.stable.official.ed1daf0bf, sans .NET.
Exécutable : C:/Users/Admin/.gemini/antigravity/scratch/godot/Godot_v4.7.2-stable_win64_console.exe.

- `godot --headless --path . --import` : code 0, zéro ERROR/SCRIPT ERROR.
- `godot --headless --path . --quit-after 2` : code 0, zéro ERROR/SCRIPT ERROR.
- `godot --headless --path . res://tests/smoke_test.tscn` : code 0, [CI] Smoke test passed, zéro ERROR/SCRIPT ERROR.
- `godot --headless --path . res://tests/t8_cash_scene_test.tscn` : code 0 ; alternative exacte sur les deux parcours, aucun euro dépensé ni lancement, double toucher, annulation voile/Retour/bouton, animations réduites et valeur finale exacte.
- `git diff --check` : code 0.
- Deux WARNING d’ancres de la suite de fumée : MomentsScenario.gd:65 et LiveThemeScenario.gd:64, préexistants et hors T-8.

Mesures réellement obtenues :
```
[CI] T8: visible=(1405.217, 626.087) scene=[P: (162.6087, 122.0), S: (1080.0, 492.087)] card=(760.0, 492.087) error=
[CI] T8 responsive: screen=(469.5652, 633.9131) scene=[P: (23.47826, 122.0), S: (422.6087, 499.9131)] card=[P: (23.47826, 277.0), S: (422.6087, 344.9131)] narrow=true
[CI] T8 actions: PASS (both fabrication paths, exact alternative preview, zero spending/launch, immediate input, double tap, veil/back/cancel, reduced motion)
```

En paysage, carte de 760 unités, scène de 1080 unités (moins de 90 % du visible), hauteur de 492,087 (moins de 80 %). En étroit, Nora en buste au-dessus, contenu défilant, boutons fixes de 56 unités minimum. Le test vérifie les rectangles finaux, la barre de défilement et le focus.

## Captures reproductibles

Pour chaque MODE :
`godot --path . --audio-driver Dummy --rendering-method gl_compatibility res://tests/t8_cash_scene_test.tscn -- MODE`

- [wide.png](wide.png) : 2424×1080, fin d’animation −2 503 €.
- [animation.png](animation.png) : 2424×1080, capture déclenchée lorsque la valeur est strictement entre départ et arrivée.
- [alternative.png](alternative.png) : 2424×1080, devis et alternative réellement calculés sur un fixture déterministe.
- [narrow.png](narrow.png) : 800×1080, buste et contenu défilant.
- [no-alternative.png](no-alternative.png) : 2424×1080, caisse nulle, aucun conseil finançable.

Rendu OpenGL de compatibilité sur Intel UHD 630, audio Dummy pour éviter le périphérique audio indisponible du PC. Tous les rendus finaux : code 0, zéro ERROR. Les captures wide/animation/narrow reprennent explicitement les chiffres du cas Pixel T7 dans un devis de présentation ; l’alternative est calculée par la source réelle, d’où son prix différent de l’ancienne partie Nova. Les captures alternative/no-alternative utilisent des devis intégralement calculés. Ce sont des captures locales, pas des captures Android ni une partie Pixel.

## Coordination et limites

Inventaire initial paginé : PR brouillons #82/#89, sans chevauchement. #136 terminée et fermée avec commentaire de fusion #137 @ 798daec selon arbitrage explicite d’Alexandre. Réservation #138 étendue à main.gd et ProductionPreview avant modification. Le précontrôle est refait avant push.

Autorisations : branche, commits, push et PR brouillon seulement. Aucun skip ci, fusion, build stable ou installation. Version inchangée 0.13.3-demo / 28. Aucune lecture ou modification de sauvegarde personnelle ; les outils de capture désactivent l’écriture.

À vérifier par Claude : relecture indépendante, tenue des styles dans l’écran complet, Retour matériel et défilement au doigt sur Android après un futur build/installation autorisés. L’intégration Android n’est pas revendiquée par les captures locales.
