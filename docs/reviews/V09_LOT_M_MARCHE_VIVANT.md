# Lot M — marché vivant et croissance qui paie (29/09)

Lot ajouté au plan après l'audit `V09_AUDIT_LEAD_TYCOON.md`. Commencé par ChatGPT (M1 à M3 commités,
M4 en cours quand sa session s'est arrêtée), terminé et vérifié par Claude.

## Ce qui a été fait

| Morceau | Auteur | Contenu |
| --- | --- | --- |
| M1 vie des produits | ChatGPT | Pic de lancement, plateau, déclin, fin de série à 8 ans ; segments qui montent puis déclinent (calculatrices, PC de bureau…) ; ventes qui baissent quand un rival sort mieux |
| M2 grands marchés | ChatGPT + Claude | Chaque marché demande une équipe et un budget (PC de bureau 10 dév., serveur 25, datacenter 32) pour un marché jusqu'à 8× plus grand. Claude : marchés du garage jouables à 2 dév. ; ventes réduites si l'équipe est trop petite (voir plus bas) |
| M3 presse relative | ChatGPT | Les notes comparent au meilleur rival et à votre génération précédente (« Déception : il recule face à… ») |
| M4 menaces | ChatGPT + Claude | Guerre des prix, récession, pénurie de silicium, procès de brevet, nouvel entrant : une tous les ~4 ans dès 1975. Financer une réponse ou encaisser. Claude : coûts proportionnels au chiffre d'affaires |
| Capacité réglable | Claude | La capacité n'est plus figée au lancement ; ruptures mesurées et signalées par Nora |

## Découverte : pourquoi les ventes d'Alexandre étaient figées

Dans sa sauvegarde de 1985, chaque CPU récent vendait **exactement sa capacité de production**
(diamant 1 E : 226/226, xeon : 101/101, xeon X : 1/1). La demande était plus forte, mais la capacité
était fixée une fois pour toutes au lancement, et rien ne le disait. Désormais :
- Produits › Vendre › « Capacité de production » : ajustable à tout moment ; au-delà du maximum
  négocié, une extension payante (jusqu'à ×2 par décision) ;
- la fiche du modèle affiche « ⚠ rupture : N clients repartis sans CPU » ;
- Nora prévient une fois par rupture sérieuse (≥ 20 % de la demande).

## Deux corrections d'équilibrage

1. **Faillite au premier CPU.** Avec 5 développeurs exigés pour « Industriel » (marché de 1971) et
   2 au départ, un premier projet sur ce marché ruinait l'entreprise au mois 19. Marchés du garage
   ramenés à 2-4 développeurs, pénalité d'équipe adoucie (puissance 0,6 au lieu de 0,72).
2. **Grandir sans embaucher.** Une entreprise de 8 personnes atteignait 1 milliard d'euros en visant
   le datacenter. Les ventes d'un marché sont maintenant multipliées par
   (équipe / équipe requise)^0,6 (minimum 0,30) tant que l'équipe Développement est trop petite.
   Affiché sur la fiche du modèle : « ⚠ équipe trop petite pour ce marché : ventes ×0,49 ».

## Mesures (sonde 40 ans, `_claude_probe/invest_probe.gd`)

| Joueur automatique | Salariés 2010 | Chiffre d'affaires 2010 | Trésorerie 2010 |
| --- | --- | --- | --- |
| Passif (même marché, pas de R&D) | 12 | 2,8 M€/an | 20 M€ |
| Change de marché, n'embauche pas | 8 | 66 M€/an | 673 M€ |
| Change de marché **et embauche** | 38 | **209 M€/an** | 1,2 Md€ |

Critères du lot :
- ventes qui varient : écart trimestriel maximal médian 59 à 77 % selon le joueur ✅ ;
- aucun modèle de plus de 8 ans ne vend encore (plus vieux vendu : 96 mois) ✅ ;
- grandir paie : à marché égal, embaucher donne ×3,2 de chiffre d'affaires ✅ ;
- menaces : 9 en 40 ans (1975, 1979… 2007), ≈ 2,3 par décennie ✅ ;
- notes : le joueur passif passe de 81 (1972) à ~54 dès 1983 ; les joueurs qui investissent restent entre 63 et 92 ✅.

Partie d'Alexandre rejouée 36 mois sans nouvelle génération : chiffre d'affaires mensuel
374 k€ → 120 k€ (les vieux CPU sortent du marché) ; première menace (guerre des prix) en sept. 1986,
réponse à 130 k€. Rester immobile coûte maintenant de l'argent.

## À surveiller

- **Ordre de grandeur de fin de partie** : 0,7 à 1,3 Md€ pour un joueur qui investit, contre 20 M€
  pour un joueur passif (×35 à ×65). Cohérent pour un tycoon, mais à calibrer avec le lot F
  (rachats, filiales) pour que cet argent serve.
- Le nombre de modèles vivants reste élevé (9 à 16) : le lot D (gamme choisie, retrait) reste utile.
