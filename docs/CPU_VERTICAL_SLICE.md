# Vertical slice CPU — conception détaillée

> Objectif : transformer le laboratoire actuel en une boucle CPU complète, crédible et amusante, tout en gardant les détails avancés facultatifs.

## État d’implémentation — V0.3

Le conseil d’architecture est jouable : à partir du brief courant, l’équipe prépare trois plans (prudent, équilibré, audacieux). Les prévisions tiennent compte des compétences R&D, du management, du savoir-faire CPU, de la maturité de la division, de l’équipement estimé, du budget, de l’approche et de la trésorerie. Le joueur peut appliquer un plan, le personnaliser puis le lancer.

Une architecture terminée produit désormais une gamme initiale de trois modèles :

- **Essentiel** valorise les puces partiellement exploitables avec moins de cœurs, de cache et de fréquence ;
- **Signature** représente le cœur de gamme et le compromis commercial principal ;
- **Apex** réserve les meilleurs bins à la performance, à l’image et aux marges élevées.

Le rendement dépend de la fiabilité finale, de la complexité, du procédé et de la maturité de la division. Il détermine la répartition des bins, les coûts et les capacités conseillées. Les trois références partagent la même génération, mais possèdent leur propre public, prix, coût, plafond de production et réception commerciale. La demande totale du portefeuille est plafonnée afin que plusieurs modèles ne puissent pas vendre plusieurs fois le même marché. Les propositions, générations et produits sont sauvegardés avec migration des anciennes parties.

## 1. Ce que le joueur fabrique réellement

Le joueur ne crée pas seulement un modèle isolé. Il finance une **génération d'architecture**, puis décline cette base en une famille de processeurs.

Une génération contient :

- une architecture et son jeu d'instructions/licence ;
- une microarchitecture ;
- un ou plusieurs types de cœurs ;
- une hiérarchie de caches ;
- une interconnexion ;
- un contrôleur mémoire et des interfaces ;
- une stratégie monolithique ou chiplet ;
- un procédé de fabrication et un packaging ;
- un microcode/firmware ;
- des outils, compilateurs et validations ;
- une durée de vie estimée et un potentiel de déclinaison.

La génération peut ensuite donner plusieurs références : entrée de gamme, grand public, gaming, professionnel, serveur ou basse consommation. Certaines variantes restent verrouillées tant que le moteur CPU de base n'est pas stable.

## 2. Les trois couches d'information

### Couche essentielle — toujours visible

Le joueur lit d'abord **cinq arbitrages**, et non une fiche technique brute :

- **performance** : puissance brute et capacité à tenir les charges exigeantes ;
- **efficacité / thermique** : consommation, chauffe et marge énergétique ;
- **maîtrise du coût** : capacité à garder un coût unitaire compatible avec le positionnement ;
- **fiabilité** : stabilité, rendement attendu et risque de retours ;
- **délai / risque** : probabilité de sortir à temps sans dérive majeure.

L'adéquation au client cible reste affichée séparément, car elle répond à une autre question : « ce compromis correspond-il au marché choisi ? ». Ces cinq axes sont une **couche de lecture** calculée à partir de la simulation détaillée ; ils ne remplacent pas les paramètres techniques.

### Couche de conception — laboratoire standard

- cœurs et types de cœurs ;
- fréquence cible ;
- cache ;
- enveloppe thermique ;
- procédé de fabrication ;
- stratégie monolithique/chiplet ;
- mémoire et connectivité principales ;
- niveau d'innovation.

### Couche avancée — simulation ou panneau dépliable

- IPC estimé ;
- threads ;
- niveaux de cache ;
- canaux mémoire, débit, ECC ;
- lanes et version d'interconnexion ;
- taille de die/chiplets ;
- rendement estimé ;
- limites boost/base ;
- accélérateurs, virtualisation et sécurité ;
- packaging, température, tension ;
- couverture de validation et dette microcode.

La couche avancée explique les résultats mais ne doit pas être obligatoire pour lancer un premier CPU.

### Recherche continue, expérience et confiance

La recherche CPU fonctionne en parallèle du développement produit. La première version expose volontairement trois axes simples :

- **Architecture & performance** ;
- **Énergie & thermique** ;
- **Fiabilité & stabilité**.

Le joueur répartit les chercheurs R&D entre ces axes. La Recherche et le Développement étant désormais deux équipes distinctes, renforcer la Recherche ne retire plus artificiellement des ingénieurs au Développement. Le budget de recherche fondamentale est distinct du budget du produit.

Chaque axe conserve trois notions différentes :

- **connaissance** : ce que l'entreprise comprend et sait théoriquement exploiter ;
- **expérience** : ce que l'équipe a réellement pratiqué au fil de ses recherches et développements ;
- **confiance** : qualité des estimations que l'équipe peut fournir au joueur.

La connaissance progresse avec des rendements décroissants : atteindre un niveau correct est relativement rapide, devenir expert demande un investissement durable. Le développement de produits apporte aussi un peu d'expérience dans l'axe travaillé, afin qu'une génération imparfaite reste utile pour la suivante.

À certains paliers, l'équipe peut faire remonter une **découverte R&D**. Le joueur peut approfondir la piste, ce qui crée un élan temporaire et de l'expérience supplémentaire, ou l'archiver. Ces événements servent de base aux futures découvertes technologiques plus spécifiques sans imposer un arbre de recherche gigantesque.

Les propositions de génération tiennent compte de cette recherche. Une équipe peu expérimentée fournit des estimations moins fiables et Camille doit le signaler ; une équipe mature donne des prévisions plus précises sans supprimer complètement l'incertitude.

### Équipe Développement distincte

La Recherche et le Développement sont deux équipes différentes. La Recherche accumule connaissances, expérience scientifique et nouvelles pistes. Le Développement transforme ce savoir en architecture réellement intégrée, testée et validée.

L'équipe Développement possède sa propre taille, son propre score, son management, son expérience et une charge liée au nombre de projets actifs. Une bonne R&D ne garantit donc pas à elle seule un bon produit : une équipe de développement trop petite ou surchargée ralentit l'intégration, réduit la qualité des validations et rend les prévisions moins fiables.

À l'inverse, augmenter fortement la Recherche ne retire plus artificiellement des ingénieurs au Développement : le joueur doit recruter, organiser et financer les deux capacités séparément.

### Industrialisation et équipe Production

Un CPU terminé en Développement n'est plus immédiatement vendable. Il entre dans une phase d'**industrialisation** prise en charge par l'équipe Production.

La Production possède désormais :
- un score d'équipe influencé par les profils réels des employés ;
- une maîtrise propre à chaque procédé de gravure ;
- une connaissance qualité ;
- une connaissance maintenance ;
- une expérience qui progresse en industrialisant réellement des générations.

Le joueur choisit une stratégie industrielle par projet :
- **Économie** : coût plus faible, mais rendement/qualité moins favorables ;
- **Équilibrée** : compromis par défaut ;
- **Qualité renforcée** : plus chère et légèrement plus lente, mais meilleur rendement et moins de défauts ;
- **Cadence prioritaire** : industrialisation plus rapide et capacité plus forte, avec davantage de risque qualité.

Le résultat d'industrialisation fixe ensuite le rendement final, le taux de défaut, la capacité réelle, le coût unitaire et une partie de la fiabilité commerciale. Les défauts de fabrication augmentent aussi les retours SAV après le lancement.

## 3. Demander une nouvelle génération

Le joueur fournit un brief :

- segments prioritaires ;
- enveloppe budgétaire ;
- date ou fenêtre de sortie ;
- priorité : performance, efficacité, fiabilité, prix ou innovation ;
- niveau de risque accepté ;
- stratégie : interne, partenariat, licence ou achat ;
- durée de vie souhaitée ;
- compatibilité à préserver ou rupture de plateforme acceptée.

L'équipe analyse son expérience, ses spécialistes, son équipement, les technologies connues et le marché. Elle propose jusqu'à trois plans.

| Plan | Bénéfice | Contrepartie |
|---|---|---|
| Révision sûre | rapide, compatible, rendement élevé | gain limité, durée de vie plus courte |
| Nouvelle génération équilibrée | bonne gamme et progrès durable | budget et délai moyens |
| Rupture ambitieuse | fort potentiel, innovation, image | risque, coût, validation et retard |

Chaque estimation possède une confiance. Une équipe junior peut sous-estimer le délai ou le risque ; une équipe expérimentée fournit des fourchettes plus fiables.

## 4. Paramètres techniques et conséquences de jeu

| Choix | Gains possibles | Coûts/risques possibles |
|---|---|---|
| Plus de cœurs | multicœur, serveur, création | surface, coût, consommation, rendement |
| Fréquence élevée | réactivité, jeu, benchmark | tension, chauffe, fiabilité |
| IPC/microarchitecture complexe | performance à fréquence égale | temps de conception, bugs, validation |
| Cache plus grand | latence réduite, performance | surface, consommation, coût |
| Gravure avancée | densité, efficacité | prix wafer, capacité, maturité |
| Chiplets | gamme modulaire, rendement potentiel | packaging, interconnexion, latence |
| Contrôleur mémoire avancé | débit, serveur, IA | validation, compatibilité, die |
| TDP élevé | performance soutenue | refroidissement, image, marché limité |
| Accélérateur dédié | avantage sur certains usages | surface inutilisée ailleurs, logiciel |
| Sécurité/virtualisation | pro, serveur, contrats | complexité et validation |

Les relations ne doivent pas être purement linéaires. Une fréquence trop haute combinée à un refroidissement faible augmente fortement le risque ; une nouvelle gravure immature peut diminuer le rendement malgré sa densité.

## 5. Valeurs dérivées visibles par le marché

Le moteur transforme la conception en mesures que les clients comprennent :

- performance monocœur ;
- performance multicœur ;
- performance par watt ;
- performance par euro ;
- latence mémoire ;
- débit mémoire ;
- consommation au repos et en charge ;
- température/bruit système estimés ;
- stabilité et taux de panne ;
- compatibilité ;
- capacité IA ou vectorielle lorsque présente ;
- sécurité et virtualisation ;
- coût total de possession pour les professionnels.

Chaque segment pondère ces mesures différemment. Le même CPU peut dominer en serveur et être un mauvais choix pour un ordinateur compact.

## 6. Fabrication simplifiée mais réelle

Le joueur ne manipule pas des milliers de matières. Il choisit une chaîne industrielle résumée par cinq décisions.

### 6.1 Technologie de fabrication

Procédé mature, performant ou de pointe. Impact : densité, fréquence, consommation, coût du wafer, capacité disponible et rendement initial.

### 6.2 Structure du silicium

Monolithique, plusieurs dies ou chiplets. Impact : modularité de gamme, taille des dies, interconnexion, packaging et validation.

### 6.3 Packaging et substrat

Standard, avancé ou spécialisé. Impact : coût, puissance, nombre d'entrées/sorties, dissipation, capacité fournisseur et fiabilité.

### 6.4 Assemblage et test

Couverture économique, équilibrée ou intensive. Impact : coût, détection de défauts, retours et réputation.

### 6.5 Contrat industriel

Sous-traitance flexible, capacité réservée, partenariat ou fab interne bien plus tard. Impact : investissement, prix, priorité, volume, risque et dépendance.

Les matières (silicium, cuivre, substrats, terres/produits chimiques) existent derrière ces contrats. Elles remontent au joueur lorsqu'une pénurie, un choix environnemental ou une innovation les rend stratégiques.

## 7. Phases du projet CPU

1. **Étude d'opportunité** — besoin client, concurrence et fenêtre de marché.
2. **Architecture** — plans générationnels, blocs, ISA, plateforme et risques.
3. **Conception** — cœurs, cache, interconnexion, mémoire, puissance et vérification.
4. **Prototype** — premiers échantillons, mesures et défauts.
5. **Validation** — charges, températures, cartes mères, firmware, OS et sécurité.
6. **Industrialisation** — rendement, binning, packaging, capacité et coût.
7. **Lancement** — gamme, prix, stock, marketing et partenaires.
8. **Suivi** — ventes, retours, correctifs, révisions et fin de vie.

À chaque phase, le chef de projet présente un résumé, les changements depuis le précédent rapport et au maximum quelques arbitrages importants.

## 8. Événements, découvertes et recherches débloquées

| Déclencheur | Exemple de découverte | Effet possible |
|---|---|---|
| Spécialiste thermique + banc avancé | gestion de puissance améliorée | TDP réduit ou boost plus stable |
| Équipe cache expérimentée | politique de cache innovante | IPC/latence améliorés |
| Collaboration fonderie | règle de conception optimisée | meilleur rendement |
| Prototype instable | piste de microcode | correctif rapide avec légère perte |
| Travail sur chiplets | interconnexion propriétaire | technologie réutilisable ailleurs |
| Analyse SAV | défaut récurrent compris | fiabilité génération suivante |
| Recherche matériaux | substrat plus conducteur | température ou densité améliorée |

Une découverte peut :

- appliquer un bonus contrôlé au projet ;
- ouvrir une décision ;
- créer une recherche séparée ;
- devenir une technologie d'entreprise ;
- générer un brevet ;
- être partagée avec une autre division.

Le joueur choisit parfois entre exploiter immédiatement une piste imparfaite ou financer une recherche plus sûre pour la génération suivante.

## 9. Microcode et écosystème logiciel

Le projet possède une qualité de microcode et une couverture de compatibilité. Les tests portent sur :

- gestion de puissance et fréquences ;
- démarrage et firmware de carte mère ;
- mémoire ;
- veille et reprise ;
- virtualisation ;
- instructions et compilateurs ;
- systèmes d'exploitation ;
- sécurité ;
- charges réelles de partenaires.

Un problème après lancement peut être corrigé par mise à jour, mais avec coût, délai, confiance client et parfois perte de performance. Un défaut physique grave exige révision, remplacement ou rappel.

## 10. Gamme et binning

> **Implémenté en V0.2.8 :** création de la gamme Essentiel / Signature / Apex, rendement générationnel, répartition des bins, coûts, capacités et segments distincts. Les variantes supplémentaires et le réglage manuel de l’allocation viendront ensuite.

La fabrication produit des puces de qualités différentes. Le joueur peut les classer en modèles :

- haut de gamme à fréquence élevée ;
- modèle principal ;
- modèle économique avec blocs désactivés ;
- version basse consommation ;
- version professionnelle/serveur si la validation le permet.

Cette mécanique augmente le rendement commercial sans multiplier la conception. Une gamme trop large coûte toutefois en validation, marketing, stock et support.

## 11. Lancement et réception

Avant la sortie, le joueur choisit : prix, volumes, gamme, date, promesse et échantillons presse. Les tests publics comparent le CPU aux concurrents selon des mesures cohérentes.

Les réactions doivent répondre à des questions simples :

- est-il rapide pour ce public ?
- consomme-t-il trop ?
- est-il stable et compatible ?
- vaut-il son prix ?
- la plateforme durera-t-elle ?
- la marque tiendra-t-elle ses promesses de support ?

## 12. SAV et maintenance

Après lancement, la simulation suit lots produits, retours, symptômes, versions microcode, satisfaction et coûts de garantie. Le joueur reçoit des signaux avant d'obtenir une certitude parfaite.

Décisions possibles : enquête, correctif, partenariat carte mère/OS, remplacement, extension de garantie, rappel, compensation, arrêt d'un lot, nouvelle révision ou déni. Chaque réponse agit sur argent, capacité, réputation, confiance et ventes futures.

La fin de commercialisation n'est pas la fin du produit. Il reste des garanties, pièces, mises à jour et contrats à honorer jusqu'à la fin de support annoncée.

## 13. Données minimales à ajouter au moteur

### Génération CPU

- identifiant et nom de code ;
- parent/technologies héritées ;
- architecture choisie ;
- durée de vie estimée ;
- potentiel de gamme ;
- niveau de risque et confiance des estimations ;
- maturité, couverture de validation et dette technique ;
- état du cycle de vie.

### Design technique

- cœurs/types, fréquence, IPC, cache, TDP ;
- nœud, structure die/chiplet et packaging ;
- mémoire, I/O, accélérateurs ;
- microcode, compatibilité et sécurité ;
- taille, rendement, coût unitaire et capacité.

### Produit commercial

- génération source et variante ;
- bin/positionnement ;
- prix et volume ;
- benchmarks ;
- versions firmware ;
- lots, retours, garanties et fin de support.

## 14. Ordre recommandé d'implémentation

1. Socle de division CPU, sauvegarde et maturité.
2. Objet génération et trois propositions d'architecture — implémenté en V0.2.7.
3. Paramètres techniques complémentaires avec affichage essentiel/avancé.
4. Découpage architecture → plusieurs modèles — première version implémentée en V0.2.8.
5. Procédé, packaging, rendement et contrat de fabrication simplifiés.
6. Microcode, compatibilité et validation.
7. Incidents post-lancement, correctifs, garantie et fin de vie.
8. Découvertes d'équipe et recherches dérivées.
9. Équilibrage et délégation complète.

## 15. Références techniques

- RISC-V International, spécifications d'architecture : https://riscv.org/specifications/ratified/
- Arm, architecture matériel/logiciel : https://www.arm.com/architecture
- Arm, chiplets : https://www.arm.com/glossary/chiplets
- TSMC, 3DFabric et packaging : https://www.tsmc.com/english/dedicatedFoundry/technology/3DFabric
- UCIe Consortium, interconnexion die-to-die : https://www.uciexpress.org/specification
- Intel, familles, niveaux et suffixes de processeurs : https://www.intel.com/content/www/us/en/processors/processor-numbers.html
- Intel, exemple officiel d’une gamme partageant une plateforme avec cœurs, cache et puissance différenciés : https://www.intel.com/content/www/us/en/products/docs/processors/core-ultra/core-ultra-desktop-processors-series-2-brief.html

