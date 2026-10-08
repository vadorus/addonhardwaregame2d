# Reprise pour Codex — 07/10/2026 au soir

Ce document permet de reprendre le travail de Claude sur la branche `v013/demo-octobre`, là où il s'est arrêté.
Lis-le après `AGENTS.md`, qui reste la règle prioritaire.

Objectif du mois : **la démo pour testeurs fermés, fin octobre**. Seule la branche **CPU** est concernée.

### Les autres documents à lire (le jeu dans son ensemble)

| Sujet | Document |
|---|---|
| Vision et concept | `docs/VISION.md` |
| Game design | `docs/GAME_DESIGN.md` |
| Bible de conception | `docs/DESIGN_BIBLE.md` |
| Périmètre jouable CPU | `docs/CPU_VERTICAL_SLICE.md` |
| Philosophie de simulation | `docs/SIMULATION_PHILOSOPHY.md` |
| Direction artistique et UX | `docs/UX_ART_DIRECTION.md` |
| Briefs graphiques (Astra) | `docs/BRIEF_ASTRA_*.md` |
| Feuilles de route | `docs/ROADMAP_V010.md`, `docs/PLAN_V09_V10.md` |
| Économie | `docs/V06_PLAYTEST_ECONOMY.md` |
| Conception détaillée (projets, recherche, lisibilité, référence Device Tycoon) | `docs/design/*.md` |
| Construire PC et Android | `docs/BUILD_PC_ANDROID.md` |
| Version Play Store, clé de publication, état de la console | `docs/PUBLICATION_PLAY_STORE.md` |

---

## 1. Démarrer

```bash
git fetch origin && git checkout v013/demo-octobre && git pull
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . res://tests/smoke_test.tscn    # doit finir par « [CI] Smoke test passed »
```

**Dernier commit de code avant ce document :** `252b3bf` (Équipe).

Ce commit ajoute aussi les maquettes dans `docs/design/maquettes_canvas/` ; elles sont décrites au §4.

### Outils de vérification utiles

**Capture rendue des onglets.** Sous Linux, il faut un écran virtuel. Sous Windows, la même commande fonctionne sans `xvfb-run`.

```bash
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  res://tests/tools/feel_capture.tscn -- --moment=onglets --months=84
```

- Sans `--save`, l'outil joue une partie automatiquement pendant N mois, puis capture chaque onglet et chaque sous-page.
- `--save=<chemin>` capture une sauvegarde réelle à la place.
- Les captures arrivent dans le dossier utilisateur de test (le chemin est affiché en sortie).

**Sonde économique sur 30 ans** (argent, gravure atteinte, architectures, meilleur rival) :

```bash
godot --headless --path . res://tests/tools/demo_economy_probe.tscn -- --tech
```

- `--tech` ne lance que le profil DEFAUT.
- Valeurs de référence pour un bot passif : 8 µm en 1974, 6 µm en 1979, 3 µm en 1985.

---

## 2. Ce qui a été fait le 07/10

| Commit | Sujet |
|---|---|
| `82d77c9` | **Musiques de saison** : Halloween et fêtes de fin d'année. 3 morceaux CC0 chacun plus une boucle de menu, intercalés avec la musique de la décennie. |
| `cecb41a`, `3beb405`, `dd3bb09` | Outil de capture des onglets (`feel_capture.gd`, moment `onglets`) sur une vraie partie. |
| `acf9c77` | **Noms du personnel** : plus aucun candidat « Nora » (elle est l'assistante), pas de doublons, chercheurs spécialisés CPU. |
| `eb402c1`, `f255107` | Sonde : progrès technologique par année et frontière des rivaux. |
| `5846322` | **Diffusion du savoir** : sans recherche, la gravure suit l'état de l'art avec du retard. Auparavant, le joueur restait bloqué à 10 µm pendant 16 ans. |
| `4a0f665`, `c6883fd` | **Labo** refait d'après la planche 5. |
| `c69bad3`, `5b77e93` | Fichiers `.uid`. |
| `ac70db7`, `5b77e93`, `dd3bb09` | **Presse** dans l'esprit du « Jour J » : salle de presse avec Nora, courbe des notes, une pile de coupures par CPU. |
| `252b3bf` | **Équipe** : scène où Nora fait le point, visage sur chaque fiche, en-tête de scène commun (`SceneHeader`). |

### Nouvelles API à connaître

**`ui/components/SceneHeader.gd`** : la règle commune décidée lors de la revue des onglets.

- Chaque onglet s'ouvre sur une scène : un décor voilé, un personnage qui dit une phrase, et à droite le chiffre du moment avec un bouton.
- API :
  - `set_scene(art, kicker)`, `set_speaker(portrait)`, `set_line(text)`
  - `set_hero(value, caption, button_text, color)`
  - signal `hero_pressed`
  - `line_text()`, `hero_button_text()` pour les tests
- Pour l'instant, seul **Équipe** (`PersonnelScreen`) l'utilise.

**`ui/components/LabBoard.gd`** : planche 5, hébergé dans `LabScreen`, page « Le labo ».

- Scène avec Camille et un panneau héros.
- Frise « Nos architectures » : les 3 dernières possédées, la suivante avec un anneau de progression, puis une carte en pointillés.
- 3 équipes de recherche avec visages.
- Colonne latérale : gravure et carnet des trouvailles.
- Communique par `signal board_action(action: Dictionary)`. Types d'action : `OPEN_STEPPER`, `SHOW_PROJECTS`, `SHOW_RESEARCH`, `OPEN_COCKPIT`, `PROJECT_DECISION`, `CONCEPT`, `MESSAGE`. `LabScreen._on_board_action` les traite.
- `OPEN_COCKPIT` remonte jusqu'à `main.gd` (`_on_lab_action` → `_open_project_cockpit`).

**`ui/components/PressBoard.gd`** : hébergé dans `MediaScreen`, page « Tests de vos CPU ».

- `static products_with_reviews(news)` regroupe les critiques par produit : les plus récents d'abord, la meilleure critique d'abord.
- Classe interne `Curve2DView` : courbe des notes sur une échelle resserrée.

**`ui/WorkplaceArt.gd`** : les visages.

- `CAST` fixe les personnages nommés : Camille Durand = 2, Samira Lefèvre = 7, Noah Leroy = 8. Nora utilise le look 4 (`NORA_LOOK`).
- `cast_look(name)`.
- `assign_looks(staff) -> {id: look}` : le casting d'abord, puis un hachage stable sans doublon.
- `face_avatar(look, diameter, ring_color)` : médaillon circulaire découpé dans la pose « joie ».

**`scripts/ResearchManager.gd`** : `_process_knowledge_diffusion()`, appelé chaque mois.

- Concerne MINIATURIZATION, LAYOUT et ARCHITECTURE.
- Un plancher à 80 % de la frontière de l'industrie, rattrapé à 5 % par mois.
- Tire aussi la gravure (`technologies.manufacturing`) et publie la nouvelle « La gravure … est à notre portée ».

**`scripts/SoundManager.gd`** : `music_key(base, theme)` renvoie `"menu+HALLOWEEN"` et `music_tracks()` intercale les morceaux.

- Si un fichier manque, le jeu retombe sur la musique de la décennie.
- Script de construction des pistes : `tools/audio/build_seasonal.py`. Crédits : `assets/audio/CREDITS.md`.

**`scripts/PersonnelManager.gd`** : `_unique_candidate_name()`.

- Migration dans `load_state` : `_rename_assistant_namesakes()` renomme les « Nora X » des anciennes sauvegardes.

### Nouveaux tests, branchés dans `smoke_test.gd`

- `StaffNamesScenario`
- `KnowledgeDiffusionScenario`
- `LabBoardScenario`
- `PressBoardScenario`
- `LiveThemeScenario`, adapté à la musique de saison

> ⚠️ La CI refuse **toute ligne `ERROR:`** dans les logs des tests de mise en page. Par exemple, `vertical = true` sur un `HBoxContainer` en produit une : utilisez `BoxContainer`.
> ⚠️ Un scénario qui rencontre une **erreur d'exécution** GDScript s'interrompt et renvoie `""`, ce qui est lu comme un succès.
> Après chaque modification, lis aussi la sortie du smoke test (`SCRIPT ERROR`), pas seulement la dernière ligne.

---

## 2 bis. Ce qui a été fait le 08/10

**Planche 4 « La fabrication »** : le prototype validé face au marché, le choix du fondeur et la gamme qui sortira, en une vue.

- `scripts/ProductionPreview.gd` (modèle pur, sans hasard ni effet sur l'état) :
  - `foundry_options(job)` : les fondeurs possibles, chacun avec son aperçu et deux mots (« Rapide », « Pas cher », « Soigné », « Risqué »…) ;
  - `build(job, provider, binning)` : 5 lignes de comparaison (vitesse, sobriété, fiabilité, prix, marge) contre l'ancien modèle de la maison et le meilleur rival du segment, rang au banc d'essai, puces bonnes par plaquette, répartition E / standard / X, délai, coût engagé, phrase de Noah.
- `ProductionManager` :
  - le calcul de fin d'industrialisation est extrait dans `_industrialization_result(..., jitter)` (même ordre d'appels au hasard qu'avant) ;
  - `_monthly_progress()` est partagé ;
  - nouveau `preview_industrialization(job_id, provider, strategy, binning)`.
- `ProductManager.preview_cpu_range(project, industrialization)` : la gamme qu'on obtiendrait, sans rien créer.
- `ui/components/ProductionBoard.gd` :
  - la planche elle-même, avec le signal `launch_requested(payload)` (même charge utile que `apply_industrialization`) ;
  - utilisée dans le **parcours CPU** (`CpuJourney._build_production`, qui remplace la liste déroulante et les 4 stratégies) et dans **Produits > Fabriquer**.
- **Produits** : un `SceneHeader` avec Noah et `products_diagnosis()` (usine à choisir / préparation / prix à fixer / ventes du mois).
- `IndustrializationPanel.hide_waiting` : la carte « choix à faire » n'est plus en double sous la planche. Elle reste disponible quand le panneau est utilisé seul, ce dont dépend `FabricationPageScenario`.
- **Tests** :
  - `ProductionBoardScenario` est branché dans le smoke test ;
  - `workshop_layout_test` presse désormais « Lancer la fabrication » (toujours visible sans défiler en 1616×720).
- **Limite connue** : le délai affiché ne compte pas les retards aléatoires des fondeurs, qui restent une surprise possible.

**Planche 6 « La finition »**, juste avant le lancement dans le parcours CPU.

- `scripts/CpuFinish.gd` : trois pistes (Sobre et pro, Vitrine, Économique), 4 couleurs, 3 logos et un dessin caché.
  - Les effets sont modestes et lisibles :
    - **Vitrine** : la puce coûte environ 6 % de plus, la presse donne +2 ;
    - **Économique** : la puce coûte environ 8 % de moins, sobriété −1 et fiabilité −1 ;
    - **dessin caché** : presse +1.
  - La couleur et le logo sont purement esthétiques.
- `ProductManager.apply_cpu_finish(generation_id, finish)` pose la finition une seule fois, sur toutes les puces prêtes de la génération ; `generation_needs_finish()` dit s'il en reste à habiller.
  - Champs ajoutés aux produits : `finish`, `finish_press`.
  - **Anciennes sauvegardes** : une puce déjà lancée sans `finish` compte comme « sobre », sans effet. Une puce prête sans `finish` passe par la finition dans le parcours CPU. Aucune migration n'est nécessaire.
- `MediaManager.review_breakdown` ajoute le facteur « finish », libellé « Finition du boîtier » dans `ReviewExplainer`.
- `ui/components/FinishingBoard.gd` : le boîtier dessiné (pattes, encoche, capot doré, logo, inscriptions), la puce au microscope, les pistes de Camille, les retouches, l'effet en clair et « Valider la finition ».
  - Dans le parcours CPU, l'étape « Lancer » commence par la finition.
  - `main.gd` traite l'action `apply_finish`.
- **Tests** :
  - `FinishingScenario` (smoke) couvre les effets, l'application unique, la sauvegarde et la presse ;
  - `workshop_layout_test` passe par « Valider la finition », dont le bouton est visible sans défiler en 1616×720.
- **Volontairement laissé de côté** : renommer la gamme à la finition (« Nova / Astra / Orion », « 2 / 200 / II » sur la planche). C'est à faire avec la tâche « noms de projets uniques ».
- **Point de vigilance** : depuis Produits > Vendre, on peut encore lancer sans passer par la finition (puce « sobre »).

**Planche 8 « La voix du monde »**, en tête de l'onglet Marché.

- `scripts/MarketVoices.gd` est en lecture pure (testé). Il lit les vrais calculs du jeu :
  - `focus_product()` : le dernier CPU lancé ;
  - `gaps()` : ventes et part de marché face à la prévision du lancement, note de presse face à la génération précédente ;
  - `value_read()` : zone « Trop cher / Juste / Bonne affaire », sur le même rapport prix / référence que `price_demand_multiplier` ;
  - prix conseillé, avec ventes et contribution estimées par `forecast_cpu_launch`. Il ne conseille **pas** de baisser quand on vend déjà toute la capacité ;
  - `voices()` : le public, les concurrents, les pros (banc d'essai), la presse (les vrais tests du jour J).
- `ui/components/MarketBoard.gd` : la planche. Le bouton « Baisser à X € » émet `update_price`, que `main._on_market_action` relaie vers l'action produit existante.
- Marché : un `SceneHeader` (Nora), dont la phrase vient de `MarketVoices.headline()`.
- **Test** : `MarketVoicesScenario` (smoke).
- **Limite** : les cartes « public » sont des archétypes (revendeur, fabricant client, club, ingénieur) dont le texte dépend des chiffres. Ce ne sont pas encore des clients persistants.

**Planche 7 « La carte de l'entreprise »**, en tête de l'onglet Entreprise.

- `scripts/CompanyBranches.gd` décrit les branches :
  - **jouables** : CPU (le tronc), qui ouvre le labo, et Logiciel, qui ouvre le coin logiciel ;
  - **« Version complète »** : Défense en 1980, Aérospatial en 1990 ;
  - **« Extension à venir »** : Mobile, Consoles, Cartes mères, Serveurs ;
  - **aucune mécanique** n'est ajoutée hors CPU (`AGENTS.md`). Ce sont les emplacements des futurs DLC payants.
- `ui/components/BranchMap.gd` : l'arbre est dessiné (tronc et branches), un bouton par nœud, et une fiche à droite (statut, texte, points, phrase, bouton).
  - `CompanyScreen` gagne le signal `navigate_requested`, branché sur `_on_dashboard_navigation`, une scène de Nora (âge, CPU en vente, rang mondial) et `set_viewport_width`.
- **Test** : `CompanyBranchesScenario` (smoke).

**Revue des événements (après-midi du 08/10)** : chaque choix fait ce qu'il annonce.

- **SAV** (`AfterSalesManager`) : « Surveiller » n'efface plus un diagnostic payé ; un dossier grave laissé ouvert pèse sur la réputation ; un dossier surveillé et calme se referme après 6 mois (`CALM_MONTHS_TO_CLOSE`).
- **Validation finale** (`DevelopmentGates`) : deux reprises au plus (`MAX_VALIDATION_RECHECKS`), ensuite seul « Valider » est proposé.
- **Revue prototype** : l'effet annoncé (`prototype_impact`) est exactement celui appliqué, dans `cockpit_directive_impact`.
- **Phase 4 du CPU** (`CpuPrototypeModel.milestone`) : elle ne recopie plus les boutons de la phase 2 ; elle garde ses choix (dernier effort performance, polir l'efficacité sans surcoût, fiabiliser +1 mois).
- **Menace marché** (`MarketManager`) : ignorer ne débite plus d'argent ; on affiche une estimation des ventes perdues et la réputation pro baisse. Pas de nouvel entrant si Nexus ne peut pas être ajouté.
- **Trouvailles** (`ResearchManager`, `WorkshopDiscoveries`) : une idée en suspens à la fin d'un CPU passe au carnet au lieu de bloquer ; poursuivre une piste ralentit les autres (×0,9).
- **RH** (`ExecutiveManager`, `PersonnelManager`) : un dossier traité ne revient pas avant 3 mois ; la prime collective agit sur la cohésion ; la cohésion baisse si le moral moyen est sous 50.
- **Test** : `EventsAuditScenario` (smoke). Restent à traiter : contrat d'étude ouvert seulement après le premier lancement, pénalités B2B non annoncées, capacité −28 % du rappel non affichée, arbitrages ACK_ONLY à choix identiques, salon à 250 k€ en 1985.

**Conception Software** : l'audit et le plan (lots 0 à 8) sont dans un Claude Doc partagé avec Alexandre, « Tech Empire — Branche Software : audit, architecture et plan ». Seul le lot 0 (correctifs) passe avant la démo.



## 3. Où en est la revue des onglets

**Décision d'Alexandre (07/10, 17 h 05).** Les planches de maquettes du midi sont plus proches de la cible que les onglets actuels. Il faut **refaire les onglets d'après les planches**, pas les retoucher par petits bouts.

| Onglet | État | Planche |
|---|---|---|
| Labo | ✅ refait. Validé sur le Pixel par Alexandre. | 5 |
| Presse | ✅ refait. Pas encore vu sur le Pixel : l'APK du Pixel date d'avant. | 3 |
| Équipe | ✅ refait, capture relue le 08/10. Pas encore vu sur le Pixel. | (règle commune) |
| Produits / parcours CPU | ✅ planches 4 et 6 faites (08/10) : scène de Noah, `ProductionBoard` (fabrication), `FinishingBoard` (finition avant le jour J). | 4 Fabrication, 6 Finition |
| Marché | ✅ planche 8 faite (08/10) : scène de Nora + `MarketBoard` (espéré/obtenu, vaut-il son prix, quatre voix). | 8 Voix du monde |
| Entreprise | ✅ planche 7 faite (08/10) : scène de Nora + `BranchMap`. Les sous-pages restent à simplifier. | 7 Carte des branches |
| Tableau de bord / atelier | déjà proche des planches 1 et 2 | 1, 2 |

---

## 4. Les maquettes (`docs/design/maquettes_canvas/`)

- Il y a 8 planches de 1280×580, en HTML avec des gabarits `{{…}}`. La disposition est dans `canvas.json`.
- Elles s'ouvrent dans un navigateur.
- Les images pointent vers `../../../assets/...`.
- La plupart des correspondances sont exactes : portraits `perso_0X_*` et icônes `J4_icones/zone_*`.
- Cinq images ont été **devinées** :
  - le garage (`decor_0_garage`)
  - `moment_presse`
  - la puce `_sources/astra_suite_puce_1993.png`
  - `trophee_or`
  - `moment_premier_cpu`

| # | Fichier | Contenu attendu en jeu |
|---|---|---|
| 1 | `Main.dc.html` | **L'établi : concevoir.** Camille propose, le joueur choisit les pièces de la puce sur l'établi. |
| 2 | `Atelier.dc.html` | **L'atelier vit : développer.** Le garage s'anime pendant le projet et l'équipe est visible à son poste. |
| 3 | `JourJ.dc.html` | **Le jour J : la presse.** La révélation des notes. Il a servi de modèle à l'onglet Presse. |
| 4 | `Production.dc.html` | **La fabrication.** « Le prototype est validé : place à l'usine ». Voir le détail ci-dessous. |
| 5 | `Recherche.dc.html` | **Le labo.** Fait (`LabBoard`). |
| 6 | `Finition.dc.html` | **La finition : le design du CPU.** Voir le détail ci-dessous. |
| 7 | `Branches.dc.html` | **La carte de l'entreprise.** « Le tronc, c'est le CPU. Les branches poussent avec les époques. » Voir le détail ci-dessous. |
| 8 | `VoixDuMonde.dc.html` | **La voix du monde : après la sortie.** Voir le détail ci-dessous. |

**Planche 4, La fabrication** :

- Le stock.
- Le nouveau CPU face au marché : l'ancien modèle, le rival, des écarts chiffrés et un verdict.
- « Qui grave nos puces ? » : le choix du fondeur.
- Les puces bonnes par plaquette (rendement).
- La répartition des trois versions E / standard / X, en % et en prix.
- Le bouton « Lancer la fabrication ».

**Planche 6, La finition** :

- Le boîtier, avec son nom, son numéro et le matériau.
- « La puce au microscope ».
- « Les trois pistes de Camille ».
- Les retouches : couleur, nom de gamme, numéro, logo gravé, dessin caché.
- Le bouton « Valider la finition », puis le passage au jour J.

**Planche 7, La carte de l'entreprise** :

- Des nœuds à toucher, avec trois statuts : « Jouable », « Version complète » et « Extension à venir ».
- C'est ici que se brancheront les futurs DLC payants (voir le §6).

**Planche 8, La voix du monde** :

- « Espéré, obtenu » : les objectifs comparés aux résultats.
- Une jauge **« Vaut-il son prix ? »** : Trop cher / Juste / Bonne affaire, avec le conseil de Nora et une baisse de prix proposée.
- Des citations de clients avec leur effet.

---

## 5. Prochaines tâches, dans l'ordre

Pour chaque tâche : un test déterministe dans `tests/`, le smoke test au vert, et une capture rendue relue.

> **Pour Codex, à partir du 08/10 au soir : suivre `docs/PLAN_CODEX_2026-10-08.md`** (liste unique et ordonnée). Les tableaux ci-dessous détaillent chaque étape.

### Plan complet jusqu'à la démo de fin octobre (décidé le 08/10, 14 h)

Le plan réunit la refonte d'interface (planches 1 à 8), la revue des événements et la conception Software (Claude Doc « Tech Empire — Branche Software : audit, architecture et plan »).

| Ordre | Bloc | Contenu | Pourquoi maintenant |
|---|---|---|---|
| 1 | **Software, lot 0** | Support calculé sur le prix réel ; approches de contrat équilibrées ; libellés « ~-1 mois » et « Compat./perf. » ; pas de public « particuliers » avant 1977 ; **firmware plafonné par génération** ; `software_choice_preview_test` réparé | Un testeur peut empiler le firmware à l'infini ou gagner sans réfléchir en Premium |
| 2 | **Événements restants** | Contrat d'étude ouvert avant le premier lancement ; pénalités B2B annoncées ; capacité du rappel affichée ; arbitrages à choix identiques ; coût des salons selon l'époque | Chaque choix doit faire ce qu'il annonce |
| 3 | **Entreprise au garage** | Masquer Divisions, Groupe et délégation tant que l'entreprise est un garage | Un débutant ne doit pas voir des pages vides |
| 4 | **Élasticité des prix** | La demande réagit au prix de façon lisible, cohérente avec « Vaut-il son prix ? » | L'économie est jugée trop facile |
| 5 | **Labo et Presse sur `SceneHeader`** | Code des scènes unifié | Entretien, aucun effet visible |
| 6 | **Livraison démo** | APK sur le Pixel (avec sauvegarde d'abord) ; AAB signé ; piste de test fermé avec la liste des testeurs | Attend Alexandre pour l'envoi et les adresses |
| Après la démo | Software lots 1 à 8 ; gamme vieillissante / refresh (à cadrer avec Alexandre) ; renommer les doublons de noms des anciennes sauvegardes | Nouvelles mécaniques, pas avant la validation de la tranche CPU |

**Lot 0 Software fait le 08/10 (Claude)** :
- support logiciel sur le prix payé (`SoftwareCatalog.support_monthly_cost`, 3e paramètre) ;
- serveurs : prix 220 €, support 5 % ;
- approches de contrat « Rapide » (coût ×1,10, paiement ×0,75) et « Soigné » (paiement ×1,10, XP ×1,6) ;
- public « Passionnés et universités » avant 1977 ;
- « aucun développeur affecté » au lieu de « ~-1 mois », « Performances » au lieu de « Compat./perf. » ;
- firmware plafonné par produit (`FIRMWARE_GAIN_CAPS`, `firmware_effect`, migration `_firmware_gain_from_history`), logiciel de contrôle limité à la v3 ;
- `software_choice_preview_test` réécrit pour l'interface actuelle ;
- test `SoftwareLotZeroScenario` (smoke).

**Pour Codex, à partir du point 2** : un commit par point, un test déterministe chaque fois, le smoke test et les quatre tests de la CI au vert. Claude relit chaque commit avant que l'APK parte sur le Pixel.

**Points 2 à 5 faits par Codex (08/10, `9eb7fd0` → `7901b64`, détail dans `RETOUR_CODEX_2026-10-08_POINTS_2_5.md`).** Relecture de Claude le 08/10 à 17 h : code relu, aucune anomalie bloquante. Relancés sous Linux et réussis : import, démarrage, smoke, branding, les trois tests de mise en page et d'équilibrage de la CI, parcours CPU, carrières interactives, prototype, aperçu logiciel, finances, expérience complète, sauvegarde. Captures Entreprise, Marché et Presse relues. Reste le point 6 (APK, puis test fermé).

### Plan de correction performance et architecture (décidé le 08/10, 18 h)

Source : `docs/AUDIT_ARCHITECTURE_2026-10-08.md`. Mesures sur une partie de 7 ans (15 CPU en vente) ; sur le Pixel, compter 2 à 4 fois plus lent.

Règles pour chaque étape :
- un commit par étape ;
- un test déterministe ;
- smoke, branding et les trois tests de mise en page et d'équilibrage de la CI au vert ;
- `tests/screen_refresh_test.tscn` au vert dès que l'interface change ;
- la mesure avant/après notée dans le message de commit ;
- aucun changement de rendu non voulu (captures avant/après relues) ;
- aucun nouveau champ de sauvegarde sans migration.

| Étape | Quand | Contenu | Fichiers | Critère de réussite | Test |
|---|---|---|---|---|---|
| **C1** ✅ | Fait (`ff149a0`) | Onglets cachés marqués « en retard » et reconstruits à leur affichage ; signaux d'une même image regroupés ; `Portrait` immobile quand il est caché | `main.gd`, `ui/Portrait.gd` | Fin de mois 984 → 59 ms ; `_refresh_all` 561 → 25 ms | `screen_refresh_test` |
| **C2** | Avant la démo | **Animations économes.** Les `_process` qui appellent `queue_redraw()` à chaque image (`CrewMember`, `CpuBench`, `ProjectVisual`, `ComponentArt`, `GarageLife`, `LiveThemeOverlay`) passent par un battement partagé à environ 20 Hz et s'arrêtent quand le nœud est caché. `OS.low_processor_usage_mode` est activé quand le temps est en pause ou qu'un menu couvre l'écran, et désactivé à la reprise. | nouveau `ui/AnimationClock.gd` (autoload léger ou statique), nœuds cités | Rendu identique à l'œil ; moins de redessins par seconde au QG en pause (compteur dans le test) | `AnimationClockScenario` : un nœud caché ne redessine pas, la pause active le mode basse consommation, la reprise le coupe |
| **C3** | Avant la démo | **Plus de vérification à chaque image.** `main._process` ne recherche plus une décision bloquante à chaque image : la recherche passe sur le changement de jour de `TimeManager` et sur les signaux de décision. La date et la réputation de l'en-tête ne sont reformatées que si elles changent. | `main.gd`, `scripts/TimeManager.gd` (signal de jour s'il manque) | Une décision bloque toujours le temps le jour même ; plus aucune copie profonde par image | Scénario : une directive en attente met le temps en pause au jour suivant ; la date affichée reste juste |
| **C4** | Avant la démo si le Pixel saccade, sinon juste après | **Réutiliser les lignes au lieu de tout recréer** dans `CompanyScreen`, puis `ProductsScreen`. Un `RowPool` réutilisable (`acquire()`, `release_all()`, lignes masquées puis réaffichées) ; on ne met à jour que textes, valeurs et couleurs. | nouveau `ui/components/RowPool.gd`, `ui/screens/CompanyScreen.gd`, `ui/screens/ProductsScreen.gd` | `refresh()` d'Entreprise 145 → moins de 30 ms et de Produits 77 → moins de 20 ms (PC) ; nombre de nœuds stable après 20 rafraîchissements | `RowPoolScenario` + temps et nœuds stables dans `screen_refresh_test` |
| **C5** | Après la démo | **Lecture sans copie.** Recenser les `duplicate(true)` des accesseurs appelés par l'interface (248 dans `scripts/`). Garder la copie seulement quand l'appelant modifie ; sinon, accesseur `*_view()` en lecture seule, documenté. | `scripts/*Manager.gd` | Aucun comportement changé ; moins d'allocations par fin de mois | Tests existants + vérification qu'un écran ne modifie pas l'état (comparaison `get_state()` avant/après rafraîchissement) |
| **C6** | Après la démo | **Découper `main.gd`** (4 000 lignes). Un contrôleur par onglet (`ui/controllers/LabController.gd`, `ProductsController.gd`, `MarketController.gd`…) reçoit les actions de son écran et ses rafraîchissements ; `main.gd` ne garde que la coquille, la navigation et les fenêtres. Une étape par onglet, sans changer le rendu. | `main.gd`, nouveaux `ui/controllers/` | `main.gd` sous 2 000 lignes ; aucun test cassé | Tests existants à chaque étape |
| **C7** | Avant Steam | **Entrées unifiées** (détaillé dans le plan tactile et manette ci-dessous, étapes T4 et T5). Un `InputRouter` unique : tactile et souris traduits au même endroit, actions `ui_*` et focus pour la manette et le Steam Deck. On retire les tests faits à la main dans `NotificationFeed`, `GarageHub`, `CrewMember` et `main`. | nouveau `ui/InputRouter.gd`, fichiers cités | On peut jouer une partie au clavier ou à la manette ; le tactile est inchangé sur le Pixel | `InputRouterScenario` (évènements simulés tactile, souris et manette) |
| **C8** | Quand l'état grossira (plusieurs divisions) | **Sauvegarde en arrière-plan.** Copie de l'état sur le fil principal, puis `JSON.stringify` et écriture atomique par `WorkerThreadPool` ; pas de deuxième sauvegarde tant que la première n'est pas finie. | `scripts/SaveManager.gd` | Sauvegarde identique octet par octet à la version actuelle ; aucun gel visible | Test d'intégrité : sauvegarder, recharger, comparer |
| **C9** | Au fil de l'eau | **Anciens tests en échec hors CI** : `complete_layout_test`, `project_brief_world_test` (API d'interface disparues) ; `r1_visual_test`, `r2_visual_test` (rendu réel nécessaire). Les réécrire pour l'interface actuelle ou les retirer avec une note. | `tests/` | Plus aucun test du dossier en échec silencieux | — |
| **Mesure Pixel** | Avec le prochain APK | Profileur Godot en débogage à distance : temps d'image au QG, fin de mois à ×3, onglet Entreprise ouvert. Noter les chiffres ici. | — | Plus d'à-coup visible au QG en fin de mois | Humain (Alexandre + Claude) |

Ordre conseillé (performance) : C2 et C3 (petits, sans risque), puis la mesure Pixel avec l'APK.

### Plan de correction tactile, souris et manette (décidé le 08/10, 19 h)

**Constats mesurés le 08/10** (Pixel simulé en paysage 2400×1080, échelle mobile 1,15, environ 420 ppp, donc **1 px logique ≈ 0,104 mm**, 8 mm ≈ 77 px, 6 mm ≈ 58 px) :

| Constat | Mesure | Gravité |
|---|---|---|
| Zones tactiles trop petites | Sur les 7 onglets : **72 zones sous 6 mm, 54 entre 6 et 8 mm, 1 seule au-dessus de 8 mm**. Les plus petites : les onglets « Le public / Les pros / Les concurrents / La presse » du Marché (3,3 mm), les sous-onglets d'Entreprise, d'Équipe et de Presse (4,2 à 4,4 mm), les boutons de vitesse et le menu ☰ (4,6 mm) | Élevée |
| Double appui sur « Toucher encore pour confirmer » qui confirmait une action payante | Aucun délai minimal | ✅ corrigé (`8aba103`, 350 ms, retombe seul après 5 s, `ConfirmGuardScenario`) |
| Infobulles invisibles sur téléphone | 26 `tooltip_text` (dont la complexité et le risque de bugs des fonctions logicielles) | Moyenne |
| Aucune navigation clavier ou manette | 22 `focus_mode = FOCUS_NONE`, une seule action `InputMap` utilisée (`ui_cancel`), aucun raccourci (pas même Espace pour la pause) | Moyenne (Élevée avant Steam) |
| Tactile et souris testés à la main | 4 endroits : `NotificationFeed`, `GarageHub`, `CrewMember`, `main` (écran d'intro) | Faible |
| Aucun retour haptique | Pas de `Input.vibrate_handheld` | Faible |
| Zone morte du défilement à 4 px (≈ 0,4 mm) | Un léger glissement du doigt annule un appui sur un bouton placé dans une liste. Choix volontaire (`LabDepthScenario` l'impose) pour un défilement réactif | À trancher sur le Pixel |

**Hors sujet pour ce jeu** : joystick virtuel, *coyote time*, courbes d'accélération de visée. Tech Empire se joue au toucher sur des menus. Leurs équivalents utiles sont la tolérance d'appui, l'appui long, la protection contre le double appui et la vitesse de défilement à la manette ; ils sont repris ci-dessous.

**Architecture visée : une seule couche d'entrée**

`ui/InputRouter.gd` (autoload léger) :
- **Mode d'entrée courant** : `TOUCH`, `MOUSE_KEYBOARD` ou `GAMEPAD`. Il bascule au dernier évènement reçu (un toucher, une souris qui bouge ou une touche, un bouton ou un stick de manette) et émet le signal `mode_changed(mode)`.
  - L'interface s'adapte à ce signal : en manette, le focus est visible et le texte dit « Ⓐ Confirmer » ; au toucher, les zones sont agrandies ; en souris, les infobulles restent.
- **Actions nommées** dans l'`InputMap` : `ui_accept`, `ui_cancel`, les flèches et `ui_focus_next/prev` (déjà fournies par Godot), plus `te_pause`, `te_speed_up`, `te_speed_down`, `te_tab_next`, `te_tab_prev`, `te_menu`.
  - Clavier par défaut : Espace, `+`, `-`, Tab et Maj+Tab, Échap.
  - Manette par défaut : Start, gâchettes, LB/RB, Select.
  - Les écrans écoutent les **actions**, jamais les touches ou les boutons physiques.
- **Gestes tactiles** traduits à un seul endroit :
  - *appui* : relâché à moins de 12 px du point de départ (≈ 1,25 mm) et en moins de 450 ms ;
  - *appui long* : maintenu 450 ms sans bouger, il ouvre l'explication qu'une infobulle donnerait à la souris ;
  - *glissement* : au-delà du seuil, il est laissé au défilement.
- Les quatre traitements faits à la main sont remplacés par un appel au routeur, sans changer leur comportement.

**Étapes**

Mêmes règles que le plan performance : un commit par étape, un test déterministe, la CI au vert et des captures avant/après relues.

| Étape | Quand | Contenu | Critère de réussite | Test |
|---|---|---|---|---|
| **T1** ✅ | Fait (`8aba103`) | Protection des confirmations contre le double appui | Un double appui < 350 ms ne confirme pas ; une seconde touche volontaire confirme | `ConfirmGuardScenario` |
| **T2** | Avant la démo | **Zones tactiles d'au moins 6 mm partout, 8 mm pour les actions principales**, seulement sur téléphone (`OS.has_feature("mobile")`, ou un réglage « Grandes zones tactiles » sur PC). Une fonction `UI.touch_target(control, kind)` relève la hauteur minimale (secondaire 58 px, principale 77 px) et l'écart entre deux zones (8 px au moins). D'abord : sous-onglets (`ScenePager` ou équivalent), onglets du Marché, boutons de vitesse et ☰, puis « Lancer », « Valider » et « Confirmer ». | Plus aucune zone sous 6 mm dans les 7 onglets ; mises en page 1280×720 et 1600×720 sans débordement | `TouchTargetScenario` : le même balayage que la mesure ci-dessus, en échec sous 6 mm ; `garage_layout_test` et `workshop_layout_test` au vert |
| **T3** | Avant la démo | **Infobulles accessibles au toucher.** Un appui long (450 ms) sur un contrôle qui a un `tooltip_text` affiche ce texte dans une bulle, comme au survol. | Les 26 explications sont lisibles sur le Pixel | Scénario : appui long simulé, bulle visible avec le bon texte ; un appui court ne l'ouvre pas |
| **T4** | Après la démo | **`InputRouter` et actions nommées** (architecture ci-dessus). Raccourcis PC : Espace (pause), `+`/`-` (vitesse), Tab (onglet suivant), Échap (fermer). Les quatre traitements faits à la main passent par le routeur. | Pause, vitesse et onglets fonctionnent au clavier ; le tactile est inchangé | `InputRouterScenario` : évènements simulés tactile, souris, clavier et manette, bascule de mode, actions reçues |
| **T5** | Avant Steam | **Navigation à la manette et au Steam Deck.** Focus activé sur les contrôles interactifs (au lieu de `FOCUS_NONE`), ordre de focus logique par écran, focus visible, défilement des listes au stick (vitesse croissante tant qu'il est maintenu, zone morte de 0,2), Ⓐ et Ⓑ pour confirmer et annuler. | Une partie complète (créer la société, concevoir, fabriquer, lancer) se joue sans souris | Scénario : enchaînement d'actions `ui_*` simulées jusqu'au lancement d'un CPU |
| **T6** | Après la démo | **Retours haptiques** (option, active par défaut sur téléphone) : 15 ms sur une confirmation, 30 ms au jour J et au lancement, double impulsion courte sur une erreur. Demande la permission Android `VIBRATE` : mettre à jour `export_presets.cfg`, `PrivacyScenario` (qui vérifie aujourd'hui « aucune permission »), le texte de confidentialité et, si besoin, la fiche Play Console. | Vibrations ressenties sur le Pixel ; désactivables | Scénario : l'option coupée n'appelle jamais la vibration ; `PrivacyScenario` mis à jour |
| **T7** | Avec le prochain APK | **Zone morte du défilement** : essayer 4, 8 et 12 px sur le Pixel. Garder la plus petite valeur pour laquelle un appui sur un bouton d'une liste n'est jamais annulé. | Choix noté ici, puis `LabDepthScenario` ajusté | Humain sur le Pixel, puis test ajusté |

Ordre conseillé (entrées) : T2 et T3 avant la démo, juste après C2 et C3 ; T7 avec le prochain APK ; T4, T6 puis T5 après la démo.

### Plan de correction du rendu et des textures (décidé le 08/10, 19 h)

Source : `docs/AUDIT_RENDU_2026-10-08.md`.

Mesures sur 7 ans de partie, en 1600×720 avec OpenGL : **300 à 370 appels de rendu par image**, une surface dessinée de **7 à 10 fois l'écran**, **52 à 71 Mo de textures** non compressées en mémoire vidéo. Il n'y a aucun shader personnalisé ni aucune lumière ; le coût vient du remplissage et du nombre d'appels.

Règles : un commit par étape, des captures avant/après relues (et jugées par Alexandre pour tout ce qui touche à l'image), la mesure avant/après dans le message de commit, et la CI au vert.

| Étape | Quand | Contenu | Critère de réussite | Test |
|---|---|---|---|---|
| **R1** | Avant la démo | **Cadence plafonnée.** `application/run/max_fps` à 60 sur PC et 30 sur mobile, avec un réglage « Fluidité : 30 / 60 images/s » dans le menu, enregistré dans `user://settings.cfg`. À combiner avec le mode basse consommation de C2. | Le Pixel reste à 30 images/s ou plus, chauffe moins ; le réglage est conservé | Scénario : le réglage applique et conserve `Engine.max_fps` |
| **R2** | Avant la démo | **Compression des grandes images.** Décors, moments clés et bandeaux en *VRAM Compressed*, avec mipmaps et taille limitée à 2048 px. Portraits en VRAM Compressed, sans mipmaps. Icônes et pictogrammes en *Lossless*. Dans l'export Windows, garder S3TC/BPTC ; dans les deux exports Android, cocher ETC2/ASTC. | Mémoire des textures ≤ 30 Mo après avoir visité tous les onglets ; aucun défaut visible sur les captures jugées par Alexandre | `TextureBudgetScenario` : charge les écrans et vérifie `RENDER_TEXTURE_MEM_USED` ≤ 30 Mo ; contrôle des `.import` (mode attendu par dossier) |
| **R3** | Avant la démo si le Pixel saccade, sinon après | **Moins de surfaces empilées.** Supprimer les fonds pleins cachés sous d'autres fonds (cartes posées sur des cartes de même couleur, fond plein sous un décor opaque), passer les conteneurs purement structurels en `StyleBoxEmpty`, découper le bandeau de scène pour ne pas peindre deux fois sous le texte. | Recouvrement ≤ 4× au QG (cible finale 3×) | Le balayage de la mesure ci-dessus devient un scénario, en échec au-dessus du seuil |
| **R4** | Après la démo | **Moins d'appels de rendu.** Une palette fermée de `StyleBox` partagées (`UI.stylebox()` mis en cache par couleur, rayon et bordure au lieu d'en créer une par panneau) ; les petites icônes regroupées dans un atlas (`AtlasTexture`) ; les `_draw()` répétés (barres, jauges) regroupés en un seul nœud qui dessine toutes ses lignes. | ≤ 150 appels de rendu dans chaque onglet | Le scénario de R3 vérifie aussi `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` |
| **R5** | Après la démo | **Un seul pipeline.** `renderer/rendering_method="gl_compatibility"` aussi sur PC, pour que le PC, le Pixel et les tests aient le même rendu, avec moins de mémoire et un démarrage plus rapide. Garder la possibilité de revenir à Forward+ si une future branche en a besoin. | Captures PC identiques à l'œil ; démarrage plus rapide | Captures avant/après ; `--quit-after 2` sans erreur |
| **R6** | Après la démo | **Ombres et décors.** Ombres des panneaux pré-dessinées en 9-patch (ou supprimées sur mobile) ; une seule saison de décor chargée à la fois (libérer la précédente au changement de saison). | Mémoire stable au changement de saison ; rendu identique à l'œil | Scénario : changement de saison, mémoire des textures qui n'augmente pas |
| **Mesure Pixel** | Avec le prochain APK | Temps d'image au QG et dans l'onglet le plus chargé, chauffe et batterie sur 15 minutes, avant et après R1 et R2. Noter les chiffres ici. | — | Humain (Alexandre + Claude) |

Ordre conseillé (rendu) : R1 et R2 avec C2, C3, T2 et T3 avant la démo, puis la mesure Pixel ; on décide de R3 selon ce que montre le téléphone ; R4 à R6 après la démo.

### Plan de correction game design, économie et sensations (décidé le 08/10, 19 h 30)

Source : `docs/AUDIT_GAME_DESIGN_2026-10-08.md` (boucles en organigramme, modèle chiffré, liste de contrôle des sensations).

Constats de la sonde de carrière (4 graines, 1971 → 2030) :
- **Standard** : la stratégie adaptée fait **faillite en février 1973 sur 3 graines sur 4** ;
- **Accessible** : la même stratégie finit à **190–214 M€** ;
- **aucune partie n'atteint la 1re place** ;
- `balance_ceiling_test` ne contrôle que les 24 premiers mois.

Règles : un commit par étape, un test déterministe, la CI au vert, et la sonde de carrière relancée avec les résultats avant/après dans le message de commit.

| Étape | Quand | Contenu | Critère de réussite | Test |
|---|---|---|---|---|
| **G1** | Avant la démo | **Falaise de trésorerie (F1).** Comprendre pourquoi la stratégie adaptée meurt en 1973 en Standard (embauches, budget de R&D, paiements choisis), puis ajouter l'**alerte d'autonomie** : chaque embauche ou budget de R&D montre les mois de trésorerie *après* la décision ; orange sous 3 mois, rouge et confirmation sous 1 mois. Ajuster le coût de démarrage si l'automate n'est pas seul en cause. | En Standard, la stratégie adaptée passe 1976 sur au moins 5 graines sur 6 ; l'alerte apparaît avant toute faillite évitable | Scénario : une embauche qui ramène l'autonomie sous 3 mois affiche l'alerte ; la sonde de carrière confirme le critère |
| **G2** | Avant la démo | **Sensations du jour J et des records.** La pause de suspense de 600 ms avant les notes, les notes une à une, de petits confettis (au plus 120) au premier CPU, aux records de ventes et à la 1re place, et le décompte du résultat à la clôture du mois. Tout est coupé en animations réduites. | Alexandre juge le jour J plus fort sur le Pixel ; aucun effet en animations réduites | Scénario : en animations réduites, aucun nœud de particules n'est créé ; la séquence du jour J garde l'ordre des notes |
| **G3** | Après la démo | **Garde-fous de carrière dans la CI.** `career_probe` réduit à 2 graines × 2 difficultés, avec des seuils : Accessible ≤ 3× Standard à stratégie égale ; la stratégie adaptée en Standard vivante en 2000 sur au moins 1 graine sur 2 ; la stratégie figée qui décline après 2000 (voulu). | Seuils tenus | Nouveau test `career_guard_test` (court, nocturne si trop long pour chaque commit) |
| **G4** | Après la démo | **Puits proportionnels (F2).** Impôt sur les bénéfices de 25 % au-delà de 200 k€ par an (annoncé en décembre, prélevé en janvier) ; coût de développement × 1,25 par génération ; entretien des gammes de plus de 36 mois (0,5 % de leur chiffre d'affaires par mois). Nouveaux champs de sauvegarde avec migration. | Accessible adapté entre 30 et 300 M€ en 2030 ; Standard adapté entre 10 et 100 M€ | G3 + scénario de l'impôt (seuil, annonce, prélèvement) |
| **G5** | Après la démo | **Une 1re place atteignable (F3).** Les rivaux réagissent quand notre part dépasse 25 % (baisse de prix de 0,4 point par point au-dessus) ; le joueur adapté peut atteindre la 1re place vers 1985–1995 sur au moins 1 graine sur 2, puis doit se battre pour la garder. Objectif affiché par Nora (« 2e mondial : il manque 3 points de part de marché »). | Critère de rang tenu dans la sonde | G3 étendu au rang |
| **G6** | Après la démo | **Comprendre son déclin (F4).** Quand la gamme vieillit ou que l'architecture est dépassée, Nora l'annonce avec un chiffre (« notre meilleur CPU fait 72 % du leader ») et une piste : refresh, nouvelle architecture ou retrait. Lié au refresh de gamme à cadrer avec Alexandre. | Pas de baisse de chiffre d'affaires de plus de 2 ans sans explication | Scénario : une gamme sous 80 % du leader déclenche l'annonce |
| **G7** | Après la démo | **Moins d'attente (F6).** Pendant le développement, une petite décision optionnelle tous les 2 à 3 mois (trouvaille, échantillon client, presse), en réutilisant les événements existants. Jamais bloquante. | Au moins 3 décisions par an en moyenne sur la carrière | La colonne `decisions` de la sonde |

Ordre conseillé (game design) : G1 et G2 avant la démo ; G3 en premier après la démo (il sert de filet aux autres), puis G4, G5, G6 et G7.

### Plan monétisation (proposition du 08/10, 19 h 45)

Source : `docs/MONETISATION_2026-10-08.md`.

Principe : jeu gratuit, puis achat unique de la version complète, extensions de branches et cosmétiques purement visuels. Pas de passe de saison, de boîte à butin, d'énergie, de monnaie premium ni de publicité. Tout le contenu est livré dans le jeu ; un droit, vérifié localement, en ouvre l'accès, hors ligne.

**Rien de payant dans la démo de fin octobre.**

| Étape | Quand | Contenu | Critère de réussite | Test |
|---|---|---|---|---|
| **M0** | Avant la démo | **Décisions d'Alexandre** : la limite gratuite (option A recommandée : 1971–1985 gratuit), les prix et la première extension. Rien à coder. | Décisions notées ici | — |
| **M1** | Après la démo | **Couche des droits** : `scripts/Entitlements.gd` (liste fermée de produits, `owns()`, signal, cache local `user://entitlements.cfg`) et `FakeStore`. `CompanyBranches` et les finitions lisent `owns()`. | Le jeu reste entièrement jouable hors ligne ; une sauvegarde faite avec une extension s'ouvre sans elle (éléments figés, mention « nécessite l'extension ») | `EntitlementsScenario` : posséder ou ne pas posséder, cache hors ligne, sauvegarde ouverte sans l'extension |
| **M2** | Après M1 | **Limite gratuite et écran de version complète** : une seule proposition au moment choisi (1985 avec l'option A), bouton « Plus tard » toujours visible, pas de rappel avant le palier suivant ; la partie continue après l'achat sans rien perdre. | Aucune fenêtre d'achat en dehors des moments prévus | Scénario : la proposition ne revient pas dans les 12 mois de jeu suivants ; après l'achat factice, la carrière continue |
| **M3** | Avant la sortie publique Android | **Google Play Billing** : plugin officiel pour Godot 4, achats non consommables, confirmation sous 3 jours, « Restaurer les achats » dans le menu. Mise à jour de la page de confidentialité, de la section « Sécurité des données » et de la classification (« achats intégrés »). **Rien n'est envoyé à Google sans l'accord d'Alexandre.** | Achat, puis restauration après réinstallation, sur la piste de test interne | Test manuel sur le Pixel avec un compte testeur de licence ; `PrivacyScenario` mis à jour |
| **M4** | Avant Steam | **Steam** : GodotSteam, un DLC par produit (droit seul), succès Steam. | Le DLC acheté est reconnu sans connexion après la première vérification | Test manuel sur un compte Steam de test |
| **M5** | Après M1 | **Premiers cosmétiques** : finitions de boîtier (couleurs, logos, matières) et un thème de garage, **sans aucun effet sur les notes ni les ventes** ; défis du moment gratuits, calés sur la vraie date, qui donnent aussi des cosmétiques. | Une finition payante n'a aucun effet chiffré | Scénario : notes et ventes identiques avec ou sans cosmétique |
| **M6** | Avant la démo, puis en continu | **Rétention** : le premier CPU lancé en moins de 10 minutes de jeu ; un résumé de Nora « ce qui vous attend » au retour ; un palier visible à chaque semaine de jeu (déménagement, 2e génération, Logiciel). | Mesuré avec les testeurs (temps jusqu'au premier jour J) | Scénario : le parcours guidé atteint le jour J en moins de N actions |

### Plan audio (décidé le 08/10, 20 h)

Source : `docs/AUDIT_AUDIO_2026-10-08.md`. Les musiques sont déjà normalisées à −20 LUFS. En revanche, il n'y a aucun bus audio (pas d'atténuation, pas de limiteur), aucune musique après 1990 et pas d'état « tension ».

| Étape | Quand | Contenu | Critère de réussite | Test |
|---|---|---|---|---|
| **A1** | Avant la démo (nécessaire à G2) | **Bus audio** : `default_bus_layout.tres` avec `Master` (limiteur à −1 dB), `Musique`, `Ambiances` et `Effets`. Chaque lecteur de `SoundManager` va sur son bus ; les volumes des réglages pilotent les bus. Fonction `duck(bus, db, duree)` pour l'atténuation. | Réglages de volume inchangés pour le joueur ; plus de saturation sur le Pixel | Scénario : les lecteurs sont sur le bon bus, `duck()` baisse puis rétablit le volume du bus |
| **A2** | Avant la démo | **Jour J et célébrations** : musique à −12 dB pendant le suspense, puis le jingle `review_good` ou `review_bad`, et remontée en 1,5 s ; −8 dB pendant 2 s aux célébrations ; −6 dB pour la musique et −10 dB pour les ambiances quand un menu est ouvert. | Le suspense du jour J s'entend sur le Pixel | Scénario : séquence d'atténuation (valeurs de volume du bus aux étapes clés) |
| **A3** | Après la démo | **État « tension »** : un filtre passe-bas (≈ 1,2 kHz) et −3 dB sur le bus Musique quand il reste moins de 3 mois de trésorerie, pendant un rappel ou une crise de réputation ; retour quand la cause disparaît. | Audible mais discret | Scénario : l'entrée et la sortie de l'état suivent la cause |
| **A4** | Après la démo | **Voix et formats** : 8 voix d'effets sur mobile et 12 sur PC, en coupant le son le plus ancien et le moins prioritaire ; effets courts réimportés en WAV QOA ; 3 ambiances audibles au plus sur mobile ; volume séparé pour les ambiances dans les réglages. | Aucun son coupé au hasard ; latence des clics réduite | Scénario : priorités de voix ; réglage des ambiances conservé |
| **A5** | Après la démo (avec Astra ou une banque libre CC0) | **Musiques 2000s, 2010s et 2020s**, dans le même esprit calme, normalisées à −20 LUFS ; `era_for_year` étendu. Mettre à jour `assets/audio/CREDITS.md`. | Chaque époque a ses morceaux | Test : chaque époque renvoie au moins 2 morceaux existants |

Ordre conseillé (audio) : A1 et A2 avant la démo, avec G2 ; A3 à A5 après la démo.

Ordre conseillé (monétisation) : M0 dès que possible (ça oriente le contenu de la démo) ; M6 avec la démo ; M1, M2 et M5 après la démo ; M3 avant la sortie publique Android ; M4 avant Steam. On décide de C4 avant la démo selon ce que montre le téléphone ; le reste vient après.

Historique des tâches précédentes :

1. ✅ **Valider Équipe en capture** (08/10) : fait, accords corrigés (« 1 personne », phrase de Nora au singulier).
2. ✅ **Finition → planche 6** (08/10), voir §2 bis.
3. ✅ **Marché → planche 8** (08/10), voir §2 bis.
4. ✅ **Entreprise → planche 7** (08/10), voir §2 bis. La version « garage simplifiée » reste à faire, voir le point 4 bis.
4 bis. **Entreprise, sous-pages** : masquer Divisions, Groupe et délégation tant que l'entreprise est un garage. Les déverrouillages actuels sont dans `PAGE_UNLOCKS`.
5. **Passer Labo et Presse sur `SceneHeader`**, pour unifier le code. Leurs scènes sont aujourd'hui codées à la main dans chaque board.
6. ✅ **Noms de CPU uniques** (08/10) : `ArchitectureManager.unique_cpu_name()` donne au nom le premier numéro libre (« Nova 1 » → « Nova 2 »).
   - Il est appliqué aux trois points de création (assistant, premier atelier, labo avancé) et à `next_model_name()`.
   - Tests : `UniqueNamesScenario` ; `CpuStepperScenario` attend désormais « Nova 2 ».
   - **Non fait** : renommer les doublons des anciennes sauvegardes (ils sont référencés par les produits et la presse ; à décider avec Alexandre).
7. ✅ **Confidentialité dans le jeu** (08/10) : Menu > « Confidentialité ».
   - Le texte est dans `scripts/PrivacyPolicy.gd`, et `PrivacyScenario` vérifie que l'export ne demande aucune permission Android.
   - `ONLINE_URL` pointe vers la page publiée sur GitHub Pages (branche `gh-pages`, `confidentialite.html`). Elle fait le même engagement et doit rester cohérente avec le texte du jeu.
8. **Élasticité des prix** : la demande doit réagir au prix de façon lisible. Ce point est lié à la tâche 3.
9. **Plateformes / sockets / refresh** : une gamme qui vieillit et un rafraîchissement de gamme. À cadrer avec Alexandre avant de coder.

---

## 6. Google Play — où on en est

- **Compte** : développeur 5596457224700637014, application 4973288943456373927, package `com.vadorus.techempire`.
- **Déclarations** : les 10 déclarations « Contenu de l'appli » sont enregistrées.
  - Classification : PEGI 3, avec une référence rare à l'alcool, pour le champagne du décor du Nouvel An.
  - Public visé : 13 ans et plus.
- **Fiche Play Store** : la fiche fr-FR est complète.
- **Examen** : **rien n'a été envoyé**.
- **Reste à faire** :
  1. Publier une version sur le test fermé (piste Alpha), avec l'AAB signé par la clé d'importation. Voir `docs/PUBLICATION_PLAY_STORE.md`.
  2. Créer une liste de testeurs.
  3. Garder au moins **12 testeurs pendant 14 jours d'affilée**.
  4. Demander l'accès à la production.
- **DLC payants prévus plus tard.** Le jour où ils arrivent, il faudra mettre à jour, dans la Play Console :
  - « Informations de connexion » ;
  - « Classification » (achats intégrés) ;
  - « Sécurité des données ».
- **Bandeau « vérification des développeurs Android »** : faible priorité, noté seulement.
- **Ne jamais faire** :
  - envoyer pour examen ou accepter des conditions sans l'accord d'Alexandre ;
  - versionner la clé ou son mot de passe.

---

## 7. Pixel d'Alexandre : précautions

- L'APK installé à côté du Play Store est signé avec la **clé de debug du PC du travail**.
- Installer la version Play Store par-dessus provoque un conflit de signature. Il faudrait alors désinstaller, et **la sauvegarde serait perdue**. Il faut la sauvegarder avant.
- **Sauvegarde** : script `Documents\_TechEmpire_signature\install_pixel.ps1` sur le PC du travail. Il sauvegarde, exporte, puis exécute `adb install -r`.
  - Lire la sauvegarde **uniquement** avec `cmd /c "adb exec-out run-as com.vadorus.techempire cat ... > fichier"`.
  - Une redirection PowerShell corrompt l'encodage. `repair_save.ps1` répare ce type de dégât.
- **Restauration** : `adb push` vers `/data/local/tmp`, puis `run-as ... cp`.
- Ne jamais installer pendant qu'Alexandre joue.
- Prévenir avant d'ouvrir une fenêtre Godot sur ses PC.
- Ne pas toucher aux autres worktrees, par exemple `TechEmpire-cpu-experience-20261007`.
- L'APK actuel du Pixel ne contient pas encore Presse ni Équipe. Il faudra le reconstruire au prochain branchement.

---

## 8. Points ouverts, à vérifier par un humain

- La sauvegarde d'Alexandre (environ 16 M€) date d'**avant** la correction de l'économie. Ses chiffres ne reflètent donc pas l'équilibrage actuel.
- Les cinq images devinées dans les maquettes : à confirmer visuellement.
- Musiques de saison : écoute faite à la construction des pistes seulement, pas en jeu sur le téléphone.
- Équipe et Presse : vérifiées par les tests et par une capture (Presse uniquement), pas encore sur le Pixel.
- Le plan directeur (Claude Docs, onglet « Revue des onglets — 07/10 ») contient la checklist de la revue. Il doit être mis à jour à mesure que les onglets avancent.
