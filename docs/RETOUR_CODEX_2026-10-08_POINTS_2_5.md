# Transmission à Claude — points 2 à 5 de la démo CPU

## Base et périmètre

- Demande : section 5 de `docs/REPRISE_CODEX_2026-10-07.md`, points 2 à 5, un commit par point.
- Branche : `v013/demo-octobre`, base exacte `237f16a` (lot 0 Software déjà terminé).
- Copie utilisée exclusivement : `C:\Users\Admin\Documents\TechEmpire-v031-validation`.
- Aucun développement d'autre secteur, aucune construction APK/AAB, aucune installation Pixel.
- Auteur Git choisi pour ces commits : `basso867 <basso867@gmail.com>`. Identité passée à la commande, sans modifier la configuration Git globale.
- La demande utilisateur renouvelée de récupérer, committer et pousser a été traitée comme dérogation aux interdictions Git du pilote. Les autres restrictions sont conservées.

## Commits à relire

| Point | Commit | Sujet |
|---|---|---|
| 2 | `9eb7fd0` | Annoncer les effets réels des événements restants |
| 3 | `63251c8` | Simplifier les pages Entreprise au garage |
| 4 | `1adca5b` | Rendre la demande sensible aux prix et lisible |
| 5 | Le commit contenant ce document | Unifier les scènes Labo/Presse avec SceneHeader |

La référence exacte du dernier commit et le résultat du push sont consignés après exécution dans `.agent-output/report.md`, rapport local non versionné.

## Point 2 — événements restants

### Comportement

1. **Contrats d'études avant le premier lancement.** `GarageBusiness.study_window_open()` ne dépend plus de `MarketManager.b2b_offers_open()`. Les études peuvent donc aider à financer le premier CPU. Les garde-fous existants restent appliqués : entreprise créée, au moins deux mois d'activité, petite équipe et une seule offre client en attente. Les contrats de vente B2B conservent leur propre condition de lancement.
2. **Pénalités B2B visibles avant signature.** Le dialogue client, la liste des contrats et les appels d'offres annoncent le taux sur la valeur des unités manquantes et la perte de réputation proportionnelle : clientèle pro jusqu'à −1,5 et fiabilité jusqu'à −0,8 par mois. Le calcul financier est partagé avec `contract_shortfall_penalty()`. Les anciens contrats sans taux explicite gardent le défaut historique de 8 % ; les taux particuliers des appels d'offres restent respectés.
3. **Capacité après rappel.** Les deux panneaux SAV annoncent la baisse durable de 28 %, la baisse thermique supplémentaire de 12 % lorsqu'elle s'applique, ainsi que les capacités avant/après de chaque produit concerné. `recall_capacity()` sert à l'aperçu et à l'application. Le calcul antérieur et ses arrondis sont conservés : 1 000 → 720, ou 1 000 → 633 en thermique.
4. **Arbitrages ACK_ONLY.** Un signalement sans mesure automatique affiche un seul accusé de réception dans le panneau PDG et dans Entreprise. Les arbitrages possédant une vraie mesure gardent leurs deux choix. Même un appel ancien avec `apply_recommendation=true` ne classe plus un ACK_ONLY comme une mesure appliquée.
5. **Salons selon l'époque.** Le plancher de la présentation passe progressivement de 15 000 € en 1985 à 250 000 € en 2010 ; celui de la fuite de 6 000 € à 100 000 €. Interpolation linéaire entre ces années, planchers bornés en dehors. La part liée au chiffre d'affaires reste de 75 % ou 30 % du CA mensuel récent, si elle est plus élevée. Le coût affiché et le débit emploient toujours `expo_cost()`.

### Fichiers

- `scripts/AfterSalesManager.gd`, `DivisionManager.gd`, `GarageBusinessManager.gd`, `Interactions.gd`, `LateGameEvents.gd`, `MarketManager.gd`.
- `ui/components/AfterSalesPanel.gd`, `CeoDecisionPanel.gd`, `TenderPanel.gd` et `ui/screens/CompanyScreen.gd`.
- Nouveau `tests/scenarios/RemainingEventsScenario.gd` (+ UID), adaptation de `GarageBusinessScenario.gd`, branchement dans `tests/smoke_test.gd`.

### Vérification spécifique

Le test vérifie l'annonce et le débit d'une ancienne offre à 8 %, un taux explicite de 18 %, les rappels thermique et standard, l'absence de faux choix ACK_ONLY, les coûts de salon et le débit effectif. Le scénario GarageBusiness vérifie l'offre d'étude avant toute vente, son avance, sa charge sur le développement et son paiement final.

## Point 3 — Entreprise au garage

- Le stade garage correspond à `ExecutiveManager.workplace.tier == 0`.
- Divisions et Groupe restent masqués à ce stade, même avec beaucoup de trésorerie ou des déverrouillages provenant d'une ancienne sauvegarde.
- Les raccourcis de navigation vers ces deux pages reviennent à Aperçu au garage.
- La page Budgets reste accessible selon ses conditions existantes. Son intitulé devient « Budgets » ; la délégation des départements y est masquée au garage. La délégation de division est également masquée.
- Aucun mandat, déverrouillage historique ou état de division n'est supprimé. Après un déménagement, les conditions de déverrouillage existantes et les drapeaux sauvegardés redeviennent applicables.
- Les nouveaux déverrouillages Divisions/Groupe exigent désormais des locaux hors garage, pour éviter des annonces prématurées.

Fichiers : `scripts/ExecutiveManager.gd`, `ui/screens/CompanyScreen.gd`, nouveau `tests/scenarios/GarageCompanyScenario.gd` (+ UID), `tests/smoke_test.gd`.

Le test couvre une ancienne sauvegarde avec pages déjà déverrouillées, les raccourcis, les budgets sans délégation, la sortie du garage et le retour à un état garage alors que Groupe était sélectionné. Les règles de simulation de la délégation existante ne sont pas réécrites : c'est une simplification de présentation.

## Point 4 — élasticité des prix

### Courbe du facteur direct de demande

| Prix / référence du segment | Facteur |
|---:|---:|
| ≤ 0,75 | 1,12 |
| 0,90 | 1,10 |
| 1,00 | 1,00 |
| 1,12 | 0,80 |
| 1,25 | 0,55 |
| 1,50 | 0,28 |
| 2,00 | 0,06 |
| 3,00 | 0,008 |
| 5,00 | 0,0005 |

Interpolation linéaire continue entre les repères ; après 5×, décroissance continue par `0.0005 * (5 / ratio)^2`. Cette courbe remplace les ruptures à 0,75 et 5× et pénalise davantage les prix élevés. Le score produit, la notoriété, la concurrence, les effets de presse, le vieillissement et la capacité continuent d'agir : ces facteurs ne sont pas une promesse de variation identique des ventes finales.

- `product_price_ratio()` et les seuils de prix sont partagés avec `MarketVoices`.
- Le panneau « Vaut-il son prix ? » affiche l'effet direct du prix sur la demande avant capacité.
- Le plancher artificiel de 5 % dans la conversion du portefeuille est supprimé ; le plafond commercial conserve les autres garde-fous.
- Nora conserve l'absence de baisse conseillée lorsque toute la capacité se vend déjà.
- Le prix minimal conseillé inclut désormais la part du distributeur ; pas de faux conseil de hausse lorsqu'une baisse pour un produit trop cher serait impossible sans sacrifier la marge minimale.
- La perte annoncée par puce lors d'une baisse utilise la marge nette du revendeur, plutôt que le seul écart de prix public.

Fichiers : `scripts/MarketManager.gd`, `scripts/MarketVoices.gd`, `ui/components/MarketBoard.gd`, nouveau `tests/scenarios/PriceElasticityScenario.gd` (+ UID), `tests/smoke_test.gd`.

Le test balaie la monotonie et la continuité, puis trois difficultés × trois époques (1971/1985/2000) × deux segments (calculatrices/embarqué). Il compare prévision et demande mensuelle, vérifie l'absence de mutation, la cohérence de la jauge, l'effet d'une hausse sur plusieurs modèles, la capacité saturée et les coûts trop élevés. Ce n'est pas un playtest de l'équilibrage de toutes les carrières sur trente ans.

## Point 5 — Labo et Presse sur SceneHeader

- Suppression de la construction dupliquée de l'en-tête dans `LabBoard` et `PressBoard`.
- `SceneHeader` accepte des réglages de présentation optionnels conservant les dimensions et styles de chaque scène. Ses valeurs par défaut restent celles des autres onglets.
- Ajout d'une barre de progression optionnelle, de `set_progress()`, `hero_value_text()` et `hero_caption_text()`.
- Le Labo conserve les actions Concevoir, Voir le projet, Choisir maintenant et Décider, ainsi que la progression de phase et les poses de Camille.
- La Presse conserve les notes, le texte de comparaison et les poses de Nora. Retour au bon état vide lorsque les critiques disparaissent.
- Correction découverte pendant la validation : `_clipping()` créait un `HFlowContainer` non attaché si aucune explication technique n'existait. Il est maintenant libéré. Cela élimine les avertissements de ressources de ce cas sans changer le rendu.

Fichiers : `ui/components/SceneHeader.gd`, `LabBoard.gd`, `PressBoard.gd`, adaptation de `tests/scenarios/LabBoardScenario.gd` et `PressBoardScenario.gd`, nouveau `SharedScenesScenario.gd` (+ UID), `tests/smoke_test.gd` et ce document.

Le nouveau scénario vérifie le composant réellement utilisé, les clics et signaux pour les quatre situations du Labo, la barre de progression, plusieurs notes/portraits de Presse et le retour à l'état vide.

## Validation réellement effectuée

Moteur local : **Godot 4.7.2 stable officiel, ed1daf0bf**, Windows, sans .NET.

Pour chacun des points 2 à 5 : import, démarrage de la scène principale, smoke test, puis les quatre contrôles de `.github/workflows/godot-ci.yml` :

```text
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . res://tests/smoke_test.tscn
godot --headless --path . --script res://tests/branding_config_test.gd
godot --headless --path . res://tests/garage_layout_test.tscn
godot --headless --path . res://tests/workshop_layout_test.tscn
godot --headless --path . res://tests/balance_ceiling_test.tscn
```

Les nouveaux scénarios sont intégrés au smoke test. Vérification des logs pour `ERROR:`, `SCRIPT ERROR`, `Parse Error` et `Failed to load script`, et pas seulement de la dernière ligne de succès.

**Résultat final : tous ces contrôles passent, sans ligne d'erreur.** Le smoke conserve deux avertissements préexistants de dimensionnement/ancres dans `MomentsScenario` et `LiveThemeScenario`. Les avertissements de fuite de ressources provenant des coupures de presse sans détail ont disparu après le correctif du point 5.

Vérifications supplémentaires : exécution ciblée de `PriceElasticityScenario` et `SharedScenesScenario`, puis `software_choice_preview_test.tscn` et `cpu_journey_test.tscn`. Ces deux derniers passent sans erreur. `git diff --check` exécuté.

Les commandes GitHub Actions elles-mêmes n'ont pas été lancées depuis GitHub ; leurs contrôles Godot ont été reproduits localement. Les scripts Agents API de la CI n'ont pas été modifiés ni revalidés.

### Captures rendues et relues

Rendu réel OpenGL 3.3 sur Intel UHD 630, fenêtres de 1280×720, son désactivé via `--audio-driver Dummy`, sauvegardes de test désactivées :

- Point 2 : panneau de rappel thermique, capacité 1 000 → 633 visible.
- Point 3 : Entreprise et Budgets au garage, sans pastilles Divisions/Groupe.
- Point 4 : Marché, effet du prix et conseil de Nora chiffrés.
- Point 5 : Labo libre, Presse vide, Presse avec deux générations. Les trois PNG avant/après sont identiques en SHA-256.

Captures et scripts de capture locaux dans `.agent-output/`, non versionnés. Les captures sont des scènes préparées pour la vérification, pas des captures de la partie Pixel.

### Échecs rencontrés puis résolus

- Premier import sandboxé : accès refusé aux répertoires de configuration Godot ; relancé avec les permissions nécessaires.
- Premier rendu : périphérique audio WASAPI indisponible ; relancé avec le pilote Dummy.
- Premier test d'élasticité : tolérance trop stricte sur le flottant 1,12 stocké dans un Vector2 ; tolérance corrigée et scénario puis smoke relancés.
- Premier test des scènes : attendait « 3,0/10 » alors que le format historique affiche « 3/10 » ; attendu corrigé.
- Diagnostic des fuites de Presse : origine identifiée et corrigée comme indiqué au point 5.

## Sauvegardes et fichiers locaux

Aucun nouveau champ de sauvegarde n'est ajouté. Les défauts historiques des contrats sont conservés. Les déverrouillages et mandats ne sont pas effacés. Aucun changement de schéma ne requiert donc une nouvelle migration ; le comportement économique corrigé s'applique aussi aux anciennes parties.

Cette copie était initialement sur `feature/ui-ux-v0.3.1` à `4aff040`, sans le commit `237f16a`. La branche demandée a été récupérée directement depuis `origin`, sans fusion de l'ancienne branche, ni changement du remote. La création du suivi automatique était refusée par la configuration limitée du clone ; la branche locale a été créée depuis la référence récupérée avec `--no-track`.

Douze UID non suivis entraient en collision avec la branche cible : sauvegardés dans `.agent-output/pre-reprise-uids/` avant le changement de branche. Dix autres UID non suivis préexistants sont restés en place et exclus des commits. Aucun autre worktree, notamment `TechEmpire-dev`, n'a été modifié.

## À vérifier par Claude et Alexandre

1. Relire les quatre commits dans l'ordre et relancer les contrôles sur la branche à jour.
2. Juger en jeu la sévérité des nouveaux prix et les nouveaux coûts de salon : valeurs choisies et testées automatiquement, mais plaisir/équilibre de long terme non validés par un humain.
3. Vérifier la lisibilité sur le Pixel, notamment les avertissements SAV/B2B longs et la page Budgets. Les tests de formats paysage ne remplacent pas l'essai physique.
4. Confirmer le choix de masquer Divisions/Groupe jusqu'au déménagement tout en conservant Budgets et les mandats anciens en simulation.
5. Sauvegarder la partie du Pixel avant toute future installation. Aucun APK/AAB n'est fourni par cette tâche, aucune publication Play Console n'est effectuée.

Le rapport local final distingue l'état effectivement vérifié des limitations et consigne le résultat réel du push.
