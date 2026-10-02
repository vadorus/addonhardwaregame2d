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

## Quand les décisions cessent de peser — STANDARD

Après 1979, ADAPTÉE a 65 années-graines sans aucune décision et pourtant une marge annuelle moyenne de **59,1 M€**,
contre **37,4 M€** sur 247 années-graines avec décisions (6 graines / STANDARD / eff0871).
EN RETARD : **56,9 M€** sur 91 années-graines sans décision contre **40,8 M€** sur 221 années-graines actives
(6 graines / STANDARD / eff0871). La croissance devient donc largement passive une fois le moteur de ventes lancé.

Années sans décision + marge positive communes aux 6 graines :
- ADAPTÉE : **2002, 2006, 2010, 2014, 2018, 2022, 2025, 2026, 2029, 2030** ;
- EN RETARD : **2001, 2002, 2005, 2006, 2009, 2013, 2016, 2017, 2020, 2021, 2024, 2025, 2028** ;
- FIGÉE : **1982, 1996, 2000, 2004, 2008, 2012, 2021, 2025, 2029**
(6 graines / STANDARD / eff0871).

## ACCESSIBLE — confirmation

| Source (graine / mode / commit) | FIGÉE marge cumulée 2030 | ADAPTÉE | EN RETARD | Trésorerie 1990 A / R |
|---|---:|---:|---:|---:|
| 104729 / ACCESSIBLE / eff0871 | 11,19 M€ | 2 600,16 M€ | 3 120,68 M€ | 490,0 / 514,6 M€ |
| 208877 / ACCESSIBLE / eff0871 | 12,05 M€ | 2 594,01 M€ | 3 177,56 M€ | 499,0 / 526,0 M€ |
| 313133 / ACCESSIBLE / eff0871 | 12,45 M€ | 2 600,59 M€ | 3 158,62 M€ | 496,3 / 522,7 M€ |
| 417401 / ACCESSIBLE / eff0871 | 11,71 M€ | 2 604,46 M€ | 3 153,33 M€ | 486,9 / 516,2 M€ |
| 521657 / ACCESSIBLE / eff0871 | 12,17 M€ | 2 641,79 M€ | 3 180,78 M€ | 493,3 / 518,6 M€ |
| 625919 / ACCESSIBLE / eff0871 | 11,71 M€ | 2 613,30 M€ | 3 179,94 M€ | 490,2 / 524,4 M€ |

ADAPTÉE bat FIGÉE **6/6**, mais EN RETARD bat ADAPTÉE **6/6** avec **+20,0 à +22,5 %** de marge cumulée
(6 graines / ACCESSIBLE / eff0871). Moyennes : 2 609,1 M€ contre 3 161,8 M€.
La trésorerie dépasse **100 M€ dès 1981 dans 6/6 graines** pour A et R ; le proxy financier cesse de contraindre
au plus tard en **1978 dans 12/12 runs A/R** (1977 sur certaines graines ; 6 graines / ACCESSIBLE / eff0871).

Rang mondial : seul 521657 atteint n°1, pour ADAPTÉE et EN RETARD en **1981**, puis les deux retombent hors n°1 en **1983** ;
FIGÉE n'est jamais n°1 et les cinq autres graines A/R non plus (521657 / ACCESSIBLE / eff0871 ; autres graines / même source).
Donc aucune stratégie ne reste n°1 sans agir.

Aucun `BLOCKER`, aucune faillite et aucune erreur Godot sur les 18 runs ACCESSIBLE ; bilan total : **36/36 carrières jusqu'en 2030**
(6 graines × 3 stratégies × 2 modes / eff0871).

## Plateau ACCESSIBLE et limites de mesure

Après 1978, ADAPTÉE gagne en moyenne **59,5 M€/an sans décision** contre **44,8 M€/an avec décisions** ;
EN RETARD **71,6 M€ sans décision** contre **56,7 M€ avec décisions** (6 graines / ACCESSIBLE / eff0871).
Années sans décision + marge positive communes aux 6 graines :
- ADAPTÉE : **2001, 2004, 2005, 2008, 2009, 2012, 2013, 2016, 2017, 2020, 2021, 2024, 2025, 2028** ;
- EN RETARD : **2000, 2001, 2004, 2008, 2012, 2016, 2026, 2030**
(6 graines / ACCESSIBLE / eff0871). Le mode facile accentue donc encore la carrière passive.

Limite importante : **0 action `SalesAdvisor`** est enregistrée dans les 24 runs ADAPTÉE/EN RETARD des deux modes
(6 graines × 2 stratégies × 2 modes / eff0871). Le code consulte bien `SalesAdvisor`, mais ces conditions ne déclenchent
aucun conseil actionnable de prix/capacité/promotion ; la couverture « ajuste le prix » n'est donc pas démontrée par C3.

Le « cash non contraignant » (1979 STANDARD ; au plus tard 1978 ACCESSIBLE) est un **proxy annuel** fondé sur les seuils
financiers explicites du probe et une marge annuelle positive jusqu'en 2030. Pour prouver le mois exact, crochet souhaité :
journaliser toute décision candidate refusée pour trésorerie avec `action`, `cash requis`, `cash disponible` ; idem pour compter
les épisodes SalesAdvisor actionnables. Aucun crochet n'a été ajouté dans ce lot, conformément au brief.

## Ce qu'il faut régler en premier — sans le faire ici

**P0 — rendre le progrès technique économiquement utile.** En STANDARD, EN RETARD finit avec **+5,9 à +11,9 %** de marge
face à ADAPTÉE tout en restant 10 µm/4 bits ; ADAPTÉE finit pourtant à 250–350 nm + Multicœur
(6 graines / STANDARD / eff0871). CA cumulé moyen quasi identique : 3 733,3 M€ R contre 3 729,5 M€ A,
mais dépenses 1 368,1 M€ R contre 1 547,9 M€ A : l'ancien procédé économise ~179,8 M€ sans vraie pénalité de demande.
En ACCESSIBLE le défaut empire : **+20,0 à +22,5 %**, avec CA moyen 4 378,8 M€ R contre 3 888,3 M€ A
et dépenses 1 216,9 M€ R contre 1 279,2 M€ A (6 graines / ACCESSIBLE / eff0871).
À régler d'abord : avantage réel des procédés/architectures modernes et/ou obsolescence commerciale des anciens, puis leurs coûts.

Cela confirme directement le constat d'impact **#4** (gravure plus fine non récompensée) et rend critique le **#1** :
une architecture 4 bits reste commercialement viable jusqu'en 2030 alors que les axes Vitesse/Énergie/Fiabilité ne nourrissent aucun calcul.
Les constats **#2 Robuste**, **#3 fréquence sans enveloppe** et **#5 R&D Fiabilité** ne sont pas isolés par C3 : ne pas prétendre les valider ici.
Ils doivent être testés/réglés après P0, idéalement par comparaisons contrôlées à marché, équipe et procédé identiques.

**P1 — recréer une contrainte après le premier succès.** Proxy cash libre dès 1979 STANDARD et ≤1978 ACCESSIBLE ;
100 M€ dès 1983 / 1981 (6 graines par mode / eff0871), puis les années sans décision rapportent davantage en moyenne.
Il faut ensuite régler coûts de croissance, investissements et risques tardifs pour que l'argent redevienne un arbitrage.

**P2 — revoir la progression mondiale.** Malgré 2,1–3,2 Md€ de marge cumulée, les stratégies finissent rang 4–6 selon la graine ;
les rares n°1 sont temporaires (313133/625919 STANDARD ; 521657 ACCESSIBLE / eff0871). La carrière économique et le rang divergent trop.
