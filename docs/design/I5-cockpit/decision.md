# Décision d'Alexandre — I5 (01/10, 13h40)

Alexandre suit les 5 recommandations de la synthèse de Codex.

1. **Action payante ou irréversible** : « Examiner », puis devis (coût, effet, trésorerie restante), puis confirmation. Jamais de dépense directe depuis la carte de Nora.
2. **Mode Accessible** : Nora propose, le joueur confirme. Pas d'action automatique dans cette première version.
3. **Offensive contre un rival** : elle vit dans **Marché**, avec un raccourci depuis le produit concerné. On réutilise `attack_advice()` et son garde-fou (coût ≤ 25 % de la caisse).
4. **Fin de vie** : toujours proposée et confirmée par le joueur, jamais automatique.
5. **Portefeuille** : tri par urgence d'abord (« À examiner », puis En vente, Fin de série, Archives), puis par génération dans chaque groupe.

Également retenu dans la synthèse :
- un seul gros bouton d'action sur la carte « Ce mois-ci » ; un deuxième signal en texte seulement ;
- seuil de capacité : 20 ventes perdues **et** 20 % de demande perdue ;
- le calcul de la contribution (frais de distributeur) est vérifié avant d'en faire un indicateur principal ;
- le nombre de conseils de Nora par profil est mesuré.

Réalisation : Claude, branche `v010/I5-cockpit`.
