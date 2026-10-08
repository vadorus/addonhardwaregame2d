# Audit d'architecture et de performances — 08/10/2026

Base : `v013/demo-octobre` après `7901b64`.

Moteur : Godot 4.7.2, **100 % GDScript** (aucun C#, aucun C++). Les questions de ramasse-miettes .NET ne s'appliquent donc pas. GDScript compte les références : pas de pause de ramasse-miettes, mais chaque objet ou dictionnaire créé puis jeté a un coût direct.

## Méthode

Tout a été mesuré sur une partie jouée automatiquement pendant 7 ans (1971 → 1978, 15 CPU en vente), sous Linux x86 :

- `build/tmp/perf*.gd` : sondes non versionnées, à recréer au besoin ;
- `Performance.OBJECT_*` pour compter les objets et les nœuds orphelins ;
- chronométrage de chaque gestionnaire de fin de mois et de chaque écran.

Le rendu de ce conteneur est logiciel (llvmpipe). Le temps d'image affiché ici n'a donc **aucune valeur** pour le Pixel. Seuls les temps de calcul GDScript sont comparables, et un téléphone ARM sera 2 à 4 fois plus lent.

## Résumé

**Points forts**
- La simulation est rapide et déterministe : **14 ms par mois** sans interface, dont 15 ms pour `ProductManager`, le plus lourd.
- Aucun fil de calcul, donc aucun problème de concurrence.
- Les sauvegardes sont écrites de façon atomique (fichier temporaire puis sauvegarde de secours).
- Pas de fuite de nœuds : 0 orphelin, et le nombre de nœuds reste stable après 20 reconstructions d'écran.
- Les managers en autoload sont des modules de données purs, testables sans interface.

**Points faibles**
- L'interface reconstruit ses écrans en entier : elle détruit puis recrée ses nœuds (61 `queue_free` dans `ui/`).
- `main.gd` (4 008 lignes) mélange construction de l'interface, routage des actions et formulaires hérités.
- 26 singletons s'appellent directement entre eux.

**Risques par plateforme**
- **Android** : le mois de jeu tombe sur une image ; à vitesse ×3, chaque reconstruction coûteuse se voit. Plusieurs nœuds se redessinent à chaque image, ce qui use la batterie.
- **PC / Steam Deck** : pas de navigation à la manette (pas d'actions `InputMap` d'interface, focus non géré).

## Vulnérabilités et goulots, par gravité

| # | Gravité | Constat (mesuré) | État |
|---|---|---|---|
| 1 | **Élevée** | À chaque signal de simulation, l'interface reconstruisait **tous les onglets, même cachés**, et plusieurs signaux (`research_changed`, `contracts_changed`, `cases_changed`…) le faisaient **de façon synchrone**, plusieurs fois par mois. Fin de mois en 1978 : **984 ms** avec l'interface, contre 14 ms sans. `_refresh_all` : **561 ms**. | **Corrigé** : 59 ms et 25 ms |
| 2 | **Élevée** | Un écran *visible* se reconstruit en entier : Entreprise **145 ms**, Produits **77 ms**, Marché 32 ms, rien qu'en GDScript sur PC. Sur le Pixel, cela fait un à-coup visible à chaque fin de mois quand cet onglet est ouvert. | Proposé (lot P2) |
| 3 | Moyenne | Des animations dessinées « à la main » se redessinent à chaque image (`Portrait`, `CrewMember`, `CpuBench`, `ProjectVisual`, `GarageLife`…). `Portrait` le faisait **même caché**. Le mode basse consommation (`low_processor_mode`) n'est pas utilisé. | `Portrait` corrigé ; le reste est proposé (P3) |
| 4 | Moyenne | `main._process` interroge à chaque image si une décision bloque le temps. `cpu_pending_directive` copie en profondeur un dictionnaire, et le texte de date est reformaté à chaque image. | Proposé (P3) |
| 5 | Moyenne | 248 `duplicate(true)` dans `scripts/`, souvent dans des accesseurs appelés par l'interface : des copies profondes pour simplement lire. | Proposé (P4) |
| 6 | Moyenne | Couplage fort : `main.gd` concentre 54 appels de rafraîchissement directs et tout le routage des actions ; les écrans lisent et modifient les managers directement. | Proposé (P4) |
| 7 | Faible | La sauvegarde transforme tout l'état en JSON d'un seul bloc, sur le fil principal. C'est acceptable aujourd'hui, mais à surveiller quand l'état grossira (10 à 15 divisions). | Proposé (P5) |
| 8 | Faible | Le tactile et la souris sont testés à la main dans 4 fichiers (`NotificationFeed`, `GarageHub`, `CrewMember`, `main`). Il n'y a pas de routeur d'entrées, ni de focus clavier/manette pour Steam. | Proposé (P5) |
| 9 | Faible | Quatre anciens tests échouent déjà avant ce travail : `complete_layout_test`, `project_brief_world_test`, `r1_visual_test`, `r2_visual_test`. Les deux derniers ont besoin d'un rendu réel. Ils ne font pas partie de la CI. | À réécrire ou retirer |

Pas de multithreading à ajouter : 14 ms par mois de simulation ne le justifient pas, et le jeu doit rester déterministe.

## Correctif appliqué (1)

Fichier `main.gd` :

- `_refresh_screen(screen, method)` reconstruit l'écran s'il est affiché. Sinon, il le note dans `_stale_screens`.
- `_flush_stale_screens()` est branché sur `tabs.tab_changed` : l'écran en retard se reconstruit **une fois**, quand il apparaît.
- `_request_refresh_part(part)` / `_flush_refresh_parts()` : les signaux qui reconstruisaient de façon synchrone sont regroupés (une reconstruction par image au plus). Cela concerne la recherche, les fournisseurs, les contrats, le SAV, l'actualité et les candidats.
- `_refresh_research()` passe par `_refresh_research_now()` quand le Labo est visible.
- Hors de l'arbre de scène (tests unitaires), le comportement reste immédiat.

Fichier `ui/Portrait.gd` : l'animation s'arrête quand le portrait est caché ou quand les animations sont réduites.

| Mesure, partie de 7 ans | Avant | Après |
|---|---|---|
| Fin de mois avec l'interface ouverte | 984 ms (max 1 383) | **59 ms** (max 93) |
| 84 mois joués avec l'interface | 777 ms / mois | **56 ms / mois** |
| `_refresh_all` sur le QG | 561 ms | **25 ms** |
| Nœuds orphelins | 0 | 0 |

Test : `tests/screen_refresh_test.tscn`. Il vérifie :

- qu'un onglet caché est marqué « en retard » ;
- que l'onglet visible est reconstruit tout de suite ;
- que 3 signaux de la même image donnent 1 seule demande ;
- qu'afficher l'onglet le reconstruit.

Non-régression : smoke, branding, mise en page du garage et de l'atelier, plafonds d'équilibrage, parcours CPU, expérience complète, cockpit, gameplay R1, sauvegarde, aperçu logiciel. Les 4 anciens tests du point 9 donnent le même nombre d'erreurs avant et après.

## Plan proposé, sans casser la démo

- **P2 (après la démo, prioritaire)** : réutiliser les nœuds au lieu de tout reconstruire, d'abord dans `CompanyScreen` puis dans `ProductsScreen`.
  - On garde un réservoir de lignes par liste (`RowPool` : `acquire()` / `release_all()`) et on ne met à jour que les textes et les valeurs.
  - Objectif : moins de 10 ms par reconstruction sur PC.
  - Test : le nombre de nœuds et le temps restent stables après 20 reconstructions.
- **P3** : animations économes.
  - Un seul minuteur partagé à 15–20 Hz pour les petites animations dessinées, au lieu de `queue_redraw()` à chaque image.
  - `OS.low_processor_usage_mode = true` quand le temps est en pause ou qu'un menu est ouvert.
  - Option « 30 images/s » dans les réglages pour Android.
  - La vérification des décisions bloquantes passe sur le signal de jour de `TimeManager` au lieu de chaque image.
- **P4** : découpler.
  - Un contrôleur par onglet extrait de `main.gd` (routage des actions, rafraîchissements).
  - Des accesseurs en lecture seule sans `duplicate(true)` quand l'appelant ne modifie rien.
- **P5** : avant Steam et les nombreuses divisions.
  - Un `InputRouter` unique : actions `ui_*` avec focus pour la manette et le Steam Deck, et le tactile traduit en un seul endroit.
  - Une sauvegarde préparée sur le fil principal (copie de l'état) puis écrite par `WorkerThreadPool`, avec un test d'intégrité.

## À vérifier humainement

- Une mesure sur le Pixel avec le profileur de Godot (débogage à distance) : temps d'image réel, fin de mois à ×3, onglet Entreprise ouvert.
- Le ressenti : plus d'à-coup en fin de mois sur le QG ; un léger à-coup peut rester sur Entreprise et Produits tant que P2 n'est pas fait.
