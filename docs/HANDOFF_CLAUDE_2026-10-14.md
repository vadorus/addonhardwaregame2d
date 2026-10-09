# Passation à Claude — retour prévu mercredi 14 octobre 2026

**Préparé le 10/10/2026.** Date de retour indicative communiquée par le propriétaire. Ce document sert à reprendre sans répéter des audits entiers.

**Première PR à relire :** [#83 — DOC-001, référentiel documentaire (brouillon)](https://github.com/vadorus/addonhardwaregame2d/pull/83). Base `c1d4f6e`, aucun fichier de gameplay modifié, 64 liens internes vérifiés sans manque. **Pas fusionnée.**

## Lecture rapide

1. Lire [INDEX.md](INDEX.md), [ETAT_ACTUEL.md](ETAT_ACTUEL.md), [DECISIONS.md](DECISIONS.md), puis [JOURNAL_DEVELOPPEMENT.md](JOURNAL_DEVELOPPEMENT.md).
2. Relever réellement `git status`, branche, HEAD, comparaison de la branche de travail avec `v013/demo-octobre` et les PR ouvertes. Ne pas supposer que le HEAD du 10/10 est encore le dernier.
3. Lire le diff de chaque lot, les rapports `docs/reviews/RETOUR_*` et les résultats de CI / tests.
4. Relancer les tests ciblés et faire la relecture des impacts simulation, UI, performance, sauvegarde et gameplay.
5. Fusionner uniquement après feu vert approprié ; ne jamais écraser la partie Pixel.

## Baseline historique du 10/10

- Démo `v013/demo-octobre` @ `c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f`, projet `0.12.2`.
- T3 déjà **fusionné dans la démo** par ce commit. Ne pas rouvrir un chantier « fusion T3 » sur la seule foi du rapport de branche écrit avant la fusion.
- Tests T3 réels PC/Pixel documentés dans [T3_PIXEL_ACTIONS_2026-10-09.md](reviews/T3_PIXEL_ACTIONS_2026-10-09.md). Le complément perte de focus a été validé sur PC, pas à nouveau sur Pixel.
- Les mesures de performances P0 sont historiques, liées à des versions précises : ne pas attribuer leurs FPS, pics de latence ou captures au HEAD actuel.
- Certaines améliorations audio / rendu et la limitation 30/60 FPS apparaissent dans le code bien qu'anciens audits les signalent absentes.
- Une carte des futures branches existe ; ni boutique DLC ni vérification des achats réellement opérationnelle n'ont été confirmées.

## Nouveau dossier de planification au 10/10

- [AUD-001 — Audit multidisciplinaire](AUDIT_MULTIDISCIPLINAIRE_2026-10-10.md) : preuves actuelles de code et constats d'audits historiques distincts.
- [Plan priorisé complet](PLAN_PRIORISE_2026-10-10.md) : codes QA-00, PLAY-00, VIS-00, FTUE-01, CPU-01, BUD-01, CAREER-01, NAR-01, etc. **C'est une proposition** ; le plan de phase 1 du 8 octobre est conservé, ses tâches déjà fusionnées doivent être réconciliées avec Git.
- **Attention :** aucun nouveau test Godot / Pixel n'a été exécuté pour AUD-001 ; ne pas en tirer une validation du commit de démo.

## QA-00 réellement exécuté sur PC le 10/10

[Rapport technique avec résultats, commandes et limites](reviews/RETOUR_2026-10-10_QA00.md).

**Points nécessitant la relecture de Claude :** sortie tactile (RID/ObjectDB leaks), avertissement UID à froid, économie graine 104729 (STANDARD ADAPTEE faillite en 1973, ACCESSIBLE ADAPTEE 225 M€ et rang Empire 3), script `career_probe.gd` qui affiche le faux commit `eff0871`, et presse : 91 corps répétés sur 100 articles homogènes. QG capture PC uniquement ; autres onglets, Pixel et ancienne sauvegarde **non testés**.

## Nouvelle campagne CAREER-01 et correction d'outillage QA-02

- [Rapport 24 carrières / 4 graines](reviews/RETOUR_2026-10-10_CAREER01_4SEEDS.md) : Standard 12/12 faillites, Accessible 9/12 survies, ADAPTÉE 190,7–225,2 M€ fin de carrière. Ce sont des profils automatiques ; **rang Empire et non CPU sectoriel**.
- [Issue #84 : diagnostiquer l'économie](https://github.com/vadorus/addonhardwaregame2d/issues/84), [issue #85 : narration](https://github.com/vadorus/addonhardwaregame2d/issues/85).
- [PR #86 QA-02](https://github.com/vadorus/addonhardwaregame2d/pull/86) : provenance SHA des CSV corrigée ; Godot test dédié, smoke et replay de la graine 104729 Standard PASS. Pas fusionné.
- À faire : traçage mensuel des choix et charges 1971–1973, stratégies prudentes contre le script, indicateur véritable rang CPU, revue visuelle des onglets déverrouillés sur copie de partie.

## Ordre conseillé de revue

1. **Sécurité de branche / Git :** historique lisible, fichiers réellement modifiés, absence de changements hors périmètre, aucune clé / build / sauvegarde committée.
2. **Tests au commit :** import, boot, smoke, scénarios déterministes modifiés. Signaler les avertissements distinctement des PASS.
3. **Sauvegarde :** compatibilité anciens formats, tests en sandbox ; conserver les SHA de sauvegarde de référence en privé.
4. **Pixel :** revue des changements visibles, copie de partie ; mesurer les performances si elles sont annoncées.
5. **Game design et narration :** cohérence de la décision et des textes avec les valeurs de simulation, fréquence des répétitions.
6. **Monétisation :** ne pas transformer en engagement commercial des fonctionnalités futures.

## Décisions réservées au propriétaire

Prix, contenus exacts des DLC, intégration des paiements, changement profond de la boucle CPU, fusion de branches risquées et publication en boutique.

## Pour chaque lot réalisé durant l'absence

Trouver dans [JOURNAL_DEVELOPPEMENT.md](JOURNAL_DEVELOPPEMENT.md) : identifiant, branche, commit, problème initial, changement, tests réellement exécutés, capture/Pixel si pertinent, limites et action attendue de Claude. En cas de différence entre journal et diff Git, **le diff réel prévaut** et le journal doit être corrigé.

