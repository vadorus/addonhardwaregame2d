# Politique de maintenance Git et documentaire — Tech Empire

**Applicable à partir du 10/10/2026 pour tout nouveau lot.** Ne modifie pas `AGENTS.md` ni les restrictions propres aux agents.

## Un changement = une trace vérifiable

Avant une modification :
- Identifier la branche de base et relever le HEAD + `git status`. Ne pas partir du `master` par défaut.
- Décrire le problème reproduit, le résultat attendu, le périmètre et les risques sauvegarde/UI/économie.
- Utiliser une branche courte et isolée : `fix/<sujet>`, `feat/<sujet>`, `docs/<sujet>`, `audit/<sujet>` ; ne pas mélanger les travaux.

Après chaque modification :
1. Relire le diff, y compris les fichiers ajoutés / supprimés.
2. Exécuter les tests de `AGENTS.md` dans la mesure du possible, plus les scénarios ciblés. En cas d'impossibilité, l'écrire explicitement.
3. Si gameplay/économie : tests déterministes, comparatif avant/après et contrôle des conséquences.
4. Si interface : capture avant/après **sur le même état** et vérification au doigt sur Pixel lorsque disponible.
5. Si sauvegarde : migration explicite, chargement ancienne partie sur copie, jamais de modification non contrôlée des données personnelles.
6. Créer un [rapport de lot](MODELE_RAPPORT_LOT.md) et une ligne au [journal](JOURNAL_DEVELOPPEMENT.md).
7. Faire un commit dédié avec message `<LOT> : description précise`, pousser la branche seulement lorsque autorisé et permis par les règles de l'agent, puis ouvrir une PR de relecture si utile.
8. **Pas de fusion automatique** : distinguer branche à jour, commit poussé, PR ouverte, fusion réelle, validation Pixel et publication.

## Niveau de preuve obligatoire

- `NON TESTÉ` : code ou document seulement relu.
- `TESTÉ PC` : commande, commit, logs / assertions et défauts connus.
- `TESTÉ PIXEL` : appareil, version APK, conditions, copie de sauvegarde, captures ou relevés pertinents.
- `VALIDÉ PROPRIÉTAIRE` : retour humain explicite sur le ressenti / l'autorisation concernée.

Une fonction peut être `implémentée` sans être `validée`. Ne jamais remplacer une preuve manquante par une affirmation.

## Audit / documentation historique

- Chaque audit daté doit mentionner **commit, plateforme, protocole, date, conclusions, limites**, et statut `ACTUEL POUR COMMIT` / `À REVÉRIFIER` / `HISTORIQUE`.
- Ne pas supprimer les rapports anciens : les relier depuis [reviews/INDEX.md](reviews/INDEX.md) et corriger les nouvelles synthèses.
- Quand le HEAD change, actualiser [ETAT_ACTUEL.md](ETAT_ACTUEL.md) ; ne pas recycler les mesures anciennes comme actuelles.
- Ne jamais publier de sauvegarde privée, empreinte identifiante d'appareil, jeton, mot de passe, clé, APK ou export généré dans Git.
- Pour les fichiers volumineux de mesures/captures, référencer seulement les données non sensibles autorisées et préciser si les preuves sont locales.

## Préparation du retour de Claude

Chaque PR doit indiquer **ce que Claude doit contrôler**, le risque de régression, et les tests qui restent à exécuter. Une PR revue et corrigée ne doit pas effacer ses conclusions initiales. À la fin d'une session, actualiser [HANDOFF_CLAUDE_2026-10-14.md](HANDOFF_CLAUDE_2026-10-14.md).

