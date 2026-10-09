# Tech Empire — état constaté du projet

**Photographie : 10 octobre 2026**  
**Dépôt :** `vadorus/addonhardwaregame2d`  
**Branche examinée :** `v013/demo-octobre`  
**HEAD vérifié :** `c1d4f6e310c083dc26aef67bb0d4a9b94b8a178f` (fusion T3).  
**Moteur / version du projet :** Godot 4.7.2 / `0.12.2` d'après `project.godot`.  
**Portée de cette révision :** lecture du dépôt et de preuves existantes. **Aucun nouveau test Godot, build, APK ou essai physique Pixel n'a été exécuté** pour cette photographie.

## QA-00 — vérification réellement exécutée au même HEAD, 10/10/2026

[Rapport réel PC, économie et narration](reviews/RETOUR_2026-10-10_QA00.md) : 12 commandes Godot terminent code 0 ; re-import propre après avertissement UID initial, smoke/budget second CPU/parcours CPU/Software PASS ; scénario cible tactile PASS mais **fuites moteur à la fermeture**. Graîne 104729 : STANDARD ADAPTEE/EN_RETARD faillite 02/1973 ; ACCESSIBLE ADAPTEE 225 M€ ; aucune première place dans la **colonne rang Empire**. Articles gabarits : 100 essais homogènes, 9 corps distincts, 91 répétés après neutralisation des noms. Capture QG PC réussie ; sept onglets **non validés**. **Aucun essai Pixel actuel.**

Cette mise à jour complète mais n'efface pas la photographie statique antérieure.

## CAREER-01 — mesure multi-graines au même HEAD

[Résultats réels de 24 trajectoires](reviews/RETOUR_2026-10-10_CAREER01_4SEEDS.md) : 4 graines, 2 modes, 3 stratégies. STANDARD : **12/12 faillites**. ACCESSIBLE : **9/12 survies** ; ADAPTÉE finit à **190,7–225,2 M€**. Classement mesuré = **Empire**, pas CPU sectoriel. Causes à diagnostiquer avant de changer l'économie. [Issue #84](https://github.com/vadorus/addonhardwaregame2d/issues/84).

## Tableau de statut

| Domaine | Constat au HEAD | Niveau de preuve | Suite |
| --- | --- | --- | --- |
| Simulation CPU | Code et scénarios de parcours présents | Code + rapports de tests antérieurs, non rejoués ici | Rejouer la batterie ciblée au HEAD |
| Logiciel | Gestionnaires, activités et parcours présents ; maturité UX à confirmer | Code / retours antérieurs | Vérifier clarté et effet réel des décisions |
| Sauvegardes | `SaveManager.gd` gère versionnement, migration et écritures de protection | Inspection antérieure du code | Tester ancien format et copie isolée, ne jamais sacrifier la partie personnelle |
| T2 zones tactiles | Fonctionnalités présentes dans la démo | Code + rapport PC/Pixel du 09/10 | Continuer revue au doigt des écrans tardifs |
| T3 infobulles | **Fusionné** dans le HEAD `c1d4f6e` | Historique Git + rapport T3 | Complément perte de focus testé PC, **pas retesté sur Pixel** ; couverture exhaustive des boutons non démontrée |
| Performances | Outil P0 et optimisations récents dans le dépôt | Preuves Pixel datées (08–09/10), pas mesure au HEAD | Mesure comparable sur copie de référence |
| Interface / graphismes | Plusieurs scènes modernisées, mais encore des écrans à formulaires/listes | Inspection du code ; appréciation visuelle à refaire | Captures réelles des sept onglets + comparaison de références |
| Variété presse / employés | Règles et dictionnaires de formulations ; génération encore largement à gabarits | Inspection `scripts/MediaManager.gd` et fichiers de présentation | Auditer répétitions et contradictions, tester avant modification |
| Boutique / DLC | Carte des branches futures / version complète | `CompanyBranches.gd`, `BranchMap.gd` | **Aucune boutique ou facturation confirmée** ; ne pas présenter les offres comme commercialisables |
| Audio | `default_bus_layout.tres` et contrôle audio présents | Code actuel ; ancien audit audio dépassé sur le point « sans bus » | Revalider écoute sur appareil |
| Publication commerciale | Préparatifs dans la documentation, sans livraison confirmée par cette revue | Documents | Pas de publication / commande Play Store sans autorisation |

## Distinction des validations

- **Présent dans le code** : ne signifie ni test PC, ni test Pixel, ni plaisir de jeu.
- **PASS historique** : résultat valable pour le commit, le scénario et le matériel consignés dans le rapport.
- **Validé sur Pixel** : requiert le commit / APK, la sauvegarde testée et des résultats réels.
- **Proposé** : ne doit jamais apparaître comme fonction existante dans les fiches de jeu.

## Preuves importantes, avec portée

- [P0 Pixel, référence douze mois](reviews/P0_PIXEL_REFERENCE12_COMPLET_2026-10-08.md) : 36/36 fins de mois réalisées **sur un ancien APK témoin** ; les lenteurs Entreprise/Produits ont déclenché des diagnostics. Pas un benchmark du HEAD.
- [Validation T2 et autres lots](reviews/T2_PIXEL_C2_R1_A1_2026-10-09.md) : résultats réels avec limites de couverture.
- [Contrôles T3 sur Pixel](reviews/T3_PIXEL_ACTIONS_2026-10-09.md) : six actions testées ; complément focus uniquement sur PC et fusion confirmée séparément par Git.
- [Audit de game design](AUDIT_GAME_DESIGN_2026-10-08.md) : photographie historique des difficultés économiques et de la répétitivité de décisions, à relancer après modifications.
- [Plan actif déclaré](PLAN_CODEX_2026-10-08.md) : peut citer des étapes désormais intégrées ; ne pas réexécuter aveuglément.

## Risques / points ouverts

1. Tests de régression et performances **au HEAD actuel** à mesurer avant nouvelle conclusion quantitative.
2. Comparaison visuelle à actualiser par captures réelles, lisibilité des derniers onglets non jugée ici.
3. Répétitivité **ludique et narrative** : distinguer manque de décisions et variété artificielle des phrases.
4. Architecture future DLC / droits d'accès : encore proposition ; préserver la compatibilité des sauvegardes.
5. Certaines feuilles de route anciennes et le README historique contiennent des états obsolètes : voir [INDEX.md](INDEX.md).

**Mise à jour obligatoire :** changer cette fiche seulement après vérification d'un nouveau HEAD et lier les preuves ; l'ancienne conclusion ne devient jamais automatiquement vraie pour une nouvelle version.

