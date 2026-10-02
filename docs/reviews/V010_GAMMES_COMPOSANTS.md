# V0.10 — Gammes de composants : mémoire, alimentations, boîtiers

Date : 2 octobre 2026. Auteur : Claude (chef développeur). Demande d'Alexandre (2/10, 7 h 56 et 14 h 16) :
« créer des CPU, de la mémoire, des alimentations, des boîtiers… puis des PC, des portables, des consoles »,
et « tu es encore loin d'un vrai jeu qui rivalise avec Game Dev Tycoon, PC Tycoon ou Hardware Tycoon ».

## Ce qui change pour le joueur

Produits a un 4e onglet, **Gammes**. Trois nouvelles familles, chacune avec son marché, ses clients et ses
rivaux, s'ouvrent au fil de l'histoire :

| Famille | Ouverture | Rythme | Rivaux (fictifs) |
|---|---|---|---|
| Mémoire | 1er CPU en vente (ou 1974) | vieillit vite : un modèle tous les ~2 ans | Kairo, Mnemos, Teraxis, Hanseong (1984) |
| Alimentations | 1977 | lent : un bon modèle tient 3 ans | Voltaris, Ampère & Fils, Fortis (1983), Silentium (1996) |
| Boîtiers | 1981 | très lent | Tôlerie Mercier, Bastion (1983), Aerobox (1994), Aurora Design (1998) |

La boucle, à la Game Dev Tycoon mais sur du matériel :

1. **Pour quels clients ?** Chaque segment dit ce qu'il veut (« Gros systèmes et serveurs — veulent :
   Fiabilité, Capacité, Vitesse »). De nouveaux segments naissent : portables (1992), joueurs (1993-1995)…
2. **Quatre réglages de 1 à 5**, en unités de l'époque : « barrette de 256 Ko », « 23 MHz », « 450 W »,
   « rendement 82 % », « Montage sans outils ». 3 = le standard de l'année de sortie. Chaque réglage a un
   effet secondaire nommé (plus de capacité = puces moins fiables ; plus de rendement = moins de bruit).
3. **Fiche d'impact sous chaque « + »** (et sous « − » au-dessus du standard) : ce qui monte (vert), ce qui
   baisse (rouge), la note de presse, les ventes, le coût par unité, les mois en plus.
4. **Prix** : prix cassé, prix du marché ou premium.
5. **Récapitulatif** : chaque qualité face au meilleur rival à la date de sortie, la note probable de la
   presse et ses raisons, coût / prix / marge, ventes estimées, coût du développement et délai de
   rentabilisation.
6. **Sortie** : une fenêtre « Nouveau modèle en vente » avec l'illustration, la note qui monte, les raisons
   (✓ / ✗) et un conseil pour le prochain modèle.
7. **Vie du modèle** : ventes, marge et part du mois ; « Face aux rivaux : en tête / au niveau / dépassé par
   X » ; parts de marché de toute la famille. Les rivaux sortent de nouveaux modèles à leur rythme et
   **ripostent** quand vous dominez leur marché.
8. **Maîtrise** : les deux premiers modèles apprennent le métier (niveaux 4 puis 5) ; ensuite, des
   programmes de maîtrise (6 mois, de plus en plus chers) affinent toute la gamme.
9. **Synergie avec le CPU** : posséder sa propre usine de puces rend la mémoire 12 % moins chère à produire.

Les illustrations sont dessinées et suivent l'époque : puce à pattes avant 1982, barrette ensuite,
dissipateur coloré après 2000 ; alimentation au ventilateur qui tourne ; boîtier beige puis noir à LED bleue.

Captures (1212 × 540) : `docs/reviews/GAMMES_captures/` — `haut`, `atelier`, `recap`, `sortie`, `boitier`.

## Fichiers

- `scripts/ComponentCatalog.gd` (nouveau) : familles, réglages, segments, rivaux, formules pures, unités.
- `scripts/ComponentManager.gd` (nouvel autoload) : ouverture, projets, maîtrise, rivaux, ventes, presse,
  aperçu fidèle, pastilles, sauvegarde.
- `ui/components/ComponentsPanel.gd`, `ComponentArt.gd`, `ComponentRevealPanel.gd` (nouveaux).
- `ui/screens/ProductsScreen.gd` : onglet « 4 GAMMES ».
- `main.gd` : fenêtre de sortie, jamais par-dessus un autre grand moment ; action « status ».
- `scripts/SimulationManager.gd`, `scripts/SaveManager.gd`, `project.godot` : branchements.
- Tests : `tests/scenarios/ComponentRangesScenario.gd` (dans le smoke test),
  `tests/scenarios/ProductCockpitScenario.gd` (4 étapes au lieu de 3).
- Outils : `tests/tools/components_probe` (sonde), `tests/tools/capture_gammes` (captures),
  `tests/tools/career_probe.gd` (deux points d'extension `_end_year` / `_extra_month`, sans effet sur C3).

## Vérifié (réellement exécuté)

- `--import`, `--quit-after 2` : aucune erreur de script.
- `smoke_test` : passe, dont le nouveau scénario Gammes, qui vérifie :
  - ouverture à la bonne date (pas de mémoire en 1971 sans CPU ; mémoire seule en 1974 ; alimentations 1977 ;
    boîtiers 1981) ;
  - unités d'époque (4 Kbit en 1975, 64 Ko en 1982, 4 Go en 2010) ;
  - pastilles d'un cran de capacité (Capacité ▲▲▲, Fiabilité ▼, €/unité +3,1 €, +1 mois) et écart exact
    dans l'aperçu complet (+15 / −5 points, +1 mois) ;
  - **la note annoncée est exactement la note obtenue**, et les ventes estimées sont les ventes du premier
    mois (±2 %), le coût de développement facturé est celui annoncé ;
  - vieillissement, nouveaux modèles des rivaux (le vieux modèle perd plus de la moitié de sa part),
    sauvegarde JSON aller-retour, ancienne sauvegarde sans gammes, retrait, nouvelle partie remise à zéro,
    écran construit et « + » qui agit.
- `garage_layout_test`, `workshop_layout_test`, `balance_ceiling_test` : passent.
- Sonde `components_probe` (stratégie ADAPTÉE de C3, Standard, 1971-2010, graines 104729 et 521657) :

| Graine | Trésorerie 2010 sans gammes | avec gammes (3 familles bien suivies) |
|---|---|---|
| 104729 | 116,9 M€ | 199,5 M€ |
| 521657 | 122,9 M€ | 198,0 M€ |

  Notes de presse du joueur-sonde : 7,7 à 8,5 ; parts : mémoire 10-25 %, alimentations 37-64 %, boîtiers
  17-45 % ; marge annuelle des gammes en 2009 ≈ 11,5 M€ (mémoire 6, alimentations 4,3, boîtiers 1,3).

## Supposé / à vérifier humainement

- **Équilibrage** : les gammes ajoutent ~+65 % de trésorerie en 2010 pour un joueur qui suit les trois
  familles. Le cap des 100 M€ (P1) arrive donc plus tôt (~2003 au lieu de ~2009) pour ce joueur. C'est un
  choix assumé (diversifier doit payer) mais à confirmer en jouant, avec le lot « histoire » de Codex.
- Le marché des boîtiers est petit avant le PC complet (≈ 1 000 unités/mois en 1985) : un premier boîtier
  se rentabilise lentement, l'écran le dit. Il prendra son sens avec l'assemblage de PC (prochain lot).
- Pas encore testé sur le Pixel (lisibilité tactile des « − / + », longueur des pastilles).
- `AGENTS.md` limite encore le périmètre au CPU : cette extension est une demande explicite d'Alexandre.

## Suite prévue

1. **Assemblage de PC** : combiner son CPU + sa mémoire + son alimentation + son boîtier (ou ceux des
   rivaux, achetés plus cher) pour vendre des PC, puis portables et consoles.
2. Joueur sur Pixel, retours d'Alexandre sur la lecture des pastilles.
3. Fusion du lot « histoire vivante » de Codex.
