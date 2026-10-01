# I5 — Analyse indépendante Astra

Base lue : `v010/I5-brief`, commit `6dbfdbc5f1f1f915f20672d5026c4cf4582ac2ab`.
Le diff du code entre cette base et `06930b3` est vide ; aucune autre analyse consultée.
Sources : **[C]** code inspecté ; **[T]** test/capture fourni, non rejoué ; **[S]** supposition de conception à valider.
Les valeurs [S] sont proposées, non mesurées.
Vérification réalisée : lecture du brief, du protocole, des captures et du code. Aucun test Godot ni essai téléphone exécuté.

## 1. Diagnostic — ce qui marche / ce qui coince

**À garder :** les étapes Fabriquer/Vendre/SAV, les générations et leurs modèles, les retours clients, la comparaison prévision/réel.
Les anciennes générations sont déjà repliées, et la sélection est conservée par identifiant : inutile de repartir de zéro [C : `ui/components/ProductLifecyclePanel.gd:323-343,395-443`].

**Novice :** la page présente un catalogue de commandes avant de répondre à « est-ce que mon CPU va bien ? ».
Les captures montrent une hiérarchie confuse et des textes sombres sur fond gris [T : `captures/vente_mois1_0.jpg` à `_3.jpg`].
Une commande visible semble être une tâche attendue, même quand elle est coûteuse ou prématurée.
**Expert :** le problème est la comparaison entre produits et l'absence de coûts/effets réunis avant décision, pas le nombre de systèmes.

**Faits qui changent la proposition :**
- L'offensive vérifie la solvabilité immédiate, sans réserve de trésorerie [C : `ui/components/ProductLifecyclePanel.gd:723-725`, `scripts/EconomyManager.gd:35-36`].
  Le conseil stratégique possède pourtant déjà un garde-fou : coût ≤ 25 % de la caisse [C : `scripts/MarketManager.gd:2472-2481`].
- La « contribution » omet les frais de distributeur, pourtant débités. Ne pas en faire le chiffre vedette sans correction comptable préalable [C : `scripts/ProductManager.gd:735-745,802-813`].
- La leçon conseille d'agrandir avant de vérifier une contribution négative : inverser cette priorité dans le futur diagnostic [C : `scripts/ProductManager.gd:857-864`].
- Capacité contradictoire : le champ utilise un pas de 10 avec minimum 1, puis reçoit la capacité exacte [C : `ui/components/ProductLifecyclePanel.gd:180,853-866`, `ui/UiKit.gd:156-161`].
  L'arrondi du contrôle est une cause plausible du 143 → 141 observé, **pas une cause reproduite** [T : `captures/vente_mois1_1.jpg`, `_2.jpg` ; S : diagnostic].
  Les contrôles reçoivent le même produit ; mélange de modèles non démontré [C : `ui/components/ProductLifecyclePanel.gd:574-602`].
  Le libellé « Réduire » de la capture diffère aussi du code lu : vérifier la provenance du binaire avant de conclure [C : `ui/components/ProductLifecyclePanel.gd:874-879`].
- Les 7 retours sur 143 ventes ne prouvent pas une crise [T : `captures/vente_mois1_1.jpg`].
  Le SAV combine retours, défauts et fiabilité ; un taux isolé ne suffit pas [C : `scripts/AfterSalesManager.gd:251-277`].

## 2. Proposition — principe

[S] Un cockpit qui donne d'abord un état, sa cause et la prochaine décision utile.
[S] Une carte Nora, 3 indicateurs, au plus 1 action principale ; « rien à modifier » est une réponse normale.
[S] Le critère « 2 actions maximum » vise les décisions recommandées, pas les onglets, filtres ou accès aux détails.
[S] Toutes les commandes restent accessibles dans « Gérer ce modèle » ; les déclencheurs règlent leur mise en avant.
[S] Un portefeuille compare les produits ; la fiche explique et prépare la décision, sans dépense automatique.

## 3. Maquette en texte

### Premier mois — cas calme [S : scénario]

- **Votre CPU est en vente.** Nora : « Les premiers retours sont encourageants. Laissez-le trouver son public. »
- **Ventes / contribution / satisfaction**, avec période et modèle.
- Aucun achat demandé ; poursuivre avec le contrôle de temps existant.
- Puis « Votre gamme », « Gérer ce modèle », « Détails et historique ».
- Avant tout mois terminé : « Premières ventes en cours », jamais des zéros présentés comme un échec.

### Premier mois — captures du brief [T pour les valeurs ; S pour l'agencement]

- **Nova — Essentiel : des clients repartent sans CPU.**
- **143 ventes/mois / contribution à fiabiliser / satisfaction 75,3 sur 100** [T : `captures/vente_mois1_1.jpg`].
- Nora : « La demande dépasse votre production. Regardons ce qu'il est possible de financer. »
- Bouton principal **Examiner la capacité**, sans paiement ; détail : **72 demandes non servies** [T : même capture].
- Devis : capacité actuelle → possible, débit réel, caisse restante, plafond.
- Devis dangereux : « Vous pouvez attendre ; la rupture peut faire partir des clients. »
- **Pas de “ne faites rien” automatique** : ce cas justifie un diagnostic.

### Douzième mois avec défaut [S : scénario, pas simulation]

- **Gamme Nova — un problème de fiabilité demande votre attention.**
- Indicateurs : ventes / contribution / retours rapportés aux ventes de la même période.
- Nora : « Le SAV a ouvert un dossier. Vérifions la cause avant de payer une modification. »
- Bouton principal **Ouvrir le dossier SAV**, ciblé sur le dossier et les modèles concernés.
- Dans le dossier : comparer remède terrain, firmware et révision selon le diagnostic.
- Expliquer que la révision concerne la fabrication future, sans présenter cela comme la réparation du parc vendu [C : `scripts/ProductManager.gd:317-327`].

### Fin de partie — vingt CPU [S : scénario]

- **Portefeuille** ; filtres « À examiner / En vente / Fin de série / Archives », recherche par nom ou génération.
- Synthèse : ventes totales / somme des contributions corrigées / modèles à examiner.
- Lignes : **gamme et modèle | ventes | contribution | signal principal** ; détails au toucher, sans grille horizontale sur téléphone.
- Alertes anciennes visibles malgré les replis ; ordre stable sous le doigt.
- Ligne → fiche courte ; retour → filtres et position conservés.
- Avec trois modèles, ce même portefeuille tient en liste compacte : pas de seconde interface à apprendre [S].

## 4. Tableau des déclencheurs

Les conditions ci-dessous concernent **le conseil visible**, jamais une interdiction supplémentaire.
[S] Devis avant dépense ; niveau financier DANGEREUX ou IMPOSSIBLE : examiner/reporter, sans bouton vert d'achat.
Le seuil DANGEREUX existant est inférieur à 3 mois de réserve structurelle ; ce n'est pas une prévision de faillite [C : `scripts/ExecutiveManager.gd:615-650`].

| Action | Condition mesurable de mise en avant | Message et destination |
|---|---|---|
| Capacité | Hausse : au moins 20 ventes perdues et 20 % de demande grand public perdue [C : seuil actuel, `scripts/ProductManager.gd:771-775`]. Vérifier marge et plafond du devis [C : `scripts/ProductManager.gd:531-560`]. Baisse : utilisation < 70 % pendant 2 mois et frais de réservation positifs [S]. | « Des clients repartent sans CPU : examinons la capacité. » Si plafond atteint : expliquer les locaux, pas proposer une hausse impossible. En baisse : « Une capacité réservée vous coûte sans être utilisée. » |
| Promotion | Aucune campagne active ; utilisation < 70 % sur 2 mois, satisfaction ≥ 60/100, contribution corrigée positive [S]. Pas de conseil publicitaire en rupture. | « Il reste de la place pour vendre davantage. Comparer une campagne. » Examiner prix et positionnement avant achat ; coût visible. |
| Révision matérielle | Dossier fabrication/thermique ouvert. Hors crise : économies unitaires remboursant la révision en ≤ 12 mois à ventes constantes, ou efficacité < 60/100 [S : seuils à calibrer]. | « Améliorer les prochaines séries » ; comparer fiabilité/coût/efficacité, coût total et contreparties. Aucun seuil universel de retours déclenchant un achat automatique. |
| Firmware / microcode | Dossier firmware/stabilité ou demande volontaire d'optimisation [S], ET logiciel ≥ 12 et architecture ≥ 24 [C : `scripts/ProductManager.gd:332-335`]. | « Un réglage logiciel peut aider ; comparer ses effets. » Prérequis manquants affichés dans le détail. Ne pas promettre qu'un firmware clôt le dossier SAV. |
| Attaquer un rival | Réutiliser `attack_advice()` : âge ≥ 2 mois, coût ≤ 25 % de caisse, ventes rivales ≥ max(2 × ventes du modèle, 200), temporisation respectée [C : `scripts/MarketManager.gd:2472-2498`]. Ajouter capacité disponible et devis prudent [S]. | « Un rival domine ce segment. Examiner une offensive. » C'est une occasion stratégique, pas une urgence ni une réaction obligatoire à une attaque. |
| Fin de vie | Appartenance à `retire_candidates()` : test booléen réutilisant âge, remplacement, ventes et contrats, avec protection de la dernière référence [C : `scripts/ProductManager.gd:987-1023`]. | « Cette ancienne référence pèse peu dans vos ventes. Comparer maintien, fin de série et retrait. » Afficher la cause retenue par le moteur. |
| Logiciel de contrôle | Génération avec produit lancé, logiciel non publié [S] ; logiciel ≥ 18 et intégration ≥ 24 [C : `scripts/ProductManager.gd:337-340`]. Après publication : mise à jour sur demande, pas relance mensuelle [S]. | « Un logiciel commun peut améliorer cette gamme. » Présenter tous les modèles concernés et le devis de génération [C : `scripts/ProductManager.gd:385-410`]. |

[S] Signaux SAV prioritaires, puis pertes/ruptures, puis occasions. Un conseil reporté reste consultable ; une aggravation le réactive.
[S] Mois clôturés uniquement ; historique absent = « à observer ».
[S] Réévaluer après action ; ne pas proposer comme neuf ce qui est déjà actif.

## 5. Ce qu'on replie, déplace ou retire

- **Replier** les jauges techniques, citations longues, prévision initiale et historique. Garder le signal utile au-dessus du repli.
- **Déplacer** les commandes dans « Gérer ce modèle », avec raccourcis depuis les conseils.
- **Prix :** visible dans la ligne ; réglage volontaire avec marge et effet estimé avant validation [S].
- **SAV :** lien vers son écran et son dossier existants.
- **Fin de vie :** section séparée ; confirmation avec conséquences et contrats.
- **Retirer de l'écran principal** commandes verrouillées, sélecteur redondant et chiffres en double.
- **Ne supprimer aucun système.** « Promotion de déstockage » et « fin de série avec retrait » sont distinctes dans le moteur ; les renommer clairement [C : `scripts/ProductManager.gd:252-272,931-951`].
- **Expert :** « Toutes les commandes » reste visible et accessible en un toucher depuis la fiche [S]. Options verrouillées expliquées en texte, pas uniquement au survol.
- **Nora :** explique et propose ; le joueur décide. Preuve et alternatives dans le détail.
- [S] Après la célébration, bilan regroupé ; actualités ordinaires dans le fil, urgence signalée sans recouvrir les contrôles.

## 6. Critères d'acceptation — à exécuter lors de l'implémentation

**Automatiques [S : objectifs, aucun résultat revendiqué]**
- État calme : aucune dépense conseillée, au plus 1 action principale ; tous les réglages restent accessibles.
- État de rupture : même identifiant produit et même période dans carte, devis et action ; conservation exacte d'une capacité de 143 après rafraîchissement [T : valeur des captures ; S : assertion].
- Tester juste sous, sur et au-dessus des seuils du tableau, sans ventes, sans historique et avec contrat professionnel.
- Le devis affiché égale le débit réel, selon la difficulté ; sa consultation ne débite rien.
- Contribution = revenus moins tous les coûts directement imputables, distributeurs inclus ; somme du portefeuille réconciliée avec ces postes, charges communes séparées.
- Une contribution négative empêche le conseil simpliste « produisez davantage » ; un plafond empêche une proposition irréalisable.
- Cas de caisse 20 303 € et offensive annoncée 20 000 € : aucun achat immédiat depuis la carte principale [T : `captures/vente_mois1_0.jpg`, `_2.jpg` ; S : comportement attendu].
- Avec 3 puis 20 modèles [S : jeux de test], une alerte ancienne reste trouvable ; changer de filtre ne change pas la cible d'une action ouverte.
- Recharger une sauvegarde sans préférences du cockpit ni historique complet : aucun crash, ni nouveau coût, ni produit perdu ; comportement prudent par défaut.
- Rafraîchir/réouvrir ne réinitialise ni temporisation ni sélection ; après dépense concurrente, revalider le devis avant exécution.
- Compléter les tests navigation et capacité, qui ne couvrent pas cette UX [T : `tests/scenarios/ProductCockpitScenario.gd:17-45`, `tests/scenarios/ProductionCapacityScenario.gd:17-47`].

**Téléphone et PC [S : protocole proposé]**
- Tester le paysage 1616 × 720 du brief [T : `BRIEF.md:13`] sur le téléphone réel, puis sur PC avec clavier/souris.
- Au premier affichage, état, indicateurs et action principale tiennent sans défilement ; aucun toast ne les recouvre.
- Un novice trouve quoi faire en ≤ 15 secondes et explique pourquoi ; dans le cas calme, il comprend qu'aucun achat n'est requis [S : cible exploratoire].
- Un expert ouvre prix, firmware et retrait en ≤ 2 touchers depuis la fiche, sans tutoriel imposé [S].
- Contrôles d'action ≥ 48 unités logiques, puis validation au doigt à l'échelle réelle [S : cible ergonomique, pas mesure actuelle].
- Tester défilement, noms longs, clavier virtuel, retour du SAV et ouverture d'une ancienne génération ; aucun débordement horizontal.
- Vérifier le contraste sur l'appareil : les captures seules ne permettent pas d'attribuer le fond gris au thème ou à un voile modal.
- Évaluer séparément compréhension novice, vitesse expert et plaisir.

## 7. Risques et parades

| Risque | Parade proposée [S] |
|---|---|
| Une action cachée devient introuvable | Accès permanent aux commandes ; signal portefeuille indépendant des replis. |
| Nora devient un pilote automatique | Expliquer les compromis ; proposer « Plus tard » ; aucune commande exécutée sans choix. |
| Simplification qui masque une vraie crise au lancement | Priorité au dossier SAV ou à la rupture, indépendamment de l'âge du produit. |
| Conseils qui oscillent ou se répètent | Mois clôturés, dédoublonnage par problème, report mémorisé et réactivation sur aggravation. |
| Conseil rentable en apparence, caisse vidée | Contribution corrigée ; montant réellement débité ; réserve après achat ; confirmation contextualisée. |
| Révision confondue avec réparation du parc | Séparer fabrication future et traitement du dossier SAV ; vérifier l'état du dossier après action. |
| Fausse précision du retour sur investissement | Afficher les hypothèses et l'incertitude ; ne pas présenter les ventes perdues comme ventes futures garanties. |
| Ancienne sauvegarde assimilée à un mauvais produit | Donnée absente explicitée ; champs UI optionnels et migration seulement si nécessaire. |
| Portefeuille trop chargé ou trop financier | Garder noms, visuels de gamme et mots simples ; contribution définie comme apport avant charges communes. |

**Ordre recommandé :** fiabiliser chiffres/devis et capacité ; poser la carte et les accès ; ajouter portefeuille et déclencheurs ; valider au doigt.
Cette étude ne corrige aucun de ces points : elle les identifie comme préalables ou critères du futur lot.

## 8. Questions que seul Alexandre peut trancher

- Valides-tu « laissez vendre » quand tout va bien, avec commandes toujours accessibles ?
- Nora doit-elle signaler une rupture dès le lancement ? Je recommande oui.
- Pour une dépense dangereuse mais payable, préfères-tu avertissement avec confirmation ou interdiction ? **Je recommande l'avertissement**, pour préserver la liberté.
- Veux-tu retrouver par défaut le portefeuille ou le dernier modèle consulté ? **Je recommande le portefeuille**, avec conservation du retour à la fiche.
