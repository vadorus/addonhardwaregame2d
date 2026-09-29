# Lot F1 — Vie des rivaux et rachats (29/09, Claude)

Première étape du lot F (« après 2010 : la partie continue »). Ordre validé par Alexandre :
F1 rivaux et rachats → F2 filiales → F3 nouveaux marchés → F4 événements et salon → F5 prestige.

## Mesure de référence (avant F1)

Sonde `tests/tools/campaign_probe.tscn` (commit `0812f4d`) : un fabricant moyen joué de 1971 à 2030
(une génération tous les 3 ans, notes = moyenne des rivaux + 3, plus gros marché ouvert).

- Trésorerie du joueur : 130 M€ en 2010 → 364 M€ en 2030, sans aucun usage.
- Rivaux : trésorerie 1,1 → 2,3 Md€ ; architecture bloquée à 100 dès 2017 ;
  aucun rachat, fusion ni faillite en 60 ans ; un seul entrant (Nexus, 1991).
- Cause : frais fixes d'un rival ≤ 7 000 € + 600 €/génération, R&D ≤ 34 000 €/mois, pour des
  centaines de milliers d'euros de ventes ; un rival à sec était simplement renfloué (90 000 €).

## Ce qui change

Règles dans `scripts/RivalLife.gd`, état sauvegardé dans `MarketManager`.

- **Frais de structure** : 62 % de la marge brute moyenne sur ~2 ans. En temps normal un rival garde
  un tiers de sa marge ; l'excédent au-delà de 8 mois de chiffre d'affaires ressort (dividendes).
- **Générations ratées ou réussies** : à chaque sortie, ~16 % de flop (ventes ×0,55 pendant 18-30 mois,
  donc des pertes) et ~10 % de succès (×1,25). Brèves presse dans les deux cas.
- **Santé** : 8 mois de pertes → « en difficulté » ; dettes > 2 mois de CA → « au bord de la faillite ».
  Visible dans Marché (fiche du rival, ligne « État »).
- **Rachat par le joueur** (carte « Nora : racheter X ? » dans À faire, catégorie RACHAT) :
  - rival en difficulté : 55 % de sa valeur (10 mois de CA + 30 % de sa trésorerie) ;
  - à partir de 1995, rival sain au prix fort (×1,35), tous les 4 ans au plus, si l'argent dort ;
  - effets : ses clients (+25 % de demande sur son marché pendant 2 ans), 40 % de l'écart de
    savoir-faire (architecture, layout, miniaturisation), un concurrent de moins, brève presse ;
  - pas d'offre avant 1978 ni sur une société de moins de 3 ans ; refus → Nora attend 18 mois.
- **Sans le joueur** : un rival en difficulté peut être absorbé par un rival riche (fusion, brève) ;
  insolvable sans repreneur → faillite. Avant 1980 avec 3 rivaux, l'ancien renflouement reste.
- **Entrants** : dès que le marché compte moins de 3 rivaux (2 ans d'écart), et de temps en temps
  après 1985 jusqu'à 5 rivaux. Savoir-faire proche de l'état de l'art, noms fixes, jamais deux fois.
- Nexus Micro (menace « nouvel entrant » du lot M) ne renaît plus après un rachat.

## Mesures après F1 (sonde, même graine)

| | Référence | F1, sonde qui rachète | F1, sonde qui refuse tout |
|---|---|---|---|
| Rachats par le joueur | 0 | 7 (185 M€, 1978-2027) | 0 |
| Fusions / faillites entre rivaux | 0 | 0 (rachetés avant) | 1 fusion (Helix absorbe Quantum, 2011) |
| Entrants | 1 | 8 | 2 |
| Trésorerie moyenne d'un rival en 2030 | 2,3 Md€ | 145 M€ | 137 M€ |
| Trésorerie du joueur 2010 → 2030 | 130 → 364 M€ | 68 → 201 M€ | 132 → 370 M€ |

Critère du plan « l'argent a toujours un usage » : premier usage en place ; F2 à F5 en ajoutent.
Critère « les rivaux ne restent pas figés » : tenu dans les deux modes.

## Tests

- `tests/scenarios/RivalLifeScenario.gd` (dans le smoke test) : flop et pertes, fragilité, offre dans
  À faire, sauvegarde de l'offre, rachat (paiement, retrait, savoir-faire, clients), refus et veille,
  entrant, fusion, faillite d'une jeune société (bug corrigé : elle attendait une offre impossible),
  sauvegarde du journal, ancienne sauvegarde sans données F1.
- Smoke test vert.

## Reste à faire

- F2 : la société rachetée devient une filiale (mandat, revenus, équipe) au lieu de disparaître.
- Vérifier sur le Pixel 10 la lisibilité de la carte RACHAT et de la ligne « État » dans Marché.
