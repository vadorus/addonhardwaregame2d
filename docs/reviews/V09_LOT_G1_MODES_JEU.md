# Lot G1 — Modes Accessible / Standard / Simulation

## But
Transformer l'ancienne « difficulté » en vrais préréglages d'expérience, sans retirer aucune mécanique.
Le joueur choisit surtout le niveau d'accompagnement et la quantité de complexité montrée au départ.

## Modes
- **Accessible** : Nora très présente, laboratoire en Essentiel, délégation conseillée, économie plus tolérante.
- **Standard** : accompagnement contextuel, interface progressive, équilibre de référence.
- **Simulation** : Nora discrète, laboratoire en Expert dès le départ, direction directe, économie et IA plus exigeantes.

Dans les trois modes, le joueur peut ouvrir tous les réglages, changer la profondeur du laboratoire et prendre lui-même les décisions.

## Compatibilité
- L'ancien identifiant `REALISTIC` est migré automatiquement vers `SIMULATION` au chargement.
- Les coûts unitaires physiques de production et de SAV restent identiques : le mode Simulation ne triche pas sur les statistiques.
- Les sauvegardes Standard/Accessible restent inchangées.

## Validation
- `DifficultyScenario.gd` vérifie les trois profils, les écarts économiques et l'IA concurrente.
- Il vérifie aussi Nora (`GUIDED / CONTEXTUAL / MINIMAL`), la profondeur du labo (`ESSENTIAL / EXPERT`) et la migration `REALISTIC -> SIMULATION`.
- Smoke complet Godot 4.7.2 : vert le 30/09/2026.
