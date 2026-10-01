# Tech Empire face à ses concurrents — synthèse de Codex

Date : 01/10/2026. Document de décision ; aucune réalisation autorisée par cette synthèse seule.
Analyses comparées : [Astra, commit c3667f5][A] et [Claude, commit 3af8366, correctif final inclus][C].
Méthode : protocole de `v010/concu-brief`, lecture des analyses, vérifications ciblées du code et des sources officielles.
Le correctif de Claude est postérieur à sa lecture d’Astra : il résout une erreur, ce n’est pas une confirmation indépendante.
Toutes les références de code ci-dessous portent sur `94592cd`, référence commune du brief et des analyses.
Aucune sonde, partie comparée ou séance sur Pixel exécutée par Codex pendant cette synthèse.
Les résultats rapportés par Claude restent attribués à Claude ; ses journaux et son paquet Android n’ont pas été reproduits ici.
Les seuils marqués « proposés » sont des hypothèses de validation, jamais des résultats acquis.

## Accords — ce que l’on peut retenir

« Acquis » signifie accord de conception entre les analyses, pas preuve que Tech Empire dépasse déjà ses concurrents.

| Question du brief | Accord utile pour la suite |
| --- | --- |
| Concurrents | PC Tycoon 2 est la comparaison matérielle principale ; Game Dev Tycoon, la référence du lancement et de la progression. Les autres éclairent des risques, sans dicter notre catalogue. |
| Points forts | Protéger Nora, le QG chaleureux, l’équipe visible, l’apprentissage entre générations et les rivaux actifs. Leur supériorité vécue reste à tester. |
| Retards | Priorités communes : comprendre ses résultats, conserver des décisions intéressantes en carrière, rendre le jeu fiable et lisible sur téléphone. |
| Partie longue | Faire évoluer les besoins des clients et la concurrence. Prévenir le joueur et laisser des réponses possibles ; éviter les dépenses artificielles destinées à vider sa caisse. |
| Lancement | Compléter l’explication et le lien avec les ventes. Garder la cérémonie existante : le correctif de Claude retire sa proposition de la recréer. |
| Rejouabilité | Des situations de départ différentes peuvent renouveler la partie ; elles ne doivent pas retarder la correction de la boucle principale. |
| Largeur | Finir le jeu CPU avant une autre famille de produits. Aucun engagement immédiat sur GPU, mémoire ou consoles. |
| Bêta | Essais tactiles, appareil moins puissant, reprise des sauvegardes et préparation Play sont nécessaires. L’anglais est important pour un public international. |
| Plan | Des lots courts, vérifiables et compatibles avec le temps libre d’Alexandre ; pas de refonte géante ni de promesse d’exhaustivité. |

## Désaccords — arguments et limites

### Priorité : défi de carrière ou compréhension du lancement ?

**Claude : carrière d’abord.** Pour : ses sondes signalent une domination rapide et une trésorerie confortable ; corriger la note seule ne rendrait pas la suite intéressante. Contre : changer l’économie avant de rendre ses effets compréhensibles peut masquer le problème initial. [C], section 3 et 9
**Astra : lancement d’abord.** Pour : un retour compréhensible apprend au joueur à s’adapter et permet de mieux interpréter les essais. Contre : une belle explication peut révéler une stratégie gagnante répétitive sans la corriger. [A], section 5 et 9
Le choix dépend de la taille du chantier : une amélioration limitée de l’explication peut précéder l’équilibrage, sans attendre un carnet complet.
Un défaut de sauvegarde ou de mise à jour passe toutefois avant ces deux chantiers.

### Défi : ruptures programmées ou évolution des systèmes existants ?

**Claude : des ruptures d’époque et des ripostes ciblées.** Pour : rythme visible, anticipation et occasions de revoir sa stratégie. Contre : calendrier à apprendre par cœur, surcharge de contenus et sentiment que le jeu punit le leader. [C], section 4
**Astra : besoins, obsolescence et rivaux existants d’abord.** Pour : moins de nouveaux systèmes et davantage de conséquences liées aux décisions. Contre : une évolution trop diffuse peut rester invisible et ne pas casser une recette dominante. [A], section 4
Le code possède déjà des choix de prix, recherche, capacité et repositionnement : `scripts/CompanyAIManager.gd:50-96`.
Il faut mesurer leur effet avant de conclure qu’une nouvelle mécanique de riposte est nécessaire.
Les dates historiques et délais proposés par Claude sont des réglages de jeu à tester, pas une chronologie scientifique validée ici.

### Accessible : guider ou garantir l’absence de faillite ?

**Claude : aucun novice ne fait faillite ; le leader passif doit reculer.** Pour : protège les débutants et rend le défi mesurable. Contre : l’invulnérabilité retire des conséquences ; un recul imposé peut punir une stratégie encore pertinente. [C], section 4
**Astra : conserver des pertes évitables et des adaptations utiles.** Pour : le joueur comprend et garde sa liberté. Contre : il faut concevoir des avertissements et une aide suffisante pour éviter les impasses. [A], section 4
Interdire d’être premier avant une date, ou obliger à dépenser, mesure un calendrier imposé plutôt que l’intérêt des décisions.
Une stratégie adaptée doit être comparée à une stratégie figée au même mode ; l’aide doit être évaluée séparément.

### Note : carnet de découverte ou explication disponible dès le départ ?

**Claude : barres et carnet dont les connaissances se débloquent.** Pour : apprentissage visible, envie d’expérimenter et souvenir des essais. Contre : cacher les besoins fondamentaux peut recréer l’opacité reprochée aux concurrents. [C], section 5, corrigée
**Astra : expliquer le pari, les causes du verdict et le prochain essai, avec détail sur demande.** Pour : décision directement utile. Contre : tout dévoiler sans progression peut réduire le plaisir de découverte. [A], section 5
Un compromis est possible : afficher les besoins essentiels avant le premier lancement ; enrichir le carnet avec comparaisons, historique et conseils plus précis.
Une étude de marché peut réduire une incertitude ; elle ne devrait pas faire payer l’explication rétrospective d’une note déjà reçue.
Le code interdit de promettre une décomposition universelle en quatre critères : voir la vérification ci-dessous.

### Rejouer : départs tardifs ou scénarios limités ?

**Claude : plusieurs années de départ, défis courts et argent illimité.** Pour : changement immédiatement visible, réutilisation du moteur. Contre : cohérence à initialiser entre recherche, rivaux, équipe, produits et tutoriel ; son estimation d’effort n’est pas vérifiée. [C], section 6
**Astra : scénarios de redressement et de spécialiste ; dates libres plus tard.** Pour : périmètre plus contrôlable et essais reproductibles. Contre : moins de liberté et risque de départs trop proches de la campagne normale. [A], section 6
Le bac à sable financier doit aussi être testé : retirer une contrainte peut casser des objectifs, des conseils ou des classements.

### Bêta : anglais immédiatement, performances maximales ?

**Claude : anglais avant bêta ; cible de 60 images/s.** Pour : recrutement plus large et bonne réactivité. Contre : traduction et optimisation peuvent retarder un test fermé francophone ; ce seuil n’est pas une règle Play. [C], section 8–9 ; seuil proposé par Claude
**Astra : français possible en test fermé ciblé ; budget de 30 images/s.** Pour : apprendre plus tôt et limiter le coût matériel. Contre : ce plan ne valide ni la localisation ni l’expérience d’un public international. [A], section 8 ; seuil proposé par Astra
Les tailles ne s’opposent pas : 43 Mo est une mesure d’AAB rapportée par Claude ; 150 Mo est un budget de téléchargement proposé par Astra. Ce ne sont ni le même objet ni une comparaison de mesures reproduites. [C], section 8 ; [A], section 8
La priorité doit porter sur les lenteurs perceptibles, la chauffe et les entrées tactiles, pas sur un nombre isolé d’images par seconde.

### Modèle commercial et extensions : décider ici ou réserver l’arbitrage ?

**Astra : achat unique recommandé.** Pour : promesse lisible et pas de boutique à entretenir au départ. Contre : aucune mesure de conversion ou de disposition à payer dans cette étude. [A], section 8
**Claude : renvoi à l’étude monétisation.** Pour : conserve une décision cohérente entre les études. Contre : le recrutement et la fiche devront tout de même annoncer un modèle clair. [C], section 8
Les deux acceptent le principe sans avantage payant ; cette synthèse ne décide ni prix ni nouveau modèle.
Sur les familles futures, Claude exclut définitivement certains produits ; Astra refuse une interdiction définitive.
Pour l’exclusion : maîtrise du périmètre. Contre : fermer une option utile sans prototype. Pour l’ouverture : liberté future. Contre : promesses implicites et dispersion. [C7 ; A7]
L’accord immédiat est suffisant : CPU d’abord, aucune extension promise dans la prochaine livraison.

## Vérifications factuelles de Codex

### La note et sa cérémonie — désaccord résolu, périmètre corrigé

La révélation progressive, le son et le verdict sont présents dans `ui/components/ReviewRevealPanel.gd:70-149`.
Les cartes affichent le titre du média et une comparaison : même fichier, lignes 151–189.
Les comparaisons prédécesseur/rival sont préparées dans `scripts/MediaManager.gd:84-109,138-148`.
Le correctif final de Claude est donc confirmé : supprimer le chantier de recréation de la cérémonie.
En revanche, la décomposition des contributions n’est pas transmise dans les cartes de ce chemin lu (`MediaManager.gd:96`).
**Limite des quatre barres :** le calcul varie selon le média et inclut aussi innovation, facilité d’usage, marque ou écosystème (`MediaManager.gd:188-213`).
L’interview et les comparaisons modifient ensuite le résultat (`MediaManager.gd:118-136`).
Une explication fidèle doit couvrir ces effets et les bornes du calcul ; les barres peuvent résumer, pas prétendre recomposer seules toute note.

### Les sondes — alerte crédible, extrapolation non démontrée

Claude rapporte notamment 22 M€ pour l’intermédiaire et 31 M€ pour l’expert au terme de sa sonde, ainsi que 5,1 M€ pour le novice. Source : [C], section 3, exécution déclarée par Claude ; chiffres non reproduits par Codex.
Ces résultats justifient une enquête sur la facilité ; ils ne prouvent pas que toutes les années restantes sont sans défi.
`profiles_probe` utilise le chemin de développement, mais associe par défaut NOVICE à Accessible et les autres à Standard (`tests/tools/profiles_probe.gd:2-18`).
Le mode commun peut être imposé (`même fichier:25-30,45-47`). Il faut le faire pour isoler l’effet de la stratégie.
`campaign_probe` ajoute directement des produits lancés et leurs métriques (`tests/tools/campaign_probe.gd:92-115`).
Elle reste utile pour les marchés et les rivaux ; elle ne remplace pas une carrière passant par conception et industrialisation.
Avant rééquilibrage, archiver commit, commandes, mode, conditions aléatoires et journaux. Aucun résultat nouveau n’est annoncé ici.

### Concurrents — corriger les généralisations

Pages Steam consultées : PC Tycoon 2 affiche 79 % sur 318 avis ; Hardware Tycoon 61 % sur 31 ; Processor Dev Tycoon 30 % sur 10. [W1], [W2], [W3] ; relevé du 01/10/2026, susceptible d’évoluer
Le relevé Hardware diffère des 62 % sur 29 avis de Claude : actualisation du relevé, sans conclusion sur sa cause. [C], section 1 ; [W2]
Ces petits ensembles et les différences de public ne démontrent ni « aucun bon jeu » ni une supériorité de Tech Empire.
Les avis de PC Tycoon consultés décrivent bien une incompréhension des notes ; leur sélection par utilité ne classe pas statistiquement les reproches du genre. [W4]
La fiche actuelle de PC Tycoon annonce des rivaux développant leurs produits et un mode plus exigeant. Les avis anciens ne suffisent pas à déclarer ces fonctions absentes ou inefficaces aujourd’hui. [W1]
La fiche Android de Game Dev Tycoon annonce un mode pirate facultatif et une interface adaptée aux téléphones et tablettes. « Un seul mode » et « les autres sont de simples portages » ne sont donc pas des acquis. [W5]
Les prix régionaux ne sont pas comparables sans pays et date communs ; aucun prix concurrent n’est utilisé pour fixer celui de Tech Empire.

### Play et téléphone — règles distinctes des objectifs produit

Google confirme : pour les comptes personnels créés après le 13/11/2023, au moins 12 testeurs inscrits en continu pendant 14 jours au test fermé avant demande d’accès production. Ce n’est pas une acceptation automatique. [W6]
Le test fermé peut commencer après configuration de l’application ; le test ouvert nécessite l’accès production. [W6]
La page officielle exige Android 16 / API 36 pour les nouvelles applications ordinaires depuis le 31/08/2026, sous réserve d’extension accordée. Vérifier le paquet effectivement envoyé. [W7]
La compatibilité des bibliothèques natives avec les pages de 16 Ko doit être contrôlée sur le paquet et testée dans l’environnement correspondant. [W8]
La continuité de signature conditionne les mises à jour Android ; Play distingue clé d’envoi et clé de signature de l’application. Une clé commune de test ne valide pas à elle seule la future distribution Play. [W9]
L’incident de sauvegarde décrit par Claude n’est pas reproduit ici : sa cause exacte reste à confirmer par les certificats et le chemin d’installation. [C], section 8
L’anglais est un choix de public, pas une condition établie par les règles de test citées. Les déclarations Play, la confidentialité et la classification restent à compléter selon le contenu et les données réellement utilisés.
Le volume de textes annoncé par Claude n’est pas recompté ; il faut inventorier les chaînes avant d’estimer la traduction. [C], section 3

## Recommandation de Codex — à faire valider

Promesse proposée : **« Je comprends mes choix, je vois mon entreprise grandir, et je dois encore réfléchir après mes premiers succès. »**
Je recommande une explication courte et fidèle avant un rééquilibrage lourd, avec un préalable de sécurité des sauvegardes.
Réutiliser les systèmes actuels ; essayer une transition de marché limitée avant de programmer toutes les ruptures proposées.
Garder Accessible accompagné, avec erreurs récupérables ; ne pas transformer « novice jamais perdu » en invulnérabilité générale.
Conserver les besoins essentiels visibles ; réserver au carnet l’apprentissage approfondi et l’historique.
Ne pas trancher la monétisation ici. Ne promettre aucune famille matérielle supplémentaire ni date de sortie avant ces validations.

### Plan retenu par Codex : cinq lots maximum

Tous les seuils ci-dessous sont **proposés par Codex**, à approuver et ajuster après le premier relevé.
Les années de carrière viennent du brief ; la prolongation de contrôle jusqu’à 2030 reprend la proposition d’Astra. [A], section 9
Les lots sont classés ; la préparation administrative peut avancer sans attendre la fin du gameplay.

| Lot | Périmètre proposé | Preuve attendue avant passage |
| --- | --- | --- |
| **A — Sauvegarder et mettre à jour sans perte** | Vérifier l’incident signalé, la signature et le parcours d’installation ; garder une référence de performance sur Pixel et appareil plus modeste. | Mise à jour depuis chacun des postes de développement sans désinstallation ; 20 interruptions/reprises sans perte ; journal des versions et certificats. Aucun secret dans Git. |
| **B — Comprendre le lancement** | Garder la cérémonie ; expliquer les contributions réelles, rendre le bilan consultable et relier note, demande, ventes et marge. Carnet limité aux informations utiles. | 4 novices sur 5 lancent et retrouvent les ventes en moins de 15 minutes sans aide orale ; 8 testeurs sur 10 expliquent la cause principale du verdict et une action possible. Tests calcul/texte couvrant chaque média et les ajustements. |
| **C — Garder des choix en carrière** | Établir la mesure de départ, puis régler besoins et réactions existantes. Ajouter une transition annoncée seulement si les mesures le justifient. | Carrière par chemin réel jusqu’à 2010, puis poursuite jusqu’à 2030 sans blocage ; sur 6 conditions reproductibles, la stratégie adaptée dépasse la figée dans au moins 4 cas au même mode. Publier marge, parts de marché et décisions, pas seulement le classement final. |
| **D — Bêta et qualité mobile** | Test fermé francophone possible après stabilité du parcours ; anglais avant recrutement international. AAB via Play, déclarations, contrôles PC/téléphone et budgets mesurés. | Parcours essentiels sans bouton inaccessible ni texte coupé ; téléchargement inférieur à 150 Mo et démarrage inférieur à 10 s comme budgets initiaux. Viser 30 images/s stables sur appareil modeste, 60 si la chauffe le permet ; mesurer aussi les pauses de fin de mois. Aucun défaut bloquant connu non corrigé ; exigences Play vérifiées séparément. |
| **E — Donner envie de recommencer** | Après les retours de bêta : 2 scénarios limités, redressement et spécialiste. Reporter les départs à année libre et l'argent illimité jusqu’à examen de leur coût. | Victoire et échec atteignables sans blocage pour chaque scénario ; 3 testeurs expérimentés sur 5 choisissent une nouvelle tentative et expliquent ce qu’ils changeraient. |

Pour le lot C, dépasser la stratégie figée doit correspondre à des décisions compréhensibles, pas à une recette artificielle écrite pour réussir la sonde.
Pour Accessible, observer des erreurs puis une récupération avec Nora ; une absence de faillite dans un scénario automatisé n’est pas une garantie universelle.
Une régression des sauvegardes, un blocage tactile ou un résultat incohérent arrête le passage au lot suivant.
Les soirées estimées par Claude restent des suppositions, pas un engagement. Chiffrer l’effort après mesure et périmètre détaillé.
Claude réaliserait le code après décision ; Astra interviendrait sur les seuls visuels nécessaires ; Codex contrôlerait les preuves de passage.

## Cinq questions pour Alexandre

1. Valides-tu l’ordre proposé : sauvegardes, explication des notes, défi de carrière, bêta, puis scénarios — en restant centré sur les CPU ?
2. En Accessible, préfères-tu une aide forte avec erreurs récupérables, ou une protection explicite contre la faillite ? Codex recommande l’aide forte.
3. Veux-tu que les besoins essentiels des clients soient visibles dès le départ, et que le carnet débloque surtout des conseils et comparaisons ? Codex le recommande.
4. Préfères-tu commencer par un test fermé francophone, puis traduire avant d’élargir, ou attendre l’anglais pour recruter ? Codex recommande le test francophone ciblé.
5. Pour rejouer, acceptes-tu de commencer après la bêta par des scénarios limités, et de reporter les années de départ libres ? Codex le recommande.

## Sources et traçabilité

Les sources web ci-dessous ont été ouvertes par Codex le 01/10/2026. Les relevés de boutiques ne valent que pour les pages consultées.
Les références de code ont été relues directement ; les résultats d’exécution attribués aux analyses ne sont pas certifiés à nouveau.
Le seul fichier à publier est `docs/design/concurrence/synthese.md` sur `v010/concu-synthese`, depuis `v010/concu-brief`.
Pas de modification de code, de roadmap ou de décision ; pas de test du jeu lancé pour ce document.

[A]: https://github.com/vadorus/addonhardwaregame2d/blob/c3667f5/docs/design/concurrence/analyse-astra.md
[C]: https://github.com/vadorus/addonhardwaregame2d/blob/3af8366/docs/design/concurrence/analyse-claude.md
[W1]: https://store.steampowered.com/app/2832320/PC_Tycoon_2/
[W2]: https://store.steampowered.com/app/4490710/Hardware_Tycoon/
[W3]: https://store.steampowered.com/app/3600280/Processor_Dev_Tycoon/
[W4]: https://steamcommunity.com/app/2832320/reviews/?browsefilter=toprated
[W5]: https://play.google.com/store/apps/details?id=com.greenheartgames.gdt&hl=en
[W6]: https://support.google.com/googleplay/android-developer/answer/14151465?hl=en
[W7]: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en
[W8]: https://developer.android.com/guide/practices/page-sizes
[W9]: https://developer.android.com/studio/publish/app-signing
