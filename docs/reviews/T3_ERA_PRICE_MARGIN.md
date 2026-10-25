# T-3 — Prix d'époque et marge par puce (issue #116)

**Auteur :** Codex · **Relecteur :** Claude · **Base :** `v013/demo-octobre` @ `e22096571559d513ced1e70475ae51a1b18aaa14` · **Branche :** `codex/t116-era-price-margin-20261025`.

## Périmètre exécuté

- `scripts/MarketManager.gd` : `era_price_factor(year)` = 1 avant 1986, +0,015 par an à partir de 1986, plafonné à 1,35 (plafond atteint en 2009) ; `segment_reference_price_base` (non daté) ; référence de marché datée, année explicite optionnelle.
- `scripts/CpuProductLine.gd` : `market_entry_unit_cost` utilise désormais la **base non datée**, en conservant la rampe propre D2 de 1971 à 1981.
- `scripts/ProductManager.gd` : `unit_margin(product)`, décomposition prix/distributeurs/fabrication (silicium × tension × expérience + entrée) ; utilisée aussi par `_sell_product_month` en préservant l'ordre et l'arrondi de production historiques ; `recommended_unit_price` cible 35 % de marge, dans la fourchette [0,8 ; 1,6] × référence et au pas de 5 ; compteur et alerte après deux mois consécutifs de **ventes boutique** à marge négative ; réarmement après récupération.
- `ui/components/ProductLifecyclePanel.gd` : affichage explicite et coloré de la marge, exclusion de SAV/capacité/B2B/royalties ; conseil de prix **non appliqué** ; fiche du modèle et carte de lancement utilisent la fonction commune et n'affichent plus le plancher de 5 €.
- Scénarios `MarketEntryCostScenario`, `MarketEconomyGuardScenario`, `PriceElasticityScenario` : tests des bornes et prix datés, coût D2 indépendant de l'époque, marge, conseil et anti-répétition des alertes.

## Appelants de segment_reference_price : décision

Toutes les références de **marché** gardent le mode **avec époque** : `MarketManager.gd` L735/762/777/1068/1205/1296/1651/1869/1941 (lignes à la base), `ProductManager.gd` L118, `CpuPalmares.gd` L62, `MarketVoices.gd` L46, `Subsidiaries.gd` L72, panneau L831. Tous les tests/outils existants restent avec époque, à l'exception du calcul attendu du coût d'entrée dans `MarketEntryCostScenario.gd`. Le **seul calcul métier BASE** est `CpuProductLine.market_entry_unit_cost`.

## net_margin_per_unit : comportement antérieur conservé

La fonction historique `ProductManager.net_margin_per_unit` force une marge minimale de 5 € et est appelée directement par `ProductManager.capacity_change_quote` pour tarifer une extension de capacité. La modifier modifierait le coût des extensions, y compris avant 1986 : **elle reste inchangée**. `ProductLifecyclePanel.launch_card_data` utilisait cette fonction pour afficher la marge : il utilise maintenant `unit_margin` sans modifier les ventes. Inventaire des appelants confirmé dans les fichiers audités ; recherche de code GitHub incomplète pour l'exhaustivité des autres fichiers.

## Compatibilité et limites métier

- Les prix persistés des produits déjà lancés ne sont pas réécrits. La création de **nouvelles** gammes utilise la référence datée via `build_range`. Pas de migration de sauvegarde.
- Le prix conseillé à 35 % n'est **jamais appliqué** automatiquement.
- La marge par puce couvre la vente **boutique** : exclut frais fixes de réservation de capacité, SAV, redevances et revenus spécifiques des contrats B2B. Le revenu et les frais mensuels B2B restent ceux de la simulation.
- `ProductManager._sell_product_month` conserve le **même ordre de multiplication et arrondi mensuel** des coûts de production. La nouvelle alerte n'affecte pas directement trésorerie, demande ou coûts.
- Aucun changement à `main.gd`, sonde C3, workflows, coûts salariaux, SAV ou mécanisme B (maturité du procédé).

## Relecture Claude du 25 octobre 2026 : calibrage corrigé

- Relecture de la PR #117 au SHA `90cc661` : **code validé**, mais barème initial **0,035/an, plafond 2,00 refusé** après campagne C3 complète (48 simulations, 4 graines × 2 modes × 3 stratégies × 2 versions), Godot 4.7.2, zéro erreur moteur ; CSV **1971–1985 identiques 24/24**.
- Barème initial : STANDARD FIGÉE survivait 4/4 et ADAPTÉE terminait avec ~1,6–1,8 Md€ en 2030, ce qui supprimait le risque.
- Essais ciblés de Claude (STANDARD, graines `104729` et `313133`) : avec **0,015/an, plafond 1,35**, FIGÉE **fait faillite en 2026 (2/2)**, ADAPTÉE atteint **0,46–0,51 Md€**, EN RETARD **0,18–0,20 Md€** et marge nette annuelle ADAPTÉE **+8 à +19 %** sur 1995–2030.
- **Décision de calibrage** : 1,00 jusqu'en 1985, puis +0,015/an à compter de 1986 ; repères 1986 ×1,015, 1995 ×1,15, 2005 ×1,30, 2008 ×1,345, 2009 et après ×1,35.
- **Attention** : ces résultats sont les observations de Claude sur la version initiale et ses **deux essais de calibrage**. La campagne complète de la **nouvelle version** n'a pas encore été relancée ; ne pas extrapoler un verdict 4/4.

## Validation obligatoire : état réel

La campagne et les tests Godot n'ont **pas été exécutés localement par Codex** dans cet environnement. La campagne initiale et les essais ciblés ci-dessus ont été exécutés par Claude ; la vérification de la variante recalibrée reste **à faire par Alexandre**. Les captures d'interface ne sont **pas** disponibles ; les trois cas demandés restent à contrôler sur une copie isolée (vert ≥ 15 %, orange 0 à < 15 %, rouge < 0 %).

### Campagne C3 — non encore exécutée / résultats attendus

**Sonde inchangée :** `tests/tools/career_probe.tscn`. Graines officielles : `104729,208877,313133,417401`. Pour **chacune** des branches base et T-3 :

```powershell
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . res://tests/smoke_test.tscn
godot --headless --path . res://tests/tools/career_probe.tscn -- 104729,208877,313133,417401 STANDARD
godot --headless --path . res://tests/tools/career_probe.tscn -- 104729,208877,313133,417401 ACCESSIBLE
```

Exécuter dans **deux copies isolées** (base `e220965` et tête T-3), chacune avec `user://` séparé ; copier les CSV et logs hors de `build/` avant comparaison. **24 runs par branche**, soit **48 au total**, trois stratégies `FIGEE`, `ADAPTEE`, `EN_RETARD`.

| Contrôle requis | État | Résultat |
| --- | --- | --- |
| STANDARD / ADAPTEE : survie 2030 ≥ 3/4 | NON EXÉCUTÉ | à renseigner |
| Marge nette annuelle ADAPTEE après 2000 : 5–25 % (nouveau seuil Claude) | CAMPAGNE COMPLÈTE À RELANCER | essai 2 graines : 8–19 % sur 1995–2030 |
| ACCESSIBLE / STANDARD cash 2030 ≤ ×3, même graine et stratégie | NON EXÉCUTÉ | à renseigner |
| CSV identiques 1971–1985 entre base et T-3 (même graine) | VALIDÉ sur SHA initial ; à reconfirmer | Claude : 24/24 sur `e220965` vs `90cc661` ; aucun changement attendu avec nouveau facteur avant 1986 |
| FIGEE peut encore échouer, pas de suppression artificielle du risque | VALIDATION PARTIELLE, À CONFIRMER | Claude : faillite 2026 sur 2/2 graines STANDARD au nouveau barème |
| Valorisation des filiales 2010, écart ACCESSIBLE/STANDARD avant et après | NON EXÉCUTÉ | à renseigner |
| CI Godot (35 scènes), parse/import/smoke | À VÉRIFIER SUR NOUVEAU SHA | CI initiale distincte du recalibrage ; résultat à joindre |
| Captures de la même interface en vert/orange/rouge | NON PRODUITES | à joindre |

**Attention à l'historique :** `docs/reviews/RETOUR_2026-10-10_CAREER01_4SEEDS.md` relève 12/12 faillites STANDARD sur un ancien SHA et 9/12 survies ACCESSIBLE. Ces données historiques ne doivent **pas** être présentées comme une campagne avant/après T-3 sur `e220965`.

## Décision d'intégration

**PR brouillon et nouvelle relecture Claude obligatoires** après la campagne complète du coefficient révisé, aucune fusion ni publication sans autorisation distincte d'Alexandre. Les critères de carrière sur quatre graines et les trois captures ne sont pas validés à ce stade.
