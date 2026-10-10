# PROGRESSION-01 — Plafond réel de contenu et stratégie d'évolution

**Date : 10/10/2026.** **Origine : clarification directe du créateur de Tech Empire.**  
**État : conception et décision de séquencement, aucun changement du jeu.**  
**Référence observée : `v013/demo-octobre` au commit `c1d4f6e`.**

## 1. Il existe bien une limite de durée de vie *ludique*

L'absence de victoire terminale imposée ne signifie **pas** progression sans fin.

- **Fin technique actuelle :** `SimulationManager.gd` arrête la carrière quand la trésorerie est épuisée ; l'année 2030 des sondes n'est pas un arrêt obligatoire.
- **Limite de contenu actuelle :** l'offre Hardware jouable tourne essentiellement autour du CPU, avec un périmètre fini d'activités et de technologies effectivement conçues. La répétition possible des lancements de produits ne signifie pas une expansion infinie des choses à découvrir.
- **Software :** la branche existe déjà dans le code, mais sa profondeur et son intérêt restent **nettement en deçà de la vision du créateur**. Sa présence technique ne justifie pas de la présenter comme terminée.
- **Risque :** les revenus, trophées, événements ou nouveaux noms de génération peuvent continuer à varier alors que **les décisions inédites, possibilités et découvertes sont épuisées**.

Il faut donc mesurer non seulement « combien d'années la simulation peut tourner » mais aussi **quand le joueur n'a plus de nouvelle possibilité significative**. L'horloge longue n'est pas, à elle seule, une preuve de durée de vie.

## 2. Clarification fondamentale sur les « générations »

Deux sujets distincts qu'il ne faut plus confondre :

1. **Générations de produits CPU déjà supportées :** sortir un nouveau CPU, changer certaines caractéristiques / architectures, progresser en R&D, lancer une nouvelle gamme. `ResearchManager.gd`, `MarketManager.gd` et la bible de design disposent de plusieurs briques liées à ce cycle.
2. **Système de nouvelles générations technologiques au sens structurel et extensible :** capacité future à introduire de nouvelles familles, sauts techniques, ères, dépendances, évolutions à long terme et synergies entre branches selon une architecture modulaire cohérente. **Ce système envisagé par le créateur n'a pas encore d'architecture validée ; il ne faut ni le présenter comme présent ni le développer à la hâte.**

La bible `docs/DESIGN_BIBLE.md` est une **vision cible**, pas un justificatif pour considérer toutes les technologies documentées comme implémentées.

**Décision de séquencement : NE PAS lancer maintenant la refonte du moteur « générations technologiques »**. Commencer par comprendre la structure présente, les frontières entre produit, technologie, compétence, marché, division et sauvegarde. Seule une proposition d'architecture et ses tests exploratoires peuvent être préparés, sans engagement d'implémentation.

## 3. Stratégie de croissance voulue

Le **plan de repli / d'extension** envisagé par le créateur est **d'ajouter d'autres branches d'activité plus tard**, pour ouvrir de nouveaux types d'objectifs et de gameplay lorsque le domaine CPU devient plus familier.

Cependant, **ajouter un menu GPU / Mobile / Spatial sans gameplay propre n'augmente pas réellement la durée de vie**. Une future branche doit offrir :
- de nouvelles décisions propres à son secteur ;
- des technologies et contraintes distinctes, pas un CPU rebaptisé ;
- des interactions avec les activités existantes (matériel ↔ logiciel, sous-traitance, licences, fournisseurs, R&D partagée) lorsque les fondations le permettront ;
- des objectifs, des adversaires et des scénarios qui évoluent avec l'entreprise ;
- la possibilité de jouer spécialisé ou diversifié, sans obliger à posséder toutes les divisions ;
- une migration fiable des anciennes parties.

C'est une **trajectoire possible** et non l'autorisation d'ouvrir aujourd'hui plusieurs nouvelles branches.

## 4. Les scénarios vivants n'effacent pas la limite de contenu

[SCENARIO-01](SCENARIOS_DEFI_CLASSEMENTS_2026-10-10.md) propose rivalités, crises, classements et histoires émergentes. **Ces systèmes approfondissent la boucle déjà jouable et renouvellent les situations ; ils ne remplacent ni de nouvelles mécaniques ni une véritable progression technologique.**

Aucune répétition forcée des mêmes choix sous prétexte que les rivaux « réagissent ». Lorsqu'une filière a réellement atteint son plafond, le joueur doit pouvoir considérer la spécialisation comme une réussite, changer d'ambition ou découvrir une activité **une fois celle-ci jouable**.

## 5. Ordre de développement recommandé et dépendances

| Étape | Nature | Condition de sortie |
| --- | --- | --- |
| **PROG-00 : établir le plafond CPU actuel** | Audit comportemental et technique | Tableau « premières heures → premières générations → carrière avancée » : technologies réellement disponibles, décisions distinctes et point de saturation, sans inventer un nombre d'heures |
| **CORE-01 : améliorer la tranche CPU existante** | Gameplay, interface, économie | Deux carrières contrastées intéressantes ; décision pendant le développement, stratégies concurrentielles, gestion viable, conséquences visibles |
| **SOFT-01 : approfondir le Software existant** | Vraie boucle produits / services / contrats et maintenance | Un logiciel a une identité, des décisions, un cycle commercial et des conséquences lisibles distinctes du CPU |
| **WORLD/RANK : renouveler les défis au sein de ces branches** | Scénarios adverses et palmarès multiples | Les défis servent à transformer les décisions, pas à retarder artificiellement le plafond de contenu |
| **ARCH-00 : étude uniquement** | Cadrer technologies, familles, époques, compétences, données, migrations et synergies | RFC courte montrant 2 technologies de branches différentes, une dépendance partagée, une sauvegarde migrable et des scénarios de tests ; **pas de grand refactor tant que non approuvée** |
| **BRANCH-00 : extensions futures** | Nouvelles divisions sélectionnées ensuite | Une branche pilote offre sa propre boucle et apporte plus de profondeur que de menus ; coût et compatibilité vérifiés |
| **GEN-01 : système technologique modulaire futur** | Développement seulement si ARCH-00 est validée | Exigences et limites validées, trajectoire d'intégration progressive, tests d'anciennes parties et non-régression économique |

L'ordre **ARCH-00 / BRANCH-00 / GEN-01** n'est pas définitivement fixé : il dépend de l'architecture choisie. Ici, **ARCH-00 ne constitue pas une autorisation de coder GEN-01**.

## 6. Ce qui ne doit PAS arriver

- Dire « carrière infinie » sous prétexte qu'il n'y a pas de date de fin.
- Confondre 25 générations de produits avec 25 nouvelles familles de technologies.
- Ajouter du contenu factice pour gagner des heures de jeu.
- Renforcer artificiellement les rivaux quand le joueur a atteint le plafond technologique, afin de simuler une progression qui n'existe pas.
- Promettre que le Software est déjà suffisamment profond.
- Construire une architecture générale de toutes les branches **avant d'avoir défini le contrat de données et les tests minimaux**.
- Utiliser un DLC ou un achat comme solution obligatoire pour pallier un cœur de jeu trop faible.
- Modifier le score Empire ou l'équilibrage pour masquer l'absence de progression.

## 7. Questions ouvertes, non à décider unilatéralement

- Quel **plafond de progression** paraît satisfaisant pour une version CPU seule, et sur combien de cycles réellement différents ?
- Jusqu'où approfondir Software **avant** de considérer l'ajout d'une troisième branche ?
- Le système technologique futur sera-t-il daté historiquement, exploratoire, ou hybride ?
- Quelles données doivent être communes entre les branches et quelles différences doivent rester propres au secteur ?
- Quel ordre d'extension est réellement pertinent une fois le CPU/Software stabilisé ?

**Statut final :** clarification du créateur documentée ; aucun code changé, aucun essai Godot revendiqué, aucun lancement GEN-01 ou nouvelle branche autorisé.
