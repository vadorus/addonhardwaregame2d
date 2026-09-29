# Lot F2 — Filiales (29-30/09, Claude)

Deuxième étape du lot F. Avant : « Créer une filiale » (Entreprise › Groupe) prenait le capital sans aucun
effet, et une société rachetée au lot F1 disparaissait du jeu.

## Ce qui change

Règles dans `scripts/Subsidiaries.gd` ; état dans `CompanyManager.subsidiaries` (déjà sauvegardé).

- **Une société rachetée devient une filiale** : elle garde son chiffre d'affaires et son marché.
  Une partie de son savoir-faire rejoint toujours la R&D (lot F1).
- **Mandat choisi par le joueur** (un clic sur la fiche) :
  - *Verser des dividendes* (défaut pour un rachat) : 80 % du bénéfice remonte chaque mois ;
    sans investissement, la filiale perd 0,4 % de potentiel par mois ;
  - *Grandir* (défaut pour une création) : tout est réinvesti, pas de dividendes ;
  - *Intégrer au groupe* : 12 mois, ses clients passent chez le joueur (+25 % de demande sur son
    marché pendant 24 mois), puis elle rejoint la marque (+prestige). Irréversible.
- **Injecter du capital** (bouton, ≈ 6 mois de CA) et **revendre** (90 % de sa valeur, confirmation).
- **Vie propre** : son directeur demande des fonds (carte FILIALE dans À faire, 3 mois pour répondre),
  gros contrat, client perdu (brèves presse).
- **Créer une filiale** fonctionne vraiment : capital → potentiel, démarrage petit, pertes pendant
  2 ans de montée en charge. Capital du formulaire relevé de 5 M€ à 500 M€ maximum.
- **Anciennes sauvegardes** : l'ébauche `{name, sector, capital, reputation}` devient une filiale
  « Grandir » déjà sortie de sa montée en charge.
- Écran : Entreprise › Groupe affiche une fiche par filiale (CA, résultat, valeur, dividendes versés,
  capital investi, mandat, boutons). Les cartes RACHAT et FILIALE ouvrent cette page.

## Équilibrage (sonde de campagne)

Premier réglage : 11 filiales à 339 M€ de CA par mois en 2030 et 2,3 Md€ de trésorerie. Financer un
directeur se remboursait en 2,5 ans et rien ne bornait une filiale. Corrigé :

- une filiale ne dépasse pas **25 % de son marché** ; plus elle s'en approche, moins un euro investi la
  fait grandir (minimum 5 %), et si le marché décline elle décline avec lui ;
- projet de directeur : 6 mois de CA, compte 1,5 fois une injection ordinaire ;
- marge nette : 15 % (rachat), 14 % (création).

Sonde 1971-2030 après réglage (sonde qui rachète quand elle peut et finance les directeurs si elle a
3 fois la somme) :

| | Avant F2 (F1 seul) | F2 |
|---|---|---|
| Rachats | 7 (185 M€) | 9 (542 M€) |
| Capital injecté dans les filiales | — | 501 M€ |
| Dividendes reçus sur la partie | — | 901 M€ |
| Filiales en 2030 | — | 9, 46 M€ de CA par mois |
| Trésorerie du joueur 2010 → 2030 | 68 → 201 M€ | 49 → 252 M€ |

L'argent a désormais deux usages de fin de partie (rachats, capital des filiales) sans devenir une
machine à multiplier l'argent.

## Tests

- `tests/scenarios/SubsidiariesScenario.gd` (smoke test) : création (capital payé, refus des cas
  invalides, pertes de démarrage, croissance sur 3 ans), dividendes, érosion, injection et plafond de
  marché, demande du directeur dans À faire, rachat → filiale, intégration (clients puis disparition,
  irréversible), revente, sauvegarde, migration de l'ancienne ébauche.
- `RivalLifeScenario` mis à jour : un rachat crée une filiale.
- Capture PC (1212×540) de la page Groupe vérifiée : fiches lisibles, boutons qui passent à la ligne.

## Reste à faire

- F3 : nouveaux marchés (défense / aérospatial, GPU / RAM / PC) — les filiales créées y trouveront leur
  place (aujourd'hui seul le secteur CPU est actif).
- Test réel sur le Pixel 10 de la page Groupe.
