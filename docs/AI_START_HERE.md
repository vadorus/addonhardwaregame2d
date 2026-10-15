# Démarrage partagé — Tech Empire — Godot

> Fiche initiale vérifiée le 14 octobre 2026 ; n'est pas synchronisée automatiquement.

**Branche produit : `v013/demo-octobre`**. Ne jamais partir automatiquement de `master` (branche GitHub par défaut). Godot 4.7.2, GDScript, jeu hors ligne et sauvegardes anciennes à préserver.

Lire dans cet ordre : `AGENTS.md`, `docs/AI_COORDINATION.md`, les notes de reprise et décisions **les plus récentes**. Le fichier `docs/REPRISE_CODEX_2026-10-07.md` est historique ; tenir compte des commits postérieurs.

**Travaux repérés le 14/10, statuts à reverifier avant de commencer :**
- PR #88 : presse / diversité narrative, relecture Pixel à faire — https://github.com/vadorus/addonhardwaregame2d/pull/88
- PR #89 : carrière / embauche prudente, **ne règle pas la faillite à long terme** — https://github.com/vadorus/addonhardwaregame2d/pull/89
- PR #81 : budgets et lisibilité des projets — https://github.com/vadorus/addonhardwaregame2d/pull/81
- PR #82 : design Software-Hardware, documentaire — https://github.com/vadorus/addonhardwaregame2d/pull/82
- Issues #84 et #85 : équilibrage et articles de presse.
- Le 14/10, plusieurs lots ont déjà été intégrés directement sur `v013/demo-octobre` : **chercher les derniers commits** avant d'ouvrir un chantier parallèle.

**Validation :** `godot --headless --path . --import`, `godot --headless --path . --quit-after 2`, `godot --headless --path . res://tests/smoke_test.tscn`, tests déterministes de la fonctionnalité. Pour l'interface, essais réels au doigt sur une **copie** de la sauvegarde Pixel. Certaines consignes du pilote Agents API interdisent `gh` : effectuer l'inventaire distant hors de ce pilote.

## Instruction de départ commune à chaque IA
1. Lis ce document, `docs/AI_COORDINATION.md` et `AGENTS.md` quand il existe.
2. Vérifie **maintenant** issues, PR (brouillons inclus), branches et derniers commits.
3. Fournis l'inventaire des travaux déjà engagés et les risques de doublon.
4. **Sans attribution par l'utilisateur, ne modifie rien.** Une tâche active doit avoir un seul agent auteur et un autre relecteur.
5. Termine avec le modèle `docs/AI_TASK_TEMPLATE.md` et un compte rendu de tests vérifiables.

Pour les trois dépôts, GitHub est le registre partagé mais il **ne déclenche aucun agent automatiquement**.
