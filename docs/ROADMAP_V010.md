# Tech Empire — feuille de route V0.10 « de la démo au jeu »

Rédigée le 30/09/2026 (Claude, chef dev) à la demande d'Alexandre, après les deux audits du jour :
`docs/reviews/V09_BETA_INTERNAL_AUDIT.md` (matin) et `docs/reviews/V09_AUDIT_CLAUDE_CHEF.md` (profils joueur, 10 ans, Pixel).
Suite de `docs/PLAN_V09_V10.md` (lots A à G et M, tous faits). Les nouveaux lots commencent à **H**.

## La ligne d'Alexandre (à relire avant chaque lot)

- **Ni simulation hardcore, ni jeu bidon plié en 5 minutes.** Le réalisme sert de repère, le plaisir décide.
- Un novice ne doit jamais « péter un plomb » ; un joueur qui connaît le jeu doit toujours avoir un défi.
- Clair, pas prise de tête, fun, on sent l'avancement. Style chaleureux (garage, bois, crème, Nora).
- Même jeu sur PC et Android. Cosmétiques jamais pay-to-win.

## Où on en est (30/09)

Technique saine (tous les tests verts), début de partie réussi (garage, Nora, bulles de points, premier silicium,
interview de presse, notes révélées). **Mais la partie s'éteint après le premier CPU** : argent illimité, grandir ne paie pas,
rien ne pousse à la génération suivante, décisions et offres B2B qui s'empilent, pages trop chargées en chiffres.

## Règles de travail entre Claude, ChatGPT et Astra

1. **Un lot = un responsable = une branche** partie de `feature/ui-v09-navigation` :
   `v010/<lot>` (ex. `v010/H1-gammes`). Fusion dans la branche d'intégration seulement après les vérifications ci-dessous.
2. **Fichiers réservés par lot** (tableau plus bas). Deux lots qui touchent le même fichier ne tournent jamais en même temps.
3. **Le Pixel n'a qu'un pilote à la fois.** Avant toute installation : sauvegarde de la partie d'Alexandre copiée sur le PC.
   Jamais d'installation pendant qu'Alexandre joue.
4. **Clé de signature de test commune** aux deux PC (lot Q0) : plus jamais de désinstallation qui efface les parties.
5. **Chaque lot se termine par** : smoke test + tests de disposition verts ; sondes d'équilibrage rejouées
   (`tests/tools/beta_*_audit`, `_claude_probe/profiles10y`) ; partie au doigt sur le Pixel ; note dans `docs/reviews/` ; commit + push.
6. Le code du jeu ne se modifie pas pendant un audit : diagnostic d'abord, corrections ensuite.

## Les chantiers

### Q — Socle (avant tout le reste, petit)

| Lot | Contenu | Responsable | Fichiers | Terminé quand |
|---|---|---|---|---|
| Q0 | Clé de signature de test commune dans le projet, script de build qui l'utilise sur les deux PC | Claude | `export_presets.cfg`, `tools/build_all.ps1`, `docs/BUILD_PC_ANDROID.md` | Un APK construit sur chaque PC s'installe par-dessus l'autre sans perdre la partie |
| Q1 | Sondes d'équilibrage transformées en **tests avec plafonds** (pas seulement des minima de survie) | Claude | `tests/scenarios/Balance*`, `tests/smoke_test.gd` | Le smoke test échoue si la première gamme Standard passive dépasse 1 M€ à 24 mois |

### H — Équilibrage « le jeu reste un défi » (priorité n°1)

| Lot | Contenu | Responsable | Fichiers | Terminé quand |
|---|---|---|---|---|
| H1 | **Marge d'une jeune marque** (corrigé après diagnostic : la demande est déjà partagée dans une gamme ; le problème est une marge brute de 75-83 % dès le 1er mois). Pistes : part des distributeurs qui baisse quand la marque grandit, coût de fabrication qui baisse avec l'expérience | Claude | `MarketManager.gd`, `CpuProductLine.gd`, `ProductManager.gd` | Standard passif : 250-600 k€ à 24 mois |
| H2 | **Capacité payante** : coût ≈ plusieurs mois de marge, plafond lié au fondeur / à l'usine, plus de doublement en chaîne | Claude | `ProductManager.gd` | Une extension se rembourse en 4-8 mois, pas en 2 semaines |
| H3 | **Grandir paie** : équipe plus grande = projets plus rapides et meilleurs ; locaux plus grands = plus de capacité et de marchés | ChatGPT | `ResearchManager.gd`, `ExecutiveManager.gd` | Sur 10 ans, l'intermédiaire qui grandit finit ≥ 2× plus riche que le novice passif |
| H4 | **Les produits vieillissent** : demande et prix baissent après ~18-24 mois, rivaux qui sortent mieux ; Nora dit « préparez la suite » | ChatGPT | `MarketManager.gd` (après H1), `Interactions.gd` | Aucun joueur passif ne reste n°1 mondial avec 3 personnes ; un 2e projet est proposé ≤ 6 mois après le 1er lancement |
| H5 | **Ruptures qui font mal** (satisfaction / fidélité) et **projection de trésorerie** avant chaque engagement coûteux (surtout en Simulation) | Claude | `ProductManager.gd` (après H2), écrans concernés | Le pionnier Simulation peut échouer, mais il a vu « il vous restera X € au lancement » avant de valider |
| H6 | **Modes vraiment différents après le lancement** (Accessible / Standard / Simulation) | ChatGPT | `BalanceManager.gd` | Écart de difficulté mesurable à 24 mois et à 10 ans |

### I — Clarté et interface « on comprend quoi faire et pourquoi »

| Lot | Contenu | Responsable | Fichiers | Terminé quand |
|---|---|---|---|---|
| I1 | **Bug** : décisions prototype / validation coupées en haut sur téléphone | Claude | `LabScreen.gd`, `DecisionCard.gd` | Question et nom des 3 options visibles au doigt sur le Pixel |
| I2 | **Offres B2B calmées** : seulement après le 1er produit, une à la fois, jamais sur le bouton vert ni dans « prochaine étape » | Claude | `GarageHub.gd`, `MarketManager.gd` (après H1) | Aucune offre avant le 1er lancement dans la partie novice |
| I3 | **Boîte de décisions** : 3 visibles au maximum ; les autres expirent ou prennent un choix par défaut annoncé | ChatGPT | `ExecutiveManager.gd`, `CeoDecisionPanel.gd` | Sonde 10 ans : jamais plus de 3 décisions en attente |
| I4 | **Pages de lancement et de fabrication en cartes claires** : 3 chiffres qui comptent, le reste replié ; chaque option expliquée ; bouton d'action toujours visible | Claude | `ProductsScreen.gd` | Un novice lance sa production et son produit sans lire une ligne de jargon |
| I5 | **Cockpit après lancement progressif** : les actions apparaissent quand un problème les rend utiles (stepping si pannes, offensive si un rival attaque) | Claude | `ProductsScreen.gd` (après I4) | Au 1er mois de vente : 2 actions visibles au maximum |
| I6 | Petits défauts : « Conception avancée » qui ouvre bien les réglages, libellé « Passer à 151/mois », menu du mode de jeu lisible, 2e CPU qui propose un vrai progrès | Claude | `LabScreen.gd`, `CpuDesignStepper.gd`, `main.gd` | Liste vérifiée au doigt |

### J — Graphismes (en parallèle, sans conflit avec le code)

| Lot | Contenu | Responsable | Fichiers | Terminé quand |
|---|---|---|---|---|
| J1 | **Décors par palier** dans le style du garage : atelier, petit bureau/labo, PME, siège (puis campus, groupe, empire) | Astra | `assets/` uniquement | 4 décors livrés au même format que le garage actuel |
| J2 | **Personnages** : équipe visible à son poste, expressions, Nora | Astra | `assets/` | Chaque membre de l'équipe a un sprite |
| J3 | **Moments mis en scène** : puce qui s'allume (premier silicium), bacs du tri des puces, jour de sortie | Astra (dessin) + Claude (animation) | `assets/`, composants dédiés | Les deux moments sont visuels, plus seulement du texte |
| J4 | Icônes cohérentes (barre du bas, cartes, produits) | Astra | `assets/`, `GarageBadge.gd` | Plus d'icônes dessinées au trait provisoires |

### K — Environnement « le décor raconte la progression »

| Lot | Contenu | Responsable | Fichiers | Terminé quand |
|---|---|---|---|---|
| K1 | Brancher les décors J1 sur les paliers de locaux, avec un **moment déménagement** | Claude | `GarageHub.gd`, `ExecutiveManager.gd` | Chaque palier change le QG, avec une petite séquence |
| K2 | Le décor vit : équipe qui grandit à l'écran, produits en vitrine, trophées, saisons et événements visibles | Claude + Astra | `GarageHub.gd`, `assets/` | Une partie de 10 ans montre au moins 5 changements visibles au QG |

### L — Son

| Lot | Contenu | Responsable | Fichiers | Terminé quand |
|---|---|---|---|---|
| L1 | Ambiance du garage et des locaux (atelier, bureau, usine) | à décider (banque de sons libres ou compositeur) | `assets/audio/` (à créer ; les sons actuels sont synthétisés dans le code), `SoundManager.gd` | Chaque palier a son ambiance |
| L2 | Sons d'interface plus riches, jingles de lancement, de premier silicium et de triomphe presse | idem + Claude pour l'intégration | idem | Chaque moment fort a son son |
| L3 | Vraie musique par époque (remplace les boucles générées) | idem | idem | Une piste par décennie, réglable |

## Ordre recommandé

1. **Q0 + Q1** (socle, rapide).
2. **H1 → H2** (Claude) pendant que **J1** démarre (Astra) : aucun fichier commun.
3. **I1 + I2** (Claude, rapides et visibles) pendant **H3 + H4** (ChatGPT).
4. **H5 + H6**, puis **I3 → I4 → I5 → I6**.
5. **K1** dès que J1 est livré, puis **J2/J3/K2**.
6. **L** en fond de tâche dès qu'une source de sons est choisie.
7. **Audit bêta complet** (mêmes profils, mêmes sondes, Pixel) avant de parler de bêta publique.

## Après l'étude concurrence (décision du 01/10/2026, 22 h 55)

Étude croisée : `docs/design/concurrence/` (brief, analyses d'Astra et de Claude, synthèse de Codex, `decision.md`).
Promesse retenue : **« Je comprends mes choix, je vois mon entreprise grandir, et je dois encore réfléchir après mes premiers succès. »**
Les seuils sont ceux proposés par Codex, à ajuster après le premier relevé. Une régression des sauvegardes, un blocage
tactile ou un résultat incohérent arrête le passage à l'étape suivante. Codex contrôle les preuves de passage.

| Étape | Contenu | Qui | Preuve attendue avant de passer à la suite |
|---|---|---|---|
| **C1 — Sauvegarder et mettre à jour sans perte** | Clé de test commune aux deux PC (reprend Q0) ; script de construction et d'installation qui sauvegarde la partie avant et la vérifie après ; sauvegarde quand le jeu passe en arrière-plan ; relevé de démarrage et de fluidité sur le Pixel (puis un appareil plus modeste) | Claude | mise à jour depuis chacun des deux PC sans désinstallation ; 20 interruptions/reprises sans perte ; journal des versions et certificats ; aucun secret dans Git |
| **C2 — Comprendre le lancement** | Garder la cérémonie existante ; expliquer les contributions réelles du calcul de la note (par média, interview comprise) ; bilan consultable depuis la fiche du produit ; relier note, demande, ventes et marge ; besoins essentiels de chaque marché visibles dès le départ, carnet de Nora pour conseils, comparaisons, historique | Claude (+ Astra si icônes) | 4 novices sur 5 lancent et retrouvent leurs ventes en moins de 15 min sans aide ; 8 testeurs sur 10 expliquent la cause principale du verdict ; tests calcul/texte pour chaque média |
| **C3 — Garder des choix en carrière** | Mesure de départ par le chemin réel (même mode pour tous les profils) ; réglage des besoins et des réactions existantes des rivaux ; une transition de marché annoncée seulement si les mesures la justifient ; Accessible : erreurs rattrapables avec Nora | Claude | carrière réelle jusqu'à 2010 puis 2030 sans blocage ; sur 6 conditions reproductibles, la stratégie adaptée bat la stratégie figée dans au moins 4 cas au même mode ; marge, parts et décisions publiées |
| **C4 — Bêta et qualité mobile** | Test fermé **en français** (12 testeurs, 14 jours) ; AAB envoyé via Play ; déclarations (confidentialité, données, classification) ; contrôle des pages mémoire de 16 Ko ; anglais avant d'élargir | Claude + Astra (fiche) | aucun bouton inaccessible ni texte coupé ; téléchargement < 150 Mo ; démarrage < 10 s ; 30 images/s stables sur appareil modeste (60 si la chauffe le permet) ; aucun défaut bloquant connu |
| **C5 — Donner envie de recommencer** | Après la bêta : 2 scénarios (redressement, spécialiste). Année de départ libre et argent illimité reportés | Claude | victoire et échec atteignables sans blocage ; 3 testeurs expérimentés sur 5 relancent une partie |

Ce qui n'est **pas** décidé : prix et modèle payant (étude monétisation), nouvelle famille de produits (CPU d'abord).

## Critères de sortie V0.10 (bêta publique)

- Tous les tests verts, y compris les **plafonds** d'équilibrage.
- Standard passif : 250-600 k€ à 24 mois ; intermédiaire ≥ 2× novice passif à 10 ans ; jamais n°1 mondial avec 3 personnes.
- Un novice joue 30 minutes sur le Pixel sans jamais être bloqué ni noyé (≤ 3 décisions en attente, aucune carte coupée).
- Chaque palier de locaux a son décor et son ambiance ; les deux grands moments sont visuels et sonores.
- Alexandre a joué 1 heure et dit que c'est fun.
