# C4 — Réutilisation des lignes SalesPortfolio : résultats Pixel 10

**Date : 8 octobre 2026. Statut : correctif terminé et testé, sur branche de relecture distincte.** Aucun changement de la simulation, des sauvegardes, des gros gestionnaires, de C3, C2 ou R1.

## Problème et solution

Le cache de signature complet ne suffisait pas : les textes et montants du portefeuille changent chaque mois, et les anciens boutons étaient donc presque toujours détruits puis recréés.

La nouvelle version de ui/components/SalesPortfolio.gd garde un Button stable par identifiant de produit. Les libellés, prix, ventes et alertes sont actualisés lorsqu'ils changent ; les styles ne sont reconstruits que si le groupe ou la sélection change ; les groupes repliés conservent leurs boutons cachés ; seuls les produits effectivement disparus sont libérés. Les en-têtes et les flèches d'origine sont préservés. La source SalesAdvisor.portfolio() continue de fournir les données à chaque appel, pour conserver une information commerciale à jour.

**Code fonctionnel : commit 91f7049**, suivi d'un ajustement purement visuel des flèches d'en-tête. Le test est tests/sales_portfolio_row_reuse_test.gd.

## Test fonctionnel

- Godot 4.7.2, douze mois simulés sur une copie isolée de la référence : PASS.
- **324 comparaisons d'identité** d'instances de boutons, aucune recréation pour les mêmes produits.
- **35 changements de texte** observés et rendus ; 27 modèles.
- PASS : sélection, changement du nom du modèle, expansion/repli des groupes, conservation des boutons, double activation d'un en-tête.
- PASS : screen_refresh_test, perf_probe_test, perf_probe_integration_test, smoke_test, garage_layout_test, workshop_layout_test, balance_ceiling_test.
- Aucun nouveau champ de sauvegarde.

## Résultats Android — Produits

**Appareil :** Pixel 10 ; cadence plafonnée à 30 FPS ; vitesse x3 ; même scénario de 12 fins de mois ; référence SHA-256 5b839da1ebf8974ee3cf2251bbeb5960047d54feb94e3f73eb2e6a54db4d472d.

Avant = prototype à signature seule de docs/reviews/C4_BRANCHMAP_SALES_AB_PIXEL_2026-10-08.md. Après = même instrumentation P0, avec boutons réutilisables.

| Mesure | Avant | Après |
|---|---:|---:|
| SalesPortfolio.refresh() moyen | 33,50 ms | **2,38 ms** |
| ProductLifecyclePanel.refresh() moyen | 42,58 ms | **12,09 ms** |
| IndustrializationPanel.refresh() moyen | 17,88 ms | 17,51 ms |
| Moyenne des pics de fins de mois | 148,20 ms | **112,23 ms** |
| Pire image | 209,35 ms | **138,44 ms** |
| Fins de mois > 150 ms | 6/12 | **0/12** |
| Fins de mois > 250 ms | 0/12 | 0/12 |

Les deux fonctions sont imbriquées : les temps ne doivent pas être additionnés. Le résultat headless concorde : SalesPortfolio.refresh() passe d'environ 11,03 ms à **3,57 ms** en moyenne sur la référence.

## P0 « après » : six séries terminées

Les six CSV ont un statut OK et la même référence SHA. Les trois séries de 12 fins de mois obtiennent **exactement le même état final** : 5e177b5ae3b08324ede4e9760f53717ad544040e1265d7777a175eed6b42fff8, conforme à la mesure « avant ».

| Écran | Fins de mois | Moyenne des pics | Pire image | Nombre > 150 ms | Nombre > 250 ms |
|---|---:|---:|---:|---:|---:|
| QG x3 | 12/12 | 115,60 ms | 156,04 ms | 1 | 0 |
| Entreprise x3 | 12/12 | 136,98 ms | 327,43 ms | 1 | 1 |
| Produits x3 | 12/12 | **112,23 ms** | **138,44 ms** | **0** | 0 |

**QG, une minute x1 :** 33,356 ms d'intervalle moyen (~29,98 FPS), P95 34,174 ms, P99 34,562 ms ; 3 images > 50 ms et **2 images > 100 ms** (116,61 et 123,30 ms). Elles surviennent aux deux clôtures de mois, vers 23,94 s et 47,95 s ; elles ne sont pas résolues par le changement de SalesPortfolio.

**QG, 30 s en pause :** 33,279 ms d'intervalle moyen, pire image 43,907 ms, aucune image > 100 ms.

**Trois tours des sept onglets :** 21/21 transitions ; aucune ne dépasse 250 ms. Maximum Entreprise 48,66 ms, Produits 22,39 ms, Labo 234,20 ms.

## Premier pic d'Entreprise : ce n'est pas une clôture de mois

Dans la trace temporelle, l'image à **327,431 ms** survient à **0,33 seconde du départ de P0**, avant toute clôture (avril 1992), avec **0 ms de calcul de simulation**. La première vraie clôture intervient à **8,11 secondes**, et son image prend **104,495 ms** (38,018 ms de simulation et 31,246 ms d'UI).

P0 attribue actuellement l'image du premier affichage à son premier lot « mois 1 ». Le dépassement ponctuel de 250 ms ne prouve donc pas une régression de BranchMap au changement de mois. Il faut instrumenter explicitement le temps de première ouverture dans un indicateur séparé sans réécrire les résultats de référence historiques. Les reconstructions mensuelles régulières d'Entreprise ont déjà été fortement améliorées.

## Limites et sécurité

La comparaison est fondée sur des APK de test instrumentés, avec la même sauvegarde et le même appareil. La batterie, le premier affichage et les fluctuations système peuvent varier ; les meilleures preuves sont les moyennes des fonctions et les 12 observations, pas un seul maximum.

L'APK de mesure inclut l'instrumentation provenant de la branche de diagnostic, alors que le commit de correction ne contient que SalesPortfolio et son test. Les mesures ont été enregistrées avant le retour des seuls symboles d'en-tête d'origine ; le code de réutilisation des contrôles n'a pas changé.

Les sauvegardes personnelles tech_empire_save.json et sa copie .bak conservent le SHA-256 468e175cab8bc52cced32c26af49a4106c89912a3be305a13741d4cf0af12b60. La sauvegarde de référence est conservée sur le PC et le Pixel, jamais publiée. Le réglage de veille USB a été rétabli et l'application a été fermée après les mesures.

## Suites — ordre confirmé

1. Relecture et validation de la branche codex/c4-sales-row-reuse ; ne pas fusionner sans validation.
2. Conserver distinct le coût de première ouverture d'Entreprise, et ne pas l'assimiler à une clôture mensuelle.
3. Conserver le protocole de comparaison complet et ses données brutes.
4. Reprendre la phase 1 figée en respectant C3, puis C2, puis R1. La réorganisation des gros scripts reste après la démo.

## Traces brutes

Le dossier c4_sales_row_reuse_2026_10_08_data contient six CSV Pixel (trois écrans x3, QG x1, QG en pause, 21 onglets) et deux CSV headless. Les CSV incluent le commit instrumenté cf031c5e9d4b9eea30e2e41fd3549452d2fdaa12 et le SHA de la référence. Les données « avant » sont conservées dans les dossiers précédents p0_diag_refresh_2026_10_08_data et c4_branchmap_sales_2026_10_08_data.
