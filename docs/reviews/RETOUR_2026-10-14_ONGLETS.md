# Retour de lot — Revue des onglets (14/10/2026)

- **Demande d'Alexandre :** « revoir tous les onglets » (après le Logiciel 2.0).
- **Méthode :** deux parties fabriquées par la sonde (`tests/tools/tabs_probe`, carrière ADAPTÉE jusqu'en 1974 en Standard et jusqu'en 1990 en Accessible, avec des logiciels du studio), puis capture de **chaque onglet et chaque section** en 1212 × 540 (`tests/tools/capture_tabs`), plus le début de partie (`capture_start`). Chaque image a été relue.
- **Branche :** `feat/revue-onglets`.

## Corrigé
| Onglet | Problème vu | Correction |
| --- | --- | --- |
| Presse | Les tests de logiciels étaient mêlés à ceux des CPU (« Tool 16 : comme C3 08 E… ») | Page « Tests de vos logiciels » ; record et courbe par type |
| Presse / Palmarès | « … prend la tête du palmarès devant C3 ADAPTEE » (le joueur devant lui-même) quand la couronne passait d'un de vos CPU à un autre | Relais silencieux (simple alerte), test ajouté |
| Marché | Appels d'offres : liste vide, « 100 » et bouton gris sans appel d'offres | Formulaire caché tant qu'aucun appel n'est ouvert |
| Marché | « 60.4 / 100 », « 7.27% », « 2.05% » | Virgule française (`UI.fr`, `UI.pct`) |
| Labo | Recherche : le détail ouvrait « → 8 µm » en 1990 alors que la tuile annonçait 0,18 µm | Ouvre sur le prochain objectif de la tuile |
| QG | « Sur le marché » montrait le plus vieux CPU (« 0.0 ventes ») | Le meilleur vendeur, ventes en entier |
| Entreprise | « La division CPU est la seule branche jouable » ; carte des branches sur l'ancien logiciel ; pictogramme Mobile manquant | Textes du Logiciel 2.0, ligne Logiciel dans Divisions |
| Produits | Les logiciels n'avaient aucune place hors de l'atelier | Étape « 5 LOGICIELS » (catalogue + accès atelier), étapes sur une ligne |
| Équipe | Recrutement : liste déroulante puis « Nora cherche 3 profils » | Un bouton par métier, un seul appui |
| Tous | Listes déroulantes au menu minuscule, compteurs à petites flèches | Style atelier pour les listes (grandes lignes), boutons − / + autour de chaque compteur (onglets, établi, parcours CPU) |

## Tests
- 38/38 scènes OK (4 scènes de rendu sous xvfb), smoke test OK.
- `complete_layout_test` et `project_brief_world_test` réparés : ils visaient des éléments retirés le 08/10 et terminaient « à 0 » malgré leurs erreurs. Code mort supprimé (`_refresh_world_markers`).

## Reste à faire (repéré, pas encore traité)
- Entreprise : beaucoup de réglages restent des listes (direction de division, avantages salariés, filiales) ; à transformer en cartes comme le studio.
- Marché « Mes ventes » : le choix du CPU par liste (24 CPU en 1990) mériterait une rangée de cartes.
- Les notifications (« Presse — … », « À faire ») couvrent le haut droit de l'écran quelques secondes à chaque onglet.
- **Non testé sur le Pixel.**
