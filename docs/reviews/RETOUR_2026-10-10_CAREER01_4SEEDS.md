# CAREER-01 — 24 carrières réellement exécutées, 10/10/2026

**Source testée :** `v013/demo-octobre`, commit **`c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f`** ; Godot 4.7.2 stable sur PC Windows, headless. **Aucun changement économique et aucun essai Pixel.**

## Protocole vérifiable

`<GODOT> --headless --path <WORKTREE> res://tests/tools/career_probe.tscn -- 104729,208877,313133,417401 STANDARD` ; deuxième commande identique avec `ACCESSIBLE`.

Les quatre graines étaient 104729, 208877, 313133, 417401. Les stratégies : FIGEE, ADAPTEE, EN_RETARD, deux difficultés : STANDARD et ACCESSIBLE. **24/24 résultats** ; les deux programmes ont code de sortie **0** et **aucune erreur Godot**.

La copie a été lancée dans `C:/Users/Admin/Documents/TechEmpire-AUD001-20261010` (worktree séparé, détaché au SHA), avec APPDATA/LOCALAPPDATA Godot isolés. Logs exhaustifs locaux : `C:/Users/Admin/Documents/TE_AUD001_logs_20261010/career_multi_standard.log` et `career_multi_accessible.log` ; CSV par graine dans `<WORKTREE>/build/`. **Aucune sauvegarde personnelle ni fichier du Pixel touché.**

**Important :** le script original `career_probe.gd` imprime le SHA historique erroné `eff0871` dans les CSV. L'exactitude du HEAD mesuré est vérifiée par le worktree Git et le programme lancé. Cet **incident de traçabilité** est traité séparément par [PR #86](https://github.com/vadorus/addonhardwaregame2d/pull/86), dont les tests ont réussi, sans altération du jeu.

## STANDARD : 12 faillites sur 12 combinaisons

| Graine | FIGÉE | ADAPTÉE | EN RETARD |
| --- | --- | --- | --- |
| 104729 | 06/2014 | **02/1973** | **02/1973** |
| 208877 | 05/2011 | **02/1973** | **02/1973** |
| 313133 | 07/2013 | 05/1997 | 02/2010 |
| 417401 | 08/2013 | **02/1973** | **02/1973** |

Six trajectoires (ADAPTÉE et EN RETARD pour les graines 104729, 208877, 417401) disparaissent dès **février 1973**. FIGÉE tient beaucoup plus longtemps (2011 à 2014) mais finit en faillite dans les quatre cas.

Sur `104729 / ADAPTEE` : trésorerie fin 1971 = **36 568 €** ; fin 1972 = **2 270 €** ; faillite 02/1973. Le journal des décisions automatiques enregistre un deuxième projet en mai 1972 et une embauche en septembre 1972. **Hypothèse, pas conclusion :** le profil automatisé engage ses dépenses sans préserver une autonomie suffisante. La fonction `career_probe.gd::_can_hire()` utilise la rentabilité récente ; elle ne remplace pas une évaluation intégrale des coûts futurs.

## ACCESSIBLE : 9 survies sur 12, très forte divergence

| Graine | FIGÉE — trésorerie finale | ADAPTÉE — trésorerie finale | EN RETARD |
| --- | ---: | ---: | --- |
| 104729 | 1 030 501 € | **225 187 329 €** | 300 989 € |
| 208877 | 653 374 € | **214 038 491 €** | Faillite 02/2029 |
| 313133 | 810 459 € | **190 699 461 €** | Faillite 04/2030 |
| 417401 | 926 835 € | **199 809 994 €** | Faillite 11/2030 |

**Synthèse : 9/12 survivent jusqu'à fin de sonde.** Les quatre ADAPTÉE survivent avec **190,7 M€ à 225,2 M€**, moyenne **207,4 M€**. Cela indique une divergence forte sous ces stratégies **automatiques** ; ce n'est pas une preuve de richesse accessible à tout joueur.

## Attention au sens du classement

Les **24** cas ont `first_rank1=-1`. Cependant, l'outil appelle `CareerPrestige.player_rank()`, mesure du rang **EMPIRE**. Ce champ ne démontre **rien à lui seul** sur l'objectif plus récent de n°1 **CPU sectoriel**. Il faut une sonde dédiée à la présence commerciale, au rang CPU, aux mois en tête et aux pertes de leadership.

## Décisions de priorisation

- **[Issue #84](https://github.com/vadorus/addonhardwaregame2d/issues/84) — P1 :** observer chaque mois les coûts du développement, salaires, choix des projets et autres engagements ; comparer le profil automatique et une stratégie réellement prudente, plutôt que modifier les coefficients au hasard.
- **P1 :** construire un avertissement clair d'autonomie après toute décision risquée, notamment embauche et démarrage d'un deuxième CPU ; vérifier les calculs et les textes réels visibles.
- **P1 :** mesurer le déséquilibre du long terme Accessible, le poids des ventes et des dépenses proportionnelles ; vérifier les rivalités et l'intérêt du renouvellement.
- **P1 :** créer une **métrique sectorielle CPU** distincte du classement Empire avant de conclure sur la domination.
- **P2 :** intégrer après relecture la [PR #86](https://github.com/vadorus/addonhardwaregame2d/pull/86) corrigeant le faux SHA de sonde, sans modifier les résultats économiques.
- **[Issue #85](https://github.com/vadorus/addonhardwaregame2d/issues/85) :** narration répétitive confirmée indépendamment par QA-00.

**Non prouvé :** cause exacte de la faillite, équilibre pour un joueur humain, gain réel d'un correctif non écrit, n°1 sectoriel, performances Android. Ne pas transformer cet audit en validation globale du jeu.

