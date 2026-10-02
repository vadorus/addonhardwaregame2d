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
