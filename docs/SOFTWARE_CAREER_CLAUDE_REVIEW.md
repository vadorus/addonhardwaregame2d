# Revue de conception : la carrière logicielle et les moyens de gagner de l'argent dans Tech Empire

## Statut et relecture de la proposition

> **Statut :** proposition de Claude demandée par le créateur, lue sur le commit `f031f9e`. Elle décrit un futur gameplay ; aucun mécanisme de ce rapport n'est implémenté par sa seule publication. Claude n'a ni exécuté Godot ni testé le téléphone.

## Relecture avant adoption

- **Liberté dès le garage :** le joueur doit pouvoir commencer directement un produit à sa marque. Le contrat Morel ne doit pas devenir un passage obligé, même si le parcours d'exemple le met en premier.
- **Matériel toujours facultatif :** une demande industrielle peut suggérer cette branche, mais le joueur doit aussi pouvoir la choisir de sa propre initiative dès que les moyens et prérequis techniques sont réunis.
- **Économie illustrative :** les tableaux sur 12 mois ne sont pas un équilibrage validé. Les charges existantes comprennent notamment 500 € de garage/fournitures **et 900 € d'entretien/locaux par mois** dans le premier bilan du prototype ; recalculer les scénarios avant de reprendre leurs trésoreries.
- **Rythme à mesurer :** 30 jours × 1,6 seconde = 48 secondes de simulation par mois ; cinq mois ne font que quatre minutes hors pauses. Valider le parcours de 30 minutes sur téléphone avant de fixer l'horloge.
- **Historique et monnaie :** les montants en euros, tarifs de location, taux de maintenance et exemples de 1971 sont des paramètres de jeu proposés, pas des faits historiques ni des prix vérifiés.

---


> **Version examinée.** Le chemin Windows `C:\Users\Admin\Documents\TechEmpire-v031-validation` n'est pas accessible depuis cette session cloud, et le dépôt qui y est attaché (`vadorus/addonhardwaregame`) est vide. J'ai donc lu la branche **`feature/ui-ux-v0.3.1`** de `vadorus/addonhardwaregame2d`, commit `f031f9e` (« Add founder software after-sales choices and phone studio focus », 23/09/2026), en lecture seule. Si votre copie locale contient des modifications non poussées, elles ne sont pas couvertes ici.
>
> **Ce que j'ai fait et pas fait.** Je n'ai modifié aucun fichier du dépôt et fait aucun commit. Je n'ai lancé ni Godot ni les tests du projet, et rien n'a été vérifié sur téléphone. Les chiffres « actuels » sont calculés à la main à partir des formules du code. Les chiffres « proposés » viennent d'un petit modèle Python de brouillon, hors dépôt, qui sert seulement à vérifier que les ordres de grandeur tiennent.
>
> **Précision.** Le fichier `scripts/Economy.gd` n'existe pas : l'autochargement `Economy` pointe vers `scripts/EconomyManager.gd` (`project.godot:29`).

---

## 0. Verdict

La branche contient déjà les bons verbes : contrat client, produit sous sa propre marque, coder / tester / faire connaître, assistance, prospection, adaptation, nouvelle version. En revanche, **il manque le cœur économique**. Le logiciel ne connaît ni clients, ni prix, ni base installée, ni concurrents, ni saturation. Le temps du fondateur n'est pas une ressource. Il en découle trois défauts majeurs :

1. **Une rente passive qui dure indéfiniment, et même augmente.** Un logiciel publié rapporte environ 2 000 € par mois sans rien faire, et au moins autant cinq ans plus tard. Avec quelques clics de prospection et d'assistance, il dépasse 10 000 € par mois.
2. **Des actions qu'on peut enchaîner sans arbitrer.** Le délai de 3 jours de jeu représente 2,4 secondes réelles à vitesse x1. On peut monter la visibilité et la qualité au maximum en une vingtaine de secondes.
3. **Des arbitrages faux.** « Coder » est un piège, parce que le projet avance tout seul. Le choix de l'imprévu client est neutralisé par un bug. Les contrats se répètent à l'identique auprès de clients sans mémoire.

Ma recommandation centrale reprend la logique de la revue CPU (une boucle concrète et des arbitrages lisibles) :

> **Le temps du fondateur, compté en jours, devient la ressource rare. En 1971, chaque vente coûte du travail (installation, formation, assistance) et entame une base installée qui s'épuise. La propriété du code est une clause de contrat que le joueur négocie.**

Ces trois règles suppriment la rente gratuite et l'enchaînement de clics, et créent le pont entre contrat et produit. Tout le reste (plateformes, outils, systèmes, exploitation) peut ensuite s'y greffer.

---

## 1. Diagnostic vérifié de l'existant

### 1.1 Ce qui est jouable aujourd'hui (dans le code)

| Mécanisme | Où | Ce qui se passe réellement |
|---|---|---|
| Catalogue de 4 logiciels | `scripts/SoftwareStudioManager.gd:5-10` | Gestion de stocks, facturation, outils pour mini-ordinateurs, OS pour mini-ordinateurs. Tous datés de 1971. Le déblocage dépend seulement de `FounderManager.programming_level` (1, 1, 2, 3), voir `:26-33`. |
| Lancer un produit | `:41-56` | Coût de lancement de 350 à 2 600 €. Un seul projet à la fois. **Impossible pendant un contrat**, et inversement (`StartupManager.gd:422`). |
| Avancement automatique | `:81-86` | 1,6 + programmation × 0,065 point par jour, **sans aucune action**. Avec la compétence de départ (18), le produit « stocks » (55 points) sort en environ 20 jours sans intervention. |
| Séances Coder / Tester / Faire connaître | `:58-79` | Une séance tous les 3 jours. Coder : +8 à 9,5 points. Tester : qualité +6 et 3 points. Faire connaître : visibilité +7 et 2 points. |
| Publication et versions | `:87-113` | Une nouvelle version remplace la précédente, remet l'âge à 0 et **reprend la qualité du projet (54 de base)**, pas celle de la version précédente. |
| Ventes mensuelles | `:155-179` | `ventes = base × clamp(qualité/70; 0,5; 1,35) × clamp(visibilité/55; 0,3; 1,5) × max(0,55; 1 − âge × 0,02)`. Il n'y a ni prix, ni clients, ni concurrents. La visibilité **gagne +1 par mois**. La qualité perd 1 par mois mais ne descend pas sous 45. |
| Après-vente | `:115-153`, `ui/SoftwareStudioPanel.gd:76-88` | Assistance à 140 € (qualité +5), prospection à 180 € (visibilité +7), adaptation (+360 € ou plus, une fois par produit et par mois, sans coût). Le délai de 3 jours est **global**. Ces actions sont possibles pendant un contrat. |
| Ouverture du matériel | `SoftwareStudioManager.gd:178`, `StartupManager.gd:479-483` | 3 500 € de ventes cumulées suffisent à passer à l'étape FIRST_HIRE, soit un peu plus d'un mois de ventes. |
| Contrats | `StartupManager.gd:11-93`, `:431-477`, `:578-632` | 10 modèles fixes. Choix d'approche « solide » ou « rapide », séances de travail, jalon à 48 %, crise d'échéance (heures supplémentaires, périmètre réduit ou abandon), verdict en étoiles, paiement unique à la livraison. |
| Spécialisations du fondateur | `FounderManager.gd:24-71` | 5 domaines avec arbres de bonus. Ils agissent **seulement sur les contrats**. Le studio ne les lit pas. |
| Sauvegarde | `SaveManager.gd:10`, `:130-133`, `:331`, `:391` | Version 28 : la section `software_studio` est créée vide pour les anciennes parties. `last_service_day` (ajouté par le dernier commit) est lu avec une valeur par défaut sans changer de version, ce qui est sans danger. |
| Interface | `main.gd:856-879`, `:1418-1480`, `ui/SoftwareStudioPanel.gd` | Scène du garage à 3 postes, menu d'actions contextuel de 3 boutons au plus, panneau studio intégré dans la page défilante du tableau de bord. |
| Tests | `tests/smoke_test.gd:69-102`, `tests/economy_test.gd` | Le test rapide exige que le premier logiciel rende le **premier mois bénéficiaire** et que le matériel soit finançable en 6 mois. Le test économique ne joue **que des contrats** et **exige de débloquer le CPU**. |

### 1.2 Ce qui n'existe que dans la documentation

`docs/DESIGN_BIBLE.md` §9 (lignes 406-449) décrit ceci :

- licences, abonnement, maintenance, extensions ;
- choix du public, du prix, de la licence, de la distribution et de la compatibilité ;
- maintenance sous contrat, assistance à plusieurs niveaux, renouvellements, incidents, demandes de fonctionnalités ;
- recrutement de programmeurs, testeurs et commerciaux ;
- services réseau ou serveurs conditionnés à l'infrastructure.

**Rien de cela n'est simulé.** La bible le reconnaît elle-même (« ne sont pas encore simulés en détail », l. 443). `docs/ROADMAP.md:138` garde « Logiciels / système d'exploitation » non coché. La règle « les dates sont des repères de diffusion, pas des barrières » (§13, marché CPU) n'est pas appliquée au logiciel : `BRANCH_WEB` et `WEB_CATALOG` utilisent `min_year: 1991`.

### 1.3 Problèmes constatés, par gravité

**P1 — Rente passive croissante et sans limite (bloquant).**
Calcul avec les formules de `SoftwareStudioManager.gd:163-176`, pour le produit « stocks » publié à qualité 54 et visibilité 30 :

| Mois après publication | 1 | 12 | 24 | 36 | 60 |
|---|---|---|---|---|---|
| Ventes brutes | 2 188 € | 1 944 € | 1 772 € | 2 173 € | **2 758 €** |

- La hausse de +1 de visibilité par mois compense puis dépasse la baisse liée à l'âge.
- La facturation atteint 2 861 € au mois 1 pour un lancement à 550 €.
- Au maximum (qualité 95, visibilité 90), on obtient **10 530 €** et **13 770 €** par mois, pour 160 et 230 € de maintenance.
- Il n'y a ni saturation, ni concurrent, ni cannibalisation entre produits.
- Le capital de départ en mode Standard est de 16 000 € (`BalanceManager.gd:23`). La pression financière disparaît donc dès le troisième mois.

**P2 — Des actions qu'on peut enchaîner.**
`TimeManager.day_duration = 0,8 s`, donc 3 jours durent 2,4 s à x1. Neuf prospections (1 620 €) font passer la visibilité de 30 à 90 en environ 22 secondes réelles et **multiplient les ventes par 2,75**. Le délai en jours de jeu ne représente ni un coût ni une décision.

**P3 — « Coder » est un bouton piège.**
Le projet avance automatiquement (`:81-86`), et le nombre de séances est limité par la durée du projet. Chaque séance « Coder » raccourcit le projet et supprime donc des séances « Tester » ou « Faire connaître », qui augmentent directement les ventes. La stratégie dominante est de **ne jamais coder**.

**P4 — Il n'y a pas de marché logiciel.**
`sales` est un montant fixe en euros. Le joueur ne choisit ni prix, ni public, ni plateforme, ni mode de licence. Les quatre logiciels ne se font pas concurrence. Le produit « OS pour mini-ordinateurs » ne dépend d'aucune machine.

**P5 — Les contrats n'ont pas de mémoire.**
- Le même contrat Morel est proposé indéfiniment.
- `completed_contract_ids` est enregistré mais ne sert à rien.
- `relation_delta` s'affiche puis disparaît : il n'est pas conservé.
- La réputation « professionnelle » gagnée (`:303`) n'influence aucune offre.
- **Bug :** `process_day` réécrit `functions_required = work_required` chaque jour (`StartupManager.gd:594`). Le « +4 fonctions » des choix SCOPE et EXTRA du jalon (`:698-704`) est donc effacé dès le lendemain. EXTRA rapporte 800 € presque gratuitement. Le test économique choisit d'ailleurs systématiquement EXTRA (`economy_test.gd:17`).

**P6 — Le temps du fondateur n'est pas une ressource.**
L'exclusion entre contrat et produit est binaire, mais l'après-vente reste possible pendant un contrat. On ne peut pas partager la semaine entre deux activités, et il n'existe aucun employé logiciel : la seule embauche proposée est Élise, électronicienne (`PersonnelManager.gd:23-37`).

**P7 — Les versions ne portent pas de contenu.**
Une nouvelle version réinitialise surtout le déclin lié à l'âge. Elle peut même **faire baisser** la qualité : un produit à 85 repasse à 54 plus les tests effectués.

**P8 — La progression est fragmentée.**
Il y a quatre compteurs : `level`, `programming_level`, les `skills` et les niveaux de domaine. Le studio n'utilise ni `software_programming_quality_bonus()` ni les arbres de domaine. `improve_developer_tools()` n'est jamais appelée (code mort). Le catalogue se débloque par `programming_level`, les contrats par niveau de domaine.

**P9 — L'interface pousse vers le matériel.**
À l'étape FIRST_HIRE, le **premier bouton** du menu du personnage est « Recruter Élise • 3 500 € » (`main.gd:1468`). L'objectif affiche « 3 mois • 2 600 €/mois » alors que le coût réel est de 1 600 € (`StartupManager.gd:860` contre `:99`).

**P10 — Les tests figent le mauvais équilibre.**
`smoke_test.gd:77-79` et `:83` rendent obligatoires la rentabilité immédiate et le financement du matériel. `economy_test.gd:42-46` échoue si le CPU n'est pas débloqué, ce qui contredit la vision « sans jamais construire de CPU ».

**P11 — Le rythme ne correspond pas aux « 30 premières minutes ».**
À x1, un mois dure 24 s (plus la pause du bilan, `main.gd:3657`). Trente minutes couvrent donc de l'ordre de un à deux ans de jeu selon les pauses. Les jalons de la première demi-heure et des douze premiers mois se confondent. Il faut choisir un rythme propre au garage (voir §3).

**P12 — Petites incohérences.**
- `can_start_software_contract` compare `Economy.money` à un coût sans facteur de difficulté (`:429`), alors que le studio utilise `Economy.can_afford`.
- Les étiquettes de dépense « Contrat logiciel — développement » passent par le facteur `research_cost`, mais pas « Création logicielle ».

**Ce qu'il faut conserver** : la structure de contrat (points de travail, projection, échéance, crise, verdict), qui est bonne ; le tutoriel discret de Nora par paliers de progression (`:634-680`) ; la scène du garage cliquable ; la règle « aucune obligation matérielle ».

---

## 2. Carte des métiers logiciels

Les déblocages dépendent de **capacités, de clients et d'infrastructure**, pas d'une date seule. Les dates restent des repères d'accélération, comme pour le marché CPU (bible §13).

**Contexte 1971.**
- Depuis la séparation des ventes logicielles d'IBM (1969), un marché du logiciel indépendant existe.
- Les clients ont des mini-ordinateurs, louent du temps sur des machines partagées, ou passent par des bureaux de services informatiques.
- Les programmes circulent sur bande magnétique, cartes perforées ou ruban perforé.
- L'installation et la formation se font sur place. La maintenance est contractuelle, la location mensuelle est courante.
- Il n'y a ni Internet commercial, ni téléchargement.
- En jeu, **tous les constructeurs et clients sont fictifs**.

| # | Métier | Travail du personnage | Revenu immédiat | Revenu récurrent | Coûts | Risque | Compétences | Prérequis / déblocage |
|---|---|---|---|---|---|---|---|---|
| **A** | **Prestation sur mesure** | Analyse chez le client, devis, développement, recette, livraison | Acompte de 30 % à la signature, solde à la recette | Aucun, sauf clause de maintenance | Temps machine loué (≈ 40 €/jour de dev), déplacements, jours non facturés de prospection | Dépassement, pénalités, client insatisfait, retard de paiement | Programmation, domaine, commercial (négociation) | Dès le départ |
| **B** | **Intégration, adaptation et maintenance** | Installer, adapter un produit existant, former, dépanner | Adaptation facturée au jour | **Contrat de maintenance annuel** (≈ 15 % du prix de licence par an) avec un niveau de service | Jours de support imprévisibles, astreinte | Incidents en série si fiabilité faible, non-renouvellement | Programmation, domaine, gestion | Un produit publié **ou** un contrat livré sous clause de maintenance |
| **C** | **Édition d'un logiciel à sa marque** | Concevoir, développer, publier, démarcher, installer, faire des versions | Licences (paiement à l'installation) | Maintenance ; ou **location mensuelle** (moins d'argent immédiat, plus de revenu durable) | 40 à 60 jours de dev, temps machine, 1,5 jour d'installation par vente, prospection | Vendre trop peu, concurrent moins cher, épuisement du parc de clients, défauts cachés | Programmation, commercial, domaine, connaissance de la plateforme | Dès le départ. Le **public** est découvert par les contrats (« mon cousin grossiste voudrait la même chose ») |
| **D** | **Outils de développement** (assembleur, éditeur de liens, utilitaires, bibliothèques, puis compilateurs) | Écrire les outils pour une plateforme, documenter, animer les utilisateurs | Licence par machine | Maintenance et mises à jour compatibles | Dev long (80 à 150 jours), documentation | Petit marché ; le constructeur peut fournir les siens | Maîtrise de la plateforme à 3+, programmation élevée | 1 produit publié sur la plateforme, **demandes de programmeurs** reçues (au moins 3), outils internes déjà utilisés |
| **E** | **Système** (moniteur, puis OS compatible) | Écrire noyau, pilotes et outils, gérer la compatibilité, négocier avec le constructeur | Accord OEM (avance) ou licence par machine | Redevance par machine vendue par le constructeur, support | Très long (200 jours et plus), besoin d'une équipe | Échec de compatibilité, dépendance au constructeur, rachat de la plateforme | Maîtrise de la plateforme à 5, outils (métier D), gestion d'équipe | Métier D actif, base installée de la plateforme suffisante, accord de coopération **ou** compatibilité développée seul (plus coûteuse) |
| **F** | **Exploitation de machines** (bureau de services informatiques : paie et facturation traitées pour les clients ; plus tard temps partagé, puis réseaux et serveurs) | Traiter les lots, gérer la capacité, la fiabilité, la relève des bandes | Prix par traitement | **Abonnement mensuel** par client | **Location d'un mini-ordinateur (lourde, fixe)**, opérateur, local | Machine sous-utilisée = perte fixe ; panne = pénalités | Gestion, commercial, domaine | Au moins 5 clients récurrents dans un public qui a besoin de traitement par lots **et** trésorerie suffisante pour le dépôt de location. Les réseaux et serveurs viennent plus tard selon l'indice d'infrastructure du monde |

**Pourquoi ces métiers sont réellement différents :**

- **A** échange du temps contre de l'argent sûr, avec un plafond.
- **B** crée du récurrent, mais avec des **obligations**.
- **C** demande un investissement en capital et en temps avant de voir le résultat, et offre le plus fort potentiel de croissance.
- **D** et **E** créent de la dépendance à une plateforme et un fort effet de levier.
- **F** transforme des charges fixes lourdes en abonnements. C'est le seul métier où la capacité se loue et peut rester inutilisée.

Le passage vers le CPU arrive naturellement plus tard : **posséder son CPU revient à posséder sa plateforme**.

---

## 3. Parcours : les 30 premières minutes, puis 12 mois

### 3.1 Le rythme d'abord

Je propose un **rythme propre au garage** : un jour dure 1,6 s à x1, soit environ 48 s par mois. Les pauses surviennent **aux décisions** (brief, jalon, publication, prix, visite commerciale), pas à chaque bilan.

Objectif : **30 minutes réelles correspondent environ à janvier–mai 1971**, avec au moins 3 décisions significatives par mois de jeu. Le temps de jeu se compte en **semaines de 5 jours ouvrés** ; l'agenda du fondateur remplace tous les délais de 3 jours.

### 3.2 Minute par minute

| Temps réel | Date de jeu | Ce que voit le joueur | Clic ou choix | Retour visible | Tutoriel discret | Si c'est bloqué |
|---|---|---|---|---|---|---|
| 00:00 | 4 janv. | Garage : Alex au terminal, téléphone mural, tableau de liège vide, étagère vide. Trésorerie 16 000 €, **autonomie ≈ 13 mois** | — | Le téléphone sonne (animation) | Nora : « Touchez Alex ou le téléphone. » | — |
| 00:30 | | Menu contextuel sur le téléphone : **« Quincaillerie Morel : gestion de stock »** | Ouvrir le brief | Carte client : besoin, budget indicatif, délai | — | — |
| 01:00 | | **Brief de contrat, 3 décisions** : 1) devis (tarif prudent / juste / ambitieux, avec probabilité d'acceptation affichée) ; 2) approche solide ou rapide ; 3) **propriété du code** : cession totale (100 % du prix) ou licence de réutilisation (−15 % et vous gardez le module « Stock ») | 3 choix, puis Signer | Acompte de 30 % : **+2 300 €**, animation de pièces | Une phrase par choix : « Moins cher maintenant, un module réutilisable plus tard. » | Devis refusé : le client propose un contre-devis. Aucune fin brutale |
| 02:00 | Sem. 1 | **Agenda de la semaine** (5 cases) pré-rempli : « 5 j Morel » | Laisser, ou déplacer 1 jour vers « Idée perso » (grisée tant qu'aucune idée n'existe) | Le jour de travail s'affiche sous Alex (« Analyse ») | « Chaque case est une journée de votre temps. » | — |
| 02:30–05:30 | Sem. 1–3 | Point de fin de semaine (bulle) : +points, défauts détectés, projection | Semaine 2 : **« 2 défauts trouvés : corriger (1 j) ou noter ? »** | Jauge de fiabilité | « Un défaut non corrigé peut revenir après la livraison. » | — |
| 06:00 | Sem. 4 | **Jalon client** (mécanique existante, bug P5 corrigé) : Morel veut des bons de commande | Accepter / facturer +800 € et +4 jours / refuser | Relation client ±, la charge change **vraiment** | — | — |
| 08:30 | Sem. 6 | **Recette** : Morel teste, 0 à 3 défauts cachés révélés | Corriger sur place (1 jour par défaut) ou livrer tel quel | Étoiles, **solde de 70 %** (≈ +5 400 €), relation +1 | « Un client satisfait devient une référence. » | — |
| 09:30 | fév. | **Nouvelle ouverture** : Morel dit « mon cousin grossiste voudrait la même chose ». Une carte « Idée de produit : Stock pour grossistes » s'épingle sur le tableau de liège. 2 nouvelles offres de contrat apparaissent (courte et peu payée / longue, bien payée et difficile) | Choisir via Alex : contrat, produit, ou partage de l'agenda | Le tableau et l'étagère deviennent interactifs | « Vous pouvez vivre de contrats, créer votre produit, ou les deux. » | — |
| 11:00 | | **Brief produit** : public (grossistes, 1 à 5 personnes), plateforme (terminal du bureau de services « Calcul-Service » ou mini-ordinateur « Norda 16 »), 3 modules sur 5. Les **5 jauges d'arbitrage** apparaissent (§4.2) | Choix, puis Lancer | Prévision de demande : « 2 à 4 clients par mois, confiance faible » | « Choisir une plateforme, c'est choisir qui peut acheter. » | Pas assez de trésorerie pour le temps machine : alternatives affichées (travailler de nuit sur le mini de Morel contre 2 jours de maintenance offerts ; mini-contrat de dépannage de 3 jours) |
| 12:00–19:00 | fév.–mars | Agenda partagé, par exemple 3 jours produit et 2 jours dépannage | Chaque semaine : répartition. Événement : « Le module Stock réutilisé fait gagner 12 jours » (si la clause de licence a été choisie) | Barre produit, défauts estimés (fourchette) | — | « Démarcher » reste **caché** jusqu'à ce qu'une démo soit prête (60 %). Avant cela, on peut présenter une **maquette** (conversion divisée par deux) |
| 20:00 | fin mars | **Décision de publication** : « Défauts cachés estimés : 3 à 8. Publier maintenant ou tester 2 semaines ? » **Prix** : licence 1 500 / 1 800 / 2 200 €, ou location 70 € par mois | Choisir | Bande « v1.0 » sur l'étagère (retour visuel) | La fourchette de défauts se resserre à chaque jour de test | — |
| 22:00 | avr. | **Visite commerciale** (1 jour) : 3 prospects en cartes (besoin, objection, budget) | Argument par prospect : prix, fiabilité ou référence Morel | Probabilité affichée **avant** le choix. Tirage déterministe (graine) | « Une référence vaut souvent mieux qu'une remise. » | Aucun prospect n'est intéressé : la carte explique pourquoi (prix trop élevé, pas de référence) et propose une remise temporaire |
| 25:00 | | **Première vente** : Alex part avec une valise de bandes (**1,5 jour d'installation**) | — | +1 800 € de licence et +270 € de maintenance. Compteur de clients installés = 1 | — | — |
| 27:00 | mai | **Premier appel d'assistance** : un bug sur les inventaires | Corriger (1 jour, publier la v1.0.1 à tous) / contourner (0,5 jour, le bug reste) | Satisfaction client, compteur d'incidents | « L'assistance est payée par la maintenance, pas offerte. » | — |
| 29:00 | fin mai | **Bilan du mois** avec deux colonnes « Contrats » et « Produits » | — | Autonomie de trésorerie mise à jour | Aperçu : « Jeanne, programmeuse à mi-temps, pourrait prendre l'assistance » | — |
| 30:00 | | **Objectif proposé** (non imposé) : « 5 clients installés » **ou** « livrer le contrat Lefèvre » | Épingler un objectif | — | — | — |

**Bilan à 30 minutes (cible de conception, non mesurée)** :

- 1 contrat livré, 1 produit publié, 1 à 2 clients installés ;
- environ 20 000 € de trésorerie ;
- une douzaine de décisions réelles ;
- aucun écran à plus de 3 cartes d'actions.

### 3.3 Trajectoire sur 12 mois, entreprise 100 % logicielle

| Période | Événements et décisions | Déblocages (par condition) |
|---|---|---|
| **T1** (janv.–mars) | Contrat Morel, idée de produit, développement v1 | Tableau des clients et étagère de produits |
| **T2** (avr.–juin) | Publication, premières ventes, premier incident, **première embauche logicielle** : programmeuse à mi-temps (assistance et corrections) **ou** commercial payé à la commission | L'onglet **Équipe** apparaît à la première embauche (réutilise `PersonnelManager` et le département « Développement », déjà présent dans `CompanyManager.gd:52`) |
| **T3** (juil.–sept.) | Un **concurrent** entre sur le public (un bureau de services propose la gestion de stock à 120 €/mois) : baisser le prix, passer en location, ajouter un module ou viser un autre public. **Portage** vers le mini « Norda 16 » : décision de 20 jours contre une base installée multipliée par 2 | Compatibilité et plateformes. Métier **B** : contrats de maintenance avec niveau de service |
| **T4** (oct.–déc.) | **v2** construite à partir des demandes des clients (backlog), ventes de mises à jour à la base installée. **Offre OEM** du constructeur Norda : 90 € par machine vendue avec votre logiciel, mais exclusivité 12 mois et assistance de premier niveau à votre charge. Demandes de programmeurs, donc **métier D** entrevu | Outils de développement si la maîtrise de la plateforme atteint 3. Bureau de services (F) si au moins 5 clients récurrents ont besoin de traitement par lots |

**Fin d'année (cible)** : 2 à 3 personnes, 1 à 2 produits, 15 à 25 clients installés, 40 000 à 55 000 € de trésorerie, une décision OEM qui engage l'année suivante.

### 3.4 Basculer vers le matériel, à titre facultatif

La porte du matériel s'ouvre sur un **besoin concret**, jamais sur un simple seuil de chiffre d'affaires :

- un client industriel demande un boîtier de commande après un contrat `ROM_CONTROL` ou `MACHINE_CONTROL` ;
- ou le constructeur partenaire propose de co-développer une carte ;
- ou le joueur y pense lui-même après au moins 2 contrats embarqués ou industriels.

Élise apparaît alors comme **une option parmi d'autres** (jamais en premier bouton). L'expérience logicielle se transfère : les niveaux de domaine embarqué et industriel réduisent le coût du prototype, et les outils (métier D) accélèrent le microcode. Refuser n'a **aucun coût**, et l'offre revient plus tard sous une autre forme.

---

## 4. Boucles interactives : conception → vente → assistance → versions

### 4.1 Trois régimes de propriété, à rendre explicites

| Régime | Qui possède le code | Ce que le joueur gagne | Ce qu'il perd |
|---|---|---|---|
| **Contrat avec cession totale** | Le client | Prix plein, relation client | Rien n'est réutilisable ; seules l'expérience et la réputation restent |
| **Contrat avec licence de réutilisation** | Le client pour son exemplaire, **vous gardez le module** | Un **module réutilisable** (−20 à 40 % de charge sur un futur produit du même domaine) | Prix réduit de 10 à 20 %. Certains clients refusent (grands comptes, secteur public) |
| **Adaptation payée d'un produit à vous** | **Vous** | Prestation facturée au jour. Choix : **intégrer au produit** (1 à 3 jours de plus, la fonction profite à tous les clients et entre dans le backlog de la v2) ou **laisser en version spécifique** (coût de maintenance divergente +5 % par branche spécifique) | Temps du fondateur ; dette technique si l'on multiplie les versions spécifiques |
| **Produit sous votre marque** | **Vous** | Licences, maintenance, location, OEM | Investissement, risque commercial, obligations d'assistance |

C'est **le pont narratif et mécanique** entre les deux voies. Le joueur qui fait des contrats prépare son catalogue s'il négocie bien.

### 4.2 Conception : cinq arbitrages lisibles, comme pour le CPU

Chaque projet, contrat ou produit, se lit sur **5 axes**, calculés à partir de la simulation :

1. **Fonctions** : la part du besoin du public couverte par les modules choisis.
2. **Fiabilité** : l'inverse des défauts cachés estimés (affichée en fourchette avec un indice de confiance).
3. **Compatibilité** : les plateformes couvertes, donc le parc de clients accessible, et les exigences en mémoire.
4. **Délai** : les jours restants selon l'agenda réel.
5. **Coût pour le client** : prix, plus frais d'installation, plus machine requise.

L'**adéquation au public visé** s'affiche à part, comme pour le CPU (« ce compromis correspond-il à ce client ? »). Les modules sont 3 à 6 par domaine, par exemple pour la gestion de stock : Mouvements, Inventaire, Bons de commande, Multi-dépôts, Éditions. Chacun a une charge, une valeur par public et un risque de défauts.

### 4.3 Allocation du temps : l'agenda

- **Le fondateur** dispose de 5 jours par semaine, soit environ 20 par mois. Les postes possibles : contrat X, produit Y (dev ou test), démarchage, installation (réservée automatiquement à chaque vente), assistance (réservée automatiquement en fonction des incidents), formation personnelle, repos.
- L'agenda **se reconduit** d'une semaine à l'autre : pas de micro-gestion, mais pas de rente non plus, parce que les résultats dépendent du plan.
- **Surcharge** : au-delà de 5 jours (soirées et week-ends), productivité +20 %, puis **fatigue** (défauts ×1,5, risque d'arrêt de 2 semaines). La fatigue remplace les délais de 3 jours.
- **Les employés** reçoivent une affectation (produit, contrat, assistance) et une priorité. Le fondateur garde toujours **au moins une responsabilité directe** (bible §6A).
- **Aucune action instantanée répétable** : chaque verbe consomme des jours.

### 4.4 Qualité, défauts cachés et assistance

- Le développement génère des **défauts cachés** : `D = charge × taux_défauts(approche, compétence, fatigue)`.
- Le test révèle une part des défauts par jour ; la correction coûte des jours.
- Après publication, les défauts restants produisent des **incidents** proportionnels à la base installée.
- Traiter un incident : correctif (jours, profite à tous) ou contournement (moins cher, le défaut reste).
- Un incident non traité en 20 jours fait chuter la satisfaction du client, donc son **renouvellement** et la réputation du public concerné.

### 4.5 Demande, prix et licences adaptés à 1971

- **Le public** a une base d'établissements équipés par plateforme, qui grandit en fonction du marché des machines (réutilise la logique de diffusion de `MarketManager`).
- **Canaux de vente** :
  - démarchage direct (jours du fondateur ou du commercial) ;
  - recommandation (références satisfaites) ;
  - **catalogue d'un constructeur ou OEM** (volume, marge réduite, dépendance) ;
  - salon annuel (événement, coût fixe).
- **Modes de licence** : licence perpétuelle et maintenance (≈ 15 %/an) ; location mensuelle (moins d'argent tout de suite, revenu durable, risque de résiliation) ; redevance OEM par machine. Le **prix** est un choix réel, avec une élasticité (§5).
- **Diffusion** : bande, cartes ou ruban. Installation sur place. L'assistance à distance par terminal n'arrive qu'avec l'infrastructure.

### 4.6 Concurrence et réputation

- **Concurrents agrégés par public** (même principe que les concurrents CPU) : trésorerie, produit, prix, fiabilité, cycle de versions. Ils entrent sur un public quand la demande observée le justifie (le joueur crée donc ses propres concurrents), baissent leurs prix, sortent des versions.
- **Réputation par public et par client** (le carnet de relations). `relation_delta` devient une donnée conservée. Les références débloquent de meilleures offres et de meilleurs tarifs.

### 4.7 Nouvelles versions

- Le **backlog** se remplit tout seul à partir des demandes d'adaptation, des incidents, des modules concurrents et des nouvelles plateformes.
- Une version = un choix d'éléments du backlog, puis développement.
- Sa valeur vient des **nouvelles fonctions**, pas d'une remise à zéro du déclin.
- **Mise à jour payante** pour les clients existants (une fraction de la licence), gratuite pour ceux sous maintenance. C'est ce qui donne sa valeur à la maintenance.
- La fiabilité d'une version repart de celle de la précédente, plus les changements. Le bug P7 disparaît.

### 4.8 Trésorerie

- Délais de paiement : acompte et solde pour les contrats ; certains clients paient à 60 jours.
- Charges fixes visibles : garage, location machine, salaires.
- **Autonomie en mois** toujours affichée, que Nora traduit : « À ce rythme, 4 mois avant de devoir signer un contrat. »

---

## 5. Modèle économique testable

### 5.1 Variables

| Symbole | Sens | Valeur de départ (Standard) |
|---|---|---|
| `J` | jours ouvrés du fondateur par mois | 20 |
| `F` | frais du garage par mois | 500 € (existant) |
| `M` | temps machine par jour de dev ou de test | 40 € (cohérent avec les 700–900 €/mois actuels des contrats) |
| `t` | tarif journalier de prestation | 260 € + 15 € par point de réputation du public (0 à 10) |
| `u` | taux d'occupation facturable | 0,60 + 0,03 × réputation, plafonné à 0,85 |
| `p` | prix de licence | choisi par le joueur (par exemple 1 800 €) |
| `m` | taux de maintenance annuel | 15 % |
| `N_s` | parc de clients accessibles non équipés d'un public, par plateforme | par exemple 60 au départ, +3 par mois |
| `i` | jours d'installation par vente | 1,5 |
| `σ` | incidents par client et par mois | 0,12 × (1,5 − fiabilité) |

### 5.2 Formules

```
Contrat :
  charge_réelle   = charge_estimée × (1 + dérive(approche, compétence))
  facturation     = jours_facturés × t × multiplicateur_devis
  paiement        = 30 % à la signature + 70 % à la recette (certains clients : +30 ou 60 jours)
  pénalité_retard = 2 % par semaine de retard, plafonnée à 20 %

Produit :
  attractivité A  = valeur(modules, fiabilité, compat) / valeur_réf
                    × (prix_réf / p)^ε × (0,7 + 0,06 × réputation_public)     ε ≈ 1,2
  part            = A^k / (A^k + Σ A_concurrents^k)                            k ≈ 2
  prospects/mois  = jours_démarchage × 0,5 × (1 + 0,1 × références) + recommandations
  ventes/mois     = min( prospects × conversion(A, argument), N_s × part,
                         jours_libres / i )          ← la vente consomme du temps
  N_s(mois+1)     = N_s − ventes_joueur − ventes_concurrents + croissance_plateforme
  licence         = ventes × p
  maintenance/mois= Σ clients_sous_contrat × p × m / 12
  renouvellement  = 0,95 − 0,25 × (incidents non résolus / clients) − 0,1 × (retard de version)
  jours_assistance= clients × σ × 0,5
  location        = clients_en_location × loyer ; résiliation/mois = 2 % + f(insatisfaction)
```

Deux principes :

- **Coût de développement** = jours × (coût d'opportunité du fondateur, affiché comme « tarif perdu » t) + jours × M. Ce « tarif perdu » **s'affiche** pour rendre l'arbitrage contrat ou produit lisible.
- **Maintenance = obligation.** Chaque euro de maintenance est lié à des jours d'assistance. Ne pas les fournir fait baisser le renouvellement.

### 5.3 Exemples chiffrés sur 12 mois

Modèle de brouillon déterministe, sans événements aléatoires. Soldes arrondis, trésorerie de départ 16 000 €.

| Mois | Contrats seuls : solde | Contrats : trésorerie | Édition seule : solde | Édition : trésorerie | Hybride (clause de licence) : solde | Hybride : trésorerie |
|---|---|---|---|---|---|---|
| 1 | +1 900 | 17 900 | −1 200 | 14 800 | +1 500 | 17 500 |
| 2 | +2 000 | 19 900 | −1 200 | 13 600 | +1 650 | 19 100 |
| 3 | +2 100 | 22 000 | −1 200 (v1 publiée) | **12 300** (minimum) | −450 | 18 700 |
| 4 | +2 300 | 24 300 | +2 900 | 15 200 | −450 (v1, Morel 1er client) | **18 200** (minimum) |
| 6 | +2 550 | 29 200 | +2 950 | 21 100 | +2 700 | 23 600 |
| 9 | +3 000 | 37 800 | +4 900 | 35 600 | +2 950 | 32 300 |
| 12 | +3 450 | **47 700** | +5 100 | **50 800** | +3 200 | **41 700** |
| Clients installés à M12 | 0 | | 24 | | 9 | |
| Tarif à M12 | ≈ 340 €/j | | — | | ≈ 300 €/j | |

**Comment lire ces profils** (c'est l'intention de conception, pas un résultat de test) :

- **Contrats** : le plus sûr. La trésorerie ne descend jamais sous le capital de départ. Mais le revenu est **plafonné** par `J × u × t` : environ 5 800 €/mois net au maximum en solo. Il faut recruter pour aller au-delà.
- **Édition** : le plus exposé. La trésorerie tombe à 12 300 €, et un défaut grave au mois 4 ferait mal. En contrepartie : base installée, maintenance récurrente et ventes de mises à jour en année 2. Mais le parc `N_s` s'épuise, il faudra donc porter le produit ou faire une v2.
- **Hybride** : l'année 1 la plus lente sur le papier, mais la plus robuste (deux sources de revenus, des références, un module réutilisable) et le mieux placé en année 2. **Si les tests montrent que l'hybride est dominé partout, il faut augmenter la valeur du module réutilisé**. C'est un réglage explicite, pas une fatalité.

### 5.4 Garde-fous

**Contre la rente gratuite.**
1. Chaque vente consomme des jours d'installation.
2. Le parc s'épuise et les concurrents entrent.
3. La maintenance est liée à des jours d'assistance.
4. Sans version, le renouvellement baisse.
5. Les plateformes vieillissent : la base installée migre vers de nouvelles machines, il faut porter le produit.
6. La visibilité **baisse** sans action. C'est l'inverse du +1 par mois actuel.

**Contre l'enchaînement de clics.** Il n'existe plus aucune action instantanée répétable : tout coûte des jours d'agenda. Le démarchage d'un même public a des rendements décroissants dans le mois (`0,5 × 0,8^(n−1)` prospect par jour).

**Contre la faillite punitive, sans supprimer le risque.**
- Alertes d'autonomie à 3 mois et à 1 mois.
- **Découvert bancaire** jusqu'à −5 000 € avec intérêts.
- Solution de secours : **mission salariée temporaire** (le fondateur est détaché 2 mois chez un client : revenu garanti, aucune progression de produit, réputation neutre).
- Faillite seulement si la trésorerie reste sous le découvert pendant 2 bilans consécutifs.
- Le risque reste réel : clients perdus, dette, opportunités manquées.

---

## 6. Interface PC et téléphone

### 6.1 L'écran principal, vu du garage

Les éléments interactifs apparaissent au fur et à mesure (**4 au plus au départ**) :

| Élément | Ouvre | Visible quand |
|---|---|---|
| **Alex / le terminal** | Menu d'activités (au plus 3 cartes) et projet en cours | Toujours |
| **Téléphone** | Offres de contrats et appels clients (incidents) | Toujours |
| **Tableau de liège** | Carnet des clients, idées de produits, backlog | Après le premier contrat livré |
| **Étagère de bandes** | Catalogue des produits | Au premier projet de produit |
| Bureau libre | Recrutement | Quand une embauche logicielle est pertinente |
| Établi électronique | Voie matérielle | **Uniquement** sur une ouverture matérielle concrète (§3.4) |

### 6.2 Menu contextuel du personnage

- **Au plus 3 cartes**, plus un lien « Autres activités… ».
- Chaque carte affiche : verbe, **jours**, **euros**, résultat attendu, un pictogramme de risque.
- Exemple : « Démarcher les grossistes • 2 j • 0 € • 1 à 2 prospects • ⚠ pas de référence ».
- Une action bloquée ne s'affiche jamais seule : la carte dit **pourquoi** et propose **une alternative faisable** (voir le tableau §3.2).

### 6.3 Téléphone, en portrait

```
┌──────────────────────────────┐
│ 16 400 € · autonomie 11 mois │ ← barre d'état compacte
│ Mars 1971 · sem. 2      ⏸ ▶ ▶▶│
├──────────────────────────────┤
│   [ scène du garage 40 % ]   │ ← toucher Alex / téléphone / tableau
│   Alex ▸ « Stock v1 » 62 %   │
├──────────────────────────────┤
│ AGENDA  L  M  M  J  V        │ ← 5 cases, glisser pour réaffecter
│        [P][P][P][C][C]       │   P=produit C=contrat
├──────────────────────────────┤
│ ▲ panneau d'actions (3 cartes)│ ← s'ouvre au toucher d'un élément
└──────────────────────────────┘
Onglets bas : Garage · Projets · Catalogue · Clients (apparaît au 1er client)
```

### 6.4 PC

- Scène au centre.
- **À gauche** : agenda et projets en cours.
- **À droite** : panneau détail (les 5 jauges d'arbitrage ; « Détails techniques » dépliable pour les modules, les défauts et la courbe de demande).
- Raccourcis : 1 à 3 pour les cartes, Espace pour la pause.

### 6.5 Catalogue

Une carte par produit :

- version et plateforme(s) ;
- **clients installés / parc accessible** ;
- maintenance mensuelle ;
- incidents ouverts ;
- demandes en attente (nombre) ;
- concurrent principal (prix, fiabilité) ;
- **une suggestion de Nora** (« 3 demandes « Multi-dépôts » : candidat pour la v2 »).

### 6.6 Dévoilement progressif

1. Contrat.
2. Tableau et idées.
3. Produit et catalogue.
4. Clients et assistance.
5. Équipe.
6. Plateformes et portage.
7. OEM et prix avancés.
8. Outils et système.
9. Exploitation.

**Jamais de boutons grisés pour les métiers futurs** (bible §6A).

À corriger au passage : `ui/SoftwareStudioPanel.gd:83` fixe une largeur minimale de 245 px par bouton, ce qui donne 3 lignes sur un écran de 360 px. À vérifier sur appareil : **non vérifié**.

---

## 7. Paliers d'implémentation dans ce dépôt

Règles de départ :
- **Réutiliser** `SoftwareStudioManager`, `StartupManager`, `FounderManager`, `PersonnelManager`, `Economy` et `SaveManager`.
- Les **données statiques** vont dans un nouveau fichier de données, `scripts/SoftwareMarketData.gd` (constantes seulement).
- **Aucun code des autres branches matérielles.**

| Palier | Contenu | Managers touchés | Sauvegarde | Tests déterministes | Dépend de |
|---|---|---|---|---|---|
| **0 — Corrections** | Supprimer l'écrasement `functions_required` (`StartupManager.gd:594`). Conserver `relation_delta` par client. Visibilité qui baisse au lieu de monter. Qualité de version reprise de la précédente. Coût « 2 600 € » corrigé. « Recruter Élise » retiré du premier bouton. `economy_test` sans obligation CPU | StartupManager, SoftwareStudioManager, main.gd | v29 : `client_relations: {}` | `test_milestone_scope_persists`, `test_no_rent_growth` (produit sans action pendant 60 mois : ventes décroissantes), `test_version_quality_not_regressed` | — |
| **1 — Agenda du fondateur** | `week_plan` et `days_available` dans FounderManager. Suppression des délais de 3 jours et de l'avancement automatique sans affectation. Surcharge et fatigue | FounderManager, StartupManager, SoftwareStudioManager, TimeManager (rythme du garage) | v30 : agenda par défaut déduit du contrat ou projet actif | `test_time_budget` (somme ≤ J ; action au-delà du budget refusée), `test_no_spam` (N appels le même jour : un seul effet), `test_contract_vs_product_share` | 0 |
| **2 — Marché logiciel minimal** | Publics, parc, prix, licence ou location, installation, épuisement du parc, visites commerciales | SoftwareStudioManager et SoftwareMarketData | v31 : produits existants convertis, `clients = lifetime_sales / prix_réf`, `N_s` initialisé | `test_saturation` (le parc s'épuise), `test_price_elasticity` (prix ×1,5 : moins de ventes mais plus de marge sur une plage définie), `test_sales_need_days` | 1 |
| **3 — Qualité, assistance, versions** | Défauts cachés, incidents, maintenance, renouvellements, backlog, mises à jour | SoftwareStudioManager (motif inspiré d'`AfterSalesManager`, sans le coupler au CPU) | v32 : `backlog`, `open_incidents`, `maintenance_clients` | `test_maintenance_requires_support`, `test_backlog_version_value`, `test_three_profiles_12_months` (3 joueurs scriptés, tous solvables en Standard ; minimum de trésorerie de l'édition entre 8 000 et 15 000 € ; hybride non dominé partout) | 2 |
| **4 — Clients persistants et contrats générés** | Carnet de clients. Modèles de contrats et instances. Clause de propriété et module réutilisable | StartupManager | v33 : `completed_contract_ids` migrés vers l'historique client | `test_ownership_regimes` (contrat en cession : rien au catalogue ; licence : module disponible ; adaptation : propriété conservée), `test_contract_offers_vary` | 1, 3 |
| **5 — Équipe logicielle** | Programmeur, testeur, commercial (département « Développement » existant) | PersonnelManager, CompanyManager | v34 : `assignment` par employé | `test_software_only_36_months` (aucun matériel, croissance, au moins 2 produits, au moins 1 embauche), `test_founder_keeps_direct_role` | 1, 3 |
| **6 — Plateformes, portage, OEM** | Plateformes fictives, base installée liée à la diffusion de `MarketManager`, offres OEM | SoftwareStudioManager, lecture de MarketManager | v35 | `test_platform_gates_market`, `test_oem_tradeoff` | 2, 4 |
| **7 — Outils, système, exploitation** | Métiers D, E et F derrière leurs prérequis. Réseaux et serveurs selon l'indice d'infrastructure | idem, et StartupManager pour les ouvertures | v36 et suivantes | Un test de déblocage par condition, sans date seule | 5, 6 |

**Règles transverses** :

- Chaque étape de migration est explicite dans `SaveManager._migrate_state`, avec un test de chargement d'une sauvegarde v28 figée (`tests/save_integrity_test.gd`).
- **Tirages avec graine** (`RandomNumberGenerator` stocké dans l'état) pour que visites commerciales et incidents soient reproductibles.
- Les probabilités sont affichées avant le choix.
- Adapter `smoke_test.gd:77-79` : exiger « le produit devient rentable **entre le mois 2 et le mois 5 avec des jours de démarchage** » plutôt qu'une rentabilité immédiate.

Contrainte AGENTS.md (« périmètre CPU d'abord ») : le propriétaire l'a levée pour cette conception. Les paliers 0 et 1 sont de toute façon **neutres ou bénéfiques pour le CPU** (corrections, agenda réutilisable par le CPU ensuite).

---

## 8. Les cinq idées les plus fortes, concessions et questions ouvertes

### 8.1 Classement

1. **Le temps du fondateur est la ressource centrale.** L'agenda en jours remplace les délais. Il supprime l'enchaînement de clics, rend réel l'arbitrage entre contrat et produit, et donne un sens à l'embauche. Il se réutilise pour le CPU.
2. **En 1971, chaque vente coûte du travail, et le marché s'épuise.** Installation, assistance, parc limité, concurrents. Le récurrent existe, mais il se paie en obligations. C'est la fin de la rente gratuite.
3. **La propriété du code est une clause négociée.** Cession, licence de réutilisation ou adaptation : c'est le pont élégant du contrat vers le produit, et une vraie décision dès la minute 1.
4. **Les plateformes et la compatibilité forment la colonne vertébrale du marché.** Elles préparent naturellement les outils, les systèmes, l'exploitation, et la synergie facultative avec le CPU (posséder son CPU revient à posséder sa plateforme).
5. **Des clients avec une mémoire, qui alimentent le backlog.** Les versions portent du contenu voulu par le marché. Les références et la réputation par public deviennent des leviers lisibles.

### 8.2 Concessions

- Les premières minutes offrent **moins de chiffres qui montent** qu'aujourd'hui : la satisfaction vient des décisions et des retours, pas d'une courbe exponentielle.
- L'agenda ajoute une interface. Il faut une valeur par défaut qui se reconduit, sinon c'est de la micro-gestion.
- Le schéma de sauvegarde s'alourdit (six migrations prévues).
- Il faudra rééquilibrer les tests existants, qui figent l'équilibre actuel.
- La géographie et les publics restent **abstraits** (un « parc » par public et par plateforme), pas une carte.
- Garder des tirages avec graine et afficher les probabilités réduit la surprise, mais c'est cohérent avec « une décision, une conséquence lisible ».

### 8.3 Questions réellement ouvertes

1. **Monnaie et pays** : euros anachroniques en 1971, ou francs puis euros ? Marché français seul au départ ?
2. **Rythme** : 48 s par mois au garage conviennent-elles, ou le créateur préfère-t-il garder 24 s et ajouter des décisions ?
3. **L'agenda se joue-t-il à la semaine ou au mois ?** La semaine est plus active, le mois plus lisible sur téléphone.
4. **Système d'exploitation contre CPU** : un joueur 100 % logiciel peut-il bâtir un OS compatible qui rivalise avec l'écosystème CPU d'un concurrent, ou l'OS reste-t-il un débouché de partenariat ?
5. **Faillite** : la « mission salariée temporaire » est-elle acceptable pour l'univers, ou préfère-t-on un repreneur ou un investisseur ?
6. **Place de la voie matérielle** : faut-il un **troisième** déclencheur, piloté par le joueur, sans besoin client ?
7. **Délégation au garage** : le bras droit peut-il gérer l'assistance avant la première embauche, ou est-ce contraire au principe « le garage reste personnel » ?