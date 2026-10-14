# RANK-01 + WORLD-01 — Palmarès CPU et défi « Un titre à défendre » (14/10/2026)

**Branche :** `feat/palmares-rivalite`, partie de `v013/demo-octobre` @ `243bfc9` (après FIX-01).
**Source de conception :** [SCENARIO-01](../SCENARIOS_DEFI_CLASSEMENTS_2026-10-10.md), décisions D-010 et D-011.

## Ce qui change pour le joueur

**Marché → Palmarès du marché CPU.** Quatre couronnes, calculées avec les mêmes règles pour vos CPU et
ceux des rivaux, à partir de valeurs que la simulation calcule déjà :

| Couronne | Mesure |
|---|---|
| Meilleur CPU | note du banc d'essai (`MarketManager.benchmark_score`) moins l'usure du marché |
| Le plus sobre | efficacité énergétique moins l'usure |
| Meilleur rapport qualité/prix | banc d'essai ÷ prix rapporté au prix habituel du marché ; il faut au moins 85 % de la médiane du banc d'essai (un prix bas ne suffit pas) |
| Leader des ventes | puces vendues le mois dernier, par entreprise |

- Une couronne ne change de main que si le challenger fait nettement mieux (+0,5 point, ou +2 %).
- Chaque ligne dit qui la tient, depuis combien de mois, votre rang et l'écart, vos mois en tête et votre
  record d'affilée. Prise et perte de couronne : alerte et brève de presse.
- L'usure : les notes d'un CPU sont celles de son époque. Sans usure, un CPU de 1974 restait « le
  meilleur » jusqu'en 2010 (vu à la sonde). On applique à tous la même usure que le marché
  (`product_age_penalty` : rien la première année, puis quelques dixièmes de point par mois).

**Le défi « Un titre à défendre »** (premier défi vivant au sens de SCENARIO-01) :
1. Déclencheur : vous tenez « Meilleur CPU » depuis 4 mois, avec moins de 4 points d'avance, après 1975, et
   au moins deux rivaux en vente. Délai de 3 ans entre deux défis.
2. Nora vient vous parler (bulle au QG et boîte « À faire ») : qui, quand, de combien. Quatre réponses,
   chiffrées avant le choix :
   - **Version boostée** : performance +8, efficacité −2 sur votre CPU couronné, coût unique ;
     gain au banc d'essai calculé avec la vraie formule ;
   - **Prix de combat** : −12 % sur vos CPU de ce marché, sans coût immédiat ;
   - **Campagne de presse** : notoriété +0,05 (s'estompe en quelques mois), prestige +0,5, coût unique ;
   - **Laisser venir** : gratuit.
   Sans réponse en 3 mois, Nora laisse venir, et le dit.
3. Six mois plus tard, le rival sort sa riposte : sa puce gagne exactement le nombre de points annoncé
   (il vise à vous dépasser d'environ 1,5 point, un peu plus s'il est riche et réputé).
4. Un an après : bilan. Titre défendu (prestige +0,5), ou perdu, en rappelant les autres
   couronnes que vous gardez. Historique conservé.

## Fichiers

- Nouveaux : `scripts/CpuPalmares.gd`, `scripts/CpuRivalry.gd`, `ui/components/PalmaresPanel.gd`,
  `tests/scenarios/PalmaresRivalryScenario.gd`, `tests/tools/capture_palmares.*`.
- Modifiés : `scripts/SimulationManager.gd` (appel mensuel), `scripts/Interactions.gd` (dialogue de
  Nora), `scripts/ExecutiveManager.gd` (boîte « À faire »), `main.gd` (ouverture du dialogue),
  `ui/screens/MarketScreen.gd` (panneau), `tests/smoke_test.gd`.
- Sauvegarde : l'état vit dans `CompanyManager.career` (déjà sauvegardé), avec valeurs par défaut :
  une ancienne partie se charge sans migration.

## Vérifié (réellement exécuté, Linux, Godot 4.7.2 headless)

- Scénario déterministe dans le smoke test :
  - trois entreprises différentes en tête de trois palmarès ;
  - pas de bascule pour 0,1 point, bascule pour un point net ;
  - pas de défi avant 4 mois de couronne ;
  - Nora et la boîte « À faire » présentent le défi, avec 4 réponses ;
  - sauvegarde/chargement au milieu de l'arc ;
  - les 4 réponses mènent à des issues différentes : version boostée → titre gardé, laisser venir →
    perdu, prix → prix baissés sans coût, campagne → notoriété ↑ et coût ;
  - le gain et le coût de la version boostée sont exactement ceux annoncés ;
  - réponse automatique au bout de 3 mois ; délai avant un nouveau défi.
- 38 scènes de test sur 38 réussies.
- Sonde (Standard, EN RETARD, graine 104729, 1971-2010) : couronnes qui changent de main (4 prises de
  couronne par catégorie pour le joueur), 4 défis déclenchés en 1979, 1985, 1989 et 1996, gagnés ou perdus.
- Sonde 24 carrières (4 graines × 3 stratégies × 2 modes, jusqu'en 2030), comparée à FIX-01 :
  - Standard : ADAPTÉE en faillite en 2016 (2015-2017 avant) ; EN RETARD 4/4 survivent avec 20 à 29 M€
    (8,7 à 20,7 M€ avant) ;
  - Accessible ADAPTÉE : 283 à 317 M€ (273 à 356 M€ avant) ; EN RETARD : 133 à 151 M€ (118 à 137 M€ avant).
  - Première version : le prestige à chaque reprise de couronne gonflait la trésorerie de fin de partie
    d'environ 60 % (vérifié en coupant ce prestige). Désormais : prestige +0,5 seulement à la première
    couronne de chaque catégorie, +0,5 pour un titre défendu, +0,5 pour la campagne. Effet mesuré : +6 à +10 %.
- Captures : `build/ui_review/PALMARES_marche.png`, `PALMARES_dialogue.png`.

## Limites et suite

- **Pas encore testé sur le Pixel.**
- Les quatre palmarès comparent tout le marché CPU, pas segment par segment.
- Le « leader des ventes » utilise le dernier mois (pas 12 mois glissants comme proposé dans SCENARIO-01).
- Un seul arc de défi pour l'instant. Suite logique (WORLD-02) : guerre des prix, rupture fournisseur,
  série de retours SAV, en réutilisant le même moteur (préavis → choix chiffrés → effets → bilan).
- Le classement « Empire » existant n'est pas modifié (décision réservée au propriétaire).
