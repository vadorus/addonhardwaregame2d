# P1 — créer et piloter les projets au garage

Le parcours partagé est `Nouveau projet → Processeur ou Logiciel`, puis pour le
logiciel `Petits contrats ou Créer un produit`. Le choix Processeur ouvre la
conception d'un nouveau CPU, y compris lorsqu'un CPU est déjà en développement.
Le premier CPU garde son atelier guidé. Les contraintes réelles (équipe, budget,
nombre de projets) sont vérifiées au démarrage et expliquées au joueur.

Pendant le développement, le panneau du garage conserve deux actions tactiles
fixes : ouvrir/piloter le travail en cours et créer un nouveau projet. Le détail
des projets défile au-dessus de ces actions. Chaque ligne CPU, Software ou contrat
ouvre le bon contexte et présente sa phase, son avancement et l'équipe affectée.
Les actualités ne doivent recouvrir aucun des boutons.

Les mécanismes R1/R2 et RC2 sont réutilisés : orientations à plusieurs étapes,
arbitrages de qualité/performance/risque/coût/délai, incidents, validation, bêta,
priorités de développement et partage réel des développeurs. Une décision requise
met le temps en pause et propose des conséquences visibles avant le clic. Le
support commercial et les devis suivent les règles P0 ; aucun marché n'est ajouté.

Validation déterministe : `complete_layout_test` vérifie six formats (1616×720,
1405×626, 1280×720, 1067×600, 800×480 et 700×720), le retour au choix de branche,
la création CPU pendant un projet actif, les projets parallèles, les contrats et
les limites de chaque cible tactile. Les tests cockpit, gameplay R2 et expérience
complète vérifient les effets réels et le cycle Software. Les captures fraîches
du choix, du devis et des décisions complètent ces tests, sans constituer un test
d'utilisabilité auprès de joueurs novices.
