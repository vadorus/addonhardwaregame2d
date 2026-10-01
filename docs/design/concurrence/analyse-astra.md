# Tech Empire face à ses concurrents — analyse indépendante d’Astra

Date de consultation : 01/10/2026. Référence du jeu : `94592cd`, fournie par le brief.
Brief et protocole lus sur `v010/concu-brief`. Aucune autre analyse ni synthèse consultée.
Méthode : lecture ciblée du code, fiches officielles et avis publics. Aucun jeu lancé, aucune sonde exécutée, aucun essai au doigt.
Les références `fichier:ligne` désignent ce commit. Les liens [S…] sont réunis à la fin.
Les nombres marqués « objectif proposé » sont des critères à essayer, pas des résultats obtenus.
Les avis ci-dessous sont un échantillon choisi par les plateformes, souvent ancien : ils signalent des problèmes possibles, pas leur fréquence actuelle.
Les expressions « reproche principal du genre » du brief restent des hypothèses : cette recherche ne permet pas de les classer statistiquement.

## 1. Les concurrents qui comptent

| Jeu et rôle dans la comparaison | Ce qui attire et plaît | Reproches observés, avec leur portée |
| --- | --- | --- |
| **PC Tycoon 2 — PC et Android ; concurrent direct.** | Concevoir ses composants, personnaliser une gamme et racheter des fournisseurs. La fiche revendique une gestion détendue ; White apprécie les créations originales et les acquisitions. [S1, S2, S3] | MoonRacer, CX Music et Pho3niX90 décrivent des notes qu’ils jugent incohérentes ; White le relève aussi malgré son avis favorable. FabiusMaximus trouve la réussite ensuite trop facile. Ces témoignages Steam ne prouvent pas que la version Android actuelle a les mêmes défauts. [S2] |
| **Game Dev Tycoon — PC et Android ; référence du rythme et de l’attachement.** | Partir du garage, donner un nom à sa création, découvrir les combinaisons et attendre les critiques. Senarin raconte un lancement raté qui menace sa société ; les avis Android apprécient l’expérimentation et les progrès. [S4, S5] | Hu Man demande une meilleure gestion des séries et de l’historique. Le récit de Senarin montre aussi combien une combinaison mal comprise peut frustrer. Ce n’est pas une preuve d’un système cassé ; l’accueil lu est largement favorable. [S5] |
| **Laptop Tycoon — référence PC, également présent dans le catalogue Android du même éditeur.** | Le dessin du produit, les animations et l’ambiance tranquille plaisent à plusieurs auteurs, dont Rymac_1 et Pip. [S6, S7] | Pip critique la comparaison des composants et les explications des notes ; Mr.Nice Guy trouve les choix superficiels ; M24H veut réutiliser ses anciens produits. Avis anciens : ne pas affirmer que ces défauts sont tous encore présents. [S6] |
| **Devices Tycoon — Android ; concurrent de la promesse « créer mon appareil ».** | Large choix d’appareils et éditeur visuel mis en avant par la fiche. Eddi-Jay Ohlms aime le jeu ; Mad Jay apprécie les mises à jour. [S7] | Mad Jay dit manquer d’usages intéressants de l’argent après avoir réussi. A demande de réduire les manipulations répétées pour ouvrir des boutiques. Témoignages individuels, pas consensus. [S7] |
| **Mad Games Tycoon 2 — PC ; référence de profondeur, concurrent secondaire.** | Le catalogue Steam met en avant la gestion étendue ; des joueurs aiment les rachats, les franchises et la liberté de bâtir leur groupe. [S8, S9] | JohnJohn demande des mods ; Shodan v3.0 signalait des difficultés d’aménagement et de lecture des retours pendant l’accès anticipé. Ce sont des demandes et observations datées, pas une mesure de qualité actuelle. [S9] |

Priorité : battre PC Tycoon sur la compréhension des décisions, et égaler Game Dev Tycoon sur l’envie de lancer le produit suivant.
La largeur de Devices et la complexité de Mad Games ne doivent pas devenir une liste de fonctions à reproduire.
La boutique Android de Game Dev Tycoon annonce l’absence de publicités et d’achats intégrés : le respect du joueur n’est donc pas un avantage exclusif de Tech Empire. [S5]

## 2. Ce que Tech Empire possède déjà et doit protéger

**Aucune supériorité globale n’est démontrée sans parties comparées.** Voici les avantages de conception déjà présents dans le code.
- **Un atelier identifiable.** Garage, atelier, siège et campus ont leurs propres décors et placements d’équipe ; Nora appartient à cet espace. [`ui/WorkplaceArt.gd:6-36`]
- **Une profondeur progressive.** Accessible, Standard et Simulation modifient l’accompagnement, la délégation et les rivaux, pas seulement le capital. [`scripts/BalanceManager.gd:5-66`]
- **Apprendre de ses produits.** Les retours de ventes, les retours clients et la rentabilité alimentent les conseils pour la génération suivante. Cela peut rendre l’apprentissage plus concret que deviner des curseurs. [`scripts/CpuMarketLearning.gd:24-90`]
- **Des rivaux qui décident.** Baisser un prix, accélérer la recherche, conserver du cash ou changer de cible existent déjà. Leur intérêt vécu reste à mesurer. [`scripts/CompanyAIManager.gd:50-120`]
- **Un début de justification de la presse.** Le jeu compare le produit à son prédécesseur et au meilleur rival. Protéger cette continuité entre choix et verdict. [`scripts/MediaManager.gd:84-109,130-148`]

Mon avantage distinctif proposé : « Je comprends ma prochaine décision et je vois mon entreprise grandir. »
L’ambiance chaleureuse soutient cette promesse ; elle ne remplace ni les arbitrages ni la fiabilité.

## 3. Les trois manques les plus risqués pour une sortie immédiate

**A — Une preuve de lisibilité de la note.** Le calcul existe, mais la carte expose surtout titre, média et comparaison.
Les pondérations, l’effet de l’interview et le lien avec les ventes ne sont pas tous expliqués dans cette carte.
Risque : « J’ai amélioré ma puce, pourquoi cette note ? » [`scripts/MediaManager.gd:118-136,188-213` ; `ui/components/ReviewRevealPanel.gd:151-189`]
Ce constat porte sur ces chemins lus ; il ne démontre pas qu’aucune autre aide n’existe.

**B — Une carrière complète dont le défi est prouvé.** Les événements tardifs consultés alternent surtout hausses de demande et baisse des coûts.
Ils entretiennent l’animation du marché, sans démontrer qu’un empire bien installé doit changer de stratégie. [`scripts/LateGameEvents.gd:10-16,56-82`]
La sonde de campagne injecte directement des produits et des caractéristiques ; elle contourne leur développement. Elle ne valide donc pas seule le parcours réel. [`tests/tools/campaign_probe.gd:92-115`]

**C — Une qualité mobile et une langue adaptées au public recruté.** Des textes français sont écrits directement dans les écrans consultés.
L’anglais n’est pas prouvé prêt ; le confort tactile, la reprise après interruption et la fluidité ne sont pas testés ici.
Un preset AAB existe déjà : le manque est sa validation en distribution réelle, pas sa création. [`ui/components/ReviewRevealPanel.gd:74-80,133-144` ; `export_presets.cfg:106-146`]
Risque de mauvais avis : une bonne simulation dont on ne peut pas lire, comprendre ou reprendre la partie.

## 4. Garder un défi jusqu’à la fin technologique

L’objectif n’est pas de menacer constamment la survie. Il faut renouveler la question intéressante.
Période du brief : de 1975 à 2010 ; plafond technologique confirmé par `scripts/MarketManager.gd:25`.

- **Au début : choisir où être utile.** Clients modestes, fiabilité ou performances, calendrier de sortie et réserve de trésorerie.
- **Quand la société grandit : choisir ce qu’elle ne fera pas.** Les équipes, la capacité et le support de l’ancienne gamme limitent les projets simultanés.
- **Quand elle domine : défendre une réputation et un marché.** Un rival ciblé ou un changement de besoins rend une spécialisation moins confortable.
- **Après le plafond : une conclusion de carrière, puis des objectifs libres.** Proposer un bilan mémorable et des défis volontaires de qualité, d’efficacité ou de redressement. Ne pas promettre une recherche infinie.

Réutiliser l’obsolescence, les besoins des marchés et les choix des rivaux avant d’ajouter un nouveau simulateur. [`scripts/MarketManager.gd:678-694,847-957`]
Annoncer le changement, expliquer qui il touche, puis laisser choisir : investir, changer de cible, accepter une baisse ou déléguer.
Éviter la taxe cachée proportionnelle à la réussite et le rival qui reçoit soudain des avantages impossibles à comprendre.
Accessible peut prévenir davantage et laisser plus de temps ; Simulation peut réduire l’aide sans augmenter les tâches répétitives.

**Mesure proposée :** comparer une stratégie figée à des adaptations explicables, au même niveau de difficulté et avec les mêmes conditions initiales.
Chercher une perte de compétitivité évitable, pas forcément une faillite.
La trésorerie seule est insuffisante : suivre marge, parts de marché, demande perdue et raisons de modifier la gamme.
Les profils existants mélangent par défaut modes et comportements ; forcer le même mode pour isoler l’effet de la stratégie. [`tests/tools/profiles_probe.gd:15-18,25-30,45-47`]

## 5. Le lancement et la note

La révélation progressive, le son, la moyenne et le verdict sont **déjà codés**. Inutile de financer une seconde cérémonie. [`ui/components/ReviewRevealPanel.gd:70-149`]
Le progrès à faire est une mise en scène de la conséquence :
- Avant le lancement, rappeler la cible, la promesse et le risque assumé. Montrer une prévision avec incertitude, pas une garantie.
- Pendant, laisser respirer le nom et l’image de la puce, puis révéler les critiques. Permettre d’accélérer pour les habitués.
- Après, expliquer pourquoi chaque média aime ou critique ce produit, puis proposer une action utile.
- Aux ventes, distinguer qualité appréciée, demande disponible, visibilité, capacité et marge : une bonne note ne garantit pas un bénéfice.

**Proposition :** une carte « Votre pari / Ce qui a plu / Ce qui freine / Prochain essai », puis le détail sur demande.
Le détail doit venir des contributions du vrai calcul, sans texte générique qui pourrait contredire le résultat.
Comparer au bon usage : une puce industrielle fiable peut réussir sans gagner le classement de puissance.

Attention aux règles actuelles : l’interview « honnête » ajoute 3 points ; « audacieuse » donne +6 ou −8 selon le rang.
Ces chiffres proviennent de `scripts/MediaManager.gd:118-128`, sur l’échelle interne de la note.
Les afficher et les expliquer, puis tester si le choix reste intéressant. Sinon, l’honnêteté risque de devenir un bouton automatique.
La présentation ne doit pas faire oublier les qualités techniques ni enseigner « choisir la bonne réplique » comme stratégie dominante.

**Objectif proposé :** 8 testeurs sur 10 peuvent nommer la cause principale du verdict et une amélioration pertinente, sans consulter un guide.
**Test proposé :** à contexte identique, une meilleure fiabilité ne dégrade pas le jugement d’un média qui la valorise ; le texte suit les contributions réelles.

## 6. Rejouer sans multiplier le travail

Les efforts ci-dessous sont des estimations qualitatives proposées, pas des devis.
- **Conserver les modes existants — effort faible.** Améliorer leur description et leur sélection ; ne pas ajouter des difficultés synonymes.
- **Scénarios de départ — effort moyen.** Reprendre une société fragile, battre un spécialiste ou réussir avec une petite équipe. Réutiliser les systèmes et les conditions de victoire.
- **Bac à sable explicite — effort faible à moyen.** Séparer la poursuite libre après carrière d’un mode sans contraintes financières. Exclure les performances de ce dernier des records de carrière.
- **Graines reproductibles — effort moyen.** Le même identifiant recrée les conditions d’une partie ; utile pour partager un défi et reproduire un défaut.
- **Année de départ libre — effort élevé.** Initialiser ensemble technologies, marchés, rivaux, équipe et historique. À reporter : changer seulement la date produit une partie incohérente.
- **Mods et défis quotidiens connectés — effort élevé et entretien permanent.** À reporter tant que les scénarios locaux n’ont pas prouvé leur intérêt.

Je commencerais par un scénario de redressement et un défi de spécialiste : **quantité proposée de 2**, pas contenu existant.

## 7. Élargir au-delà des CPU

**Maintenant : finir la boucle CPU.** Un marché « console » ou « mobile » acheteur de puces n’équivaut pas à fabriquer une console ou un téléphone.
La variété peut déjà venir des usages, des gammes et des engagements clients.
C’est aussi la priorité de `AGENTS.md` : la branche CPU doit être validée avant d’autres secteurs.

**Plus tard : des cartes graphiques**, si elles obligent à faire de nouveaux arbitrages visibles et réutilisent production, recherche et ventes.
Commencer par une expérience limitée, puis décider selon les retours ; pas une feuille de route de toutes les familles.
**Mémoire et cartes mères : après**, seulement si leurs liens avec les CPU enrichissent les décisions plutôt que multiplier les mêmes écrans.
**Consoles : bien après**, car contenus, écosystème et cycle de plateforme créent un autre jeu.
**Jamais comme objectif :** l’exhaustivité matérielle. Aucune famille n’est interdite par principe, mais aucune ne mérite d’entrer pour remplir une liste.

## 8. Avant une bêta Google Play

Distinguer test interne, test fermé et bêta ouverte. Leur accès n’est pas identique. [S10]
**Indispensable pour le produit :**
- Parcours complet au doigt : nouvelle partie, lancement, ventes, sauvegarde, reprise et génération suivante. Vérifier aussi clavier et souris sur PC.
- Reprise après mise en arrière-plan, fermeture du processus et mise à jour ; compatibilité des anciennes sauvegardes. Une écriture atomique existe, mais cela ne remplace pas ces essais. [`scripts/SaveManager.gd:163-216`]
- Mesurer temps de démarrage, blocages de fin de mois, mémoire, chauffe et taille téléchargée sur le Pixel d’Alexandre et un appareil moins puissant.
- Anglais complet avant recrutement international. Une bêta fermée francophone peut commencer auparavant ; l’anglais n’est pas une obligation réglementaire citée ici.
- Fiche honnête : jeu centré sur les CPU, histoire technologique finie, poursuite libre. Ne pas vendre les extensions futures comme disponibles.

**Indispensable pour la distribution :**
- Faire accepter et installer un AAB signé via Play ; contrôler la cible Android réelle du paquet. Le preset seul ne le prouve pas. [S11 ; `export_presets.cfg:106-146`]
- Google exige actuellement Android 16 / API 36 pour les nouvelles applications ordinaires depuis le 31/08/2026, sous réserve d’extension accordée : source officielle consultée [S12].
- Vérifier les bibliothèques natives et l’exécution avec pages mémoire de 16 Ko ; suivre l’échéance applicable dans la console, sans supposer que « Godot exporte » suffit. [S13]
- Préparer confidentialité, déclaration des données, public visé, classification et présence ou absence de publicité. Même sans collecte, le formulaire et une politique sont requis hors exemption du test exclusivement interne. [S14, S15]
- Si le compte personnel a été créé après le 13/11/2023 : au moins 12 testeurs inscrits sans interruption pendant 14 jours avant demande d’accès production. La bêta ouverte dépend de cet accès ; le test fermé n’attend pas ces jours pour commencer. [S10]

**Taille et performances : objectifs proposés**, à ajuster après mesure : téléchargement inférieur à 150 Mo, démarrage inférieur à 10 secondes, au moins 30 images/s pendant le jeu courant.
Ce sont des budgets de confort, pas les limites officielles de Google, ni des mesures du jeu.
**Prix :** je recommande un achat unique pour le jeu complet, à valider auprès des testeurs avant publication. Pas de prix chiffré défendable avec cette seule étude.
Différer la boutique cosmétique ; les skins ne doivent modifier ni économie ni progression. Trancher le modèle commercial avant de figer la fiche.
**Peut attendre :** traduction dans d’autres langues, synchronisation en ligne, succès de plateforme, extensions matérielles et nouveaux décors coûteux.

## 9. Plan proposé — cinq lots classés

Tous les seuils du tableau sont des **objectifs proposés**. Ils doivent être approuvés puis mesurés, sans annoncer qu’ils sont déjà atteints.
Les efforts sont relatifs ; fixer un petit périmètre et réévaluer après chaque lot.

| Ordre et lot | Livrable et effort estimé | Critère de passage |
| --- | --- | --- |
| **1 — Comprendre et réussir son lancement** | Explications tirées du calcul, cérémonie actuelle mieux reliée aux ventes, aide Nora ciblée. Effort moyen. | Sur Pixel, 4 novices sur 5 lancent et retrouvent leurs ventes en moins de 15 minutes sans aide orale ; 8 testeurs sur 10 expliquent leur verdict. Tests de cohérence entre calcul et texte réussis. |
| **2 — Prouver la carrière et son défi** | Étendre le chemin réel des profils ; garder la sonde de campagne pour le marché et les rivaux. Rééquilibrer les passages où une stratégie ne demande plus de choix. Effort élevé, principal investissement. | Du départ jusqu’à 2010 puis jusqu’à 2030, pas d’état bloqué. Sur 6 conditions initiales reproductibles, une stratégie adaptée bat la stratégie figée en marge cumulée dans au moins 4 cas au même mode ; journal des décisions explicable. Dates de fin : brief et sonde ; seuils : proposés. |
| **3 — Rendre le jeu fiable sur téléphone** | Anglais si recrutement international, lisibilité tactile, sauvegardes, budgets de performance et AAB installé via Play. Effort moyen à élevé. | 20 cycles interruption/reprise et une mise à jour sans perte de progression ; parcours sans texte coupé ni bouton inaccessible ; budgets de la section précédente mesurés sur appareils et builds identifiés. |
| **4 — Donner envie de recommencer** | Scénarios de redressement et de spécialiste, choix de mode clair, bilan de carrière mémorable. Effort moyen. | Chaque scénario a une victoire et un échec atteignables par scripts ; 3 testeurs expérimentés sur 5 choisissent volontairement une seconde tentative après essai, et peuvent expliquer ce qu’ils changeraient. |
| **5 — Bêta fermée et décision de sortie** | Déclarations Play, fiche fidèle, collecte des défauts, correction des obstacles récurrents, décision de prix. Effort moyen, avec délai externe. | Aucun défaut bloquant connu après recontrôle ; tous les testeurs savent reprendre leur partie ; accès production demandé seulement si exigences [S10–S15] et critères précédents sont remplis. |

Le lot de rejouabilité peut attendre si la carrière reste mal comprise ; la stabilité mobile ne le peut pas.
Aucun lot GPU n’entre dans cette séquence. La meilleure prochaine version est une boucle CPU aboutie, pas un catalogue plus grand.

## Sources web consultées

Les pages de boutique servent à établir l’offre ; les avis servent à rapporter l’expérience de leurs auteurs.
Les notes agrégées, devises et versions varient selon la page et le pays : aucune comparaison numérique de popularité n’est utilisée.

- [S1] PC Tycoon 2, fiche Steam : https://store.steampowered.com/app/2832320/PC_Tycoon_2/?l=english
- [S2] PC Tycoon 2, avis Steam cités par pseudonyme : https://steamcommunity.com/app/2832320/reviews/?browsefilter=toprated
- [S3] PC Tycoon 2, fiche Android : https://play.google.com/store/apps/details?id=com.InsignisGames.PCTycoon2&hl=en
- [S4] Game Dev Tycoon, fiche Steam : https://store.steampowered.com/app/239820/Game_Dev_Tycoon/?l=english
- [S5] Game Dev Tycoon, avis Senarin : https://steamcommunity.com/app/239820/reviews/?browsefilter=toprated ; fiche et avis Android : https://play.google.com/store/apps/details?id=com.greenheartgames.gdt&hl=en
- [S6] Laptop Tycoon, avis Steam : https://steamcommunity.com/app/1780270/reviews/?browsefilter=toprated
- [S7] Devices Tycoon, fiche Android, avis et catalogue de l’éditeur : https://play.google.com/store/apps/details?id=com.roasterygames.devicestycoon&hl=en
- [S8] Mad Games Tycoon 2, fiche Steam : https://store.steampowered.com/app/1342330/Mad_Games_Tycoon_2/
- [S9] Mad Games Tycoon 2, avis Steam : https://steamcommunity.com/app/1342330/reviews/?browsefilter=toprated
- [S10] Google, conditions de test des nouveaux comptes personnels : https://support.google.com/googleplay/android-developer/answer/14151465?hl=en
- [S11] Google, création, bundles et signature : https://support.google.com/googleplay/android-developer/answer/9859152?hl=en
- [S12] Google, cible Android obligatoire : https://support.google.com/googleplay/android-developer/answer/11926878?hl=en
- [S13] Android Developers, compatibilité des pages mémoire : https://developer.android.com/guide/practices/page-sizes
- [S14] Google, déclaration de sécurité des données : https://support.google.com/googleplay/android-developer/answer/10787469?hl=en
- [S15] Google, préparation de l’examen : https://support.google.com/googleplay/android-developer/answer/9859455?hl=en
