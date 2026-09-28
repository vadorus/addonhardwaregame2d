# V0.8.1 — Corrections plateforme PC / Android (Claude)

Date : 27 septembre 2026
Branche : `fix/v081-claude-platform`, construite **par-dessus les modifs d'Astra** (commit `d734256`, copie testée sur le Pixel 10).
Base de l'audit : `docs/reviews/V08_GARAGE_FIRST_UX_REVIEW.md` (espace de revue Claude) — les points déjà réglés par Astra n'ont pas été refaits.

## Ce qui change pour le joueur

| Problème | Correction |
|---|---|
| Plus aucun moyen de sauvegarder (bouton retiré en V0.8, aucun autosave) | Sauvegarde automatique à chaque fin de mois, à la fermeture sur PC et quand l'appli passe en arrière-plan sur Android. Menu ☰ : Sauvegarder / Charger / Taille de l'interface / Plein écran (PC) / Sauvegarder et quitter. |
| Sauvegarde précédente effacée après chaque écriture | Le `.bak` est conservé : c'est la copie de secours relue si la sauvegarde principale est corrompue. |
| Un dossier de sauvegarde par version sur PC (13 dossiers) | Dossier fixe `TechEmpire` (`use_custom_user_dir`). |
| Bouton Retour Android = quitte l'appli sans prévenir | Retour ferme d'abord ce qui est ouvert (atelier, menu d'une zone, onglet → QG), puis « Appuyez encore sur Retour pour quitter » avec sauvegarde. Sur PC, Échap fait la même chose et ouvre le menu depuis le garage. |
| Décisions PDG hors projet invisibles (SAV, RH, locaux, arbitrages) | La décision la plus grave allume la zone concernée (pastille rouge « ! »), devient le bouton vert « Traiter : … », apparaît en tête du menu de la zone. Si la zone n'est pas encore débloquée, le bouton du rail de gauche s'allume et Nora l'indique. |
| Liste « Tâches » figée et fausse | Remplacée par « Nora • prochaine étape » : une seule phrase, toujours vraie (bienvenue, décision à prendre et où, avancement de l'équipe, ventes). |
| Libellés du rail de gauche illisibles (texte foncé sur bouton foncé depuis le thème clair) | Libellés blancs ; le rail se compacte (sans icône, puis 2 colonnes) quand la hauteur manque. Il ne recouvre plus la carte de Nora. |
| Repères coupés au bord (tablette 4:3) ou cachés sous une carte (téléphone 16:9) | Chaque repère prend la position libre la plus proche de son objet, toujours à l'écran. |
| Deux pourcentages contradictoires, bouton grisé qui répète la carte | « Étape 3/6 : Alpha » + une seule barre ; pendant le développement le bouton dit « L'équipe travaille… ». |
| Texte trop petit sur téléphone | Échelle d'interface 115 % par défaut sur mobile, réglable de 90 à 150 % (bornée pour garder au moins 960×540 logiques). |
| En-tête qui déborde sur écran étroit | Mode compact sous 1220 px logiques (marque réduite, date « J1 • M8 • 1972 », « Rép. 45/100 »). |
| Encoches / zones système sur téléphone en plein écran | Marges de la zone sûre appliquées au jeu (`get_display_safe_area`). |
| Orientation Android non définie | Paysage avec capteur (les deux sens). |
| Rendu Forward+ sur Android | Renderer Compatibility sur mobile (meilleure compatibilité, moins de batterie) ; PC inchangé. |
| Réputation « 45 » sans échelle | « Réputation 45/100 ». |
| Écran Entreprise en anglais (Reliability, Value…) | Libellés français. |
| `.uid` non versionnés | Versionnés (commit séparé). |

## Fichiers touchés

`project.godot`, `main.gd`, `scripts/SaveManager.gd`, `ui/GarageHub.gd`, `ui/screens/CompanyScreen.gd`, `.github/workflows/godot-ci.yml`, `tests/smoke_test.gd`, `tests/garage_layout_test.gd`, nouveaux `tests/scenarios/GarageDecisionScenario.gd` et `tests/scenarios/PlatformScenario.gd`.

Aucune règle de gameplay, d'économie ou de simulation n'a été modifiée.

## Tests

- `smoke_test` : 20 scénarios existants + 2 nouveaux (décisions PDG dans le garage ; réglages Android, autosave réel à la fin d'un mois, bouton Retour/Échap). Tous verts.
- `garage_layout_test` (Astra) étendu de 2 à 6 formats : 1616×720, 1280×720, 1067×600, 1333×600, 1067×800, 1706×720 ; vérifie en plus le rail, les repères (dans l'écran, hors des cartes) et le garage complet à 5 zones. Il a attrapé un vrai défaut (repère Stock coincé entre deux cartes en 16:9 à 120 %), corrigé.
- `workshop_layout_test` (Astra) : vert.
- CI : les deux tests de disposition sont ajoutés au workflow `godot-ci.yml`.
- Contrôle visuel : partie jouée automatiquement jusqu'à une crise SAV et capturée sur PC 16:9, PC 16:10, ultra-large 21:9, téléphone 20:9 et 16:9 à 120 %, tablette 4:3 à 120 %.

## Reste à faire (hors de cette passe)

- Tester l'APK sur le Pixel 10 (renderer Compatibility, zone sûre, bouton Retour, reprise après mise en arrière-plan).
- Décor différent par palier de locaux : les 4 paliers utilisent toujours la même image (`garage_stage0..3.webp` existent dans le dépôt mais ne sont pas branchées sur le nouveau décor).
- « Conception avancée » reste proposée dès le premier geste (choix conservé : le test d'Astra l'exige).
- Six mois de jeu sans décision après le lancement du premier projet : Nora le dit maintenant, mais il manque de petits événements.

## Passe � chaleur � (m�me soir)

- Palette froide (blancs bleut�s, bleus) remplac�e par une palette chaude partout : fonds cr�me, texte brun, bandeaux bois, accents ambre. Vert d'action, rouges d'alerte et couleurs des rep�res conserv�s.
- Cartes du garage en papier cr�me l�g�rement translucide, bordure beige, ombre chaude ; frise d'�tapes masqu�e sur �cran bas pour lib�rer le d�cor.
- Nora a son visage (pastille � N �) dans sa carte.
- Rail de gauche : m�mes noms que la navigation (Entreprise, �quipe, Produits, March�).
- Comparaison : `docs/reviews/V081_avant_apres.png`.


## 28/09 — bugs trouvés dans la partie d'Alexandre sur le Pixel (« jade orp », 1975)

| Constaté sur le téléphone | Correctif |
| --- | --- |
| « Traiter : Décider des locaux » ouvrait l'onglet Entreprise tout en haut ; la décision était plusieurs écrans plus bas. Même souci pour RH, arbitrages, SAV, appels d'offres. | Nouvelle **carte de décision du PDG** (`ui/components/CeoDecisionPanel.gd`) au-dessus du garage : le problème, le conseil de Nora et des boutons chiffrés qui règlent la décision sur place (emménager / remettre en état / reporter ; entretien / prime ; suivre ou non la recommandation ; enquête, garantie, correctif, échange, rappel ; « noté » ; laisser passer l'appel d'offres), plus « Voir le dossier complet » et « Plus tard ». Ouverte par le bouton vert, le repère « ⚠ » du garage et la priorité du tableau de bord. |
| Le temps continuait en ×2 pendant qu'on cherchait la décision (3 mois passés). | Le temps est en pause tant que la carte est ouverte ; « Plus tard » / Retour rend la vitesse d'avant ; « Voir le dossier complet » garde la pause. |
| « Continuer » relançait la partie à la vitesse sauvegardée. | Une partie chargée repart **en pause** : « Partie chargée — novembre 1975. Appuyez sur ▶ quand vous êtes prêt. » |
| Nora conseillait de déménager (75 000 €) alors que le garage n'était qu'usé (3/8 places). | Si la place ne manque pas, Nora conseille la remise en état (5 000 €) ; le bouton vert de la carte suit ce conseil. |
| Un dossier SAV déjà en enquête ou sous surveillance restait « décision requise » indéfiniment. | Il ne revient que si la surveillance seule laisse la confiance se dégrader (sans garantie étendue). |

Test : `tests/scenarios/CeoDecisionScenario.gd` (dans le smoke test). Vérifié sur le Pixel 10 avec la vraie sauvegarde.

## 28/09 après-midi — équilibrage « grandir » (parties automatiques de 15 ans)

Mesures avant correctif (joueur automatique, 1971 → 1986) :

| | Sans embauche | En embauchant 1 dev/an |
| --- | --- | --- |
| Trésorerie 1986 | 18,0 M€ | 10,5 M€ (salaires) |
| Durée d'un CPU | 10-11 mois | 10 mois avec 15 devs |
| Ventes du CPU de 1972 en 1986 | ~120/mois | ~120/mois |

Embaucher ne servait à rien et les vieux produits se vendaient éternellement.

Correctifs :
- `DevelopmentEstimator.staffing_factor` : un CPU complexe demande une vraie équipe (2 devs jusqu'à complexité 45, puis +1 tous les 6 points). Début de partie inchangé ; dans les années 80, à 2 devs un CPU prend ~20 mois, à 5 devs ~10.
- `MarketManager.obsolescence_factor` : après 3 ans, les ventes d'un CPU déclinent jusqu'à ~5 % à 8 ans ; plus de contrats B2B sur un CPU en fin de vie.
- Nora vient proposer d'embaucher quand le projet en cours manque de développeurs et que la trésorerie le permet (conversation « On embauche ? », rappel dans 6 mois si refus).

Après correctif : le CPU de 1972 ne se vend plus en 1979 ; le joueur qui suit Nora passe à 6 salariés et garde des cycles de 10-11 mois. **Reste à traiter** : la trésorerie s'accumule encore (13-15 M€ en 1986) — il manque des investissements qui rapportent (marketing, usine, nouveaux marchés) et le début de partie est très rentable (≈1 M€/an dès 1974 à 3 personnes).
