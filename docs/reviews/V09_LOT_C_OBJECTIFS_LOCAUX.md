# Lot C — objectifs de Nora et paliers de locaux (29/09)

But (plan `docs/PLAN_V09_V10.md`) : le joueur sait toujours quoi viser, et le décor raconte sa progression.

## Objectifs de Nora

Nouveau système `Objectives` (`scripts/ObjectivesManager.gd`), sauvegardé avec la partie.
Trois pistes, un objectif en cours par piste, chacun avec sa progression et sa récompense :

| Piste | Parcours |
| --- | --- |
| Produit | 1er CPU lancé → 1 000 CPU vendus → 8/10 dans la presse → 3e génération → 100 000 CPU → n°1 du benchmark → 1 million de CPU |
| Croissance | 5 personnes → 1 M€ de trésorerie → 10 personnes → déménager dans l'atelier → siège technique → 10 M€ de CA sur un an → campus R&D → 100 M€ de CA |
| Marché | 1er client pro livré → deux marchés → marché des PC → propre usine → quatre marchés → serveurs |

Récompenses : de l'argent au début (15 000 à 60 000 €), puis réputation (innovation, prestige,
clientèle pro) et notoriété. Le déménagement dans l'atelier arrive après les 10 personnes, quand le
garage (8 places) devient vraiment trop petit.

Où les voir :
- **QG**, dans la carte de Nora : « OBJECTIFS • n/21 atteints » et les trois en cours avec leur
  progression (« 542 k€ / 1 M€ », « 4/5 », « 21 k / 100 k »). Une info-bulle donne le conseil et la
  récompense. Ils n'apparaissent qu'une fois le premier projet lancé : la toute première minute reste
  « une seule action ».
- **Entreprise › Aperçu** : le parcours complet, ce qui est fait (✓) et ce qui est en cours.
- **À la réussite** : carte verte « Objectif atteint : … — +50 000 € » et un son.

Partie d'Alexandre (1985) : au chargement, ce qui est déjà accompli est coché sans récompense
(16 objectifs sur 21). Il reste : vendre 1 million de CPU (247 000), 10 M€ de CA sur un an (5,4 M€),
entrer sur le marché des serveurs.

## Paliers de locaux

Les quatre locaux existants (garage aménagé 8 places, atelier + bureaux 16, siège technique 36,
campus R&D 80) ont chacun leur décor au QG ; ils sont maintenant trois étapes de la piste
Croissance. La vision prévoit 6 à 8 paliers : les paliers supplémentaires (PME, grand groupe,
empire) demandent de nouveaux décors dessinés, à prévoir avec la direction artistique.

## Mesures (partie neuve jouée automatiquement, 48 mois)

| Joueur | Objectifs atteints | Déménagement |
| --- | --- | --- |
| Passif (3 personnes, un seul marché) | 4 | non |
| Suit les objectifs (embauche jusqu'à 10, déménage à 9) | 9 | oui, atelier avant 1975 |

Critère du plan (≥ 6 objectifs et 1 déménagement en 48 mois pour un joueur actif) : ✅.

## Tests

`ObjectivesScenario` : trois objectifs au départ (P1, G1, M1), progression et récompense affichées,
5 personnes → G1 atteint et payé une seule fois, la piste passe à l'objectif suivant, sauvegarde,
ancienne partie cochée sans récompense et reprise au bon endroit du parcours.
