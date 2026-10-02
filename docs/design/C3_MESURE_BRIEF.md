# Brief Codex — C3 : mesurer la carrière avant de la régler

Étape C3 du plan décidé le 01/10 (`docs/design/concurrence/decision.md`, `docs/ROADMAP_V010.md`) :
**« Je dois encore réfléchir après mes premiers succès. »** Avant de toucher à l'équilibrage, il faut une mesure fiable.
Ta synthèse l'a dit : `profiles_probe` mélange modes et comportements, et `campaign_probe` injecte des produits sans
passer par la conception. Ce lot fournit la mesure de départ. **Aucun changement du jeu lui-même.**

## Qui fait quoi (en parallèle)

| Qui | Lot | Fichiers réservés |
|---|---|---|
| **Codex** | C3-mesure (ce brief) | `tests/tools/career_probe.gd` / `.tscn` (nouveaux), `docs/reviews/V010_C3_MESURE.md` |
| Claude | fiche d'impact des choix techniques | `scripts/`, `ui/`, `tests/scenarios/` (pas tes fichiers) |
| Astra | lot graphique 4 | `assets/` |

Branche : `v010/C3-mesure`, partie de `feature/ui-v09-navigation`. Ne modifie ni `scripts/`, ni `ui/`, ni `main.gd`.
Si la mesure demande un crochet dans le jeu, écris-le dans le rapport : Claude l'ajoutera.

## Ce que doit faire `career_probe`

1. **Deux stratégies jouées par le vrai chemin** (projet → décisions → fabrication → lancement → ventes), comme
   `tests/tools/profiles_probe.gd` (réutilise ses fonctions plutôt que de les recopier) :
   - **FIGÉE** : même marché, même profil de conception, prix de départ jamais modifié, n'embauche que pour remplacer,
     relance la suite de sa gamme quand elle vieillit, ne réagit à rien ;
   - **ADAPTÉE** : suit les conseils du jeu (`SalesAdvisor`, Nora), change de marché quand un rival la dépasse,
     ajuste le prix, embauche, déménage, oriente ses équipes R&D. Chaque décision est notée avec sa raison.
2. **Même mode pour les deux** : STANDARD, puis une passe ACCESSIBLE.
3. **6 conditions de départ reproductibles** (graines fixées) : mêmes conditions pour les deux stratégies.
4. **Durée** : 1971 → 2010, puis poursuite jusqu'à 2030 (mode libre), sans blocage.
5. **Relevé annuel** (fichier CSV dans `build/`, non versionné) : trésorerie, chiffre d'affaires, marge, part de marché
   par marché, rang mondial, demande perdue, décisions prises, rivaux devant.

## Ce qu'on veut savoir (le rapport `docs/reviews/V010_C3_MESURE.md`, 150 lignes max)

- Sur les 6 conditions, combien de fois ADAPTÉE bat FIGÉE en marge cumulée (critère de passage : au moins 4 sur 6) ?
- **Les années où plus rien ne compte** : la trésorerie monte sans qu'aucune décision change le résultat. Lesquelles,
  et pour quelle stratégie ?
- À partir de quand chaque stratégie est n°1 mondiale, et si elle le reste sans rien faire.
- Les blocages éventuels (partie qui ne peut plus avancer, erreur), avec le moyen de les reproduire.
- Ce que tu recommanderais de régler en premier (sans le faire), chiffres à l'appui.

Chaque chiffre dit d'où il vient (graine, mode, commit). Lancement attendu :
`godot --headless --path . res://tests/tools/career_probe.tscn -- [graines] [mode]`.
