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

