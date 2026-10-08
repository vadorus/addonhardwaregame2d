# Tech Empire — Diagnostic ciblé P0 : Entreprise, Produits et ×1

**Date :** 8 octobre 2026 · **Protocole :** prompt 12 de `docs/PROMPTS_TECH_EMPIRE.md`.
**Verdict : diagnostic établi, aucun correctif appliqué.** Sur Pixel 10, les points chauds reproductibles sont `BranchMap.refresh()` dans Entreprise, `SalesPortfolio.refresh()` dans Produits, et la reconstruction des productions terminées lorsqu'elle se déclenche. Les ralentissements de la minute à ×1 coïncident avec les clôtures mensuelles ; ils proviennent du calcul de produits et du rafraîchissement UI appelé synchroniquement par `Economy.month_closed`.

## 1. Périmètre, preuve et reproductibilité

- Départ : jeu et P0 témoin au commit **`0469df0`** ; protocole « avant » déjà archivé dans [P0_PIXEL_REFERENCE12_COMPLET_2026-10-08.md](P0_PIXEL_REFERENCE12_COMPLET_2026-10-08.md).
- Référence **identique** à la mesure « avant » : `5b839da1ebf8974ee3cf2251bbeb5960047d54feb94e3f73eb2e6a54db4d472d` (copie privée Nova Technologies 1992, R&D fondamentale temporairement suspendue). Aucun changement de cette sauvegarde.
- Système : Godot 4.7.2 ; Pixel 10, batterie ≥ 94 % pendant le diagnostic, économie d'énergie désactivée, cadence P0 fixée à **30 FPS**.
- Ordre : d'abord simulation sur PC **headless**, ensuite Pixel sur **12 mois ×3, Entreprise et Produits**, puis deux captures de **60 s à ×1** sur le QG.
- Résultats : **12/12 et OK** pour les deux écrans sur Pixel, même checksum final `5e177b5ae3b08324ede4e9760f53717ad544040e1265d7777a175eed6b42fff8`. Cela concorde avec les 36 mois du protocole précédent.
- Instrumentation seule : 17 parties directes du `CompanyScreen.refresh()`, 7 de `ProductsScreen.refresh()`, puis sous-fonctions coûteuses et étapes de `SimulationManager.process_month_end()`.
- Code instrumenté sur branche **`codex/p0-targeted-diagnostic`**, commits `8ace65b` (écrans) et `2ac7632` (simulation/économie). **Pas de modification du gameplay, pas de correctif fusionné dans `v013/demo-octobre`.**
- Une invocation de `refresh()` est enregistrée lors de l'ouverture initiale de chaque série sur Pixel. Pour comparer les moyennes mensuelles, les tableaux ci-dessous **excluent le premier appel**, soit douze appels Pixel. Le headless enregistre douze appels mensuels directs. Les sous-fonctions conditionnelles sont comptées seulement lorsqu'elles s'exécutent.

## 2. Entreprise — coupable mesuré

| Fonction | Headless moyen, 12 mois | Pixel moyen, 12 mois | Lecture |
|---|---:|---:|---|
| `CompanyScreen._refresh_scene()` | ~26 ms | ~70 ms | Comprend la carte et le héros |
| ↳ `BranchMap.refresh()` | **17,49 ms** | **60,21 ms** | **Coût dominant** |
| `CompanyScreen._refresh_empire()` | 10,90 ms | 11,22 ms | Classement/trophées reconstruits |
| ↳ Construction des trophées | ~5–6 ms | 4,55 ms | Partie du coût d'Empire |
| ↳ Classement mondial | ~2–3 ms | 2,71 ms | Partie du coût d'Empire |

**Preuve code :** `ui/components/BranchMap.gd:64-80` reconstruit les styles des boutons à chaque `refresh()`, recalcule les positions et appelle `_build_card()` ; ce dernier supprime puis recrée les contrôles de détail (`:91-127`). `CompanyScreen._refresh_empire()` (`ui/screens/CompanyScreen.gd:396`) supprime puis recrée les lignes de carrière, classement mondial et trophées. Ces créations répétées existent même lorsque le joueur ne change pas d'onglet.

**Concordance avec P0 « avant » :** rafraîchissement d'Entreprise ~84–111 ms et 12/12 fins de mois > 150 ms, un pic à 297,66 ms. Dans la série instrumentée, une image lente est relevée à chaque clôture (environ 153–189 ms après le premier affichage), avec un pic initial de 320 ms. Les chiffres d'une version instrumentée ne doivent pas être comparés comme un gain/perte de FPS face à l'APK témoin.

## 3. Produits — coupables mesurés

| Fonction | Headless moyen | Pixel moyen | Observation |
|---|---:|---:|---|
| `ProductLifecyclePanel.refresh()` | 15,97 ms | **42,96 ms** | Principal bloc de Produits |
| ↳ `SalesPortfolio.refresh()` | 11,03 ms | **33,62 ms** | Recréation des lignes du portefeuille |
| `IndustrializationPanel.refresh()` | 6,36 ms | **17,84 ms** | Variable selon signature des fabrications |
| ↳ `_rebuild_done()` | 8,37 ms lorsqu'appelé | **26,19 ms lorsqu'appelé** | Exécuté 6 fois sur les 12 mois observés |

**Preuve code :** `ui/components/SalesPortfolio.gd:23-56` retire et libère tous les anciens enfants, appelle `ADVISOR.portfolio()` puis recrée boutons et lignes à chaque rafraîchissement. `ProductLifecyclePanel._refresh_range()` le déclenche directement (`ui/components/ProductLifecyclePanel.gd:468-505`). `IndustrializationPanel.refresh()` vérifie une signature et reconstruit les boîtes des travaux seulement lorsque celle-ci change (`ui/components/IndustrializationPanel.gd:89-103`). `_rebuild_done()` est une source supplémentaire de charge pendant ces mois.

**Concordance avec P0 « avant » :** coûts UI ~50–79 ms, 3/12 fins de mois > 150 ms, pic à 161,93 ms. Les résultats ne prouvent pas que le GPU ou la résolution sont en cause.

**Attention aux doubles comptes :** les lignes avec « ↳ » sont **incluses** dans la fonction parente. Les durées du tableau ne s'additionnent pas.

## 4. Les deux saccades à ×1 : cause et preuve temporelle

La première capture instrumentée (`8ace65b`) reproduit **deux images lentes** à **23,94 s** et **47,94 s**, simultanément aux marqueurs `MONTH_CLOSED` :

| Clôture | Image lente | Simulation P0 | Rafraîchissement P0 |
|---|---:|---:|---:|
| Avril → mai 1992, 23,94 s | **119,875 ms** | 52,575 ms | 33,894 ms |
| Mai → juin 1992, 47,94 s | **110,047 ms** | 42,285 ms | 34,521 ms |

La seconde capture (`2ac7632`) reproduit la clôture à **23,93 s** avec une image à **117,563 ms** ; l'autre clôture apparaît à **47,93 s**, mais reste cette fois en dessous de 100 ms. Résumé de la seconde minute : moyenne 33,330 ms à la limite 30 FPS ; deux images > 50 ms, une > 100 ms. Les deux traces s'accordent sur la synchronisation des pics avec la fin de mois, pas sur un dépassement systématique de 100 ms.

### Découpage des calculs sur Pixel, seconde capture ×1

| Partie du mois | Première clôture | Deuxième clôture |
|---|---:|---:|
| `ProductManager.process_month()` | **28,197 ms** | **13,779 ms** |
| Callbacks `Economy.month_closed` | **32,631 ms** | **35,275 ms** |
| Préparation du bilan dans `Economy.close_month()` | 0,078 ms | 0,108 ms |
| `ExecutiveManager.process_month()` | 7,219 ms | 3,906 ms |
| `SoftwareManager.process_month()` | 4,046 ms | 2,403 ms |

Le headless sur 12 mois retrouve le classement : **callbacks `month_closed` ~44,31 ms**, `ProductManager.process_month()` ~8,21 ms en moyenne, préparation comptable ~0,04 ms. Ces valeurs PC ne sont pas directement des prévisions de temps Pixel.

**Chaîne démontrée par le code :**

`TimeManager._next_day()` → `SimulationManager.process_month_end()` → `ProductManager.process_month()` → `Economy.close_month()` → `month_closed.emit(report)` → `main.gd::_on_month_closed()` → `_refresh_all()` et reconstructions de l'écran visible.

**Conclusion :** les saccades ne viennent pas de la simple addition d'un bilan comptable ou d'un problème aléatoire du QG. La clôture mensuelle rassemble **simulation produits + rafraîchissement UI synchrone** dans une seule mise à jour. Les compteurs `simulation_ms`, `refresh_ms` et le callback `month_closed` ont des périmètres imbriqués ; il serait incorrect de tous les additionner. Les « autres ms » de P0 n'isolent pas le GPU. La part GPU n'a pas été mesurée directement.

## 5. Expériences de confirmation avant chaque correction

1. **Entreprise / BranchMap :** sur une copie de diagnostic (jamais la version de jeu), comparer 12 mois avec la carte normalement reconstruite puis avec son rafraîchissement neutralisé **uniquement pour l'expérience**. Vérifier que le temps UI baisse dans une proportion proche des ~60 ms mesurés sur Pixel. Contrôler séparément les changements de sélection et d'année.
2. **Entreprise / Empire :** idem pour `_refresh_empire()` (~11 ms) ; vérifier que l'écran conserve les classements et trophées exacts après la fermeture du mois.
3. **Produits / Portefeuille :** comparer, uniquement en expérience, la reconstruction complète de `SalesPortfolio.refresh()` avec une actualisation des textes sans recréation des contrôles ; la différence attendue concerne les ~34 ms mesurés. Contrôler les états de modèles, leurs ventes et les actions.
4. **Produits / Productions terminées :** mesurer les six mois où `_rebuild_done()` s'exécute, puis tester une mise à jour par élément. Ne pas modifier la simulation, uniquement la représentation.
5. **Saccades ×1 :** tracer séparément `ProductManager.process_month()` et `month_closed.emit` avant et après une éventuelle répartition des mises à jour UI sur plusieurs frames. Vérifier que les bilans ne sont jamais présentés avec des montants obsolètes et que les décisions bloquantes arrêtent toujours le temps.

**Correctifs minimaux envisageables, non appliqués :** mémoriser l'état de la carte des branches et réutiliser styles/cartes si rien n'a changé ; mettre à jour les lignes de `SalesPortfolio` par identifiant plutôt que détruire/recréer ; rendre les rangées de productions terminées incrémentales ; si nécessaire, différer uniquement le rafraîchissement non critique de l'UI après les calculs mensuels. Chaque candidat devra prouver sa réduction avec la même référence, **sans casser les commandes ni la cohérence économique**.

## 6. Critères pour autoriser les optimisations

Rejouer la **même référence** (SHA ci-dessus), 30 FPS, QG → Entreprise → Produits, 12 fins de mois par écran, puis 60 s à ×1. Conserver les 36 observations et le checksum final. Les seuils officiels déclenchant un diagnostic sont >150 ms sur au moins 3 des 12 fins de mois, >250 ms une seule fois ; ne pas décider C4 ni R3 par habitude. Pour ×1, vérifier les images >50 ms et >100 ms, pas seulement le FPS moyen.

Le traceur a un coût propre et la première reconstruction « à froid » diffère des suivantes. L'amélioration devra être confirmée en **comparaison A/B avec la même instrumentation**, puis sur l'APK normal. Les faits du présent rapport définissent des suspects confirmés, pas des gains déjà obtenus.

## 7. Données brutes, code et sécurité

Les six CSV ci-dessous sont conservés dans [p0_diag_refresh_2026_10_08_data](p0_diag_refresh_2026_10_08_data) :

- `diag_headless_Entreprise.csv`, `diag_headless_Produits.csv` : douze mois par écran, sous-étapes d'interface et simulation.
- `diag_pixel_Entreprise.csv`, `diag_pixel_Produits.csv` : 12 mois sur chaque écran + première construction à froid, commit de trace `8ace65b`.
- `diag_pixel_QG_x1_60s.csv` : première minute ×1, deux pics >100 ms, commit `8ace65b`.
- `diag_pixel_QG_x1_modules.csv` : deuxième minute ×1, étapes `SimulationManager` et `Economy.close_month`, commit `2ac7632`.

**Code de trace :** branche [codex/p0-targeted-diagnostic](https://github.com/vadorus/addonhardwaregame2d/tree/codex/p0-targeted-diagnostic), volontairement non fusionnée à la branche démo. **Aucun correctif appliqué à Tech Empire.**

Après les essais, **l'APK P0 d'origine a été réinstallé** sur le Pixel, sans désinstallation de l'application (même signature Android). Vérifications SHA-256 des fichiers personnels `tech_empire_save.json` et `.bak` : tous deux inchangés, `468e175cab8bc52cced32c26af49a4106c89912a3be305a13741d4cf0af12b60`. Référence P0 inchangée. Jeu fermé ; aucun fichier de sauvegarde personnel inclus dans GitHub.

## Annexe A — toutes les sous-étapes instrumentées de refresh()

Toutes les valeurs ci-dessous sont en **millisecondes par invocation**. Pour le Pixel, le premier appel de mise en place de la série est exclu ; pour le headless, les 12 appels sont déjà mensuels. Un « — » signifie que la partie ne s’est pas exécutée dans ce scénario. Les sous-parties sont incluses dans leurs parents, et ne s’additionnent pas. **Limite d'instrumentation :** les labels `executive_brief`, `workplace_and_meters` et `division_data` couvrent seulement les affectations finales et **non l'intégralité** des calculs et créations de contrôles précédents ; leurs valeurs proches de zéro ne signifient donc pas que ces groupes entiers sont gratuits. Les fonctions appelées individuellement (BranchMap, Empire, Portfolio, Industrialization) sont en revanche chronométrées de bout en bout.

### Entreprise

| Étape | N headless | Moyenne headless | N Pixel | Moyenne Pixel | Max Pixel |
|---|---:|---:|---:|---:|---:|
| scene | 12 | 25,33 | 12 | 70,00 | 90,91 |
| ↳ branch_map | 12 | 17,49 | 12 | 60,21 | 64,75 |
| ↳ scene_hero | 12 | 7,83 | 12 | 9,78 | 35,91 |
| unlocks | 12 | 0,05 | 12 | 0,08 | 0,24 |
| reputation | 12 | 0,54 | 12 | 0,35 | 0,40 |
| empire | 12 | 10,90 | 12 | 11,22 | 11,47 |
| ↳ empire_clear | 12 | 0,25 | 12 | 0,58 | 0,62 |
| ↳ empire_header | 12 | 0,91 | 12 | 1,07 | 1,23 |
| ↳ empire_lines | 12 | 1,68 | 12 | 2,29 | 2,40 |
| ↳ empire_ranking | 12 | 2,35 | 12 | 2,71 | 2,87 |
| ↳ empire_trophies | 12 | 5,68 | 12 | 4,55 | 4,85 |
| subsidiaries | 12 | 1,70 | 12 | 2,11 | 2,26 |
| subsidiary_sectors | 12 | 0,06 | 12 | 0,09 | 0,10 |
| objectives | 12 | 0,33 | 12 | 0,52 | 0,56 |
| executive_brief | 12 | 0,01 | 12 | 0,01 | 0,01 |
| workplace_and_meters | 12 | 0,00 | 12 | 0,00 | 0,00 |
| benefit_controls | 12 | 0,01 | 12 | 0,02 | 0,03 |
| hr_cases | 12 | 0,01 | 12 | 0,01 | 0,01 |
| financial_advice | 12 | 0,43 | 12 | 0,61 | 0,68 |
| division_data | 12 | 0,00 | 12 | 0,00 | 0,00 |
| division_delegation | 12 | 0,46 | 12 | 0,63 | 0,78 |
| policy_controls | 12 | 0,06 | 12 | 0,06 | 0,08 |
| marketing_hint | 12 | 0,04 | 12 | 0,05 | 0,07 |
| leader_choices | 12 | 0,10 | 12 | 0,12 | 0,16 |

### Produits

| Étape | N headless | Moyenne headless | N Pixel | Moyenne Pixel | Max Pixel |
|---|---:|---:|---:|---:|---:|
| industrialization | 12 | 6,35 | 12 | 17,84 | 37,44 |
| ↳ industry_signature | 12 | 0,10 | 12 | 0,24 | 0,34 |
| ↳ industry_jobs | 6 | 0,46 | 6 | 1,10 | 1,25 |
| ↳ industry_fab | 6 | 2,16 | 6 | 5,02 | 5,55 |
| ↳ industry_done | 6 | 8,37 | 6 | 26,19 | 29,17 |
| ↳ industry_foundries | 6 | 1,28 | 6 | 2,46 | 3,40 |
| lifecycle | 12 | 15,97 | 12 | 42,96 | 49,86 |
| ↳ lifecycle_product_list | 12 | 14,17 | 12 | 40,55 | 46,75 |
| ↳ lifecycle_range | 12 | 11,20 | 12 | 33,95 | 38,40 |
| ↳ portfolio | 12 | 11,03 | 12 | 33,62 | 37,94 |
| ↳ lifecycle_details | 12 | 2,67 | 12 | 5,75 | 8,23 |
| ↳ lifecycle_launch_card | 12 | 0,01 | 12 | 0,03 | 0,04 |
| ↳ lifecycle_month_card | 12 | 1,78 | 12 | 2,37 | 3,06 |
| after_sales | 12 | 0,07 | 12 | 0,10 | 0,12 |
| components | — | — | — | — | — |
| board | 12 | 0,01 | 12 | 0,03 | 0,05 |
| scene | 12 | 0,15 | 12 | 0,22 | 0,33 |
| badges | 12 | 0,04 | 12 | 0,06 | 0,08 |
