# Analyse de Claude — Tech Empire face à ses concurrents

Écrite le 01/10/2026 au soir, seul, avant de connaître l'analyse d'Astra. Base : commit `94592cd`.
Sources web en fin de fichier. « Sonde » = `tests/tools/profiles_probe` ou `campaign_probe`, rejouées le 01/10 à 22 h 35.

## En une phrase

Le créneau « fabricant de puces » n'a **aucun bon jeu** : les deux concurrents les plus directs sont à 62 % et 30 %
d'avis positifs sur Steam, et aucun n'est pensé pour le téléphone. Tech Empire peut devenir **le « Game Dev Story »
des puces** : chaleureux, clair, tactile, 40 ans d'histoire de l'informatique… **à condition de corriger le défaut
qui tue tout le genre : le défi qui s'éteint après les premiers succès.**

## 1. Les concurrents

| Jeu | Plateformes, prix | Avis | Ce qui plaît | Ce qu'on reproche |
|---|---|---|---|---|
| **Game Dev Tycoon** (Greenheart, 2012) | PC, iOS, Android, Switch | Metacritic PC 68, iOS 89, Switch 81 | trouver les bons couples sujet + genre ; la note en chiffre + une phrase ; garage → grand studio | « pas de concurrence », un seul mode, fin de partie répétitive |
| **Game Dev Story** (Kairosoft, 2010) | mobile, PC | Metacritic 86 | simple, rapide, on s'attache à ses employés, humour | « ralentit vers la fin », le succès devient trop facile |
| **PC Tycoon 2** (Insignis, solo, 2024) | PC 7,99 $, mobile gratuit | Steam 79 % (318 avis) | énorme largeur (CPU, GPU, RAM, cartes mères, OS, portables, écrans), 10 locaux, rachats | **note incompréhensible**, « monotone après 1 h 30 », faillite impossible après 2-3 produits, bugs |
| **Laptop Tycoon** (Roastery) | PC, mobile | avis mitigés | interface soignée, facile | trop peu profond (« un clicker »), pas de comparaison de composants, on ne revoit pas ses tests, **rivaux qui ne progressent pas**, pas de bac à sable |
| **Hardware Tycoon** (NordCode, mai 2026) | PC 11,99 $ | Steam 62 % (29 avis) | CPU 1986-2026 très détaillés, usine ou sous-traitance | **prix automatique** qui ruine une bonne puce, tutoriel faible, lenteurs, bug bloquant non corrigé |
| **Processor Dev Tycoon** (Venditor, nov. 2025) | PC | Steam 30 % (10 avis) | le sujet (CPU + histoire) | on ne peut pas sortir de produit, « niveau alpha » |

Ce que ça dit, en trois lignes :
- **Ce qui fait aimer** ces jeux : un début facile, un **moment de note** fort, **on voit grandir** son entreprise, des personnages.
- **Ce qui fait tomber** : 1) plus de défi après les premiers succès ; 2) des règles qu'on ne comprend pas (la note, le prix) ;
  3) des rivaux inertes ; 4) les bugs et l'abandon.
- **La largeur ne sauve pas** : PC Tycoon 2 fait tout, et son reproche n°2 est « monotone ».

## 2. Où Tech Empire est déjà meilleur (à protéger)

1. **L'ambiance et les gens** : Nora, l'équipe visible à son poste, le QG qui vit (saisons, fêtes, météo, nuit, vitrine).
   Seul Kairosoft fait aussi bien ; les tycoons PC sont des tableaux froids.
2. **Des rivaux vivants** (lot F1) : générations, rachats, faillites, nouveaux venus (sonde campagne : Vireo en 1985, Nexus en 1991,
   Aster « en difficulté » en 1990). Game Dev Tycoon et Laptop Tycoon n'en ont pas.
3. **Pensé pour le doigt**, testé sur un Pixel à chaque lot. Les autres sont des portages de jeux PC.
4. **La qualité** : smoke test, sondes, sauvegardes atomiques avec copie de secours. Deux concurrents directs meurent de leurs bugs.
5. **Un fil historique** : architecture → modèles → retour d'expérience, de 1971 à 2010, puis mode libre annoncé honnêtement.

## 3. Où il est en retard : les 3 manques qui coûteraient le plus d'avis

1. **Le défi s'éteint, comme chez les autres.** Sonde 10 ans (1971-1980) :
   - intermédiaire **n°1 mondial** en 1980 avec 20 personnes, 22 M€ ; expert n°1 avec 31 M€ ;
   - novice passif (3 personnes) : 5,1 M€, trésorerie qui monte chaque année sans jamais une décision risquée.
   Il reste ensuite **30 ans** de partie sans adversaire à sa taille. C'est exactement le « monotone après 1 h 30 » de PC Tycoon 2.
2. **On ne sait pas pourquoi on a sa note.** Je n'ai trouvé aucun écran « pourquoi cette note » dans le code
   (recherche `score_breakdown`, « pourquoi cette note »… : rien). C'est le reproche n°1 de PC Tycoon 2.
   *À confirmer au doigt par Astra.*
3. **Le jeu n'existe qu'en français.** Environ **4 400 textes** dans 94 fichiers, **0 appel de traduction** (`tr()`)
   (comptage du 01/10). Sur Google Play, tous les concurrents sont en anglais au minimum. *Supposition : le public
   francophone seul est trop petit pour qu'un jeu payant trouve son public.*

Juste derrière : **on ne peut pas rejouer autrement** (un seul départ : 1971, garage), alors que Game Dev Tycoon et
Laptop Tycoon sont critiqués pour ça.

## 4. La partie longue : garder le défi sans devenir hardcore

Idée centrale : **chaque époque change ce que les clients veulent.** Le n°1 d'une époque peut perdre la suivante s'il ne
s'y prépare pas. C'est vrai dans l'histoire (le « dilemme de l'innovateur »), lisible, et ça s'appuie sur ce qui existe déjà
(axes des équipes R&D : vitesse, énergie, fiabilité ; 10 marchés).

**R1, les ruptures d'époque** (5, annoncées par la presse et par Nora 2 ans avant) :
| Époque | Ce qui change |
|---|---|
| 1977-1981 micro-ordinateur | le PC familial explose, le prix compte plus que tout |
| 1981-1986 le standard | un format domine : compatibilité et volumes |
| 1986-1993 stations et serveurs | la fiabilité et la performance pure rapportent |
| 1993-2001 course aux MHz | vitesse d'abord, la chaleur commence à coûter |
| 2001-2010 basse consommation, mobile, multicœur | l'énergie devient reine ; les « fours » perdent |

Celui qui a misé sur la bonne équipe R&D avant la rupture gagne ; celui qui reste sur l'ancienne recette perd des parts,
**lentement et en le voyant venir** (jamais de chute brutale non annoncée : c'est la ligne « novice jamais perdu »).

**R2, des rivaux qui répondent au n°1** : quand le joueur domine un marché, un rival le vise (baisse de prix, contre-lancement
6 mois plus tard, débauche un ingénieur). Toujours annoncé par la presse : c'est un défi lisible, pas une punition.

**R3, des objectifs de décennie** : au début de chaque décennie, Nora propose 3 objectifs (ex. « 10 % du marché mobile
avant 2008 »), le joueur en choisit un. Récompense : trophée et prestige. Ça donne une direction au jeu long, qui manque à
Game Dev Tycoon.

**Ce que je ne ferais pas** : des coûts fixes qui explosent juste pour vider la caisse (ressenti comme une punition), ou une
difficulté qui monte toute seule avec le temps.

**Critères (sonde `profiles_probe`, étendue à 20 ans)** : intermédiaire pas n°1 avant 1985 ; à chaque rupture, un leader
passif perd au moins une place ; aucun profil n'empile de l'argent 10 ans d'affilée sans une décision qui le dépense ;
le novice en Accessible ne fait jamais faillite.

## 5. Le lancement et la note

**N1, la note expliquée en 4 barres**, face au meilleur rival du même marché : performance, consommation, prix, fiabilité.
Plus une phrase de la presse (« Rapide, mais trop cher pour le grand public »). Montrée au lancement, **et qu'on peut revoir**
depuis la fiche du produit (Laptop Tycoon est critiqué parce qu'on ne peut pas).

**N2, le carnet de Nora** : ce que chaque marché valorise (10 marchés × 4 critères). Au début, des « ? ». Chaque lancement,
ou une étude de marché payante, en révèle un. C'est notre équivalent des couples sujet + genre de Game Dev Tycoon :
**le joueur apprend, et il sent qu'il apprend.** Le carnet évolue aux ruptures (R1), ce qui relance l'apprentissage.

**N3, la mise en scène** : la note se révèle barre par barre, avec le jingle du lot L. Petit effort, gros effet.

**Critère** : au doigt, un novice explique en une phrase pourquoi son CPU a eu sa note ; test : chaque lancement produit
les 4 barres et la phrase.

## 6. Rejouer

**S1, quatre départs** (même moteur, autre situation de départ, textes de Nora dédiés) :
1971 garage (actuel) ; 1984 outsider face à des rivaux installés ; 1995 reprise d'une entreprise en difficulté ;
2001 sans usine (« fabless »), tout en sous-traitance.
**S2, trois défis courts** (30-60 min) avec un objectif et une date limite.
**S3, bac à sable** : option « argent illimité » pour ceux qui veulent juste construire (demandé pour Laptop Tycoon). Presque gratuit.

Effort : S1 moyen (états de départ + textes), S2 petit, S3 très petit.

## 7. La largeur (autres produits)

**Pas maintenant.** Nos 10 marchés donnent déjà la variété, et la largeur de PC Tycoon 2 ne l'empêche pas d'être « monotone ».
**Plus tard (V0.11+)**, une seule famille de plus, qui réutilise le système d'architecture : soit les **puces graphiques**
(à partir de l'époque 1993-2001), soit les **puces sur mesure** pour consoles et mobiles, vendues par contrat (ces marchés existent déjà).
**Jamais** : systèmes d'exploitation, assemblage de portables, écrans. C'est un autre jeu, et le chantier exploserait.

## 8. Avant une bêta Google Play

Indispensable :
- **l'anglais** (lot E ci-dessous) ;
- **un téléphone modeste** : le Pixel 10 est haut de gamme. Il faut mesurer sur un téléphone d'entrée de gamme ou un émulateur bridé ;
- **la clé de test commune aux deux PC** (lot Q0 jamais fait : le 01/10, une installation a effacé la partie d'Alexandre, restaurée depuis la sauvegarde) ;
- politique de confidentialité, fiche, captures, et 12 testeurs pendant 14 jours (règle Google pour un nouveau compte personnel).

Peut attendre : sauvegarde dans le cloud, succès Google Play Jeux, version tablette dédiée.
Taille : l'AAB fait 43 Mo, c'est correct. Le prix et le modèle payant relèvent de l'étude monétisation, déjà en cours.

## 9. Le plan : 5 lots, dans cet ordre

| # | Lot | Contenu | Qui | Terminé quand |
|---|---|---|---|---|
| 1 | **R — Le défi ne s'éteint pas** | R1 ruptures d'époque + R2 rivaux qui répondent (R3 si le temps le permet) | Claude (+ Astra : une illustration par époque) | critères du point 4 sur la sonde 20 ans, smoke test vert |
| 2 | **N — La note qu'on comprend** | N1 + N2 + N3 | Claude (+ Astra : 4 icônes de critères, page du carnet) | critère du point 5 ; partie au doigt sur le Pixel |
| 3 | **E — English** | tous les textes passent par la traduction ; choix de langue au premier lancement | Claude (code) + traduction relue par Astra ou Codex | un test parcourt chaque écran en anglais : 0 texte français |
| 4 | **P — Prêt pour le Play Store** | Q0 clé commune, perf téléphone modeste, fiche et captures, test fermé | Claude + Astra (visuels de la fiche) | 60 images/s au QG sur téléphone modeste ; 0 plantage pendant les 14 jours de test fermé |
| 5 | **S — Rejouer** | S1 quatre départs + S2 trois défis + S3 bac à sable | Claude | chaque départ joué 30 min par sonde sans blocage ni faillite en Accessible |

Pourquoi cet ordre : R et N corrigent les deux reproches qui font les mauvais avis du genre. E et P sont nécessaires avant
la bêta publique. S peut sortir **après** la publication : une mise à jour qui apporte des départs nouveaux fait revenir les
joueurs et aide le classement sur le store.

Effort (supposition, en soirées de travail d'Alexandre avec les IA) : R 4, N 3, E 3, P 2, S 3.

## Ce que je déconseille

- **Copier la largeur de PC Tycoon 2** : beaucoup de travail, et ça ne règle pas l'ennui.
- **Le réalisme pointu** (prix automatiques, cache, pipeline… façon Hardware Tycoon) : avis mitigés, novices perdus.
- **Ajouter du contenu avant de corriger la partie longue** : on rendrait plus large un jeu qui s'éteint au même moment.

## Sources

- Game Dev Tycoon : [Wikipedia](https://en.wikipedia.org/wiki/Game_Dev_Tycoon), [test Gamer Horizon](https://gamerhorizon.com/2014/01/15/lttp-game-dev-tycoon-review-simgame/)
- Game Dev Story : [Wikipedia](https://en.wikipedia.org/wiki/Game_Dev_Story), [PC Gamer sur les jeux Kairosoft](https://www.pcgamer.com/game-dev-story-leads-kairosofts-irresistible-sim-lite-games-onto-steam/)
- PC Tycoon 2 : [page Steam](https://store.steampowered.com/app/2832320), [avis Steam](https://steamcommunity.com/app/2832320/reviews/?browsefilter=toprated), [version mobile (TapTap)](https://www.taptap.io/app/33569098)
- Laptop Tycoon : [avis Steam](https://steamcommunity.com/app/1780270/reviews/?browsefilter=toprated)
- Hardware Tycoon : [page Steam](https://store.steampowered.com/app/4490710/Hardware_Tycoon/), [avis Steam](https://steamcommunity.com/app/4490710/reviews/?browsefilter=toprated)
- Processor Dev Tycoon : [page Steam](https://store.steampowered.com/app/3600280/Processor_Dev_Tycoon/), [avis Steam](https://steamcommunity.com/app/3600280/reviews/?browsefilter=toprated)
- Test fermé Google Play (12 testeurs, 14 jours) : [Squirrel, guide 2026](https://www.squirrel.fr/comment-creer-compte-developpeur-google-play-android/)
