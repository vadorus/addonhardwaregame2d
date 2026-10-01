# V0.10 / I5 — La page Vendre après le lancement

**Méthode.** Étude croisée : deux analyses indépendantes (Astra et Claude), puis une synthèse de Codex (avec une simulation pour trancher le seuil de capacité), et enfin la décision d'Alexandre. Les documents sont sur les branches `v010/I5-brief`, `v010/I5-analyse-astra`, `v010/I5-analyse-claude`, `v010/I5-synthese` et `v010/I5-decision`.

**Avant.** Au 1er mois de vente, la page affichait 19 boutons et ne disait jamais quoi faire. On pouvait lancer une offensive à 20 000 € avec 20 303 € en caisse.

## Ce qui change

1. **La carte « Ce mois-ci » de Nora** ouvre la page (`SalesMonthCard`).
   - Une phrase de bilan : puces vendues et bénéfice des ventes.
   - 3 chiffres : ventes, satisfaction, demande servie.
   - **Un seul** conseil, avec **un seul** gros bouton. Un deuxième problème éventuel est cité en texte.
   - S'il n'y a rien à faire : « Tout va bien, laissez vendre. » Avant le premier bilan : « Premières ventes en cours ».
2. **On n'achète jamais depuis le conseil.**
   - « Examiner » ouvre un devis : coût, effet, trésorerie restante, plafond éventuel. Ensuite on choisit « Confirmer » ou « Annuler ».
   - L'alerte de trésorerie n'apparaît que si l'action coûte quelque chose.
   - « Plus tard » met le conseil en pause 3 mois pour ce modèle. Le problème reste marqué ⚠ dans la liste.
3. **Le portefeuille « Vos CPU »** (`SalesPortfolio`) remplace le menu déroulant.
   - Ordre : À examiner, En vente (replié au-delà de 6 modèles), Fin de série, Archives. À l'intérieur de chaque groupe, la génération la plus récente d'abord.
   - Une ligne par modèle : prix, ventes/mois, bénéfice/mois et le problème éventuel.
   - Toucher une ligne ouvre la fiche du modèle.
4. **Toutes les commandes restent**, repliées sous « Gérer ce modèle ».
   - Chaque bouton payant affiche son prix.
   - Ce qui coûte ou ne se défait pas demande un second toucher : « Toucher encore pour confirmer — il restera X € ».
   - Une commande bloquée explique en texte ce qui la débloque, avec les niveaux actuels.
5. **L'offensive contre un rival passe dans Marché** (`RivalAttackPanel`).
   - Nora reprend `attack_advice()` et son garde-fou : coût ≤ 25 % de la caisse.
   - « Choisir moi-même la cible » reste disponible pour l'expert.
   - Toujours Examiner → devis → Confirmer.
   - La décision « attaquer X ? » du QG mène maintenant à Marché.

## Quand Nora conseille (`SalesAdvisor`)

Les conseils ne portent que sur un mois de vente terminé. Du plus urgent au moins urgent :

| Conseil | Condition | Bouton |
|---|---|---|
| Dossier SAV ouvert | dossier actif sur ce modèle | Ouvrir le dossier SAV |
| Perte à chaque puce | bénéfice du mois + réservation d'usine ≤ 0 | Revoir le prix |
| Rupture | ≥ 20 ventes perdues **et** ≥ 20 % de la demande grand public | Examiner la capacité |
| Rupture au plafond | même condition, usine au maximum | aucun : signalé dans la liste seulement |
| Rival dominant | `attack_advice()` | Voir dans Marché |
| Fin de vie | `retire_candidates()`, regroupés en un seul conseil | Examiner la fin de vie |
| Usine sous-utilisée | < 70 % deux mois de suite, ventes dans la prévision, économie ≥ 1 000 €/mois et ≥ 5 % du bénéfice | Examiner la capacité |
| Peu connu | < 70 % deux mois, sous la prévision deux mois, satisfaction ≥ 60, bénéfice positif, aucune campagne en cours | Examiner une campagne |
| Logiciel de contrôle | vient d'être débloqué, génération la plus récente, pas encore publié | Examiner le logiciel |

## Corrections en chemin

- **La « contribution » oubliait la part des distributeurs.** Relevé par Astra et vérifié : 35 % du chiffre d'affaires grand public en mode Standard. Le bénéfice affiché était donc trop beau.
  - L'argent du joueur, lui, était bien débité : seul le chiffre affiché était faux.
  - Le test se trompait de la même façon : sa puce perdait en réalité de l'argent. Le décor du test a été corrigé.
- **La leçon du terrain** dit maintenant « chaque puce vendue fait perdre de l'argent » avant de conseiller d'augmenter la capacité. Une perte due seulement aux frais fixes de réservation laisse la leçon sur la rupture.
- **Nouveaux devis sans dépense** : `revision_cost`, `firmware_cost`, `control_software_cost`. Les explications de blocage viennent de `firmware_block_reason` et `control_software_block_reason`.

## Mesures (banc 10 ans `profiles_probe`)

Les bots ne touchent jamais « Plus tard » : le nombre de mois avec un conseil affiché est donc un maximum.

| Profil | Nouveaux conseils sur ~9 ans de ventes | 12 premiers mois de vente |
|---|---|---|
| Novice | 16 | 7 mois avec un conseil, soit 4 conseils différents (rupture, rival) |
| Intermédiaire | 20 | 1 |
| Expert | 30 | 1 |

Ça fait environ 2 à 3 nouveaux conseils par an. Avant de filtrer, Nora répétait chaque mois les ruptures au plafond (68 mois chez le novice) et des économies de 18 €/mois. Les deux sont maintenant filtrées.

## Tests

- `SalesAdvisorScenario` (smoke) vérifie :
  - la part des distributeurs dans la contribution ;
  - « Premières ventes » puis « Tout va bien » ;
  - le seuil de rupture : 19 ventes perdues → rien, 19 % → rien, 72 sur 215 → conseil ;
  - la perte par puce qui passe avant la rupture ;
  - que le devis ne dépense rien, sans alerte pour une action gratuite, et refuse une action impossible ;
  - que « Plus tard » retire le conseil de la carte mais garde le modèle « À examiner » ;
  - capacité inutile, campagne, campagne déjà en cours, économie trop petite ;
  - les groupes Fin de série et Archives.
- `workshop_layout_test`, sur le vrai parcours en 1616×720 jusqu'à un mois de vente :
  - la carte « Ce mois-ci » ouvre la page ;
  - la grille d'actions est repliée ;
  - le bouton de Nora est visible sans défiler ;
  - « Examiner » ne dépense rien, et « Confirmer » est en vue.
- smoke, garage_layout, workshop_layout et balance_ceiling : OK.
- Captures dans `I5_captures/` : 1er mois, devis, 21 CPU, « Gérer ce modèle », Marché.

## Test sur le Pixel par Claude (01/10, 14h15)

Le test a été fait sur la partie d'Alexandre (avril 1972), sauvegardée avant et remise à l'identique après (même empreinte MD5). Parcours suivi :
1. fin de l'industrialisation, puis « Lancer les 3 modèles » ;
2. « Premières ventes en cours » ;
3. après un mois : carte de Nora avec la rupture de l'Essentiel ;
4. « Examiner », devis, puis « Confirmer » : capacité 144 → 161, 0 € ;
5. liste des CPU, toucher une ligne pour ouvrir sa fiche ;
6. « Gérer ce modèle » : le second toucher demandé sur une campagne, sans rien dépenser ;
7. Marché : la carte « Offensive commerciale ».

Ce que le test a fait corriger :
- **« Tout va bien, laissez vendre »** s'affichait juste après avoir monté la capacité, alors que la liste montrait encore deux ruptures (locaux pleins). La carte dit maintenant : « Rien à acheter ce mois-ci : vos locaux tournent à plein », avec le plafond et la solution (des locaux plus grands).
- **La fiche** annonçait « marge 146 €/puce », alors que le lancement disait ~59 € gagnés par puce. Elle affiche maintenant « gagné ~X €/puce (après distributeurs) », avec le même calcul.
- **La leçon du terrain** conseillait d'augmenter la capacité alors que les locaux étaient pleins. Elle le dit maintenant.
- **Le bouton capacité** affiche « (locaux pleins) » au lieu d'un plafond égal à la capacité actuelle.
- **« meilleure vente : nv1 E (0/mois) »** s'affichait avant les premières ventes. Supprimé.

Vu mais pas changé ici : après le premier mois de ventes, trois cartes s'enchaînent (notes de presse, « À la une », « Les étagères sont vides »). À regrouper plus tard.

## Reste à valider au doigt (Pixel)

- Un novice trouve quoi faire en moins de 15 secondes.
- Un expert ouvre prix, firmware et retrait en 2 touchers ou moins.
- Les bulles d'actualité en haut à droite peuvent encore passer sur la droite de la carte pendant quelques secondes.
