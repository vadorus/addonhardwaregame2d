# Audit chef dev / bêta-testeur en chef — V0.9

Date : 30/09/2026 — Claude, audit indépendant de celui du matin (`V09_BETA_INTERNAL_AUDIT.md`)
Branche : `feature/ui-v09-navigation` (`192d64c`) — Godot 4.7.2 — aucun fichier de jeu modifié

## Grille de lecture (demande d'Alexandre)

On ne juge pas le réalisme mais le **plaisir de jouer** : ni simulation hardcore, ni jeu bidon plié en 5 minutes.
Chaque problème est noté selon deux questions : *est-ce que ça perd ou agace un novice ?* et
*est-ce que ça enlève le défi à un joueur qui connaît le jeu ?* Les chiffres réels servent de repère, pas de règle.

## Méthode

1. **Santé technique** : smoke test, garage sur 6 formats, atelier sur 3 formats — tous **PASS** (seul bruit : un avertissement
   « 3 ObjectDB leaked » en sortie du test de disposition, sans effet en jeu).
2. **Sondes du matin rejouées** : chiffres **identiques** à l'audit du matin (ex. Standard passif 12 159 € → 1 491 830 € à 24 mois).
3. **Nouvelle sonde 10 ans** (`_claude_probe/profiles10y.gd`) : trois joueurs automatiques
   - *Novice / Accessible* : suit Nora, ne règle rien, n'agrandit rien ;
   - *Intermédiaire / Standard* : réagit aux ruptures, embauche jusqu'à 12, déménage, un peu de marketing, retire les vieux modèles ;
   - *Expert / Simulation* : optimise, embauche jusqu'à 25, fab interne, marchés stratégiques, rachats, gros marketing.
4. **Parties au doigt sur le Pixel 10** : novice complet (création → premier silicium → validation → fabrication → lancement → 15 mois),
   intermédiaire (cockpit produit, extension de capacité, 2e CPU avec le parcours de création), expert (Simulation, Pionnier, conception avancée).

## Verdict

**Le cœur du jeu est déjà fun et lisible au démarrage** : garage simple, Nora qui guide pas à pas, bulles de points au-dessus de l'équipe,
moment « premier silicium », tri des puces raconté par Nora, jour de sortie, interview de presse qui colore les tests, révélation des notes.
Un premier CPU sort en ~16 mois de jeu, soit quelques minutes réelles : bon rythme.

**Mais la partie s'éteint après le premier lancement** : l'argent coule à flots sans rien faire, grandir ne rapporte rien (ça coûte),
rien ne pousse à préparer la génération suivante, et le joueur est noyé sous des offres B2B et des décisions qui s'empilent.
Le problème n'est pas le réalisme : c'est qu'**il n'y a plus de défi ni d'objectif désirable** une fois le premier CPU vendu.

| Profil | Début (0-20 min) | Après le 1er lancement | Note fun |
|---|---|---|---|
| Novice | Clair, guidé, beaux moments | L'argent monte seul (+50 k€/mois), rien à faire, CTA squatté par des contrats | 6/10 puis 3/10 |
| Intermédiaire | Idem | Réagir paie trop vite (extension remboursée en < 2 semaines), grandir fait *perdre* de l'argent | 5/10 |
| Expert | Formulaire expert très lourd pour un garage de 1971 | Richesse exponentielle (75 M€ en 1981), aucun risque | 4/10 |

## Problèmes classés

### P0 — cassent le jeu

**P0-1. L'argent cesse d'être une contrainte dès la première gamme.**
- Pixel, novice passif : 75 209 € au lancement → 122 026 € un mois plus tard → 655 630 € onze mois après, **sans aucune action**.
- Sonde 10 ans : novice passif **10,9 M€** en 1981 avec **3 personnes dans le garage**, et **n°1 du classement dès 1975**.
- ~~Cause principale mesurée : la gamme de 3 modèles additionne les parts de marché.~~ **Corrigé le 30/09 à 14 h (diagnostic H1)** :
  c'est faux, `MarketManager.estimate_portfolio_demand` partage déjà la demande de la famille (plafond de marque ~3 % du segment).
  Mesure mois par mois (Standard passif, gamme de 3) : demande ~650 puces/mois (3 % de 19 445), capacité conseillée 222 + 199 + 96 = 517,
  prix 125/185/285 € pour un coût de 31/39/47 € (**marge brute 75-83 %**), recettes ~90 k€/mois, dépenses ~29,5 k€/mois
  (salaires 9,2 k€, fabrication ~19 k€) → **~60 k€ de bénéfice par mois dès le 1er mois**.
  La gamme rapporte ~5× un modèle seul surtout parce que chaque modèle ajoute **sa propre capacité** (222 → 517 puces) et des prix plus hauts,
  pas parce que les parts s'additionnent. Le vrai levier est **la marge unitaire** d'une jeune marque (et le vieillissement, H4).

**P0-2. Grandir ne rapporte rien : il fait perdre.**
- Sonde 10 ans : l'intermédiaire qui embauche (12 personnes) et déménage (locaux niveau 3) finit à **4,3 M€**, soit **moins que le novice
  passif (10,9 M€)**. Le joueur qui « fait bien » est puni ; le garage à 3 est la stratégie optimale.
- L'expert qui pousse tout (25 personnes, fab) explose à 75 M€ : le jeu récompense l'extrême, pas la croissance raisonnée.

**P0-3. Extension de capacité quasi gratuite et multiplicative** (confirme l'audit du matin).
- Pixel : +70 puces/mois pour **4 000 € une fois** ; marge ~120 €/puce → remboursé en moins de 2 semaines.
- Code (`ProductManager.capacity_change_quote` / `set_production_capacity`) : le nouveau plafond devient la base du suivant → croissance sans limite.

### P1 — gâchent l'expérience

**P1-1. Décisions prototype et validation : le haut de la carte est coupé sur téléphone** (bug reproductible, 2 fois sur 2).
« Montre-moi ça au banc de test ! » ouvre Labo > Projets déjà défilé : on voit les coûts et « Choisir », mais **ni la question ni le nom
des 3 options**, et on ne peut pas remonter. Le novice choisit à l'aveugle.

**P1-2. Rien ne pousse à préparer le CPU suivant.** Partie novice : 15 mois après le lancement, Nova 1 est toujours le seul projet,
l'équipe attend, Nora parle d'autre chose. Aucun vieillissement ressenti, aucun « vos rivaux préparent mieux ».

**P1-3. Les offres B2B squattent le guidage.** Dès le mois 5 (avant d'avoir un produit !), une offre tous les 1-2 mois
(Delta Office, Pioneer Toys, Atlas Automation, Orbital Systems, Mercury Instruments…). Elles prennent le **bouton vert principal**
et le texte « Nora • prochaine étape », compteur « À faire (3) ». Le fil du projet est perdu.

**P1-4. Les décisions s'empilent sans fin.** Sonde 10 ans : pour un joueur qui ne les traite pas toutes, **10 à 18 décisions en attente
simultanément** (colonne `max_pending`). Elles n'expirent pas et ne se règlent pas seules : bruit permanent.

**P1-5. Cockpit après lancement = formulaire à 7 lignes** (confirme l'audit) : capacité, promotion, révision matérielle, firmware,
attaque d'un rival, fin de vie, logiciel. Libellé trompeur « Passer à 151/mois » quand la capacité est déjà 151.

**P1-6. Murs de chiffres au mauvais moment pour le novice.**
- Page de lancement : 11 lignes (« redevance », « confiance 46 % », « adéquation vous 74,1 • rival 61,3 | benchmark 69,9 • 54,4 »).
- Fabrication : « précision 53 • fiabilité 88 • coût x1.15 », « techno 33 • dépendance 42 », « savoir-faire qualité 18 • maintenance 16 »
  sans dire ce que ça change pour le joueur ; seule l'option sélectionnée est expliquée ; « Construire une fab 220 000 € » proposé avec 100 k€.
- Le bouton « Lancer la production » est sous la ligne de flottaison, et un seul glissé le saute.

### P2 — à corriger ensuite

- **P2-1. Le 2e CPU est identique au 1er** (1973 : 1 cœur, 0,8 MHz, 10 µm, architecture 8 bits encore verrouillée). Le joueur refait la même
  puce : aucune sensation de progrès entre la génération 1 et 2.
- **P2-2. « Conception avancée » promet des réglages cachés** : message « vous pouvez modifier tous les paramètres » mais la section est repliée.
- **P2-3. Formulaire Expert disproportionné en 1971** (clauses fournisseur, exclusivité, IP, engagement de volume pour un garage).
  Pas de projection « il vous restera X € au lancement » avant de valider (le runway en haut aide, mais n'inclut pas industrialisation + lancement).
- **P2-4. Les systèmes de fin de partie restent invisibles la première décennie** : salon annuel 0 fois, marchés stratégiques 0-1, filiales 0
  sur 10 ans dans les trois profils. Le contenu F2-F5 existe mais le joueur ne le voit pas.
- **P2-5. Moments « tri des puces » et « premier silicium » en texte seul** : belles idées, à rendre visuelles (bacs, puce qui s'allume).
- **P2-6. Menu déroulant du mode de jeu** : texte presque illisible (blanc sur beige) quand la liste est ouverte.

### P3 — mineur

- Avertissement « ObjectDB leaked » dans `garage_layout_test`.
- Les notes de presse baissent de ~80 à ~60-70 sur 10 ans : la concurrence progresse, c'est bien, mais sans effet ressenti sur la trésorerie.

## Ce qu'il faut garder absolument

Garage + barre du bas avec cadenas, Nora « étape 1/3 », bulles de points, premier silicium, interview de presse, révélation des notes,
objectifs affichés dans la carte de Nora, cartes de projet avec frise, parcours de création (conseil « Tick » de Samira, « ce que l'équipe
a appris »), cartes chiffrées du cockpit (ventes, demande, satisfaction, contribution), ligne « Leçon » après le 1er mois.

## Réglage « fun » recommandé (pas de réalisme pour le réalisme)

Cibles de sensation, à vérifier avec les mêmes sondes :
- **Accessible** : on ne peut presque pas perdre, mais l'argent reste une ressource qu'on dépense (locaux, équipe, marketing).
- **Standard** : première gamme passive ~250-600 k€ à 24 mois (seuil de l'audit du matin) ; un joueur actif fait **mieux** qu'un passif.
- **Simulation** : un pari pionnier peut échouer, **à condition d'avoir été prévenu** clairement avant de valider.
- **Sur 10 ans** : l'intermédiaire qui grandit doit finir **au moins 2× plus riche** que le novice passif ; un garage à 3 ne doit jamais être n°1 mondial.

Leviers simples, côté jeu :
1. **Une gamme partage une seule part de marché** entre ses modèles (au lieu de l'additionner) : levier n°1.
2. **Extension de capacité** au prix de plusieurs mois de marge, plafond lié à l'usine/fondeur (plus de doublement en chaîne).
3. **Vieillissement ressenti** : demande et prix qui baissent après ~18-24 mois, rivaux qui sortent mieux, Nora qui dit
   « préparez la suite » → donne une raison de lancer la génération suivante.
4. **Grandir doit payer** : équipe plus grande = projets plus rapides et meilleurs ; locaux plus grands = plus de capacité et de marchés.
5. **B2B** : seulement après le 1er produit, une offre ouverte à la fois, jamais sur le bouton vert principal.
6. **Boîte de décisions** : 3 visibles au maximum, les autres expirent ou prennent un choix par défaut (annoncé) après quelques mois.

## Ordre de correction recommandé

1. P0-1 + P0-3 (part de marché des gammes, capacité) — puis rejouer les sondes du matin et `profiles10y`.
2. P0-2 + P1-2 (grandir paie, vieillissement, pousser la génération suivante) — vérifier « intermédiaire ≥ 2× novice » sur 10 ans.
3. P1-1 (bug des décisions coupées) — rapide, bloquant pour le novice.
4. P1-3 + P1-4 (B2B et boîte de décisions) — calme la partie.
5. P1-5 + P1-6 (cockpit progressif, pages de lancement et fabrication en cartes claires).
6. P2 ensuite, en commençant par P2-1 (2e CPU qui progresse) et P2-4 (rendre visibles les systèmes de fin de partie).
7. Transformer les sondes en **tests de balance avec plafonds** (pas seulement des minima de survie).

## Annexe — chiffres de la sonde 10 ans (fin d'année)

| Année | Novice € | Novice effectif | Novice rang | Inter € | Inter effectif | Inter locaux | Expert € | Expert effectif |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1972 | 149 790 | 3 | 4 | 88 319 | 3 | 0 | 77 556 | 3 |
| 1973 | 481 822 | 3 | 4 | 466 486 | 3 | 0 | 95 626 | 3 |
| 1975 | 2 638 509 | 3 | **1** | 1 147 452 | 12 | 3 | 796 280 | 4 |
| 1977 | 5 071 123 | 3 | 2 | 2 730 987 | 12 | 3 | 21 583 403 | 25 |
| 1979 | 7 905 841 | 3 | 1 | 4 013 835 | 12 | 3 | 52 375 335 | 25 |
| 1981 | **10 909 687** | 4 | 2 | **4 336 417** | 12 | 3 | **75 482 553** | 25 |

Remarque : l'expert de la sonde ne lance son premier CPU qu'au mois 47 (choix automatique du segment le plus grand, projet très long) ;
c'est un artefact probable de la sonde, à vérifier avant d'en tirer une conclusion.

Fichiers : sonde `_claude_probe/profiles10y.gd`, journaux `build/audit_claude/`, captures du Pixel `build/ui_review/` (N*, I*, X*).
