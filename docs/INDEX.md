# Tech Empire — index documentaire

**Mis à jour : 10 octobre 2026**  
**Révision de référence :** `v013/demo-octobre` au commit `c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f`.  
**Objet :** permettre à ChatGPT, Codex et Claude de repartir du même état sans confondre proposition, code, essai PC et essai Pixel.

> Cet index décrit une **photographie datée**, pas une synchronisation automatique. Avant de travailler, lire la branche Git courante, son HEAD et le diff éventuel ; ne jamais présenter cette photographie comme l'état d'un commit ultérieur.

## Ordre de lecture obligatoire pour reprendre le travail

1. [AGENTS.md](../AGENTS.md) — contraintes du dépôt, sécurité, sauvegardes, tests et restrictions du pilote Agents API.
2. [État actuel](ETAT_ACTUEL.md) — état constaté du code, de la démo et des validations.
3. [Décisions](DECISIONS.md) — ce qui est arrêté, proposé ou à arbitrer.
4. [Journal de développement](JOURNAL_DEVELOPPEMENT.md) — travaux datés, fichiers et vérifications.
5. [Passation à Claude](HANDOFF_CLAUDE_2026-10-14.md) — points à relire au retour.
6. [Plan opérationnel](PLAN_CODEX_2026-10-08.md) — dernière liste officiellement déclarée active dans le dépôt ; ses étapes doivent être réconciliées avec les commits réellement fusionnés.
7. Le document spécialisé correspondant à la tâche et les [preuves de tests](reviews/INDEX.md).

## Hiérarchie de vérité

1. **Code réellement présent au commit examiné**, `project.godot`, tests et diff Git : ce qui existe.
2. **Résultat d'une exécution au commit indiqué** : ce qui fonctionne dans le cadre exactement testé.
3. **Règles du projet / décisions explicites de son propriétaire** : ce qui est autorisé.
4. **Plan actif et bible de conception** : ce qu'on veut atteindre.
5. **Rapports datés / anciennes roadmaps** : preuves historiques et propositions, jamais preuve automatique de l'état présent.

Les décisions de conception se lisent d'abord dans [DESIGN_BIBLE.md](DESIGN_BIBLE.md), puis [SIMULATION_PHILOSOPHY.md](SIMULATION_PHILOSOPHY.md), [GAME_DESIGN.md](GAME_DESIGN.md), [CPU_VERTICAL_SLICE.md](CPU_VERTICAL_SLICE.md) et [VISION.md](VISION.md). En cas de contradiction, consigner le conflit dans [DECISIONS.md](DECISIONS.md), ne pas arbitrer tacitement.

## Audit et plan priorisé (10/10)

- [AUD-001 — audit multidisciplinaire sur le HEAD](AUDIT_MULTIDISCIPLINAIRE_2026-10-10.md) — audit **de code + rapports**, pas nouvelle mesure Pixel.
- [Plan priorisé 2026-10-10](PLAN_PRIORISE_2026-10-10.md) — backlog complet avec dépendances, critères et efforts **proposés** ; n'annule pas la phase 1 officiellement figée.

## Première campagne de tests réellement exécutée

- [QA-00 — Godot PC, économie et presse](reviews/RETOUR_2026-10-10_QA00.md), 10/10/2026, commit `c1d4f6e`. Les tests code 0, warnings et défauts mesurés sont séparés ; pas de Pixel ni testeur novice.

## Campagne économique multi-graines

- [CAREER-01 — 24 trajectoires mesurées](reviews/RETOUR_2026-10-10_CAREER01_4SEEDS.md) au `c1d4f6e` ; [issue #84](https://github.com/vadorus/addonhardwaregame2d/issues/84) pour investigation, [issue #85](https://github.com/vadorus/addonhardwaregame2d/issues/85) pour narration.
- [PR #86](https://github.com/vadorus/addonhardwaregame2d/pull/86) : correction du faux SHA des rapports C3, testée sur PC et en attente de relecture/fusion.

## Premier correctif de l'interface financière proposé

- [PR #87 — BUD-01 : prévoir et expliquer le coût d'une embauche](https://github.com/vadorus/addonhardwaregame2d/pull/87) : tests PC PASS, **non fusionné / Pixel non testé**. [Issue #84](https://github.com/vadorus/addonhardwaregame2d/issues/84) documente le cash-flow 1972–1973.

## Nouveaux lots du 10 octobre

- [PR #88 — presse, 100/100 textes distincts](https://github.com/vadorus/addonhardwaregame2d/pull/88), code du journal seulement ; test PC et sauvegarde PASS, reste revue narrative humaine.
- [PR #89 — sonde de carrière prudente](https://github.com/vadorus/addonhardwaregame2d/pull/89), expérience sans changer l'économie : 6 sorties précoces évitées, **12/12 faillites finales** ; vérifier la longévité commerciale et la mesure sectorielle CPU.

## Carte des sujets

| Sujet | Source principale | Preuves / compléments |
| --- | --- | --- |
| Périmètre et règles | `AGENTS.md`, `CPU_VERTICAL_SLICE.md` | `project.godot`, `tests/` |
| État réel et travaux | `ETAT_ACTUEL.md`, `JOURNAL_DEVELOPPEMENT.md` | Git, tests, PR |
| Architecture | `scripts/`, `main.gd` | `AUDIT_ARCHITECTURE_2026-10-08.md` (**daté**) |
| UX et direction visuelle | `UX_ART_DIRECTION.md`, `docs/design/` | `AUDIT_RENDU_2026-10-08.md`, captures et relecture tactile |
| Gameplay et économie | `DESIGN_BIBLE.md`, `CPU_VERTICAL_SLICE.md` | `AUDIT_GAME_DESIGN_2026-10-08.md`, sondes de carrière |
| Narration / immersion | `AI_IMMERSION.md` | `MediaManager.gd`, `MarketVoices.gd`, études de variation **à faire** |
| Android et performances | `BUILD_PC_ANDROID.md` | `reviews/P0_PIXEL_REFERENCE12_COMPLET_2026-10-08.md` et mesures plus récentes |
| Tactile T3 | `ui/TouchTooltip.gd` | `reviews/T3_PIXEL_ACTIONS_2026-10-09.md` ; état Git actuel dans `ETAT_ACTUEL.md` |
| Extensions, DLC | `MONETISATION_2026-10-08.md` (**proposition**) | `scripts/CompanyBranches.gd` et `ui/components/BranchMap.gd` |
| Publication | `PUBLICATION_PLAY_STORE.md` | Vérifier les exigences avant toute action externe |
| Historique | `reviews/`, `ROADMAP_V010.md`, `ROADMAP.md`, `PLAN_V09_V10.md` | À ne pas exécuter comme liste de tâches sans contrôle actuel |
| Prompts de revue IA | `PROMPTS_TECH_EMPIRE.md` | Ajouter le contexte du HEAD courant |

## Règle de maintenance

Tout lot, y compris un correctif de deux lignes, doit avoir un **commit identifiable** et une **entrée de journal** avec tests et limites. Voir [DOC_MAINTENANCE.md](DOC_MAINTENANCE.md). Aucune fusion automatique vers la démo. Les anciennes preuves restent conservées même quand elles sont périmées.

