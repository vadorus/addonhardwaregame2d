# Thème du moment — le jeu s'habille selon la vraie date

Demande d'Alexandre (02/10/2026, 07 h 49), après avoir joué : les fêtes devaient suivre **le vrai calendrier**,
comme les événements des grands jeux mobiles (Halloween en octobre, puis les fêtes de fin d'année), et Noël devait
avoir de vraies **guirlandes sur les bordures**, pas seulement un sapin et des ballons.

## Ce que fait le jeu

- `scripts/LiveTheme.gd` lit la date du téléphone : **Halloween du 1er au 31 octobre**, **fêtes de fin d'année du
  1er novembre au 6 janvier**. Aucune mise à jour à pousser ; les nouvelles décorations, elles, viendront avec les mises à jour.
- `ui/LiveThemeOverlay.gd`, une couche décorative qui ne capte jamais le doigt :
  - **guirlande lumineuse qui scintille** le long du haut de l'écran, avec des retombées sur les côtés
    (orange et violet pour Halloween, multicolore pour la fin d'année) ; grande sur l'accueil, fine en jeu pour ne
    cacher aucun texte du bandeau ;
  - Halloween : toiles d'araignée dans les coins et citrouilles sur l'accueil, chauves-souris qui passent ;
  - fin d'année : neige et sapin sur l'accueil.
- Accueil : message « Joyeux Halloween ! » / « Joyeuses fêtes ! » et petit air joué une fois par lancement.
- QG : les objets d'Astra du thème réel (citrouilles et toile, sapin) s'ajoutent, quelle que soit la date de la partie.
  Les petites fêtes du calendrier du jeu restent en plus (choix réversible, à confirmer par Alexandre).
- Menu : **« Décorations du moment : oui / non »**, retenu dans les réglages. Sauvegarder et charger passent côte à côte
  pour que le menu tienne toujours sur le téléphone.

## Preuves

- `tests/scenarios/LiveThemeScenario.gd` (dans le smoke test) : 8 dates (2 et 31 octobre, 1er novembre, 24 décembre,
  6 et 7 janvier, juin, septembre), réglage « non » respecté, chaque thème complet (message, air, ampoules, objets),
  guirlande visible en saison et cachée hors saison, couche qui ne capte pas le doigt, neige en fin d'année,
  QG décoré en octobre même si la partie est en mai.
- Les quatre scènes de test neutralisent le thème : leurs résultats ne dépendent jamais du mois réel.
- `smoke_test`, `garage_layout_test`, `workshop_layout_test`, `balance_ceiling_test` : verts.
- Captures (1212 × 540) : `THEME_captures/` — accueil et QG, Halloween et fin d'année.
  Corrigé après la première capture : l'accueil était dessiné par-dessus les décorations (rien ne s'y voyait), et la
  guirlande et les toiles couvraient le nom du jeu et la trésorerie en jeu.

## Suite

- Brief Astra : décorations plus riches par thème (guirlandes dessinées pour les bordures, lumière d'ambiance du QG,
  écran d'accueil décoré), et les vraies animations des personnages (frappe au clavier, marche).
- Autres thèmes possibles plus tard : Pâques, été, anniversaire du jeu.
