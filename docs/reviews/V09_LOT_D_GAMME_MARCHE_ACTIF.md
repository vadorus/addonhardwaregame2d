# Lot D — Gamme et marché actif (29/09)

But : le joueur agit sur le marché au lieu de le regarder.

## Fin de série et retrait
- Fiche produit (Produits › Vendre) : « Fin de série » (prix -25 % pendant 3 mois, petite relance
  de la demande, puis retrait automatique) ou « Retirer maintenant ».
- Un modèle sous contrat client en cours ne peut pas être retiré (raison affichée).
- Un modèle retiré ne vend plus et passe en fin de liste ; le SAV des puces vendues continue.
- **Conseil de Nora**, marché par marché (et non plus gamme par gamme, car les anciennes parties
  ont des modèles sans gamme) :
  - dépassé : une génération plus récente est en vente sur le même marché, et le modèle a 3 ans
    ou fait moins de 5 % des ventes de ce marché ;
  - pièce de musée : 8 ans et plus ;
  - version morte : après un an, moins de 1 % des ventes d'un marché qui vend vraiment ;
  - il reste toujours au moins un modèle en vente.
- Carte « Nora : N modèles à sortir de la gamme » dans Produits, et décision GAMME au bureau du PDG
  (« Tout passer en fin de série » / « Choisir modèle par modèle » / « Garder », rappel dans 6 mois).

## Attaquer un rival
- Fiche produit : « Attaquer un rival » (rivaux présents sur le même marché), coût = 40 % d'un mois
  de chiffre d'affaires, 20 000 € minimum, pendant 4 mois.
- Effet : +20 % de demande pour le modèle et plafond de part de marché élargi sur ce marché ;
  le rival perd 25 % de ses clients (38 % s'il ne réagit pas).
- **Le rival réagit** le premier mois, selon son caractère : baisse de prix de 15 %, grande campagne
  de publicité (+4 de marque), sortie anticipée de sa prochaine génération, ou rien.
  Chaque étape fait une brève dans la presse ; bilan à la fin (« ses ventes ont baissé de X % »).
- Nora propose l'offensive (décision RIVAL) quand un rival vend au moins 2 fois plus que votre
  meilleur modèle sur un marché et que l'offensive coûte moins d'un quart de la trésorerie.

## Recrutement : Nora trouve 3 profils
- Personnel › Recrutement : « Nora cherche 3 profils » → expert confirmé (compétence 80-90, salaire
  ×1,55), junior prometteur (42-54, salaire ×0,68, +3 tous les 6 mois jusqu'à +18), généraliste (60-70).
- On choisit un profil puis on le recrute (prime d'embauche = 2 mois de salaire, inchangée).

## Gammes créées par le joueur
- Déjà en place depuis le concepteur V0.9 : l'étape « Modèles » laisse choisir 1 à 3 modèles
  (Essentiel / Signature / Apex) par génération. La baisse de prix d'une ancienne génération
  passe par le prix du modèle ou la fin de série.

## Vérifications
- Smoke test vert + `RangeAndRivalScenario` (fin de série, retrait, conseil, offensive et réaction
  par baisse de prix, presse, sauvegarde, 3 profils, progression du junior).
- Partie d'Alexandre (8/1985) : 21 modèles en vente → Nora en propose 11 (tv1, tv2, tv 3, raptor
  Signature et Apex) → **10 modèles** après la fin de série, chiffre d'affaires mensuel inchangé
  (~313 k€ : les vieux modèles se cannibalisaient). Les 2 modèles au-delà de l'objectif (≤ 8) sont
  sous contrat client en cours : Nora les proposera à la fin des contrats.
- Offensive conseillée sur sa partie : Aster G14 (3 626/mois) contre raptor E (304/mois), coût 172 k€.
