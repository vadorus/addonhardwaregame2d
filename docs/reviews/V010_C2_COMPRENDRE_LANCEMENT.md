# C2 — Comprendre le lancement

Étape 2 du plan décidé le 01/10/2026 (`docs/design/concurrence/decision.md`). Réalisée par Claude le 01/10 au soir.
Promesse visée : **« Je comprends mes choix. »** Preuves à contrôler par Codex.

## Ce qui a été trouvé

- La cérémonie existait (notes une par une, son, verdict, comparaison au rival et au modèle précédent) : **gardée telle quelle**.
- Le calcul de chaque note était **déterministe mais invisible** : pondérations par type de média (performance, prix,
  fiabilité…), classement au banc d'essai, comparaison au rival et au modèle précédent, puis effet de l'interview.
- **La note de presse ne pèse que peu sur les ventes** (de −12 % à +18 %, `MediaManager.product_media_signal`).
  Ce qui fait vendre : la valeur de la puce **sur son marché** face aux rivaux (`MarketManager.evaluate_product`, poids
  par marché dans `GameData.SEGMENTS`), le prix, l'âge, un rival plus récent, la taille de l'équipe. Rien de cela n'était
  expliqué : une bonne note avec de mauvaises ventes restait un mystère.

## Ce qui a changé

| Fichier | Changement |
|---|---|
| `scripts/MediaManager.gd` | `OUTLET_WEIGHTS` : une seule table de pondérations pour la note **et** son explication ; `review_breakdown()` décompose chaque note exactement (départ 50, critères, classement, overclocking, rival, modèle précédent, interview, bornes) ; chaque test publié garde son explication (`why`, aussi dans la sauvegarde) |
| `scripts/ReviewExplainer.gd` | nouveau : « ce qui a plu / ce qui freine / prochain essai » (moyenne des vrais effets de tous les tests), calcul lisible d'un test, atout et frein par média, « pourquoi ces ventes » (vrais facteurs de la demande), priorités d'un marché (vrais poids) |
| `ui/components/ReviewRevealPanel.gd` | deux colonnes en paysage (tests / verdict et explication) ; ligne « Atout / Frein » sur chaque test ; résumé après le verdict ; bouton « Voir le calcul » ; mode « archive » sans animation ni son ; moyenne écrite à la française (« 4,7/10 ») |
| `ui/components/ProductLifecyclePanel.gd` | fiche du modèle : encadré **« Pourquoi ces ventes »** et bouton **« Revoir les tests de la presse »** |
| `main.gd` | ouverture des tests archivés depuis la fiche (le temps est mis en pause, comme au lancement) |
| `ui/components/CpuDesignStepper.gd` | choix du marché : chaque carte dit ce que le marché regarde **surtout** ; sous la grille, les 3 priorités du marché choisi (poids réels) et sa description |

**La note elle-même ne change pas** : le test recopie l'ancienne formule et compare, pour les 7 types de médias,
4 interviews et 2 classements.

## Preuves

- `tests/scenarios/ReviewExplanationScenario.gd` (dans le smoke test) :
  - pondérations à 100 % pour chaque média ;
  - **note inchangée** (ancienne formule) et **explication qui retombe exactement sur la note**, 56 combinaisons ;
  - **cohérence** : une meilleure fiabilité ne fait jamais baisser la presse spécialisée ;
  - chaque test publié et chaque brève sauvegardée gardent leur explication ; le calcul affiché finit sur la note ;
  - une puce 2,4 fois trop chère : **le prix sort comme frein principal** et le prochain essai parle du prix ;
  - l'écran affiche « Ce qui a plu / Ce qui freine / Prochain essai » et un calcul par média ;
  - la fiche retrouve les tests du modèle et explique ses ventes ; priorités du marché industriel exactes (fiabilité 34 %).
- `smoke_test`, `garage_layout_test`, `workshop_layout_test` (700, 1280 et 1616 px de large), `balance_ceiling_test` : verts.
- Captures au format du Pixel en paysage (1212 × 540) : `C2_captures/notes.jpg`, `calcul.jpg`, `marche.jpg`.

## Ce qui reste à prouver (avec de vrais joueurs)

Les critères de la feuille de route demandent des personnes : **4 novices sur 5** lancent et retrouvent leurs ventes en
moins de 15 minutes sans aide ; **8 testeurs sur 10** expliquent la cause principale de leur verdict. À mesurer pendant
le test fermé (étape C4), avec une question simple après le premier lancement.

## Volontairement pas fait

- Le **carnet de Nora** (historique des lancements, comparaisons entre générations) : la synthèse de Codex le limite
  « aux informations utiles ». Les besoins essentiels sont visibles dès le départ, et chaque produit garde ses tests
  et son explication : on décidera du carnet après les retours du test fermé.
