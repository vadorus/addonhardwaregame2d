# V0.10 / K4 — Le calendrier commercial : des périodes de l'année qui comptent

Idée d'Alexandre (01/10) : « des bonus ou des événements liés à la période ».

## Ce qui change dans le jeu (`scripts/SeasonalCalendar.gd`)

**Les ventes suivent le rythme de l'année**, comme dans la réalité.

| Mois | Période | Grand public | Clients pros |
|---|---|---|---|
| Janvier | Après les fêtes | −10 % | −3 % |
| Août | Vacances d'été | −8 % | −12 % |
| Septembre | La rentrée | +8 % | +3 % |
| Novembre | Avant les fêtes | +10 % | = |
| Décembre | Fêtes de fin d'année | **+18 %** | **+10 %** (budgets de fin d'année) |

- Grand public : calculatrices, amateurs, PC de maison, jeu, mobile. Pros : embarqué, industrie, science, bureautique, stations, serveurs, centres de données.
- **Sur une année, ça s'équilibre** (moyenne de 1,00) : c'est du rythme, pas un bonus caché.
- Les prévisions de lancement restent sur la moyenne de l'année.
- **Nora prévient à l'avance** : à la fin d'octobre, elle annonce les fêtes et conseille de vérifier la capacité ; à la fin de juillet, les vacances ; etc.
- Le QG affiche la période en cours sur la pancarte (« Fêtes de fin d'année »…) quand il n'y a pas d'événement plus important.
- **En décembre, Nora propose la fête de fin d'année de l'équipe** (le « ! » au-dessus d'elle au QG) :

  | Choix | Coût | Moral |
  |---|---|---|
  | Une vraie fête ! | 300 € par personne | +8 |
  | Un pot sympa | 60 € par personne | +3 |
  | Pas cette année | 0 € | −2 |

  Le moral joue sur la qualité du travail de chacun (formule de compétence d'équipe). Une fois par an, seulement en décembre.

## Équilibre (banc 10 ans, mêmes bots qu'avant)

| Profil | Avant | Après |
|---|---|---|
| Novice | 5,12 M€ | 5,12 M€ |
| Intermédiaire | 22,32 M€ | 22,35 M€ |
| Expert | 28,75 M€ | 31,09 M€ (+8 %) |

L'expert, qui suit la demande, profite des pics. Ça récompense l'anticipation sans rien changer pour les autres.

## Tests

- `SeasonalCalendarScenario` vérifie :
  - le rythme équilibré sur 12 mois ;
  - Noël plus fort, janvier plus faible ;
  - des pros plus lents en août et plus dépensiers en décembre ;
  - les 5 périodes nommées ;
  - la fête : seulement en décembre, coût débité, moral en hausse, une fois par an.
- `ProductionCapacityScenario` se place en avril, un mois neutre, pour garder ses chiffres exacts.
- smoke, workshop_layout, garage_layout et balance_ceiling : OK.
