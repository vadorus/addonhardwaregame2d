# V0.10 — C3 mesure de carrière

Base mesurée : `eff0871` (`feature/ui-v09-navigation`). Probe : branche `v010/C3-mesure`.
Aucun réglage du jeu dans ce lot : uniquement `tests/tools/career_probe.*` et ce rapport.

## Méthode

- 3 stratégies : **FIGÉE**, **ADAPTÉE**, **EN RETARD**.
- Modes séparés : **STANDARD**, puis **ACCESSIBLE**.
- 6 graines communes : `104729`, `208877`, `313133`, `417401`, `521657`, `625919`.
- Horizon : 1971 → 2010, puis poursuite libre jusqu'en 2030.
- Chemin réel : projet → décisions → fabrication → lancement → ventes ; propositions CPU via le vrai `CpuGenerationPlanner`.
- EN RETARD suit ADAPTÉE mais force toute la carrière à **10 µm + architecture 4 bits**.
- CSV annuels non versionnés dans `build/` : trésorerie, CA, marge annuelle/cumulée, parts de marché, rang, demande perdue, décisions, rivaux devant, gravure, architecture.

Pour chaque chiffre ci-dessous, la source est donnée sous la forme **graine / mode / commit eff0871**.
« Trésorerie non contraignante » désigne ici le premier point après lequel les garde-fous financiers du probe
(embauche/runway, changement de marché, déménagement, Concept R&D, réponse aux menaces) ne bloquent plus une action déclenchée ;
ce n'est donc pas un seuil arbitraire de richesse.

## STANDARD — résultat principal

| Source (graine / mode / commit) | FIGÉE marge 2030 | ADAPTÉE marge 2030 | EN RETARD marge 2030 | Trésorerie 1990 A / R |
|---|---:|---:|---:|---:|
| 104729 / STANDARD / eff0871 | 6,54 M€ | 2 190,37 M€ | 2 324,22 M€ | 329,8 / 351,2 M€ |
| 208877 / STANDARD / eff0871 | 7,14 M€ | 2 222,53 M€ | 2 353,87 M€ | 337,5 / 364,6 M€ |
| 313133 / STANDARD / eff0871 | 6,58 M€ | 2 164,25 M€ | 2 378,91 M€ | 334,0 / 362,7 M€ |
| 417401 / STANDARD / eff0871 | 6,36 M€ | 2 150,00 M€ | 2 370,36 M€ | 318,1 / 357,6 M€ |
| 521657 / STANDARD / eff0871 | 6,75 M€ | 2 230,95 M€ | 2 379,02 M€ | 332,9 / 353,5 M€ |
| 625919 / STANDARD / eff0871 | 7,40 M€ | 2 131,20 M€ | 2 384,67 M€ | 330,3 / 357,8 M€ |

**Critère C3 : ADAPTÉE bat FIGÉE 6/6** (6 graines / STANDARD / eff0871), donc le minimum 4/6 passe largement.
Mais **EN RETARD bat ADAPTÉE 6/6** : moyenne de marge cumulée 2 365,2 M€ contre 2 181,5 M€
(6 graines / STANDARD / eff0871). C'est un défaut d'équilibrage majeur : rester à 10 µm + 4 bits est plus rentable.

La trésorerie d'ADAPTÉE et EN RETARD dépasse **100 M€ dès 1983 dans 6/6 graines** ; selon les garde-fous financiers
réellement utilisés par le probe, elle cesse d'être contraignante dès **1979 dans 6/6 graines**
(6 graines / STANDARD / eff0871). Le constat initial « >100 M€ vers 1985 » était donc conservateur.

Rang mondial : FIGÉE n'atteint jamais la 1re place. ADAPTÉE ne l'atteint que sur 625919 en 1987 et la reperd ;
EN RETARD ne l'atteint que sur 313133 en 1983 et la reperd. Toutes les autres combinaisons restent hors n°1
(sources respectives : graines citées / STANDARD / eff0871). **Aucune stratégie ne devient n°1 puis ne le reste sans agir.**

Aucun `BLOCKER`, aucune faillite et aucune erreur Godot sur les 18 runs STANDARD (6 graines / STANDARD / eff0871).
