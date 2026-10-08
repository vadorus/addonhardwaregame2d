# Tech Empire — P0 sur Pixel 10 : mesures « avant » (PARTIEL)

Date : 8 octobre 2026. APK témoin debug 0.12.2-test3, commit 0469df0dfd4fcfef8fbf3962140fd84db7d11b26, avant C3/C2/R1 (C1 déjà présent).
Cadence fixée à 30 FPS ; Pixel 10 connecté à home par ADB, batterie 84 % lors de la préparation.
Copie de référence de Nova Technologies, avril 1992, SHA-256 468e175cab8bc52cced32c26af49a4106c89912a3be305a13741d4cf0af12b60.
Toutes les mesures se déroulent sur une copie isolée, jamais la partie personnelle.

## QG en pause — 30 secondes — PASS

- Intervalle moyen : 33,269 ms ; P50 : 33,350 ms ; P95 : 34,200 ms ; P99 : 34,493 ms.
- Pire image : 36,657 ms ; images >50 ms : 0 ; images >100 ms : 0.
- Temps de processus moyen Godot : 14,486 ms.
- CSV : build/pixel_saves/20261008_211018/P0_AVANT_0469df0_QG_repos_30s.csv.

## Trois tours des sept onglets — PASS

| Onglet | Passage 1 (ms) | Passage 2 (ms) | Passage 3 (ms) |
|---|---:|---:|---:|
| QG | 10,928 | 12,014 | 21,367 |
| Entreprise | **253,184** | 10,336 | 22,558 |
| Équipe | 97,201 | 16,407 | 36,105 |
| Labo | 219,653 | 19,011 | 28,468 |
| Produits | 114,410 | 16,308 | 23,986 |
| Marché | 134,488 | 13,304 | 13,114 |
| Presse | 195,397 | 17,566 | 17,003 |

Le premier affichage d'Entreprise dépasse très légèrement 250 ms, mais les deux affichages suivants sont rapides. Faire un diagnostic ciblé avant d'envisager C4 ; une création à froid est une hypothèse, non un fait démontré.
CSV : build/pixel_saves/20261008_211018/P0_AVANT_0469df0_onglets.csv.
Les 21 transitions sont présentes et le CSV contient le SHA exact du commit témoin.

## QG x3 — 12 fins de mois — INTERROMPU (NE COMPTE PAS)

P0 s'est arrêté, comme prévu, à cause d'une décision en attente au mois 4. L'outil n'a pris aucune décision. Trois fins de mois ont été observées avant la pause :

| Fin de mois | Pire image | Simulation | UI | Résiduel |
|---|---:|---:|---:|---:|
| 1 | 129,156 ms | 61,129 ms | 34,603 ms | 33,424 ms |
| 2 | 118,546 ms | 44,759 ms | 41,199 ms | 32,588 ms |
| 3 | 157,311 ms | 48,032 ms | 75,890 ms | 33,389 ms |

Ces trois observations ne permettent pas de vérifier les seuils établis sur douze mois complets. Elles ne justifient aucune refonte.
CSV : build/pixel_saves/20261008_211018/P0_AVANT_0469df0_QG_x3_INTERROMPUE.csv.

## Sécurité et incidents

- Installation par le script sécurisé : signature commune vérifiée ; pas de désinstallation.
- La sauvegarde principale et son .bak ont été vérifiés octet pour octet après les essais : SHA-256 identique à la référence ci-dessus. Jeu fermé à la fin.
- Deux problèmes P0 découverts sur Pixel et corrigés : panneau invisible (7a2ac33) puis index du tour 2 hors limites (0469df0).
- Les CSV ont été extraits avec ADB ; rien envoyé sur Internet par P0.
- Mesure de 60 secondes à vitesse x1 non encore faite.

## Suite avant C3/C2

Préparer une sauvegarde de référence distincte et reproductible qui passe douze mois sans décision bloquante. Conserver la même sauvegarde et sa somme de contrôle pour la version optimisée. Refaire les 36 fins de mois (12 par QG, Entreprise, Produits), puis le QG à x1 ; consigner résultats et reproductibilité avant de démarrer la suite de la phase 1.

**Verdict : P0 est opérationnel sur Pixel, mais la validation « avant » n'est pas complète.**
