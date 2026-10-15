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

## Campagne exécutée sur PC

**Godot 4.7.2**, branche d'expérience au commit initial `ba5d638`, worktree détaché `C:/Users/Admin/Documents/TechEmpire-CAREER02-20261010`, variables personnelles de Godot isolées, aucun Pixel.

Premier import : sortie 0 avec avertissement UID historique à froid. `smoke_test.tscn` : **PASS**, code 0 sans erreur. Sonde prudente 104729 Standard : code 0, aucun message d'erreur ; la prudence transforme les dates de fin de partie **ADAPTÉE 02/1973 → 10/1997** et **EN RETARD 02/1973 → 05/2013**. FIGÉE reste en faillite 06/2014 (la garde n'y a presque pas d'influence).

Le résultat a été répliqué **sur les quatre graines officielles en STANDARD**, soit 12 stratégies et **0 erreur moteur** :

| Graine | FIGÉE | ADAPTÉE — avant → prudent | EN RETARD — avant → prudent |
| --- | --- | --- | --- |
| 104729 | 06/2014 → 06/2014 | **02/1973 → 10/1997** | **02/1973 → 05/2013** |
| 208877 | 05/2011 → 03/2014 | **02/1973 → 10/1997** | **02/1973 → 06/2007** |
| 313133 | 07/2013 → 03/2012 | 05/1997 → 10/2002 | 02/2010 → 05/2013 |
| 417401 | 08/2013 → 08/2013 | **02/1973 → 09/1997** | **02/1973 → 07/2014** |

**Verdict :** 6 faillites initialement en février 1973 sont désormais évitées. **12/12 carrières Standard finissent pourtant toujours par faire faillite** avant la fin de la sonde ; la prudence au recrutement ne suffit donc pas à corriger l'ensemble de l'équilibre, et une trajectoire FIGÉE est même légèrement moins longue. Cela confirme qu'il faut auditer l'après-1990, la demande, les retours commerciaux, les coûts de maintenance et le plafonnement technologique, sans assouplir arbitrairement la difficulté.

**Vérification réellement effectuée** sur un worktree détaché au SHA `2ffa96d` : `tests/career_prudent_hiring_test.tscn` **PASS**, accepte une trésorerie de 160 000 €, refuse un recrutement lorsque la caisse ne compte que 20 000 €, sans aucun changement de trésorerie ni effectif. Godot 4.7.2 : exit 0, 0 erreur moteur. `smoke_test.tscn` PASS, `--quit-after 2` exit 0 ; premier import froid a émis l'avertissement UID historique, deuxième import 0 erreur. Logs `C:/Users/Admin/Documents/TE_CAREER02_regress_logs_20261010/`. L'identifiant UID généré du test a été ajouté à la branche pour stabiliser son chargement.

**Limites :** le test de garde n'a été exécuté que sur PC. Il ne démontre pas qu'une vraie embauche (candidate avec salaire variable) peut sauver le parcours humain, ni que les coûts du jeu doivent changer. Aucun test Pixel, aucune fusion.

**Fichiers locaux de preuve :** `C:/Users/Admin/Documents/TE_CAREER02_logs_20261010/` et CSV de la copie de travail. Ne pas confondre les CSV de cet automate expérimental avec le référentiel gelé C3 ; ils sont conservés dans un autre worktree.
