# SCENARIO-01 — Défis vivants, adversité et différentes manières de réussir

**Date :** 10 octobre 2026. **Origine :** clarification explicite du créateur de Tech Empire.  
**Statut :** orientation de game design confirmée ; règles chiffrées et nouveaux événements **proposés, non implémentés**.  
**Code comparé :** `v013/demo-octobre` @ `c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f` (Godot 4.7.2).

## 1. Clarification cruciale : un défi n'est pas un trophée

Le mot « défi » signifie ici **l'obstacle ou la situation que le monde de jeu oppose aux ambitions du joueur**. Ce n'est pas « vendre 100 000 CPU » ni une checklist de réalisations. Les trophées reconnaissent une réussite passée ; les **défis créent le besoin de décider**.

Quatre couches distinctes :

| Couche | Qui la déclenche ? | Exemple | Effet sur la durée de vie |
| --- | --- | --- | --- |
| **Ambition** | Joueur, libre de changer | Être leader de l'efficacité énergétique | Donne une direction choisie |
| **Défi / scénario** | Monde de simulation, rivaux, clients, fournisseurs, équipe | Un concurrent annonce une puce beaucoup plus sobre | Crée un obstacle réel et une décision intéressante |
| **Classement** | Mesures comparables du secteur | N°1 efficacité / € / ventes / fiabilité | Mesure plusieurs formes de réussite, pas un seul « plus riche » |
| **Réussite / trophée** | Faits constatés | Défendre le leadership CPU pendant deux ans | Garde une trace, ne remplace pas le défi |

Un jeu sans fin obligatoire peut avoir une **longue carrière** si les ambitions et défis se renouvellent, **mais seulement dans la limite de contenu réellement disponible**. Le CPU a aujourd'hui un plafond de possibilités, et la branche Software reste en construction ; les scénarios ne suffisent pas à créer de nouvelles technologies ou activités. Voir [PROGRESSION-01](PROGRESSION_LIMITES_ET_BRANCHES_2026-10-10.md). La limite 2030 des sondes est une borne de test, pas une fin commerciale.

## 2. État réel de la démo — ne pas redévelopper ce qui existe

- `scripts/SimulationManager.gd` termine la partie uniquement quand la **trésorerie est épuisée** (événement `game_over`).
- `scripts/ObjectivesManager.gd` suit déjà trois pistes **Produit / Croissance / Marché** et plusieurs buts progressifs récompensés. Ce sont des **jalons**, non des scénarios adverses.
- `scripts/CareerPrestige.gd` suit déjà **10 trophées**, le classement mondial Empire et un score composite de réputation, technologie, trésorerie, ventes, groupe, marchés stratégiques. **Il ne se réduit donc pas strictement à l'argent**, mais manque de **n°1 distincts** par critère.
- `scripts/MarketManager.gd` contient déjà des menaces de marché avec coût de réponse, perte de demande, coût de production et expiration ; la menace ne peut apparaître qu'après 1975, avec produit existant et au moins **48 mois depuis la dernière menace** dans la boucle actuelle. La réponse consiste essentiellement en **atténuer financièrement / laisser courir**, sans arc riche à plusieurs choix.
- `scripts/ExecutiveManager.gd` possède déjà des dossiers RH (locaux saturés, moral, cohésion) et délai anti-répétition. `scripts/Moments.gd` gère de grands moments illustrés déclenchés par l'état du jeu.
- `MarketManager.cpu_competitor_public_profiles()` expose prix, notes de benchmark, métriques, unités mensuelles, actions publiques et santé des rivaux. Les classements catégoriels peuvent **réutiliser ces valeurs existantes**, mais doivent mesurer les acteurs sous des règles homogènes.

La fondation existe ; le chantier n'est pas de rajouter 100 alertes aléatoires. C'est de relier **rivalité + objectifs du joueur + scénarios + choix + conséquences + reconnaissance de la réussite**.

## 3. Contrat de scénario (même moteur quel que soit le contenu)

Chaque scénario doit être défini par des faits **constatables**, et non un script qui triche contre le joueur.

```text
ID stable / catégorie / époque / conditions d'éligibilité
Acteurs identifiés (concurrent, fournisseur, équipe, client)
Signal précurseur (préavis / information visible)
Enjeu : quel indicateur ou ambition est menacé ?
Fenêtre pour réagir, durée, intensité adaptée à l'état réel
Choix possibles (au moins deux stratégies + ne rien faire)
Conséquences mesurables sur les systèmes EXISTANTS
Relances contextualisées, bilan, trace dans la presse
Mémoire : état, décisions et résultats persistés en sauvegarde
```

**Structure jouable d'un arc** : (1) prémices visibles, (2) incident/annonce, (3) choix informé, (4) effets mensuels / réaction d'un rival, (5) conclusion et nouvelles opportunités. Un événement peut déboucher sur **une victoire partielle**, pas seulement succès/échec binaire.

**Garde-fous indispensables :** intensité liée à la taille et aux moyens réels ; avertissement avant perte irréversible ; coûts connus ou estimation expliquée ; réponses viables par plusieurs stratégies ; cooldown ; maximum d'événements majeurs simultanés ; aucune activation sans système capable de calculer les conséquences ; reproductibilité d'une graine ; comportement cohérent après sauvegarde/recharge ; événements correctement datés ; ne jamais retoucher le RNG des ventes clandestinement.

## 4. Familles de défis : exemples de situations réellement jouables

| Famille / scénario | Déclencheur sensé | Enjeu concret et décisions | Conséquences testables |
| --- | --- | --- | --- |
| **Guerre technologique** — « Le rival reprend la tête » | Le joueur est leader benchmark ; concurrent rattrape sa génération | Accélérer R&D, développer une puce spécialisée, rester sur la fiabilité | Écart de benchmark, dépenses, délais, résultat presse |
| **Guerre des prix** — « Offensive discount » | Un acteur baisse réellement ses prix sur le même segment | Baisser prix, différencier par qualité/SAV, attaquer autre clientèle | Conversion en ventes, marge nette, satisfaction et parts |
| **Rupture fournisseur** — « Six mois de silicium sous tension » | Dépendance de sourcing + tension/incident avéré | Changer de fournisseur, payer des stocks de sécurité, réduire la production, investir fabrication interne | Rendement, délais, coûts, ventes perdues ; pas de pénalité magique |
| **Qualité** — « Série de retours terrain » | Incident mesuré (fiabilité / retours produit) | Campagne de correctifs, rappel volontaire, prolonger support, minimiser le problème | SAV, réputation, coût, confiance récupérée ou non |
| **RH** — « Deux chefs de projet ne s'entendent plus » | Faible cohésion + stress de projets + grande équipe | Médiation, réaffectation, formation, délégation | Productivité, moral, risques de départ, délais |
| **Contrat stratégique** — « Le client exige 99,9 % de fiabilité » | Client, capacité technique et délai compatibles | Prioriser fiabilité, négocier délai/prix, renoncer | Contrat gagné/perdu, réputation pro, arbitrages R&D |
| **Cycle de marché** — « Le public change de besoin » | Migration historique et demande réellement visible | Redéployer gamme, préserver anciennes ventes, tenter nouveau segment | Segment, part de marché, coûts de transition |
| **Pression financière** — « Le prochain CPU coûtera plus cher » | Autonomie limitée mais projet ambitieux proposé | Étaler développement, licencier technologie, financer, renoncer | Mois de trésorerie, chance technologique, dette si système implémenté |
| **Concurrence commerciale** — « Exclusivité d'un distributeur » | Présence forte d'un rival / dépendance à un canal | Négocier ailleurs, marketing ciblé, partenariat indépendant | Distribution, demande et marge selon canal |
| **Après la gloire** — « Tenir la première place » | Leadership catégoriel conservé depuis plusieurs mois | Défendre gamme, éviter l'arrogance, anticiper nouvelle génération | Durée de règne, contre-offensive crédible, perte puis reconquête |

**Ne pas injecter** un contrat, une rupture d'approvisionnement, un prêt ou une exclusivité sans primitives réellement présentes. Les exemples non raccordables sont d'abord des **spécifications futures**.

## 5. Les classements ne doivent pas récompenser le même profil

Un seul rang « meilleur empire » peut subsister **à titre de synthèse**, mais il doit cohabiter avec plusieurs champions valorisés séparément :

| Palmarès | Indicateur candidat | Comment éviter la triche/le biais |
| --- | --- | --- |
| **Meilleur CPU** | Benchmark contemporain sur une même génération/segment | Mesurer produit équivalent, pas une firme entière |
| **Meilleure efficacité** | Performance / consommation mesurée par le moteur | Même contexte de charge / segment |
| **Meilleur rapport qualité-prix** | Score client pondéré / prix normalisé au segment | Prix bas sans performances ne doit pas suffire |
| **Plus fiable** | Fiabilité, retours SAV, incidents observés | Mesurer aussi fiabilité réelle des rivaux, ne pas leur inventer des retours |
| **Favori de la presse** | Notes publiées récentes, couverture minimale | Une seule note de 100/100 ne garantit pas la première place |
| **Leader des ventes** | Unités ou parts du **même marché** sur 12 mois glissants | Ne pas utiliser ventes cumulées depuis 1971 |
| **Entreprise préférée des pros** | Livraison fiable, support, réputation, contrats | Éviter de confondre chiffre d'affaires et satisfaction |
| **Leader technologique** | R&D / architecture, avance observée sur produits réellement sortis | Débloquer une technologie non commercialisée n'est pas être leader de marché |
| **Entreprise la plus solide** | Rentabilité durable, cash-flow, autonomie, absence de crise | Pas un simple classement des liquidités brutes |
| **Empire global** | Synthèse de catégories indépendantes, normalisées, plafonnées | Éviter de compter deux fois les mêmes ventes et la même trésorerie |

Un constructeur spécialisé peut donc être **n°1 qualité**, **n°1 presse** ou **n°1 fiabilité**, sans être le plus riche ni posséder cinq filiales. Plusieurs entreprises peuvent être « premières » **simultanément dans des domaines différents**.

**Score général proposé, non décidé :** moyenne pondérée de six *dimensions déjà calculées séparément* — technologie (20 %), qualité / réputation (20 %), présence commerciale (20 %), solidité financière (15 %), relation client / SAV (15 %), innovation et adaptation (10 %). **Ne pas appliquer ces coefficients sans sonde et accord** ; le classement existant conserve son fonctionnement jusque-là. L'algorithme des NPC doit être calculable à partir de faits accessibles équivalents, même si l'UI ne publie qu'un niveau estimé.

## 6. Rythme et durée de vie

- **1971–premier lancement :** défis pédagogiques de financement, délais, qualité et premier client. Favoriser causes et conséquences courtes, éviter une crise économique impossible à prévenir.
- **Premières ventes / deuxième génération :** choix rivalité-performance/prix, recrutement soutenable, retour SAV, premiers contrats. Relances ponctuelles liées aux vrais projets.
- **Société établie :** 1 grand arc actif, parfois un second interconnecté si le joueur maîtrise la situation ; problèmes économiques, organisationnels et technologiques plus complexes.
- **Leader sectoriel :** un défi n'est pas seulement *atteindre* le rang n°1 mais **le tenir, le perdre, changer de spécialité, le reconquérir**.
- **Long terme :** rivalités persistantes, rotations de demandes, nouveaux profils de clients, héritage des choix et histoires de l'entreprise. Aucun événement ne doit punir automatiquement le joueur simplement parce qu'il gagne.

**Ne pas confondre fréquence et durée de vie.** Un défi à 3 décisions et conséquences suivies sur 18 mois a davantage de valeur que 30 popups sans impact.

## 7. Exemple entièrement contextualisé : « Un titre à défendre »

1. **Condition :** le joueur devient n°1 CPU fiabilité sur une catégorie où au moins deux concurrents disposent d'une vraie offre comparable.
2. **Annonce :** la presse donne son titre ; un concurrent crédible annonce une campagne de tests et un projet de nouvelle génération.
3. **Premier choix :** soutenir la fiabilité actuelle (SAV/QA), maintenir l'avance technologique (R&D) ou exploiter la notoriété pour gagner des parts.
4. **Deuxième étape :** une décision du rival modifie effectivement benchmark, prix ou confiance sur 6–18 mois selon ses ressources.
5. **Évaluation :** mois de leadership, qualité et ventes, dépenses et éventuel changement de stratégie du joueur.
6. **Issue :** préserver la couronne, devenir chef d'un autre palmarès, perdre provisoirement, ou rebondir. Les trajectoires restent possibles ; aucune « défaite obligatoire » cachée.
7. **Mémoire narrative :** la presse se rappelle le précédent affrontement ; le classement retient durée et meilleur exploit, pas seulement la dernière position.

## 8. Ordre d'implémentation recommandé

| Lot | Dépendance | Acceptation |
| --- | --- | --- |
| **WORLD-00** — réutiliser et auditer les menaces / RH existantes | Examen des données de `MarketManager`, `ExecutiveManager`, `ObjectivesManager` | Inventaire précis des déclencheurs, vrais coûts, fréquence et limites |
| **RANK-01** — 3 palmarès CPU indépendants (benchmark, efficacité, rapport qualité-prix) | Mesures comparables des rivaux | Test gagnants différents sur une même graine ; classement sans argent requis |
| **RANK-02** — presse, fiabilité, parts de marché et solidité | RANK-01 + mesures de vente/SAV/rivaux | Aucune catégorie n'utilise une statistique indisponible ou inventée |
| **WORLD-01** — enrichir 1 arc rivalité CPU en 3–5 étapes | RANK-01, SAVE-01, gameplay CPU | Préavis, 3 stratégies, conséquences sur 6–18 mois, sans choix dominant systématique |
| **WORLD-02** — élargir guerre des prix, approvisionnement, RH, SAV | WORLD-01 et composants existants | Arcs déclenchables et résolubles, cooldown, tests déterministes, migration si besoin |
| **CAREER-03** — inscrire distinctions et histoires dans carrière | RANK-01, WORLD-01 | Meilleur rang par catégorie, plus longue série, première accession, pertes/reconquêtes, notifications et revue sauvegarde |
| **UX-WORLD** — présentation sensible au contexte | WORLD-01 | Joueur sait pourquoi le scénario arrive, quels sont ses choix et ce qu'il risque |

**Le premier chantier réalisable sans refonte totale** : une **vraie rivalité CPU** avec classement sectoriel indépendant, une menace déclenchée à partir d'un concurrent réel, plusieurs réponses et conséquences chiffrées. **Ne pas ouvrir un nouveau secteur commercial** avant de rendre cette tranche intéressante.

## 9. Tests obligatoires

- Même graine, mêmes actions, même résultat (simulation déterministe).
- Sauvegarde/rechargement **au milieu de chaque étape** conserve le scénario, son historique et ses conséquences.
- Facteur de difficulté agit sur les ressources et conseils explicitement, pas sur une triche secrète.
- L'événement ne se déclenche pas si le rival, le fournisseur ou la capacité requise n'existe pas.
- Joueur pauvre : pas de dépense obligatoire qui rend une faillite inévitable ; alternative stratégique réelle.
- Joueur très riche : coûts et enjeux significatifs, pas de difficulté purement punitive.
- Comparer les 3 choix d'un arc sur la même graine pour vérifier que leurs conséquences sont distinctes.
- RANK : labels, calculs et exemples par segment vérifiables ; une même entreprise peut mener plusieurs catégories, plusieurs entreprises des catégories différentes.
- Peu d'événements : mesurés en **décisions significatives et effets observables**, pas en nombre de textes.
- Pas de mutation de sauvegarde Pixel personnelle, pas de fusion sans validation humaine.

## 10. Décisions encore à arbitrer avec le créateur

1. Choisir le premier palmarès mis en avant au garage.
2. Fixer le nombre d'arcs majeurs simultanés selon époque et maîtrise du joueur.
3. Décider si le score Empire global doit garder son statut actuel, être relégué en vue synthèse, ou être remplacé par une moyenne de catégories ; **ne pas changer l'économie pour cela**.
4. Définir le premier vrai scénario jouable à tester au doigt (rivalité benchmark / guerre des prix / qualité).
5. Définir ce qu'est un « grand exploit » durable (défendre n°1 24 mois, première reconquête, dépasser un rival historique).

**Toutes ces décisions de détail sont proposées. La clarification ferme du propriétaire porte d'abord sur le sens de « défi » : adversité et scénarios émergents, PAS succès/trophées.**
