# V0.10 — H3 : une équipe plus grande va plus vite et finit mieux

Date : 30/09/2026 — branche `v010/H3-equipe`.

## Constat (sonde 10 ans, `tests/tools/profiles_probe.tscn`)

La nouvelle sonde joue trois profils par le vrai chemin du jeu (projet, décisions, fabrication,
lancement, ventes, recrutement, déménagement, capacité). Avant H3 :

| Profil | Trésorerie à 10 ans | Rang | Développement moyen |
|---|---:|---:|---:|
| Novice (ne recrute pas) | 4,99 M€ | 4 | 11,6 mois |
| Intermédiaire | 20,24 M€ | 2 | 8,3 mois |
| Expert | 28,11 M€ | 1 | 6,7 mois |

L'ancien constat « l'intermédiaire gagne moins que le novice » venait de la sonde elle-même : elle
recrutait surtout en production et déménageait trop tôt. Avec un joueur raisonnable, la cible
« intermédiaire ≥ 2 × novice » est déjà atteinte (×4,1). Il restait deux trous :
- la taille de l'équipe n'améliorait pas la **qualité**, seulement la vitesse ;
- le joueur ne **voyait** nulle part ce que son équipe lui apportait.

## Ce qui change

- **Profondeur d'équipe** (`ResearchManager.team_depth`) : 0 à l'effectif conseillé du marché, 1 à 2,5 ×
  l'effectif conseillé, plus rien au-delà. Elle ajoute jusqu'à **+5 points** à toutes les notes finales
  du CPU, et +2 de plus en fiabilité avec au moins deux validateurs.
- **Étape Budget du Labo** : nouvelle ligne « Votre équipe », par exemple « 5 développeurs (2 conseillés) :
  45 % plus rapide, finition +3 » ou « 1 développeur (10 conseillés) : 60 % plus lent — recrutez dans Équipe ».
- L'estimation de durée du Labo utilise enfin le marché choisi (avant : le marché par défaut).
- QG : Nora n'est plus cachée derrière la carte « Actu & retours » au garage.

## Après H3

| Profil | Trésorerie à 10 ans | Qualité moyenne | Développement moyen |
|---|---:|---:|---:|
| Novice | 4,99 M€ | 67 | 11,6 mois |
| Intermédiaire | 20,56 M€ | 72 | 8,3 mois |
| Expert | 28,71 M€ | 75 | 6,7 mois |

Effet sur l'argent volontairement faible (+1,5 %) : H3 rend l'équipe lisible et utile, sans casser l'équilibrage H1/H2.

## Tests

- `tests/scenarios/TeamDepthScenario.gd` (dans le smoke test) : profondeur, vitesse croissante à
  rendements décroissants, recrutement → projet plus court et mieux fini, textes de la ligne « Votre équipe ».
- smoke, garage, workshop, balance_ceiling : verts.
