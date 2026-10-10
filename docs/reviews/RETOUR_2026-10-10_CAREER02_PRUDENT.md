# CAREER-02 / HYP-01 — Tester un agent financièrement prudent

**Date :** 10/10/2026. **Base :** `v013/demo-octobre` @ `c1d4f6e`, aucun coefficient du jeu modifié.  
**Nature :** expérience contrôlée sur un **automate de test**, qui ne prouve pas à elle seule que la difficulté Standard est équilibrée.

## Hypothèse

Sur la graine 104729, le parcours Adapté a perdu environ 11 214 € de prime et 5 607 € supplémentaires de salaire mensuel lors d'une embauche en septembre 1972. Avant cette dépense, le solde était ~28 829 €. La baisse à 13 959 € fin septembre précède un déficit mensuel et une faillite au début de 1973.

L'ancien `career_probe.gd::_can_hire()` se contente de vérifier que le dernier résultat mensuel est positif, ou que la caisse couvre 18 fois sa valeur absolue s'il est négatif. **Une seule bonne vente peut donc autoriser une embauche coûteuse sans réserve pour son salaire futur.**

## Expérience sans modifier C3 officiel

Un script `career_prudent_probe.gd` hérite de la sonde figée C3 et surcharge uniquement `_can_hire()`. Il conserve la règle initiale **et exige** que `ExecutiveManager.financial_advice(12000, 5607)` annonce au moins **6 mois de réserve prudente après signature**. Les montants sont des approximations prudentes issues du diagnostic ; la vraie recrue générée peut différer. Aucun changement aux fonctions simulation, vente, produit, save, production, dépenses ni difficulté.

Les résultats de C3 ne doivent pas être écrasés ni présentés comme identiques : seul le **nom du script/rapport** distingue cette expérience. Utiliser **un worktree et un répertoire `build` isolés**, conserver la même graine et vérifier année de faillite, cash et historique de décisions.

## Protocole de validation

1. Import Godot et smoke, puis `res://tests/tools/career_prudent_probe.tscn -- 104729 STANDARD`.
2. Comparer aux résultats exacts du profil C3 officiel à ce SHA (Adapté, échec 02/1973 ; Figée, échec 06/2014).
3. Si prometteur, étendre aux quatre graines et aux deux difficultés sans modifier les trajectoires de référence.
4. Aucun équilibrage global, pas de publication/fusion dans le code de jeu avant validation du joueur et seconde revue.

**Résultats non exécutés au moment de la création : à compléter après test.**
