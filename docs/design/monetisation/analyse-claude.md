# Analyse de Claude — publication Google Play et contenu payant

Écrite le 01/10/2026, avant de lire celle d'Astra. Sources : `BRIEF.md`, l'état du code et les fiches Google Play citées dans le brief.
Les prix sont des **suppositions**, à vérifier contre les jeux comparables.

## 1. Recommandation en 5 lignes

1. **Jeu gratuit à télécharger, avec un essai généreux** : l'époque du garage, de 1971 au premier déménagement (environ 1 à 2 h de jeu). Ensuite, **un seul achat débloque tout le jeu**, à vie, sans publicité. C'est le modèle « démo puis jeu complet ».
2. **Des thèmes cosmétiques optionnels** en plus (décor du QG, tenues de l'équipe, boîtes de CPU), sans aucun effet sur le jeu.
3. **Pas de publicité**, ni imposée ni récompensée : elle casserait l'ambiance chaleureuse et pousserait à « gagner plus » en regardant une pub, donc à un avantage en jeu.
4. **Saisons, fêtes et mises à jour de contenu (nouvelles époques, nouveaux composants) gratuites pour ceux qui ont acheté le jeu.** Un gros ajout, comme les GPU, pourra devenir un DLC plus tard.
5. **Ordre** : finir la V1.0, puis l'export Gradle et l'achat, puis la bêta fermée (12 testeurs, 14 jours), puis la publication.

## 2. Réponses aux questions

**Q1. Le modèle.**

| Modèle | Pour | Contre (pour ce jeu, cette équipe) |
|---|---|---|
| Payant d'emblée | simple, pas d'achat à coder, le public du genre l'accepte (Game Dev Tycoon) | très peu de gens achètent sans essayer un jeu inconnu, surtout sur mobile |
| Gratuit avec pubs et achats | beaucoup de téléchargements | ambiance cassée, avis plus durs (PC Tycoon 2 : 3,9 ★ contre 4,9 ★), réglages de pub à suivre, tentation de vendre de l'avance |
| **Essai gratuit puis jeu complet (+ cosmétiques)** | on essaie sans risque, une seule chose à acheter, pas de pub, pas besoin d'animer le jeu en continu | il faut que la première heure donne vraiment envie (c'est le travail des lots B, G2, I et K) ; une partie des joueurs ne paiera jamais |

Le jeu a une **fin de contenu** et un mode libre : c'est un jeu « complet », pas un service. L'achat unique lui correspond.

**Q2. Le prix (suppositions).**
- Jeu complet : entre 3,99 € et 6,99 €. Je partirais sur **4,99 €**. À caler sur le prix réel de Game Dev Tycoon sur Google Play, non relevé dans le brief.
- Thème cosmétique : **1,99 €** pièce, ou **4,99 €** le lot de 3.
- Une baisse à un prix de lancement (−30 %) est possible la première semaine.

**Q3. Que vendre.**
- **Payant** : le déblocage du jeu complet ; des thèmes de QG (« Néon années 80 », « Chalet en bois », « Station spatiale »), qui s'appliquent par-dessus les 4 paliers ; des tenues d'équipe par décennie ; des boîtes de CPU spéciales.
- **Gratuit pour tous** : l'essai ; les **saisons et fêtes** (lot 3 d'Astra), qui sont la « vie » du jeu ; le choix des modes ; les mises à jour d'équilibrage.
- **Plus tard (DLC possible)** : une nouvelle filière complète (GPU, RAM), seulement si le jeu de base a trouvé son public.

**Q4. La publicité.** Non. C'est la seule façon de garder une ambiance chaleureuse sans pression. Ça évite aussi les SDK publicitaires, avec leur formulaire de données et leur poids.

**Q5. Le PC.**
- Plus tard, sur **itch.io** ou **Steam**, comme jeu payant au même prix. Les thèmes y seraient inclus ou vendus en DLC.
- Les achats ne passent pas d'une plateforme à l'autre : il n'y a pas de comptes, et ce serait compliqué. Il faut le dire clairement sur la fiche.
- À décider après Android.

**Q6. La technique.**
- Passer l'export Android en **Gradle** (`use_gradle_build=true`) et viser l'**API 36**.
- Ajouter l'extension **godot-google-play-billing** : un produit « jeu_complet » et un produit par thème (achats non consommables).
- Ajouter un script `Store.gd` :
  - il interroge les achats au démarrage et sur le bouton « Restaurer mes achats » ;
  - il garde un cache local pour jouer hors ligne.
- Sur PC, et pour les tests, le jeu reste débloqué en mode développeur.
- La **fin de l'essai** : au premier déménagement, une carte claire. Elle dit ce qui vient (l'atelier, la presse, les rivaux…), propose le bouton d'achat, et propose de continuer à jouer au garage. **Jamais de perte de sauvegarde** : après achat, la partie continue au même endroit.
- **Travail estimé (supposition)** : 3 à 5 jours pour Gradle, la boutique, les tests et le dossier Google Play.
- **Risques** : la compatibilité de l'extension avec Godot 4.7.2, à vérifier en premier ; et le passage à Gradle, qui change la chaîne de build sur les deux PC.
- **Piratage** : on l'accepte. Pas de protection lourde : elle gênerait les vrais joueurs.

**Q7. Le chemin jusqu'à la publication.**
1. **V1.0 jouable sans trou** : fin du son (L), audit bêta, textes relus, icône et nom définitifs.
2. **Technique** : vraie clé de publication (hors dépôt, sauvegardée en 2 endroits), export AAB Gradle, API 36, extension de paiement, boutique, carte de fin d'essai, « Restaurer mes achats ».
3. **Dossier Google Play** : compte développeur, politique de confidentialité (simple, puisqu'il n'y a ni collecte ni pub), Sécurité des données, classification par âge, fiche avec captures 16:9 du Pixel.
4. **Test fermé** : au moins 12 testeurs pendant 14 jours (famille, amis, collègues), avec un formulaire de retours.
5. **Publication** progressive, puis corrections, puis le premier thème payant 1 mois plus tard.

## 3. Tableau des contenus

| Contenu | Gratuit / payant | Prix envisagé | Travail |
|---|---|---|---|
| Essai (garage, 1971 → 1er déménagement) | gratuit | — | Claude : carte de fin d'essai, verrou |
| Jeu complet | payant, une fois | 4,99 € | Claude : achat, restauration |
| Saisons et fêtes (lot 3) | gratuit | — | Astra (en cours), Claude |
| Thème QG « Néon 80 » | payant | 1,99 € | Astra : 4 décors + accessoires ; Claude : sélecteur de thème |
| Tenues d'équipe par décennie | payant | 1,99 € | Astra : 14 personnages × 4 poses × décennies (gros) |
| Boîtes de CPU spéciales | payant | 0,99 € à 1,99 € | Astra : 6 boîtes ; Claude : affichage |
| Nouvelle filière (GPU…) | DLC plus tard | à définir | gros chantier de conception |

## 4. Risques et parades

| Risque | Parade |
|---|---|
| L'essai ne donne pas envie | Le mesurer pendant la bêta : à quel moment les testeurs s'arrêtent. Soigner la première heure. |
| Avis « c'est payant » | Le dire dès la fiche : « Essai gratuit, jeu complet en un achat, sans pub ». |
| L'extension de paiement casse avec Godot | La tester en tout premier sur le Pixel, avec des achats de test Google. |
| Clé de publication perdue | La garder hors du dépôt, en 2 copies (PC et coffre). La signature gérée par Google permet de la remplacer. |
| Temps d'Alexandre | Pas de pub, pas d'événements en ligne : rien à surveiller au quotidien. |
| Obligations fiscales et statut pour des revenus | **À faire vérifier par un professionnel.** Google reverse le prix moins sa commission ; la déclaration des revenus reste à la charge du développeur. |

## 5. Questions pour Alexandre

1. **Le modèle** : essai gratuit puis jeu complet en un achat (sans pub), ou payant d'emblée ?
2. **Où s'arrête l'essai** : au premier déménagement (environ 1975), ou après le premier CPU vendu ?
3. **Le prix du jeu complet** : 3,99 €, 4,99 € ou 6,99 € ?
4. **Le premier thème payant** à demander à Astra après le lot 3 : Néon 80, Chalet ou Spatial ?
5. **Le PC** : on s'en occupe après Android, ou en même temps (itch.io ou Steam) ?
