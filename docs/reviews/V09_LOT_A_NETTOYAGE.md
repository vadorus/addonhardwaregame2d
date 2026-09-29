# Lot A — nettoyage et lisibilité (29/09)

Premier lot du plan `docs/PLAN_V09_V10.md`.

## Doublons retirés

- **Produits** : l'étape « Concevoir » (qui ne faisait que renvoyer au Labo) est supprimée.
  Le cockpit a trois étapes : 1 Fabriquer / 2 Vendre / 3 SAV. Il s'ouvre sur Vendre dès qu'un CPU existe.
- **SAV** : il n'existe plus qu'en Produits › SAV. Marché garde Mes ventes / Besoins / Concurrents /
  Appels d'offres. Les anciens repères « Marché + SAV » (décisions, garage) mènent à Produits › SAV.
- **Brevets** : la sous-page vide du Labo est fusionnée en bas de Labo › Recherche. Les boutons
  « Déposer » et « Licence » n'apparaissent que s'il y a un candidat ou un brevet.

## Entreprise débloquée page par page

| Sous-page | Arrive quand |
| --- | --- |
| Aperçu | avec l'onglet (1er mois) |
| Locaux & RH | 4 salariés, un dossier RH, un déménagement conseillé, ou 6 mois d'activité |
| Budgets & délégation | premier CPU en vente (ou 2 ans) |
| Divisions | 10 salariés ou un 2e secteur actif |
| Groupe | 5 M€ de trésorerie ou une filiale |

Une ligne « Plus tard : … » annonce les deux prochaines. Chaque ouverture est annoncée
(« Nouvelle fonction disponible : Entreprise › Budgets »). Les sauvegardes existantes gardent tout.
Une décision qui vise une page encore fermée l'ouvre quand même.

Mesuré (partie neuve jouée automatiquement) : mois 2 = Aperçu seul ; mois 6 = + Locaux & RH ;
1er lancement = + Budgets.

## Un moment à la fois

- Les décisions ne s'empilent plus en trois bulles rouges : une seule carte « À faire (n) — dernière : … »,
  n = nombre réel de décisions en attente.
- Les annonces « Nouvelle fonction disponible » attendent la fin des grands moments (lancement,
  interview, révélation des tests).
- Un dossier SAV ordinaire (gravité < 60) s'appelle « Dossier SAV » et peut attendre ; seule une vraie
  « Crise SAV » bloque le temps.

Pas fait : décaler le « Premier retour marché » d'un mois. Il n'ouvre pas de fenêtre (il rejoint
la carte « À faire ») ; à revoir avec le lot B si le lancement paraît encore chargé.

## Tests

- `ProductCockpitScenario` : trois étapes, plus de « Concevoir », contexte SAV → étape SAV.
- `CeoDecisionScenario` : un repère SAV n'ouvre plus Marché.
- `SensationScenario` : trois décisions → une carte « À faire (3) ».
- Smoke test, garage_layout_test et workshop_layout_test verts.
