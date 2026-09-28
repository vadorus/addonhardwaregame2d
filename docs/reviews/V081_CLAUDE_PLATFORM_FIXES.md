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

## 28/09 fin d'après-midi — les dépenses deviennent des investissements

Sonde `_claude_probe/invest_probe.gd` : 10 variantes de joueur automatique sur 15 ans (1971 → 1986), toutes en suivant les conseils d'embauche de Nora.

Ce que la sonde a révélé **avant** correctif :

| Constat | Mesure |
| --- | --- |
| Le marketing ne coûtait presque rien | 1 000 €/mois : +15 M€ en 15 ans pour 161 k€ dépensés ; 30 000 €/mois n'apportait presque rien de plus (courbe `log`). |
| La recherche se « terminait » en 4 ans | Avec programmes Concept, les 3 maîtrises CPU à 100/100 dès 1976 ; la techno CPU à 100 dès 1978 **sans aucune recherche**. Plus rien à financer ensuite. |
| Les marchés arrivaient des décennies en avance | Datacenters vendus dès 1977 (historique : 2002), jeu vidéo dès 1975. |
| La fab interne était un gouffre | −0,3 M€ (fab seule) et −9 M€ en fin de partie (MegaFab à 175 k€/mois) : la marge brute CPU est de 80 %, économiser sur le coût unitaire rapporte peu. |

Correctifs :
- **Notoriété = stock** (`CompanyManager.brand_awareness`) : elle monte d'environ 12 % de l'écart par mois vers la cible du budget, retombe si on coupe, et le budget de référence grandit avec les années (12 k€/mois en 1971, ~25 k€ en 1980). Sauvegardée ; les anciennes parties repartent au niveau entretenu par leur budget. Écran Entreprise > Budgets : jauge « Notoriété de la marque » + phrase « avec X €/mois : notoriété visée N % » et seuil de rendement décroissant.
- **État de l'art** (`ResearchManager.industry_frontier / raise_capability / raise_technology`) : chaque maîtrise progresse à plein tant qu'on est derrière le meilleur concurrent ; au-delà, le gain baisse linéairement (−100 % à +16 points d'avance, plancher 6 %). S'applique à la recherche continue, aux programmes Concept, au développement et à l'apprentissage de production. Le résumé d'un Concept le dit quand l'avance rend le point coûteux.
- **Besoins de marché** : une avance technologique peut faire émerger un besoin jusqu'à 7 ans avant sa date (le test « PC pro dès 1971 avec forte avance » reste vrai), jamais plus. Un besoin déjà apparu reste ouvert (sauvegardes existantes).
- **Fab interne** : coût unitaire 0,82 → 0,70 selon le niveau (au lieu de 0,90 fixe), et la location de la capacité inutilisée est activée d'office à la mise en service (désactivable).

Après correctif (trésorerie 1986, base = 12,2 M€) :

| Stratégie | Trésorerie 1986 | Commentaire |
| --- | --- | --- |
| Marketing 1 000 €/mois | 13,0 M€ | effet léger, normal |
| Marketing 10 000 €/mois | 18,7 M€ | 1,6 M€ dépensés → +6,5 M€ |
| Marketing 30 000 €/mois | 26,2 M€ | rendement décroissant (+7,5 M€ pour les 20 k€ de plus) |
| Fab interne | 13,8 M€ | +1,6 M€, plus d'indépendance fournisseur |
| Recherche seule (6 chercheurs + Concepts) | 11,2 M€ | moins de cash mais **2,75 M€/an de CA en 1986 contre 0,55** : l'entreprise ne s'éteint pas |
| Recherche + nouveaux marchés | 23,9 M€ | |
| Recherche + marchés + marketing | 55,0 M€ | |
| Tout (dont fab) | 60,8 M€ | |

Test : `tests/scenarios/InvestmentBalanceScenario.gd` (dans le smoke test).

**Reste à traiter** : les concurrents atteignent 95-100 dans toutes les compétences vers 1986 ; si la partie doit durer jusqu'aux années 2000, leur rythme (et donc l'état de l'art) doit être étalé. Et même avec des maîtrises au niveau des concurrents, les CPU proposés automatiquement (« plan recommandé ») restent un peu derrière en fin de période (écart −7 à −9 points) : à regarder côté planificateur de génération.

## 28/09 soir — une campagne jusqu'en 2010, puis mode libre

Décision d'Alexandre : pas de générateur de nouveautés. Quand le joueur atteint le niveau technologique final, le jeu le lui dit clairement ; les technologies suivantes viendront avec les mises à jour / DLC ; la partie continue et doit rester intéressante par d'autres systèmes.

Correctifs :
- **Plafond daté de l'état de l'art** (`MarketManager.era_technology_ceiling`, `FINAL_TECH_YEAR = 2010`) : 32 en 1971, 100 en 2010. Les compétences des concurrents et la technologie des fonderies ralentissent en approchant ce plafond. Avant : concurrents à 95-100 partout dès 1986.
- **Notes des CPU rivaux relatives à leur époque** : celles du joueur l'étaient déjà (par rapport au procédé), celles des rivaux étaient absolues ; en fin de partie les rivaux dominaient mécaniquement (écart −17 en 2010 avec des maîtrises égales). Identique en 1971 ; rendement, défauts et capacité des rivaux restent absolus.
- **Annonce de fin de contenu** (`Interactions` « MILESTONE:TECH_FINAL ») : Nora vient voir le joueur (« ! » dans le garage) quand ses maîtrises et sa fabrication sont au maximum, ou au plus tard en 2010, avec un bilan de carrière. Une seule fois ; la partie continue en mode libre.

Parties automatiques de 40 ans (1971 → 2011) :

| Stratégie | Annonce « sommet » | Trésorerie 2010 | Écart produit vs rivaux 2010 |
| --- | --- | --- | --- |
| N'investit pas | 2010 | 32 M€ | −7 |
| Recherche | 2003 | 96 M€ | + |
| Recherche + nouveaux marchés | 2003 | 217 M€ | +5 |
| Tout (marketing, fab) | 2003 | 502 M€ | +8 |

Les 12 besoins de marché s'ouvrent progressivement jusqu'en 1998.

**À construire pour le mode libre** (la trésorerie atteint des centaines de M€) : de quoi dépenser et se battre une fois la technologie plafonnée — rachats de concurrents, filiales / nouvelles divisions, guerre des prix et parts de marché, événements de marché.
