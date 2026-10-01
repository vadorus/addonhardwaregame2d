# Protocole — étude croisée du lot I5

On reprend la méthode du 25/09 (étude de l'économie du garage) : deux analyses indépendantes, une synthèse, puis Alexandre décide.

## Qui fait quoi

| Rôle | Qui | Fichier |
|---|---|---|
| Coordinateur, synthèse | **Codex** | `synthese.md` |
| Analyse 1 | **Astra** | `analyse-astra.md` |
| Analyse 2 | **Claude** | `analyse-claude.md` |
| Décision | **Alexandre** | `decision.md` (ou un message à Claude) |
| Réalisation du lot | **Claude** | code + tests, après la décision |

## Les règles

1. **Chacun travaille seul.** On ne lit pas l'analyse de l'autre avant d'avoir écrit la sienne.
2. **Personne ne touche au code du jeu** pendant l'étude. Seuls les fichiers de ce dossier changent.
3. Pas de commit sur `feature/ui-v09-navigation` ni sur `master`. Chaque analyse va sur sa propre branche :
   - Claude : `v010/I5-analyse-claude`, écrite et poussée **avant** de connaître celle d'Astra ;
   - Astra : `v010/I5-analyse-astra`, ou le fichier remis à Alexandre / Codex.
4. Un chiffre avancé doit dire d'où il vient : code (fichier:ligne), test, simulation ou supposition.
5. On répond aux 8 questions du brief, dans le format demandé (250 lignes maximum).

## Les étapes

1. **Phase 1, analyses** : Astra et Claude écrivent leur analyse chacun de son côté.
2. **Phase 2, synthèse (Codex)** : Codex lit les deux analyses et écrit `synthese.md` :
   - ce sur quoi les deux sont d'accord, qui est donc acquis ;
   - chaque désaccord, avec le pour et le contre de chaque position, sans prendre parti trop vite ;
   - si un désaccord porte sur un chiffre, une simulation pour trancher. Le banc `tests/tools/profiles_probe.tscn` simule 10 ans avec des joueurs novice, intermédiaire et expert ;
   - la recommandation de Codex, clairement séparée ;
   - la liste courte des décisions à prendre par Alexandre (5 au maximum), formulées en questions simples.
3. **Phase 3, décision** : Alexandre tranche. Claude réalise le lot I5 selon la décision, avec tests et captures, puis l'installe sur le Pixel.

---

## Message à coller à Codex (phase 1, lancement)

> Tu coordonnes une étude croisée sur Tech Empire, comme pour l'économie du garage le 25/09.
> Dépôt `vadorus/addonhardwaregame2d`, branche `v010/I5-brief`.
> Lis `docs/design/I5-cockpit/BRIEF.md` et `PROTOCOLE.md`. Transmets le brief à Astra pour qu'elle écrive `analyse-astra.md`.
> Claude a déjà poussé la sienne sur `v010/I5-analyse-claude` : **ne la montre pas à Astra** avant qu'elle ait rendu la sienne.
> Ne modifie pas le code du jeu.

## Message à coller à Astra (phase 1)

> Étude indépendante sur Tech Empire, dépôt `vadorus/addonhardwaregame2d`, branche `v010/I5-brief`.
> Lis `docs/design/I5-cockpit/BRIEF.md` (et les captures dans `captures/`). Réponds aux 8 questions en écrivant `docs/design/I5-cockpit/analyse-astra.md`, au format demandé, 250 lignes maximum.
> Tu peux lire le code pour vérifier, mais **ne modifie aucun fichier du jeu**, et ne lis pas les autres analyses (branche `v010/I5-analyse-claude`) avant d'avoir fini.
> Pousse ton fichier sur une branche `v010/I5-analyse-astra` (ou rends-le à Alexandre).

## Message à coller à Codex (phase 2, synthèse)

> Les deux analyses sont prêtes : `analyse-astra.md` (branche `v010/I5-analyse-astra`) et `analyse-claude.md` (branche `v010/I5-analyse-claude`).
> Écris `docs/design/I5-cockpit/synthese.md` selon la phase 2 de `PROTOCOLE.md` : accords, désaccords avec le pour et le contre de chacun, simulation si un chiffre est en jeu, ta recommandation à part, puis 5 questions maximum pour Alexandre.
> Pousse-la sur `v010/I5-synthese`. Ne modifie pas le code du jeu.
