# Lots H1 + H2 — marge d'une jeune marque et capacité payante (30/09/2026, Claude)

## Diagnostic (corrige l'audit du matin et le mien)
La gamme partage **déjà** la demande (`MarketManager.estimate_portfolio_demand`, plafond de marque ~3 % du segment).
Le moteur de l'argent facile était la **marge** : puces vendues 125/185/285 € pour 31/39/47 € de fabrication
(75-83 % de marge brute) → ~60 k€ de bénéfice par mois dès le 1er mois, avec 3 personnes.
Une gamme rapporte ~5× un modèle seul surtout parce que chaque modèle ajoute sa propre capacité.

## Fait
- **H1 — distributeurs** (`MarketManager.distributor_share`) : ils gardent 28 % (Accessible), 35 % (Standard) ou 38 % (Simulation)
  du prix des ventes en boutique (pas des contrats B2B). La part baisse avec la réputation, la notoriété et les locaux (plancher 12 %).
  Ligne « Distributeurs — <produit> » dans le bilan mensuel ; Nora l'explique une fois au premier mois de ventes.
- **H1 — courbe d'expérience** (`ProductManager.experience_cost_factor`) : fabrication ×1,55 au début, −8 points par doublement
  des puces vendues (×1,30 à 4 000, ×1,14 à 16 000, ×1,00 à 64 000).
- **H2 — capacité** (`ProductManager.capacity_change_quote`) : une extension coûte ~5 mois de la marge nette des puces ajoutées ;
  plafond fixe = capacité maximale prévue au lancement × (2 + 0,5 par palier de locaux), qui ne grandit plus d'extension en extension ;
  le devis explique la limite (« Limite du fondeur… »). Bouton du cockpit : prix, remboursement en ~N mois, plafond.
- **Q1** : `tests/balance_ceiling_test.tscn` **vert**, ajouté à `tools/build_all.ps1` et à la CI GitHub.

## Résultats 24 mois (test de plafonds)
| Cas | Avant | Après | Visé |
|---|---:|---:|---|
| Standard passif | 1 503 186 € | 645 180 € | 250-600 k€ (plafond 1 M€) |
| Accessible passif | 1 182 753 € | 720 351 € | 300-800 k€ |
| Standard actif (réagit aux ruptures) | 1 867 048 € | 818 025 € | 300-900 k€ |
| Simulation actif | 1 636 670 € | 560 147 € | 150-700 k€ |
| Actif / passif | ×1,24 | ×1,27 | ×1,0 à ×1,6 |
| Extension au plafond | remboursée en ~2 semaines | remboursée en 5,4 mois | ≥ 4 mois |

## Résultats 10 ans (`_claude_probe/profiles10y.gd`) — à traiter par H3 / H4 (ChatGPT)
| Profil, fin 1981 | Avant | Après H1/H2 |
|---|---:|---:|
| Novice passif (3 personnes, garage) | 10,9 M€, rang 2 (n°1 dès 1975) | 7,6 M€, rang 2 (n°1 en 1978) |
| Intermédiaire qui grandit (12 pers., locaux 3) | 4,3 M€ | **0,84 M€** |
| Expert (25 pers., fab) | 75,5 M€ | 44,4 M€ |

**Conclusion pour H3 / H4** : H1/H2 règlent la fenêtre des 24 premiers mois, mais **grandir est encore plus puni en relatif**
(le novice passif finit 9× plus riche que l'intermédiaire qui embauche et déménage). Les deux leviers restent à faire :
- H3 : une équipe plus grande doit produire des projets **plus rapides et meilleurs**, et des locaux plus grands **plus de capacité et de marchés**
  (le plafond de capacité H2 suit déjà les locaux : +0,5× par palier) ;
- H4 : les produits doivent **vieillir** (demande et prix qui baissent, rivaux meilleurs) pour qu'un garage passif ne reste pas n°1
  avec des CPU de 1972.
Critère de la feuille de route : intermédiaire ≥ 2× novice passif sur 10 ans ; jamais n°1 avec 3 personnes.
