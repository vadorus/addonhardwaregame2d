# Retour de lot — SOFT-2 « Logiciel 2.0 » (14/10/2026)

- **Demande d'Alexandre (14/10, 13 h 47) :** « revoir tous les onglets et voir l'amélioration gameplay de la partie logiciel qui est trop nulle actuellement ». Plan proposé par Claude et validé en entier, dans l'ordre : (1) l'écran et la boucle, (2) la presse et les versions, (3) la synergie avec le CPU.
- **Branche :** `feat/logiciel-2` (depuis `v013/demo-octobre` @ c3f9046) — commits 52e95fa (étape 1) et c0eaaca (étapes 2 et 3).

## Ce qui change pour le joueur

### Étape 1 — le studio
- « Nouveau logiciel » ouvre un **atelier illustré en 4 étapes** (Idée, Fonctions, Effort, Lancement), comme l'établi du CPU : décor des locaux, écran du futur logiciel qui se construit (terminal vert avant 1991, fenêtres ensuite), Camille qui commente, barre en direct (4 notes, bugs, durée, coût). **Plus aucune liste déroulante, case à cocher ni compteur numérique** dans le Logiciel (vérifié par test).
- **Idée = type × public × plateforme.** 9 types (5 anciens + Jeux 1972, Création & multimédia 1984, Sécurité 1988, Internet & navigateurs 1994), 9 publics qui apparaissent avec l'époque (Familles en 1978, Écoles en 1981, Créatifs en 1984…), 3 plateformes (le CPU le plus répandu, vos processeurs, multi-plateforme dès 1979). Chaque combinaison type × public vaut de « mauvaise » à « excellente » ; on ne le sait qu'après la sortie.
- **Fonctions d'époque.** 21 fonctions datées (interface graphique 1981, réseau 1985, Internet 1994, cloud 2006, mobile 2008, assistant 2016…), chacune avec ses pastilles (notes ▲▼, durée, risque de bugs, « adoré par ce public », « nouveau », « attendu depuis »). Une fonction devient **attendue** (son absence est reprochée), puis **de série** huit ans plus tard (elle sort du choix). Le nombre de fonctions dépend de la maîtrise (3 à 5).
- **Effort en 3 phases** (Fondations, Fonctions, Finition) : 6 jetons par phase entre 3 domaines. Chaque type a ses domaines essentiels, cachés. Camille propose une répartition d'après ce que l'équipe sait. Les phases à venir restent réglables pendant le développement (hub et cockpit), pas celles déjà commencées. Rapport de Camille à la fin de chaque phase.
- **Note sur 10** : qualité vue par le public + combinaison + justesse de l'effort + fonctions attendues manquantes + fonctions nouvelles − bugs, comparée aux attentes de l'époque **et à votre meilleur logiciel du même type** (refaire la même chose ne suffit pas).
- **Carnet de Nora** : chaque sortie note la combinaison essayée et un domaine d'effort compris ; il s'affiche dans le studio (« ★★★ Excellente idée », « essentiel / utile / secondaire ») et dans le hub.
- **Hub Logiciel** en cartes illustrées ; projets avec leurs trois phases ; catalogue avec la note (qui vieillit), prix en trois boutons, correctif, suspension.

### Étape 2 — jour J et versions
- À la sortie, **trois journaux de l'époque** testent le logiciel (chacun son angle : mesures, stabilité, prix, prise en main) ; l'écran de révélation des CPU s'ouvre avec la leçon du carnet de Nora. La moyenne des journaux = la note officielle. Records comparés logiciel contre logiciel. Alerte « Premier mois : X licences, Y € ».
- **Versions 2 et 3** (bouton « Version N » après six mois de vente) : les fonctions déjà écrites sont reprises (30 % du travail et des bugs), socle 30 % plus rapide, projet 20 % moins cher ; au moins une nouveauté obligatoire. Après la version 3, la vieille base ajoute 3 bugs par version. À la sortie, l'ancienne version quitte le catalogue et 15 % de ses clients achètent la mise à niveau à moitié prix.

### Étape 3 — synergie CPU
- Sur « Vos processeurs » : performances +6, coût ×0,9, un bug de moins ; portée = part de vos CPU par rapport au leader (palmarès des ventes, de 20 à 100 %).
- Un logiciel bien noté sur vos processeurs **augmente la demande de vos CPU** : OS ×1, serveurs ×0,6, outils ×0,5, jeux ×0,4, autres ×0,25 ; jusqu'à **+15 %** au total, selon la note qui vieillit. Affiché dans le hub (carte « Écosystème de vos processeurs ») et dans « Pourquoi ces ventes » des CPU.

## Fichiers
- Nouveau : `scripts/SoftwareStudio.gd` (données et formules pures), `ui/components/SoftwareStudioPanel.gd` (studio), `tests/scenarios/SoftwareStudioScenario.gd`, outils `tests/tools/capture_logiciel.*`, `studio_probe.*`, `run_scenario.*`.
- Modifiés : `scripts/SoftwareManager.gd` (projets STUDIO, sortie, presse, suites, carnet, ventes, écosystème), `scripts/SoftwareCatalog.gd` (4 types), `scripts/SaveManager.gd` (v35 + migration), `scripts/MarketManager.gd` (multiplicateur d'écosystème sur la demande CPU du joueur), `scripts/ReviewExplainer.gd`, `scripts/ProjectPresentation.gd`, `ui/SoftwareWorkshop.gd` (hub réécrit), `ui/ProjectCockpit.gd`, `ui/components/ReviewRevealPanel.gd`, tests `software_choice_preview_test.gd` (réécrit), `NewPlayerEntryScenario.gd`, `smoke_test.gd`.
- Anciennes parties : sauvegarde v35, carnet vide ajouté par migration ; les anciens logiciels (utilitaires « tranche jouable » et produits à réglages) continuent de se vendre comme avant.

## Tests réellement exécutés (PC, Godot 4.7.2)
- `godot --headless --path . --import` : OK.
- `godot --headless --path . res://tests/smoke_test.tscn` : **Smoke test passed**, dont « Logiciel 2.0 : combinaisons, fonctions d'époque, phases, carnet de Nora OK » et Lot 0 Software.
- 38 scènes `tests/*.tscn` : 34 OK en headless ; `r1_visual_test` et `r2_visual_test` OK sous xvfb (rendu requis) ; **`complete_layout_test` et `project_brief_world_test` échouent déjà sur c3f9046** (avant ce lot) : ils cherchent `GarageHub._new_project_action` et un marqueur `project_marker` supprimés lors d'une refonte antérieure. Ils restaient « à 0 » car leur code de sortie est 0 malgré les erreurs. À réparer pendant la revue des onglets.
- Sonde 24 carrières (graines 104729, 208877, 313133, 417401 ; STANDARD et ACCESSIBLE) : résultats identiques à RANK-01 (Standard : ADAPTÉE en faillite, EN_RETARD 20 à 29 M€ ; Accessible : ADAPTÉE 283 à 320 M€, EN_RETARD 133 à 151 M€). La sonde ne fait pas de logiciel : elle vérifie seulement que le CPU n'a pas bougé.
- Sonde économique du studio (`studio_probe`, bonne et mauvaise idée par type, 24 mois) : bonne idée = marge 1,1 à 5,5 fois le coût de développement (hors salaires) ; mauvaise idée = perte.

## Limites et points à vérifier
- **Non testé sur le Pixel.** À vérifier au doigt : lisibilité des pastilles, jetons ±, défilement du studio.
- Équilibrage à confirmer en jouant : les logiciels professionnels (BUSINESS) restent très rentables (hérité de l'ancien marché) ; la sécurité l'est peu.
- La note vieillit vite (un utilitaire perd ~0,9 point par an) : voulu pour pousser aux versions 2 et 3, à confirmer.
- Le cockpit renvoie vers l'atelier pour régler l'effort (pas de réglage direct dans le cockpit).
- L'onglet Presse range les tests de logiciels avec ceux des CPU (même pile) : à séparer pendant la revue des onglets.
