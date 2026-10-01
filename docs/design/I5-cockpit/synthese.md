# I5 — Synthèse de l'étude croisée Astra / Claude

Coordination : Codex. Décision finale : Alexandre.
Base de l'étude : `v010/I5-brief`.
Analyse Astra : `v010/I5-analyse-astra` (`6130798`).
Analyse Claude : `v010/I5-analyse-claude` (`1b0bd6f`).
Les deux analyses ont été produites séparément. Aucun fichier de code du jeu n'a été modifié pendant l'étude.

## 0. Faits complémentaires qui corrigent les deux analyses

Ces faits priment sur les interprétations faites avant leur découverte.

1. Les captures du premier mois viennent de `v010/I6-petits-defauts` (`f605bfe`), pas de `06930b3`.
2. Le défaut capacité **143 → 141** est maintenant reproduit et corrigé (`ef2be62`, fusionné dans `feature/ui-v09-navigation`). Le même défaut touchait aussi le prix **125 → 126**. Ce point est donc **clos et ne fait plus partie des arbitrages I5**.
3. La remarque d'Astra selon laquelle la « contribution » omettrait les frais distributeur reste **non vérifiée**. Elle doit être contrôlée au début de l'implémentation avant de faire de la contribution un KPI principal.

## 1. Accords — acquis pour I5

Astra et Claude convergent fortement sur le fond :

1. Le problème principal n'est pas le nombre de systèmes, mais leur exposition simultanée : le novice voit un catalogue de commandes avant de savoir si son CPU va bien.
2. Le cockpit doit répondre d'abord à deux questions : **« comment va mon produit ? »** puis **« dois-je agir maintenant ? »**.
3. **« Tout va bien, laissez vendre »** est une réponse normale. Nora ne doit pas inventer une dépense quand rien ne l'exige.
4. Aucun système de simulation ne disparaît : prix, capacité, promotion, stepping, firmware, logiciel, offensive et fin de vie restent accessibles dans un niveau expert / « Gérer ce modèle ».
5. Les actions mises en avant doivent être déclenchées par un **problème ou une opportunité mesurable**, pas simplement parce qu'une fonction existe.
6. Une vraie **vue portefeuille** devient nécessaire avec de nombreuses références ; ouvrir 20 CPU un par un n'est pas acceptable.
7. Les commandes verrouillées doivent expliquer leur prérequis au doigt, pas seulement être grisées.
8. Les décisions coûteuses doivent montrer au minimum le **coût, l'effet attendu et la trésorerie restante**.
9. Le portefeuille doit faire ressortir d'abord les produits « à examiner » et conserver filtre/position lorsqu'on revient d'une fiche.
10. Les scénarios doivent être testés automatiquement puis validés sur le Pixel en paysage 1616×720.

## 2. Désaccords — pour et contre

### A. Une ou deux actions visibles

**Astra :** au plus **1 action principale**.
- Pour : hiérarchie très claire sur téléphone ; le novice sait immédiatement quoi faire ; réduit l'effet « liste de corvées ».
- Contre : une deuxième urgence réelle peut être moins visible.

**Claude :** **0 à 2 conseils** simultanés.
- Pour : deux problèmes importants peuvent être traités sans ouvrir le portefeuille.
- Contre : deux gros CTA commencent déjà à recréer la surcharge que I5 cherche à supprimer.

Ce désaccord est ergonomique : `profiles_probe` ne peut pas le trancher. Il devra être validé par un test UX au doigt.

### B. Action coûteuse : exécuter ou examiner d'abord

**Astra :** la carte Nora ouvre **« Examiner »**, puis devis et confirmation.
- Pour : évite les dépenses accidentelles ; permet d'expliquer marge, caisse restante, plafond et incertitude ; robuste sur mobile.
- Contre : ajoute un toucher pour une décision évidente.

**Claude :** bouton vert déjà réglé quand le conseil est clair.
- Pour : rapide et très lisible ; prolonge le fonctionnement des conseils précédents.
- Contre : dangereux lorsque le coût est élevé ; le cas de l'offensive proche de toute la trésorerie montre le risque.

### C. Capacité : seuil 10 % ou 20 % de demande perdue

**Astra :** conserver le garde-fou actuel de Nora : au moins **20 ventes perdues et 20 % de demande perdue**.
- Pour : Nora parle seulement quand la rupture est significative ; moins de microgestion.
- Contre : peut laisser passer plus longtemps une pénurie modérée mais rentable à corriger.

**Claude :** conseil dès **10 % de demande perdue**.
- Pour : réaction plus rapide ; le probe intermédiaire utilise déjà ce seuil pour agrandir.
- Contre : davantage de dépenses et de conseils ; risque de faire réagir Nora à des tensions normales de lancement.

Une simulation comparative est donnée en section 3.

### D. Stepping fiabilité : diagnostic ou seuil brut

**Astra :** mettre en avant un stepping surtout lorsqu'un **dossier SAV / diagnostic** pointe une cause matérielle.
- Pour : évite de confondre un taux de retours avec une cause ; respecte la profondeur du moteur SAV.
- Contre : dépend de la qualité du diagnostic et peut être moins immédiat pour le joueur.

**Claude :** seuil simple, par exemple **retours ≥ 5 % ou satisfaction < 55**.
- Pour : simple à comprendre et à tester.
- Contre : 5 % n'est qu'une hypothèse et peut créer des faux positifs ; un retour n'implique pas forcément un défaut de silicium.

### E. Offensive contre un rival

**Astra :** réutiliser `attack_advice()` et son garde-fou existant, notamment coût ≤ **25 % de la caisse** ; la fiche produit peut y mener.
- Pour : s'appuie sur une logique déjà codée et prudente ; évite une riposte ruineuse.
- Contre : peut être trop conservateur pour un expert agressif.

**Claude :** déclencher sur perte de part / PRICE_WAR et caisse ≥ **3× le coût**, avec l'idée de placer l'action dans Marché.
- Pour : lien plus clair avec la concurrence et les menaces ; logique stratégique mieux regroupée.
- Contre : ajoute de nouveaux seuils supposés et peut éloigner l'action du produit touché.

### F. « Contribution » comme KPI

**Claude :** c'est l'un des bons chiffres à garder.
- Pour : donne une lecture économique immédiate du produit.
- Contre : seulement si son calcul correspond réellement aux coûts imputables.

**Astra :** ne pas la mettre au premier plan avant vérification des frais distributeur.
- Pour : évite d'afficher un indicateur potentiellement trompeur.
- Contre : retire temporairement un KPI financier utile.

**Fait complémentaire :** l'omission des frais distributeur n'est pas encore vérifiée. La synthèse ne tranche donc pas le calcul : **contrôle obligatoire au début de l'implémentation**.

### G. Autonomie de Nora en Accessible

**Claude :** pose la possibilité que Nora applique seule certaines actions gratuites/réversibles.
- Pour : réduit la microgestion pour un novice.
- Contre : le joueur peut ne plus comprendre pourquoi son entreprise change.

**Astra :** Nora explique et propose ; le joueur décide.
- Pour : conserve l'agence du joueur et l'apprentissage.
- Contre : un peu plus de clics dans le mode le plus assisté.

## 3. Simulation du désaccord 10 % vs 20 %

Le protocole demande une simulation lorsqu'un désaccord porte sur un chiffre. La comparaison a été faite avec `tests/tools/profiles_probe.tscn` dans **une copie temporaire hors dépôt** ; seule la constante du probe `0.10` a été changée en `0.20`. Aucun fichier de branche n'a été modifié.

Même scénario, 10 ans, profils INTER et EXPERT :

| Seuil de réaction capacité | INTER | EXPERT |
|---|---|---|
| **10 %** | 12,52 M€ ; 126 k puces ; 20 salariés ; 30 lancements ; rang 2 | 29,01 M€ ; 238 k puces ; 34 salariés ; 57 lancements ; rang 2 |
| **20 %** | 12,57 M€ ; 125 k puces ; 20 salariés ; 30 lancements ; rang 2 | 30,73 M€ ; 256 k puces ; 36 salariés ; 57 lancements ; rang 1 |

La passe à 20 % a été répétée et a rendu exactement les mêmes résultats.

Lecture :
- INTER : la différence est négligeable sur 10 ans (**+0,4 % de trésorerie** à 20 %, environ **−0,8 % d'unités**).
- EXPERT : 20 % donne ici **+5,9 % de trésorerie** et **+7,6 % d'unités**, avec deux salariés supplémentaires et un rang final meilleur.
- Le banc mesure l'économie et la stratégie automatique, **pas la fréquence ni l'agrément des conseils Nora**.

**Conclusion chiffrée :** rien dans le banc ne justifie d'abaisser le seuil de Nora à 10 %. Le seuil **20 % + minimum 20 ventes perdues** est un meilleur point de départ I5 : il n'abîme pas la trajectoire longue et limite a priori la microgestion. Il faudra ensuite instrumenter le nombre de conseils par profil.

Les autres nombres proposés par Claude (5 % de retours, −20 % de part, etc.) sont des hypothèses sans valeur opposée équivalente chez Astra ; ils restent des seuils de calibration, pas des acquis.

## 4. Recommandation de Codex — séparée des analyses

Je recommande un cockpit à deux niveaux.

### Niveau 1 — « Ce mois-ci »

- Une carte d'état tenue par Nora.
- Trois KPI maximum : **ventes, satisfaction, demande servie/perdue**. La contribution rejoint ces KPI seulement après vérification de son calcul.
- **Un seul CTA principal** pour le problème le plus important.
- Un deuxième signal peut exister en texte/badge, sans deuxième gros bouton d'action.
- S'il n'y a rien à faire : « Tout va bien, laissez vendre. »

### Niveau 2 — « Gérer ce modèle »

- Toutes les commandes restent accessibles en permanence.
- Une commande verrouillée explique son prérequis.
- Toute action **payante ou irréversible** passe par « Examiner » → devis/effets → confirmation.
- Une action gratuite et facilement réversible peut être directe, mais je recommande qu'I5 **ne l'automatise pas encore** : Nora conseille, le joueur confirme.

### Portefeuille

- Vue d'entrée dès qu'il y a plusieurs produits.
- Priorité à **« À examiner »**, puis En vente / Fin de série / Archives.
- Une ligne compacte : gamme/modèle, ventes, état économique fiable, signal principal.
- Toucher une ligne ouvre la fiche ; retour conserve filtre et position.

### Déclencheurs de départ

- Capacité ↑ : immédiat à **≥20 ventes perdues ET ≥20 % de demande perdue** ; instrumenter puis recalibrer si nécessaire.
- Capacité ↓ : sous-utilisation persistante + coût réel d'inactivité.
- Promotion : seulement sans rupture et si le produit peut réellement absorber plus de demande.
- Stepping : diagnostic matériel/SAV prioritaire ; le taux de retours sert de signal, pas de preuve de cause.
- Firmware : prérequis visibles + problème compatible identifié.
- Offensive : logique principale dans **Marché**, raccourci depuis le produit ; réutiliser `attack_advice()` et son garde-fou financier avant d'inventer un nouveau seuil.
- Fin de vie : proposition explicable, jamais retrait automatique silencieux.

## 5. Points déjà réglés / à vérifier avant le code I5

- **Réglé hors I5 :** arrondi capacité/prix 143→141 et 125→126 (`ef2be62`).
- **À vérifier au début d'I5 :** calcul de la contribution et prise en compte des frais distributeur.
- **À instrumenter dans I5 :** nombre de conseils Nora par profil et par année, afin de calibrer les seuils sans transformer Nora en alarme mensuelle.
- **À valider sur Pixel :** compréhension novice et vitesse expert ; le probe 10 ans ne remplace pas ce test UX.

## 6. Décisions à prendre par Alexandre — 5 maximum

1. **Pour toute action payante ou irréversible, valides-tu « Examiner » puis confirmation plutôt qu'une dépense directe depuis la carte Nora ?**
   - Recommandation Codex : **oui**.
2. **En mode Accessible, Nora doit-elle seulement proposer les actions gratuites/réversibles, ou peut-elle les appliquer automatiquement ?**
   - Recommandation Codex : **elle propose, le joueur confirme**, au moins pour la première version I5.
3. **L'offensive contre un rival doit-elle vivre principalement dans Marché, avec un raccourci depuis le produit concerné ?**
   - Recommandation Codex : **oui**.
4. **La fin de vie doit-elle toujours être proposée et confirmée par le joueur, jamais automatique lorsqu'un successeur arrive ?**
   - Recommandation Codex : **oui**.
5. **Pour le portefeuille, valides-tu un tri principal par urgence (« À examiner » d'abord), puis par génération à l'intérieur de chaque état ?**
   - Recommandation Codex : **oui**.

Le seuil de capacité 20 % n'a plus besoin d'un arbitrage humain immédiat : la simulation donne un point de départ suffisant, à confirmer ensuite par instrumentation UX.