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
