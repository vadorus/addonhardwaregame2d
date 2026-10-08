# Tech Empire — Essai A/B ciblé BranchMap / SalesPortfolio (Pixel 10)

Date : 8 octobre 2026. **Verdict : BranchMap validé, SalesPortfolio non concluant.** Aucun découpage de grands scripts, ni modification de la simulation.

## Cadre de comparaison

- Version « avant » : branche diagnostique P0 `codex/p0-targeted-diagnostic`, trace Pixel `8ace65b`. Version « après » : mêmes sondes P0 et appels `refresh()`, avec deux modifications de cache de signatures au commit `28f9fda`.
- Même Pixel 10, même limite à **30 FPS**, vitesse **×3**, ordre **Entreprise → Produits**, **12 fins de mois par écran**, rechargement automatique de la référence P0 avant chaque série.
- Référence : SHA-256 `5b839da1ebf8974ee3cf2251bbeb5960047d54feb94e3f73eb2e6a54db4d472d`.
- Les quatre séries (deux avant / deux après) sont `OK`, avec **12 mois** chacune et un checksum final identique : `5e177b5ae3b08324ede4e9760f53717ad544040e1265d7777a175eed6b42fff8`.
- Les temps des fonctions représentent les douze rafraîchissements mensuels (sans la construction initiale). Le pire temps d'image inclut la mise en route mensuelle et la première image.
- Attention : les tests sont instrumentés, pas une comparaison d'APK final non instrumenté. Aucun gain GPU n'est affirmé.

## Entreprise : amélioration prouvée sur Pixel

| Indicateur | Avant | Après |
|---|---:|---:|
| `BranchMap.refresh()`, moyenne sur 12 mois | **60,21 ms** | **0,22 ms** |
| `CompanyScreen._refresh_scene()`, moyenne | 70,00 ms | 10,16 ms |
| Image mensuelle moyenne | 182,98 ms | **132,81 ms** |
| Fins de mois > 150 ms | 12 / 12 | **1 / 12** |
| Fins de mois > 250 ms | 1 / 12 | **1 / 12** |
| Pire image | 320,23 ms | **265,37 ms** |

**Interprétation :** les saccades répétées du rafraîchissement Entreprise chutent fortement. Il subsiste toutefois une première image à **265,37 ms**, au-dessus du seuil officiel de 250 ms : **Entreprise n'est pas encore entièrement sous les seuils**.

**Cause corrigée :** `ui/components/BranchMap.gd` recalculait les StyleBox des boutons et supprimait/recréait la carte de détail à chaque fermeture de mois. Une signature des contenus réellement visibles (sélection, libellés, statuts selon l'année, droits d'ouverture, descriptifs et boutons) court-circuite les reconstructions inutiles. Le héros « nom/rang » du haut de l'écran reste mis à jour par `CompanyScreen` et n'est pas figé par ce cache.

**Tests :** sélection CPU / Logiciel / Défense, boutons verrouillés, transition de statut 1979→1980, identité persistante des boutons et StyleBox lors des actualisations sans changement.

**Code validé et intégré à `v013/demo-octobre` :** commit `73bbc7a` (`codex/c4-branchmap-validated`). Ne pas considérer le seuil de 250 ms levé avant le diagnostic de la première image.

## Produits : cache de signature insuffisant

| Indicateur | Avant | Après |
|---|---:|---:|
| `SalesPortfolio.refresh()`, moyenne sur 12 mois | 33,62 ms | **33,50 ms** |
| `ProductLifecyclePanel.refresh()`, moyenne | 42,96 ms | 42,58 ms |
| `IndustrializationPanel.refresh()`, moyenne | 17,84 ms | 17,88 ms |
| Image mensuelle moyenne | 144,45 ms | **148,20 ms** |
| Fins de mois > 150 ms | 6 / 12 | **6 / 12** |
| Fins de mois > 250 ms | 0 / 12 | 0 / 12 |
| Pire image | 166,44 ms | **209,35 ms** |

**Aucun gain mensuel démontré.** Les chiffres de vente, prix, contributions et signaux peuvent changer chaque mois : une signature fidèle des lignes visibles détecte correctement le changement, **mais reconstruit toutes les lignes** presque à chaque fois. Le pic maximum après est plus haut ; ne pas l'attribuer au cache sans mesure complémentaire, mais surtout **ne pas annoncer de gain**.

**Test du prototype :** conserve les lignes lorsqu'aucun contenu n'a changé ; détecte sélection, changement de nom, expansion/réduction de groupe et mise à jour visible. C'est un test de cohérence et non une preuve de gain à la fin du mois.

**Code expérimental seulement :** `codex/c4-salesportfolio-experiment`, commit `b736bf4`. **Ce prototype n'est PAS fusionné dans `v013/demo-octobre`.** Ne pas le présenter comme une optimisation acquise. Étape suivante possible, avec validation distincte : réutiliser les boutons et mettre leurs textes à jour par identifiant produit, sans libérer/recréer toute la liste à chaque bilan, y compris lorsque les valeurs commerciales changent.

## Temps de démarrage à froid Pixel et export GDScript

Le chronomètre ADB fait `am force-stop`, `am start -W`, puis vérifie par captures d'écran la présence de l'écran titre. Trois répétitions sur chaque APK, même téléphone, sans réinstallation entre répétitions d'un même groupe.

| Démarrage jusqu'à l'écran titre | Avant | Après |
|---|---:|---:|
| Essai 1 | 7,483 s | 7,243 s |
| Essai 2 | 6,873 s | 6,990 s |
| Essai 3 | 7,132 s | 7,059 s |
| Moyenne | **7,163 s** | **7,097 s** |

L'écart moyen est d'environ **0,07 s** : trop faible pour conclure à une amélioration réelle, surtout avec la méthode de capture d'écran et seulement trois essais. `am start -W` est inférieur au temps réel de préparation de l'interface ; il ne doit pas être confondu avec le chargement jusqu'au titre.

**Contrôle de configuration :** le préréglage Android de `export_presets.cfg` indique `script_export_mode=2`, soit **Compressed binary tokens** (GDScript en jetons binaires compressés), pas les sources texte. Aucune modification d'export nécessaire. Le temps de démarrage n'est pas attribuable uniquement à la taille des fichiers `.gd`.

## Tests et précautions

- Après réimport Godot complète, PASS : `branch_map_signature_test`, `sales_portfolio_signature_test`, `perf_probe_test`, `perf_probe_integration_test`, `screen_refresh_test` et le smoke test complet.
- Le premier smoke test d'un nouveau worktree échouait sur le décor du garage tant que l'import d'assets n'était pas terminé ; après réimport réussie, **le smoke test complet est PASS**.
- L'APK corrigé installé sur Pixel utilise la clé de signature de test commune ; ni désinstallation ni migration des sauvegardes.
- Sommes SHA-256 de `tech_empire_save.json` et `.bak` identiques avant/après installation : `468e175cab8bc52cced32c26af49a4106c89912a3be305a13741d4cf0af12b60`. La référence P0 n'a pas changé.
- Les six mois-segments et les temps des fonctions sont observés sur la même référence mais le téléphone peut varier légèrement en charge/température ; ne pas en déduire la causalité d'un seul maximum.

## Sources brutes

- `p0_diag_refresh_2026_10_08_data/diag_pixel_Entreprise.csv`, `diag_pixel_Produits.csv` — avant.
- `c4_branchmap_sales_2026_10_08_data/after_pixel_Entreprise.csv`, `after_pixel_Produits.csv` — après.
- `c4_branchmap_sales_2026_10_08_data/cold_before.txt`, `cold_after.txt` — 3 démarrages par APK.
- Rapport de diagnostic antérieur : [P0_DIAGNOSTIC_CIBLE_2026-10-08.md](P0_DIAGNOSTIC_CIBLE_2026-10-08.md).

**Décision technique appliquée :** fusion par avance rapide de BranchMap seul dans la branche de démo (`73bbc7a`). SalesPortfolio reste uniquement dans sa branche expérimentale. La grosse refactorisation de `main.gd` et `MarketManager.gd` reste après la démo (C6). Ne pas conclure que la phase 1 entière est validée par cette seule comparaison.

