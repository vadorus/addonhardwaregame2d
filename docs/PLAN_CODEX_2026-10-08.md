# Plan de travail pour Codex — à partir du 08/10/2026 au soir

C'est **la seule liste à suivre**. Le détail de chaque étape (fichiers, critères, tests) est dans `docs/REPRISE_CODEX_2026-10-07.md`, section 5, sous le code de l'étape (C2, T2, R1…). Les rapports d'audit expliquent le *pourquoi* :

| Audit | Fichier |
|---|---|
| Architecture et performances | `docs/AUDIT_ARCHITECTURE_2026-10-08.md` |
| Rendu et textures | `docs/AUDIT_RENDU_2026-10-08.md` |
| Game design et économie | `docs/AUDIT_GAME_DESIGN_2026-10-08.md` |
| Audio | `docs/AUDIT_AUDIO_2026-10-08.md` |
| Monétisation | `docs/MONETISATION_2026-10-08.md` |
| Fiches des boutiques | `docs/FICHES_BOUTIQUES_2026-10-08.md` |

Le tactile et la manette n'ont pas de fichier d'audit à part : leurs constats sont directement dans la section 5 du document de reprise.

## Règles (les mêmes pour chaque étape)

1. **Avant de commencer** :
   - `git fetch origin`, puis travailler sur `v013/demo-octobre` à jour ;
   - travailler dans la copie de travail habituelle, jamais dans `TechEmpire-dev` (il contient des modifications non enregistrées) ;
   - lire `AGENTS.md`.
2. **Un commit par étape**, message en français, en commençant par le code de l'étape (« C2 : … »).
3. **Identité Git** : `vadorus <vadorus@users.noreply.github.com>`. **Jamais l'adresse Gmail d'Alexandre.**
4. **Après chaque étape**, lancer et vérifier qu'aucune ligne `ERROR:`, `SCRIPT ERROR` ou `Parse Error` n'apparaît :
   ```text
   godot --headless --path . --import
   godot --headless --path . --quit-after 2
   godot --headless --path . res://tests/smoke_test.tscn
   godot --headless --path . --script res://tests/branding_config_test.gd
   godot --headless --path . res://tests/garage_layout_test.tscn
   godot --headless --path . res://tests/workshop_layout_test.tscn
   godot --headless --path . res://tests/balance_ceiling_test.tscn
   godot --headless --path . res://tests/screen_refresh_test.tscn
   godot --headless --path . res://tests/cpu_journey_test.tscn
   ```
   Pour les étapes d'économie (G1, G4, G5) : relancer aussi `res://tests/tools/career_probe.tscn -- 104729,208877,313133,417401 STANDARD` (puis `ACCESSIBLE`) et noter les résultats avant/après dans le message de commit.
5. **Un test déterministe** pour chaque nouvelle mécanique. Pour toute modification de sauvegarde : **migration explicite** et test de chargement d'une ancienne sauvegarde.
6. **Toute modification visible** : une capture avant/après, relue.
7. **Interdits** :
   - modifier `.github/`, `tools/agents/`, `AGENTS.md`, `.gitignore` ou `.gitattributes` ;
   - ajouter un secret ou la clé de signature ;
   - construire ou installer un APK (c'est Claude, avec Alexandre, qui s'en charge) ;
   - envoyer quoi que ce soit sur la Play Console ;
   - ouvrir un nouveau secteur (GPU, mobile, etc.) avant la validation de la tranche CPU.
8. **À la fin d'un lot**, écrire `docs/RETOUR_CODEX_<date>_<lot>.md` sur le modèle de `RETOUR_CODEX_2026-10-08_POINTS_2_5.md`. Il doit séparer ce qui a été vérifié de ce qui reste supposé. Claude relit chaque commit avant que l'APK parte sur le Pixel.

## Phase 1 — avant la démo de fin octobre (dans cet ordre)

| # | Étape | En une phrase | Taille |
|---|---|---|---|
| 0 | **P0** | **D'abord la mesure** : l'outil de mesure intégré (voir « Protocole de mesure sur le Pixel » plus bas), seul dans son commit, **avant toute optimisation de la phase 1**. Ce commit sert de **version témoin** : Claude en tire un premier APK pour mesurer l'« avant » | Petite |
| — | *Mesure « avant »* | Claude construit l'APK témoin (P0 seul), sauvegarde la partie du Pixel, installe, et mesure avec Alexandre selon le protocole | — |
| 1 | **C3** | Ne plus chercher à chaque image une décision bloquante ; reformater la date seulement quand elle change | Petite |
| 2 | **C2** | Animations économes (battement partagé à environ 20 Hz, arrêt quand le nœud est caché) et mode basse consommation en pause | Moyenne |
| 3 | **R1** | Limite d'images par seconde (30 sur mobile, 60 sur PC) et réglage « Fluidité » dans le menu | Petite |
| 4 | **A1** | Bus audio Master (limiteur), Musique, Ambiances, Effets, et fonction `duck()` | Petite |
| 5 | **T2** | Zones tactiles d'au moins 6 mm partout et 8 mm pour les actions principales, sur téléphone | Moyenne |
| 6 | **T3** | Un appui long affiche les infobulles sur téléphone | Petite |
| 7 | **G1** | Comprendre la faillite de 1973 en Standard, puis ajouter l'alerte de mois de trésorerie avant chaque embauche ou budget de R&D | Moyenne |
| 8 | **G2 + A2** | Jour J : 600 ms de suspense avec la musique atténuée, notes une à une, jingle ; confettis légers aux records ; décompte de fin de mois | Moyenne |
| 9 | **R2** | Compression des grandes images (ASTC/ETC2 sur Android, BC7 sur PC), icônes sans compression ; captures avant/après **à faire juger par Alexandre** | Moyenne |
| 10 | **M6** | Le premier jour J atteignable en moins de 10 minutes (mesurer, puis raccourcir si besoin) ; résumé de Nora au retour en jeu | Petite |
| — | *Mesure « après »* | Claude relit tout, construit l'APK de la phase 1, installe, puis mesure avec Alexandre **dans exactement les mêmes conditions** que la mesure « avant » | — |
| 11 | **Diagnostic ciblé** | **Seulement si un seuil est dépassé** : on lit dans le CSV *quelle partie* coûte (simulation, reconstruction d'un écran précis, rendu), on reproduit ce cas, et on corrige ce point-là. C4 (réutiliser les lignes d'Entreprise et Produits) ou R3 (fonds superposés) ne sont appliqués **que si le diagnostic les désigne** ; jamais de refonte d'office | Selon le diagnostic |
| 12 | **T7** | Sensibilité du défilement réglée d'après l'essai sur le Pixel | Petite |

## Protocole de mesure sur le Pixel (demandé par Alexandre le 08/10)

Les images par seconde au repos ne suffisent pas. On compare **avant** (APK témoin : P0 seul, sans les optimisations de la phase 1) et **après** (APK de la phase 1), dans **les mêmes conditions** :
- **la même copie de sauvegarde**, rechargée avant chaque série (jamais la partie d'Alexandre elle-même) ; la copie est gardée à part dans le dossier de travail de Claude, avec sa date ;
- le même téléphone, chargé à plus de 50 %, hors mode économie d'énergie, applications en arrière-plan fermées, luminosité fixe ;
- la même échelle d'interface et le même réglage de fluidité (30 images/s si R1 est présent : noter le réglage dans le CSV) ;
- les séries dans le même ordre : repos, fins de mois, changements d'onglets.

Les trois situations :

| Situation | Comment | Ce qu'on relève |
|---|---|---|
| **Repos** | QG affiché, temps en pause, 30 s ; puis 60 s de jeu à ×1 | Images par seconde moyennes **et** temps d'image du 95e et du 99e centile, pire image, nombre d'**interruptions visibles** (images de plus de 50 ms) ; chauffe ressentie |
| **Fins de mois à vitesse ×3** | Pour **chacun** des trois écrans (QG, **Entreprise**, **Produits**) : recharger la copie, vitesse ×3, 12 fins de mois de suite. **36 observations** au total | Pour chaque fin de mois : la pire image, et sa décomposition (temps de simulation, temps de reconstruction de l'écran, reste du rendu) ; puis médiane et pire valeur par écran |
| **Changements d'onglets** | Passer 3 fois par les 7 onglets, dans l'ordre, temps en pause | Temps entre l'appui et l'affichage complet de l'onglet (pire et médiane, par onglet) |

**L'outil, étape P0** : `scripts/PerfProbe.gd`, un autoload inactif par défaut.
- Il s'active seulement par un réglage caché (Menu, puis 5 appuis sur la version) ou par l'argument `--perf-probe`.
- Il enregistre le temps de chaque image (`Performance.TIME_PROCESS` et la durée réelle entre deux images).
- Il **sépare les causes** d'un ralentissement :
  - la simulation : durée de `SimulationManager.process_month_end()` ;
  - la reconstruction de l'interface : durée de `_refresh_all()`, de `_flush_refresh_parts()` et du `refresh()` de chaque écran, avec le nom de l'écran ;
  - le rendu : le reste du temps de l'image.
- Il marque les fins de mois (signal `month_processed`) et les changements d'onglet (`tabs.tab_changed`), qu'il mesure jusqu'à la première image affichée après le rafraîchissement.
- Pour chaque série : moyenne, médiane, 95e et 99e centile, pire image, et nombre d'images de plus de 50 ms (interruptions visibles) et de plus de 100 ms (saccades nettes).
- Il écrit `user://perf_<date>.csv` (une ligne par évènement, avec le commit, le réglage de fluidité et le nom de la série) et affiche un résumé à l'écran.
- **Aucun envoi réseau.**
- Inactif, il ne coûte rien : aucune mesure, aucun fichier.
- Test : un scénario simule 2 fins de mois et 1 changement d'onglet, puis vérifie les lignes du CSV et la séparation entre simulation et reconstruction.

**Seuils** (sur le Pixel). Un seuil dépassé déclenche un **diagnostic ciblé**, pas une refonte :

| Mesure | Correct | Diagnostic à lancer si |
|---|---|---|
| Pire image d'une fin de mois à ×3, par écran | ≤ 100 ms (à peine visible) | > 150 ms sur au moins 3 des 12 mois, ou > 250 ms une seule fois |
| Changement d'onglet | ≤ 150 ms | > 250 ms sur un onglet |
| Jeu à ×1 | 99e centile ≤ 50 ms ; au plus 1 interruption visible par minute | Plus de 1 interruption visible par minute, ou 30 images/s non tenues |

Lecture du diagnostic :
- **la simulation domine** : on regarde le gestionnaire le plus lent (chronométrage par gestionnaire, comme dans l'audit d'architecture) ;
- **la reconstruction d'un écran domine** : on corrige cet écran (C4 s'il s'agit d'Entreprise ou de Produits) ;
- **le rendu domine** : R2 d'abord, puis R3.

Les chiffres mesurés sont notés dans `docs/REPRISE_CODEX_2026-10-07.md` (ligne « Mesure Pixel »), avec la version de l'APK.

## Propositions d'Alexandre (08/10, 19 h 53) — non définitives

| Sujet | Proposition actuelle |
|---|---|
| Limite gratuite | Jusqu'en 1985 |
| Version complète | 4,99 €, à tester |
| Première extension | Mobile, à confirmer |
| Difficulté de la démo | **Accessible par défaut : autorisé** (à réévaluer après G1) |
| Titre Play Store | « Tech Empire » : candidat privilégié |
| Mesures sur le Pixel avec P0 | **Principe validé** (avant/après, mêmes conditions, diagnostic ciblé) |
| Refresh de gamme | À concevoir séparément |

Codex **peut** régler la difficulté Accessible par défaut dans la démo. Le reste (prix, limite gratuite, extension) **n'entre pas dans le code** avant la confirmation d'Alexandre (étapes M1/M2).

**Objectif d'Alexandre pour la démo** : une démo agréable à jouer, compréhensible et stable, pas seulement un jeu qui passe ses tests. Une étape n'est finie que si elle sert cet objectif.

## Phase 2 — après la démo (dans cet ordre)

1. **G3** : garde-fous de carrière dans la CI. C'est le filet de sécurité pour tout ce qui suit.
2. **G4, G5, G6, G7** : impôt et puits d'argent proportionnels ; 1re place atteignable et rivaux qui réagissent ; Nora qui explique le déclin ; petites décisions pendant le développement.
3. **C5, C6** : lecture des données sans copie ; découpage de `main.gd` en un contrôleur par onglet.
4. **R4, R5, R6** : moins d'appels de rendu, le même moteur de rendu sur PC que sur le Pixel, ombres et décors.
5. **A3, A4, A5** : musique de tension, priorités des voix et format des effets, musiques à partir des années 2000.
6. **T4, T6** : un gestionnaire d'entrées unique avec raccourcis PC ; vibrations, qui demandent une mise à jour de la confidentialité.
7. **M1, M2, M5** : couche des droits d'accès (hors ligne), limite gratuite, premiers cosmétiques. **Seulement après les décisions d'Alexandre (M0).**
8. **Software, lots 1 à 8**, dans l'ordre, après la validation de la tranche CPU. Le plan détaillé est dans le Claude Doc d'Alexandre « Tech Empire — Branche Software : audit, architecture et plan ». Résumé :
   - lot 1 : un registre d'effets plafonnés et les révisions des anciens CPU (BSM3 : microcode et firmware avec adoption progressive, parc installé) ;
   - lot 2 : catalogue `SoftwareDefinition` qui remplace les 5 familles, avec migration ;
   - lot 3 : moteur de projet commun (logiciels liés au matériel, puis logiciels métier avec cahier des charges) ;
   - lot 4 : le CPU continue seul, sans directeur, quand on joue une autre branche ;
   - lot 5 : outils internes ;
   - lot 6 : époques après 1977, marché lié au parc de machines ;
   - lot 7 : Web et Internet comme époque ;
   - lot 8 : branche Réseau et hébergement.
9. **C8, C9** : sauvegarde en arrière-plan ; réécrire ou retirer les 4 anciens tests en échec.

## Phase 3 — avant la sortie publique et Steam

- **M3** : Google Play Billing, confidentialité, « Sécurité des données » et classification mises à jour, avec l'accord d'Alexandre.
- **T5** : une partie complète jouable à la manette et au Steam Deck.
- **M4** : Steam (GodotSteam, DLC « droit seul », succès).
- **Fiches des boutiques** : textes de `FICHES_BOUTIQUES_2026-10-08.md`, après les choix d'Alexandre.

## Ce qui attend Alexandre (Codex ne le tranche pas)

- **M0** : la limite gratuite, les prix et la première extension (propositions ci-dessus, à confirmer).
- La difficulté par défaut de la démo (proposition : Accessible, à revoir après G1).
- La description de la fiche Play (titre proposé : « Tech Empire ») et « Pixel Graphics » ou « Hand-drawn » sur Steam.
- Le refresh de gamme et les plateformes sur plusieurs générations : à cadrer avant tout code.
- Les adresses Gmail des testeurs pour le test fermé.
