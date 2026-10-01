# Faits apparus après les deux analyses (pour la synthèse)

Note factuelle de Claude (01/10). Elle ne contient aucun argument pour l'une ou l'autre analyse.

1. **Provenance des captures.** Elles viennent de la branche `v010/I6-petits-defauts` (commit `f605bfe`), pas de `06930b3`.
   - Le libellé « Réduire à 141/mois (gratuit, moins de stock) » vient de ce lot I6. Astra l'avait remarqué à juste titre.
   - Sur `06930b3`, le même cas affichait « Passer à 141/mois (déjà prévu au lancement) ».
2. **Cause du 143 → 141 : maintenant reproduite et corrigée** (commit `ef2be62`, fusionné dans `feature/ui-v09-navigation`).
   - C'est bien le pas du champ numérique. Il touchait aussi le prix (125 € affiché 126 €).
   - Le test `workshop_layout_test` lance la gamme, simule un mois et vérifie chaque modèle en vente. Sans la correction, il échoue avec : `I4 CPU E shows capacity 141 / price 126 instead of 142 / 125`.
   - Ce point n'est donc plus à arbitrer.
3. **Non vérifié** : la remarque d'Astra sur la « contribution » qui omettrait les frais de distributeur (`ProductManager.gd:735-745,802-813`). À contrôler au début de l'implémentation, quelle que soit la décision.
