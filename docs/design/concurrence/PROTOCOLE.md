# Protocole — étude croisée « Tech Empire face à ses concurrents »

Même méthode que le 25/09 (économie du garage), I5 (cockpit de vente) et la monétisation :
deux analyses indépendantes, une synthèse, puis Alexandre décide.

## Qui fait quoi

| Rôle | Qui | Fichier | Branche |
|---|---|---|---|
| Coordinateur, synthèse | **Codex** | `synthese.md` | `v010/concu-synthese` |
| Analyse 1 | **Astra** | `analyse-astra.md` | `v010/concu-analyse-astra` (ou fichier remis à Alexandre) |
| Analyse 2 | **Claude** | `analyse-claude.md` | `v010/concu-analyse-claude` |
| Décision | **Alexandre** | `decision.md` (ou un message à Claude) | — |
| Réalisation | **Claude** (code) + **Astra** (graphismes) | lots du plan décidé | `v010/<lot>` |

## Les règles

1. **Chacun travaille seul.** On ne lit pas l'analyse de l'autre avant d'avoir écrit la sienne.
2. **Personne ne touche au code du jeu** pendant l'étude. Seuls les fichiers de ce dossier changent.
3. Pas de commit sur `feature/ui-v09-navigation` ni sur `master` pendant l'étude.
4. Un chiffre avancé dit d'où il vient : code (fichier:ligne), sonde, source web citée, ou supposition.
5. On répond aux 9 questions du brief, 250 lignes maximum.

## Les étapes

1. **Phase 1, analyses** : Astra et Claude écrivent chacun la leur.
2. **Phase 2, synthèse (Codex)** :
   - les accords (acquis) ;
   - chaque désaccord avec le pour et le contre, sans trancher trop vite ;
   - si un désaccord porte sur un fait (note Steam, prix, règle Google Play), une vérification à la source, citée ;
   - la recommandation de Codex, à part ;
   - **5 questions maximum** pour Alexandre, en langage simple.
3. **Phase 3, décision** : Alexandre tranche. Claude met à jour `docs/ROADMAP_V010.md` avec les lots retenus et commence.

---

## Message à coller à Codex (phase 1, lancement)

> Tu coordonnes une étude croisée sur Tech Empire : « faire de Tech Empire le meilleur de son genre face à PC Tycoon 2,
> Game Dev Tycoon et les autres ». Dépôt `vadorus/addonhardwaregame2d`, branche `v010/concu-brief`.
> Lis `docs/design/concurrence/BRIEF.md` et `PROTOCOLE.md`. Transmets le brief à Astra pour qu'elle écrive `analyse-astra.md`.
> Claude a déjà poussé la sienne sur `v010/concu-analyse-claude` : **ne la montre pas à Astra** avant qu'elle ait rendu la sienne.
> Ne modifie pas le code du jeu.

## Message à coller à Astra (phase 1)

> Étude indépendante sur Tech Empire, dépôt `vadorus/addonhardwaregame2d`, branche `v010/concu-brief`.
> Lis `docs/design/concurrence/BRIEF.md`. Réponds aux 9 questions dans `docs/design/concurrence/analyse-astra.md`,
> 250 lignes maximum. Tu peux jouer au jeu et lire le code, mais **ne modifie aucun fichier du jeu**, et ne lis pas
> la branche `v010/concu-analyse-claude` avant d'avoir fini. Pousse sur `v010/concu-analyse-astra` (ou rends le fichier à Alexandre).

## Message à coller à Codex (phase 2, synthèse)

> Les deux analyses sont prêtes : `analyse-astra.md` (branche `v010/concu-analyse-astra`) et `analyse-claude.md`
> (branche `v010/concu-analyse-claude`). Écris `docs/design/concurrence/synthese.md` selon la phase 2 de `PROTOCOLE.md` :
> accords, désaccords avec le pour et le contre, vérification à la source si un fait est en jeu, ta recommandation à part,
> puis 5 questions maximum pour Alexandre. Pousse sur `v010/concu-synthese`. Ne modifie pas le code du jeu.
