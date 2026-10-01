# I5 — Synthèse de l'étude croisée Astra / Claude

Coordination : ChatGPT/Codex. Décision finale : Alexandre.
Base commune : `v010/I5-brief` (`6dbfdbc`).
Analyse Astra : `v010/I5-analyse-astra` (`6130798`).
Analyse Claude : `v010/I5-analyse-claude` (`1b0bd6f`).
Les deux analyses ont été produites séparément ; Claude n'a été lu qu'après le push d'Astra.
Aucun fichier de code du jeu n'a été modifié pendant l'étude.

## 1. Ce sur quoi Astra et Claude sont d'accord — acquis

1. Le problème principal n'est pas le nombre de systèmes mais leur exposition simultanée : le novice voit un catalogue d'actions au lieu d'un diagnostic.
2. Au premier mois, le cockpit doit répondre d'abord à : « mon CPU va-t-il bien ? » puis « dois-je faire quelque chose maintenant ? ».
3. « Ne rien faire / laissez vendre » doit être une réponse normale quand aucun problème n'est mesuré.
4. Les systèmes de simulation ne doivent pas disparaître : ils restent accessibles dans un espace expert / « Gérer ce modèle ».
5. Nora doit expliquer et proposer ; une dépense ne doit pas partir sans décision explicite du joueur.
6. Une vue portefeuille est nécessaire dès qu'on a beaucoup de CPU : le menu modèle par modèle ne tient pas à 20-21 références.
7. Les actions doivent être déclenchées par un problème ou une opportunité mesurable, pas simplement parce que le système existe.
8. Les actions coûteuses doivent montrer coût, effet attendu et trésorerie restante avant validation.
9. Les options verrouillées doivent expliquer leurs prérequis au lieu d'être seulement grisées.
10. Le cas capacité 143 → 141 et le message contradictoire doivent être corrigés ; les deux analyses pointent le pas du contrôle comme cause probable.
11. Il faut des tests automatiques par déclencheur, puis une validation réelle sur Pixel 10 en 1616×720.

## 2. Désaccords utiles

| Sujet | Astra | Claude | Lecture de synthèse |
|---|---|---|---|
| Nombre d'actions visibles | 1 action principale au maximum | 0 à 2 conseils | Compatible si on retient **1 CTA principal + éventuellement 1 information secondaire sans CTA**. |
| Action coûteuse | « Examiner » puis devis ; ne jamais payer depuis la carte principale | Bouton vert déjà réglé si le conseil est clair | Le risque financier du brief favorise Astra pour les dépenses ; le raccourci Claude reste pertinent pour les actions gratuites/réversibles. |
| Capacité ↑ | Seuil actuel : ≥20 unités perdues et ≥20 % de demande | ≥10 % de demande perdue | Les deux déclenchent sur la capture (72 ventes perdues). Le bon seuil général n'est pas démontré. |
| Stepping fiabilité | Déclencher sur diagnostic/dossier SAV ; pas de taux universel | ≥5 % de retours ou satisfaction <55 | Astra réduit les faux positifs ; Claude est plus simple à tester. Le moteur SAV dispose déjà de causes, donc le diagnostic est préférable. |
| Offensive rival | Réutiliser `attack_advice()` et son garde-fou coût ≤25 % de caisse | Baisse de part ou PRICE_WAR + caisse ≥3× coût | Les deux veulent un vrai contexte rival. Le garde-fou existant à 25 % est plus prudent et déjà codé. |
| Emplacement offensive | Reste une commande accessible depuis le modèle | Pourrait vivre dans Marché | Action conceptuellement marché ; conserver un raccourci contextuel depuis le produit évite de la perdre. |
| Mode Simulation | Même profondeur, Nora explique moins mais les commandes restent trouvables | Nora verdict seulement, repli expert ouvert par défaut | Différence de ton acceptable ; ne pas cacher l'information utile selon le mode. |
| « Contribution » en chiffre vedette | À ne pas mettre en avant avant correction : frais distributeur omis | Fait partie des bons chiffres à garder | Astra a trouvé un problème comptable concret : **corriger la contribution avant d'en faire un KPI principal**. |

## 3. Vérification chiffrée demandée par le protocole

Le désaccord 10 % vs 20 % sur la rupture a été confronté au banc existant `tests/tools/profiles_probe.tscn` sans modifier le code.
Après import du worktree Godot, profil `INTER`, 10 ans : 12,52 M€ de trésorerie, 1,09 M€ de CA au dernier mois, 126 k puces vendues, 20 salariés, 30 lancements, rang 2.
Ce profil agrandit la capacité lorsque les pertes sont ≥ max(20 unités, 10 % de la demande).
Conclusion : **10 % est jouable**, mais le banc ne compte pas les conseils I5 et n'exécute pas un scénario alternatif à 20 % ; il ne peut donc pas prouver que 10 % donne une meilleure UX.
Le seuil reste à calibrer lors de l'implémentation, avec comptage du nombre de conseils reçus par profil.

## 4. Recommandation du coordinateur

Je recommande un cockpit à **deux niveaux**.

**Niveau 1 — « Ce mois-ci »**
- Une carte d'état tenue par Nora.
- Trois chiffres maximum : ventes, satisfaction, demande servie / perdue. La contribution revient ici seulement après correction de son calcul.
- **Un seul CTA principal** lié au problème le plus important.
- S'il n'y a rien à faire : « Tout va bien, laissez vendre. » Aucun bouton de dépense.
- Un second signal peut être affiché en texte, mais sans deuxième gros bouton vert.

**Niveau 2 — « Gérer ce modèle »**
- Prix, capacité, promotion, stepping, firmware, logiciel, fin de vie et autres commandes restent accessibles en permanence.
- Les commandes verrouillées indiquent le prérequis manquant.
- Les actions coûteuses ou irréversibles ouvrent d'abord une fiche/devis : effet, coût, caisse après action, risque, puis confirmation.
- Les actions gratuites et facilement réversibles peuvent rester directes après confirmation légère.

**Portefeuille**
- Devient la vue d'entrée lorsque plusieurs produits existent.
- Filtre prioritaire : « À examiner », puis « En vente », « Fin de série », « Archives ».
- Une ligne = gamme/modèle, ventes, état financier fiable, signal principal.
- Toucher une ligne ouvre la fiche ; retour conserve filtre et position.

**Nora**
- Accessible : explication plus pédagogique.
- Standard : conseil concis + justification.
- Simulation : signal factuel et accès au diagnostic, sans masquer les outils ni prendre la décision à la place du joueur.

## 5. Déclencheurs recommandés pour le premier prototype I5

Ces seuils règlent **la mise en avant de Nora**, pas l'accès aux commandes.

| Action | Déclencheur recommandé |
|---|---|
| Capacité ↑ | Immédiat si ≥20 ventes perdues et ≥20 % de demande perdue. Tester ensuite 10 % au banc si Nora réagit trop tard. |
| Capacité ↓ | Utilisation <70 % pendant 2 mois + coût réel de capacité inutilisée. |
| Promotion | Pas de rupture ; utilisation <70 % pendant 2 mois ; satisfaction ≥60 ; rentabilité positive après correction de la contribution. |
| Stepping | Dossier SAV / fabrication / thermique indiquant une cause matérielle ; l'âge seul ne suffit pas. |
| Firmware | Débloqué + dossier/retour pertinent pour stabilité ou performance ; afficher les prérequis sinon. |
| Offensive | `attack_advice()` valide + coût ≤25 % de la caisse + capacité suffisante pour profiter de la demande gagnée. |
| Fin de vie | Réutiliser `retire_candidates()` ; jamais proposée le mois du lancement. Retrait final après confirmation. |
| Logiciel de contrôle | Une fois au déblocage d'une génération compatible ; ensuite seulement si une mise à jour apporte un effet identifiable. |

Le prix reste une commande permanente dans « Gérer ce modèle » ; Nora peut le signaler plus tard, mais il ne doit pas ajouter un CTA au premier mois sans preuve claire.

## 6. Critères d'acceptation communs

1. Premier mois calme : 0 dépense conseillée et 0 ou 1 CTA principal.
2. Cas de la capture avec rupture : 1 CTA principal cohérent sur le même modèle et la même période ; aucune contradiction 143/141.
3. Consulter un devis ne débite rien ; toute dépense affiche la caisse restante avant confirmation.
4. Une action dépassant les garde-fous financiers n'est pas présentée comme recommandation verte.
5. Avec 3 puis 20 CPU, le joueur retrouve immédiatement les modèles « à examiner » sans ouvrir chaque fiche.
6. Toutes les commandes de simulation restent accessibles en ≤2 touchers depuis une fiche produit.
7. Les actions verrouillées expliquent leur déblocage au doigt, sans dépendre d'un survol.
8. Les anciens saves chargent sans ajout obligatoire de données I5 ; absence d'historique = état prudent « à observer ».
9. Pixel 10 paysage : carte d'état + KPI + CTA principal visibles sans défilement et sans recouvrement par les notifications.
10. Test novice : identifier l'état et la prochaine action en ≤15 s ; test expert : trouver prix/firmware/retrait en ≤2 touchers.
11. Compter les conseils sur une campagne automatisée : éviter une Nora qui alerte chaque mois ; seuil exact à calibrer après instrumentation I5.

## 7. Décisions à prendre par Alexandre — 4 seulement

1. **Quand tout va bien, valides-tu que Nora dise simplement « laissez vendre » et ne propose aucune dépense ?**
   - Recommandation : **oui**.
2. **Pour une action payante ou irréversible, veux-tu un bouton « Examiner » puis confirmation, plutôt qu'un achat direct depuis la carte Nora ?**
   - Recommandation : **oui** ; c'est plus sûr sur téléphone et conserve la liberté du joueur.
3. **L'offensive contre un rival doit-elle vivre principalement dans Marché, avec un raccourci contextuel depuis le produit ?**
   - Recommandation : **oui**.
4. **La fin de vie doit-elle toujours être proposée et confirmée par le joueur, jamais automatique lorsqu'un successeur arrive ?**
   - Recommandation : **oui**.

Le seuil précis de rupture (10 % ou 20 %) ne nécessite pas une décision de design maintenant : on peut démarrer avec le seuil actuel de conseil à 20 %, instrumenter I5, puis le régler par tests sans changer le principe du cockpit.
