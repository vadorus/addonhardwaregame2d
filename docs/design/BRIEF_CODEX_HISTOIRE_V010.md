# Brief Codex — « Une histoire vivante » (V0.10, chantier C3/P2 élargi)

Date : 2 octobre 2026. Chef de projet : Alexandre. Chef développeur : Claude. Exécution de ce lot : Codex.

## Pourquoi ce lot

Retour d'Alexandre (2/10, 14 h 16) : on est « encore loin » d'un jeu qui rivalise avec Game Dev Tycoon,
PC Tycoon 2 ou Hardware Tycoon. Les derniers lots ont surtout corrigé et équilibré. Ta propre mesure C3
l'a montré : **environ une année sur cinq sans aucune décision après 1985**, et **le joueur ne finit jamais
n°1 mondial** (rang 5-6). Une partie de tycoon vit de ses moments : une crise à traverser, un rival qui
attaque, une norme qui change tout, la course au n°1. C'est ce que ce lot doit apporter.

En parallèle, Claude ajoute de nouvelles familles de produits (mémoire, alimentations, boîtiers, puis
assemblage de PC). **Ne touche pas à ces fichiers** (voir « Périmètre »).

## Objectifs

### 1. Frise historique 1971-2010 (`scripts/HistoryTimeline.gd`, nouveau)

Une vingtaine d'événements datés, inspirés de l'histoire réelle mais avec des noms fictifs, qui modifient
vraiment le marché pendant 6 à 24 mois. Exemples (à affiner) :

- 1973-74 choc pétrolier : demande en baisse, coûts en hausse ;
- 1977 « la trinité » des micro-ordinateurs grand public : boom du segment foyer ;
- 1981 le grand constructeur lance son PC : la micro pro explose, une norme s'impose ;
- 1985 guerre des prix de la mémoire venue d'Asie : prix cassés ;
- 1987 krach boursier : levées de fonds et rachats plus chers ou moins chers ;
- 1993-95 multimédia, CD-ROM, Internet grand public ;
- 1999-2001 bulle Internet puis éclatement ;
- 2004 la course aux GHz s'arrête, place au multicœur ;
- 2007 smartphone ; 2008 crise financière.

Chaque événement : une annonce lisible (titre, deux phrases, ce que ça change en chiffres simples), des
effets mesurables via les multiplicateurs existants (`MarketManager`, `LateGameEvents` est le modèle à
suivre), et **au moins un choix** pour le joueur quand c'est pertinent (ex. krach : racheter un rival
affaibli à prix cassé, ou garder sa trésorerie). Réutiliser `CeoDecisionPanel` / `Interactions` / Nora
plutôt que créer un nouvel écran.

### 2. Plus d'année sans décision

Mesure de base : ta sonde `career_probe` (6 graines, 3 stratégies). Cible : **0 année sans décision
significative** entre 1975 et 2010 sur les 18 carrières, sans inonder le joueur (au plus une décision
majeure tous les 3-4 mois en moyenne). Les événements de la frise y contribuent ; complète si besoin.

### 3. P2 : la course au n°1 mondial

Constat C3 : le rang finit 5-6, jamais 1. Il faut qu'un joueur qui joue bien (stratégie ADAPTÉE, mode
Standard) puisse **devenir n°1 entre 1995 et 2010**, et qu'un joueur moyen termine dans le top 3-4.

- Comprendre d'abord pourquoi (score de `CareerPrestige.global_ranking`, croissance des rivaux,
  plafond `_player_portfolio_share_cap`…), le documenter, puis corriger.
- Rendre la course visible : annonce quand on gagne ou perd une place, rival « ennemi juré » nommé,
  écart au n°1 lisible (« il vous manque X M€ de chiffre d'affaires »).

### 4. Crochet de mesure (ta demande de C3)

Journaliser les décisions refusées faute de trésorerie et les épisodes SalesAdvisor actionnables, pour
que la sonde les compte.

## Périmètre

- Branche : `v010/C3-histoire`, partie de `feature/ui-v09-navigation` à jour.
- **Ne pas modifier** : `scripts/ComponentCatalog.gd`, `scripts/ComponentManager.gd`,
  `ui/components/ComponentsPanel.gd`, `ui/screens/ProductsScreen.gd` (chantier de Claude).
- `scripts/SimulationManager.gd`, `scripts/SaveManager.gd`, `project.godot`, `tests/smoke_test.gd` :
  modifications **minimales et localisées** (une ligne d'appel, une entrée d'état, un scénario ajouté en
  fin de liste), pour que la fusion reste simple.
- Sauvegardes : toute nouvelle donnée a une valeur par défaut et une migration explicite ; une ancienne
  partie se charge sans erreur.
- Textes en français, phrases courtes, pas de jargon. Noms d'entreprises fictifs.

## Validation

1. `godot --headless --path . --import`, `--quit-after 2`, `res://tests/smoke_test.tscn` verts.
2. Nouveau scénario déterministe dans `tests/smoke_test.gd` (événement déclenché à sa date, effet
   appliqué puis retiré, choix enregistré, sauvegarde/chargement).
3. Sonde `career_probe` avant/après : années sans décision, rang final, trésorerie 2010 par stratégie.
4. Rapport dans `docs/reviews/V010_C3_HISTOIRE.md` : ce qui est mesuré, ce qui est supposé, limites.

Commit et push sur ta branche ; Claude relit et fusionne.
