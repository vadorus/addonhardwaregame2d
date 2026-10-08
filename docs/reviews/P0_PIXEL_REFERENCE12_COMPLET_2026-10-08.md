# Tech Empire — P0, mesures Pixel avec référence 12 mois (8 octobre 2026)

## Verdict
**36/36 fins de mois terminées (PASS) sur le Pixel 10, 12 par écran.** La simulation est reproductible : même checksum final dans les trois séries. Le QG reste sous les seuils, **Entreprise et Produits dépassent les seuils qui imposent un diagnostic ciblé**, pas une refonte automatique. La minute à ×1 fait l'objet d'une section séparée.

## Référence de test : construite sans toucher à la partie personnelle

- Source : copie de la partie **Nova Technologies, avril 1992**, 27 produits CPU, 4 logiciels, 9 projets CPU terminés, 11 salariés.
- Pour empêcher la découverte R&D « RND-007 » d'ouvrir un dialogue au troisième mois, la **copie de test uniquement** a ses 9 chercheurs R&D désaffectés (recherche fondamentale mise en pause), avec les trois allocations de recherche remises à zéro et son budget mensuel à zéro. Les produits, finances, équipes, marques et sauvegardes du joueur ne sont pas modifiés dans l'original.
- SHA-256 de la sauvegarde personnelle conservée avant et après les tests : `468e175cab8bc52cced32c26af49a4106c89912a3be305a13741d4cf0af12b60`.
- SHA-256 de la référence P0 préparée : `5b839da1ebf8974ee3cf2251bbeb5960047d54feb94e3f73eb2e6a54db4d472d`.
- Sur PC, la copie a d'abord traversé douze mois (avril 1992 → avril 1993), sans pause, décision ou faillite. Puis P0 a rechargé **la même copie** avant chaque série sur Pixel.
- Copie binaire conservée sur le PC à `build/pixel_saves/20261008_211018/P0_REFERENCE_1992_NO_RND_12MONTHS.json`, non publiée sur GitHub. Elle reste également dans le stockage privé de l'application Pixel : `files/perf_reference.json`.

## Conditions

- Pixel 10, connecté par USB au PC `home`, batterie 91 % lors de la préparation, charge USB activée.
- APK témoin au commit `0469df0dfd4fcfef8fbf3962140fd84db7d11b26`, avant les prochaines optimisations C2/C3.
- Plafond P0 fixé à **30 FPS** pour toutes les séries. Simulation ×3, ordre **QG → Entreprise → Produits**, douze fins de mois par écran et retour automatique au même état de référence.
- P0 garde les échantillons en mémoire et n'écrit le CSV qu'à la fin ; aucun transfert réseau depuis P0.

## Résultats : douze fins de mois par écran

| Écran | Série | Plus longue image | Mois > 150 ms | Mois > 250 ms | Résultat |
|---|---:|---:|---:|---:|---|
| QG | 12/12 | 150,537 ms | 1 | 0 | PASS — sous seuil |
| Entreprise | 12/12 | **297,655 ms** | **12** | **1** | PASS — diagnostic déclenché |
| Produits | 12/12 | **161,928 ms** | **3** | 0 | PASS — diagnostic déclenché |

**Critères prédéfinis :** diagnostic si strictement plus de 150 ms sur au moins 3 des 12 mois, ou strictement plus de 250 ms sur une fin de mois.

| Fin de mois | QG, pire image (ms) | Entreprise (ms) | Produits (ms) |
|---|---:|---:|---:|
| 1 | 119,547 | 297,655 | 161,928 |
| 2 | 111,474 | 164,196 | 133,002 |
| 3 | 139,407 | 191,656 | 132,637 |
| 4 | 108,126 | 170,567 | 148,840 |
| 5 | 112,643 | 166,326 | 128,177 |
| 6 | 150,537 | 184,833 | 134,754 |
| 7 | 99,071 | 165,372 | 158,413 |
| 8 | 102,084 | 166,736 | 130,959 |
| 9 | 105,795 | 184,935 | 149,290 |
| 10 | 101,836 | 163,881 | 150,260 |
| 11 | 96,900 | 166,227 | 144,269 |
| 12 | 119,982 | 164,377 | 129,529 |

### Reproductibilité

Les trois CSV contiennent la **même référence source** et le **même checksum final** :
`5e177b5ae3b08324ede4e9760f53717ad544040e1265d7777a175eed6b42fff8`.

Tous les résultats de série sont `OK`, sans décision prise par P0. L'ancienne référence avait échoué au quatrième mois ; elle **n'est pas utilisée** dans les mesures ci-dessus.

### Diagnostic préliminaire (instrumentation P0)

- **Entreprise** : rafraîchissement d'interface d'environ **84 à 111 ms** par fin de mois (contre typiquement 25 à 36 ms au QG hors pics). La reconstruction de l'écran, plutôt que le seul calcul de simulation, est la première piste à vérifier.
- **Produits** : rafraîchissement d'environ **50 à 79 ms** suivant les mois. Trois fins de mois dépassent 150 ms (mois 1, 7 et 10).
- **QG** : un pic de 150,537 ms, principalement lors du mois 6 ; seuil non atteint sur ce seul écran.
- La mesure résiduelle de P0 (autour de 33 ms à ce plafond) n'est **pas** une mesure GPU pure. L'attribution « simulation / UI / reste » est indicative et doit être vérifiée avec un profilage ciblé.
- **Décision** : investiguer le rafraîchissement d'Entreprise et Produits. C4 pourrait être justifié si la reconstruction de lignes est confirmée. **R3 n'est pas automatiquement autorisé.**

## Minute de jeu à ×1 sur le QG — PASS

P0 a rechargé la même référence, lancé la vitesse normale ×1 et chronométré **60 secondes** sur le QG (plafond 30 FPS). Le scénario a continué à faire progresser le jeu durant cette minute, sans interruption ni intervention humaine.

| Indicateur | Mesure |
|---|---:|
| Durée | 60 secondes |
| Intervalle moyen | **33,343 ms** |
| FPS moyen estimé (1 000 / intervalle moyen) | **29,99 FPS** |
| P50 temps d'image | 33,337 ms |
| P95 temps d'image | 34,199 ms |
| P99 temps d'image | 34,616 ms |
| Plus longue image | **120,450 ms** |
| Images au-dessus de 50 ms | **2** |
| Images au-dessus de 100 ms | **2** |
| Temps de processus moyen Godot | 17,408 ms |
| Résultat P0 | **OK** |

Le FPS moyen est correct à la cadence plafonnée ; **deux interruptions au-dessus de 100 ms** restent perceptibles. Une moyenne stable ne suffit donc pas à garantir une fluidité parfaite. Ces valeurs ne peuvent pas être comparées à 120 FPS au repos mesurés antérieurement, car la cadence et l'instrumentation diffèrent.

CSV : `build/P0_AVANT_REFERENCE12_QG_x1_60s.csv`, même commit témoin et même empreinte de référence que les 36 fins de mois.

## Données brutes et conservation

Les quatre CSV **sont versionnés avec ce rapport**, pour comparaison directe avec l'APK de la phase 1 :

- [QG — 12 fins de mois](p0_2026_10_08_data/P0_AVANT_REFERENCE12_QG_x3.csv)
- [Entreprise — 12 fins de mois](p0_2026_10_08_data/P0_AVANT_REFERENCE12_Entreprise_x3.csv)
- [Produits — 12 fins de mois](p0_2026_10_08_data/P0_AVANT_REFERENCE12_Produits_x3.csv)
- [QG — 60 secondes à ×1](p0_2026_10_08_data/P0_AVANT_REFERENCE12_QG_x1_60s.csv)

Ils sont aussi conservés dans `build/` sur le PC `home`. **La sauvegarde de référence n'est pas publiée sur GitHub** : elle reste dans les fichiers de test du PC et sur le Pixel. Ne pas remplacer cette référence lors de la mesure « après ».

En fin de capture, Pixel à 92 % de batterie, charge USB ; économie d'énergie Android inactive (`low_power=0`). Le réglage « rester allumé pendant la charge » a été restauré à sa valeur initiale (`15`). Les deux fichiers de sauvegarde personnels et la copie de référence ont été vérifiés par SHA-256 ; l'application a été fermée.

## Portée et prochaines étapes

La référence arrête temporairement la recherche fondamentale ; **ce résultat ne représente donc pas une carrière avec R&D active**. Il mesure la même entreprise développée et sa simulation économique/produits, à charge comparable sur les trois écrans.

Conserver strictement cette référence (même SHA), le commit témoin, la cadence, les conditions matérielles et l'ordre des séries pour refaire les 36 mesures **après la phase 1**. Aucun chantier C4/R3 ne doit être lancé sans diagnostic ciblé.
