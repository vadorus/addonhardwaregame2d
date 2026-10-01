# Analyse indépendante — Astra — monétisation de Tech Empire
Date de consultation : 01/10/2026. Base : `v010/monet-brief`, commit `af03ff50bc34d307da1de6fdd3c2d270c2cc214c`.
Aucune autre analyse ni synthèse consultée. Aucun code modifié. Les neuf questions du brief sont traitées malgré la coquille du protocole.

## Recommandation en cinq lignes
Vendre le jeu CPU complet par achat initial, sans publicité ni boutique intégrée au lancement.
Tester un prix public de 4,99 € sur Android et l’équivalent local sur PC : hypothèse commerciale, pas prévision de ventes.
Inclure les saisons, fêtes, trophées et améliorations de confort ; ne jamais vendre une meilleure économie ou progression.
Proposer le PC sur itch.io après validation Android ; réserver Steam et les thèmes décoratifs additionnels à une étape ultérieure.
Faire valider la fin CPU, les sauvegardes, la lisibilité tactile et le parcours Play avant toute promesse de date ou de DLC.

## Méthode et faits vérifiés
**Observation** signifie lecture du code ou d’une source officielle ; **H** désigne une hypothèse ou proposition d’Astra à valider.
Le brief fixe les contraintes produit ; il ne constitue pas une mesure de qualité, de durée de jeu ou de demande commerciale.
- Export actuel vers un APK debug : `export_presets.cfg:76` ; Gradle désactivé : `:89` ; paquet signé déclaré : `:92`.
- Cela ne prouve ni une signature de production sûre, ni la conformité du binaire, ni son SDK cible ; aucun export réalisé pour cette étude.
- Sauvegarde locale JSON avec temporaire et secours : `scripts/SaveManager.gd:6-8,62,200` ; traitement de version : `:86,216`.
- Gratuité du lot graphique saisons/fêtes explicitement prévue : `docs/BRIEF_ASTRA_LOT3_SAISONS_FETES.md:10`.
- La taille « 34 Mo » et la jouabilité annoncée ne sont pas remesurées ; aucune projection économique ne s’appuie dessus.
- Moteur cible Godot 4.7.2 : `AGENTS.md:14`, consigne du dépôt, pas vérification du moteur installé.
- Aucun test du jeu, achat réel, ni accès à Play Console : compatibilité, état du compte et réception commerciale restent à vérifier.

## 1. Modèle : priorité à l’achat initial
| Option | Intérêt pour Tech Empire | Coût ou difficulté | Avis |
|---|---|---|---|
| Jeu gratuit, cosmétiques payants | Essai facile ; progression accessible | Recette dépendante d’acheteurs de décoration ; catalogue, achats et support à maintenir | Fragile sans audience connue |
| Achat initial | Promesse simple, expérience autonome ; aucun flux d’achat à coder dans le jeu de base | Barrière à l’essai ; fiche et qualité doivent convaincre | Recommandé |
| Démo puis déblocage intégré | Le joueur juge avant d’acheter ; revenu lié au jeu | Paiement, restauration, coupure de démo, migration et cas réseau | Bonne alternative si l’essai est indispensable |
| Jeu payant puis cosmétiques | Finance le jeu et laisse soutenir le projet | Risque d’impression de double paiement ; dette technique de boutique | À différer |
Une démo séparée permettrait d’essayer sans intégrer Billing, mais ajoute une fiche, des builds et un transfert de sauvegarde : je ne la rendrais pas obligatoire au lancement.
Si Alexandre choisit la démo intégrée : arrêter après un jalon naturel CPU, clairement annoncé avant le début ; durée à déterminer par tests, sans minuterie ni partie supprimée.
Le jeu complet doit rester complet à son achat : aucune fonction de confort, difficulté, sauvegarde ou mode libre vendue séparément.
L’absence de données de conversion interdit de déduire une rentabilité des téléchargements des concurrents ; même leur modèle ne prouve pas ce qui vendra ici.

## 2. Prix et comparables
Relevés des vitrines officielles le jour de consultation ; marchés/devises différents, sans conversion artificielle vers l’euro.
| Comparable | Observation | Limite |
|---|---|---|
| Game Dev Tycoon Android [S1] | 4,99 USD ; achat initial ; éditeur annonce absence de pubs et d’achats intégrés | Jeu établi ; ne justifie pas une promesse de ventes |
| PC Tycoon 2 [S2] | Gratuit, pubs et achats intégrés ; Pro affiché à 5,99 USD dans la rubrique du même éditeur | Page Pro directe instable ; prix français et contenu Pro non certifiés |
| Laptop Tycoon Steam [S3] | Achat à 8,99 CHF sur la page servie | Marché PC, devise et produit différents |
Les notes vues sont 4,8 pour Game Dev Tycoon [S1] et 3,8 pour PC Tycoon 2 [S2], contre 4,9 et 3,9 dans le brief : ne pas figer ces valeurs variables.
La mention « pubs récompensées optionnelles » de PC Tycoon 2 apparaît dans un avis utilisateur [S2], pas comme engagement vérifié de l’éditeur ; seule la présence de pubs est certaine ici.
**H prix :** fourchette Android de 3,99 à 6,99 € ; point de départ 4,99 €, à confronter aux retours sur le jeu complet et au tarif français des comparables.
**H PC :** même positionnement et valeur de contenu ; sur itch.io Payouts, prix de travail 4,99 USD, puisque ce mode facture en USD [S11] ; prix final local à contrôler avant ouverture.
Ce choix privilégie une promesse abordable, pas une valorisation du temps passé ni une prévision financière. Aucun taux de conversion ou revenu attendu n’est établi.
Chiffrer les recettes nettes seulement après vérification du contrat distributeur, frais, taxes, remboursements et statut d’Alexandre ; le prix public n’est pas son revenu.

## 3. Contenus : un socle généreux, des décors facultatifs
« Inclus » signifie sans supplément pour tout propriétaire du jeu ; ce modèle ne propose pas le jeu complet gratuitement aux non-acheteurs.
Les tarifs et charges ci-dessous sont des **H**, en jours de travail concentré avec retours et intégration ; pas des délais calendaires ni des mesures de productivité IA.
| Contenu | Gratuit/inclus ou payant | Prix envisagé (H) | Travail Astra (H) | Travail Claude (H) |
|---|---|---|---|---|
| Jeu CPU complet, fin explicite, mode libre et difficultés | Achat initial | 4,99 € Android | QA visuelle et fiche : 2–4 j | Préparation publication : 4–8 j, hors finition du jeu |
| Saisons/fêtes du lot graphique, vitrine et trophées gagnés | Inclus ; jamais revente du lot gratuit | Aucun supplément | Finition du lot existant, à replanifier séparément | Intégration/QA déjà nécessaires au jeu, hors chiffrage commercial |
| Corrections, migrations, accessibilité et confort | Inclus | Aucun supplément | Selon défauts | Maintenance selon défauts |
| Thème « atelier boisé » : murs, sol, mobilier visuel, ambiance | Payant plus tard seulement | 2,99 € | 3–6 j par thème couvrant les locaux | 1–3 j d’intégration par thème, après socle achats |
| Thème « néon rétro » ; variantes de boîtes CPU purement visuelles | Payant plus tard seulement | 2,99 € le pack | 3–6 j par pack | 1–3 j après socle achats |
| Palette de tenues et accessoires d’équipe | Inclus dans un futur pack, pas microvente à l’unité | Dans le pack | 1–3 j additionnels | 1–2 j additionnels |
| GPU/RAM : campagne autonome avec nouvelles décisions | DLC éventuel, après validation CPU et décision explicite | Non fixé : périmètre inconnu | À chiffrer sur brief validé | Recherche, équilibrage, sauvegardes et QA à chiffrer |
Pas de monnaie premium, de rareté artificielle, de lot aléatoire, d’exclusivité temporaire ni de calendrier commercial.
Un thème doit fonctionner avec les évolutions des locaux et conserver la lisibilité des employés, objets et interfaces ; ce coût dépasse celui d’une jolie image isolée.
Ne pas vendre des trophées qui simulent une réussite : vendre éventuellement leur présentoir, jamais le succès.
Un DLC GPU/RAM ajouté à la même économie peut procurer de meilleurs revenus : cela contredit potentiellement « aucun avantage ».
Donc pas de composants plus rentables réservés aux acheteurs dans la campagne CPU ; préférer une campagne distincte, ou rendre la mécanique commune gratuite et ne vendre que son habillage.
Ne pas annoncer de DLC nécessaire pour atteindre une vraie fin ; le contenu déjà annoncé comme faisant partie du jeu doit être livré dans le socle.

## 4. Publicité
Non. Les interruptions détériorent la chaleur recherchée ; les récompenses économiques contrediraient l’absence d’avantage.
Même une pub pour obtenir un décor ajoute SDK, déclaration de données, disponibilité réseau et support, sans revenu prouvé.
La fiche peut mettre en avant « sans publicité » seulement si cette promesse reste vraie ; éviter de la reprendre ultérieurement sans nouvelle décision produit.

## 5. PC, droits d’achat et sauvegardes
Choix proposé : itch.io pour la première diffusion PC, après stabilisation Android ; Steam lorsque la présentation et la disponibilité d’Alexandre permettent un lancement dédié.
itch.io offre une distribution simple ; son mode « Collected by itch.io » prend le rôle de vendeur contractuel et gère la TVA annoncée par la plateforme [S11], sans supprimer les obligations personnelles d’Alexandre.
Steam offre une audience à rechercher, pas une visibilité garantie ; frais Steam Direct de 100 USD par produit [S12], en plus du travail de fiche et de validation.
Même jeu signifie mêmes règles, contenu et mises à jour ; cela ne crée pas automatiquement une licence commune Google/itch/Steam.
Proposition initiale : achats propres à chaque boutique, annoncés avant l’achat ; aucune connexion Tech Empire ou synchronisation automatique obligatoire.
Un achat Google ne restaure pas à lui seul un achat Steam. Le partage universel exigerait un service d’identité/droits ou un support manuel durable : je ne le recommande pas au lancement.
La restauration de l’application par la boutique et la récupération d’une sauvegarde locale sont deux sujets distincts.
Prévoir export/import de sauvegarde seulement après validation des schémas et des écrans Android ; si non livré, dire clairement que changer d’appareil peut perdre la partie.
Ne pas inviter depuis l’application Play à contourner son paiement ; les programmes d’alternative dépendent des pays et d’inscriptions spécifiques [S6].

## 6. Technique, charge et risques
**Chemin recommandé sans achats intégrés :** achat initial géré par la boutique, jeu sans permission Billing ; pas de plugin nécessaire pour encaisser le prix d’installation.
Préparer un AAB signé de publication, Play App Signing, clés d’envoi conservées hors dépôt et sauvegardées ; distinguer clé d’envoi et clé de signature de l’application [S7].
L’export APK actuel ne prouve pas que la chaîne AAB est prête : vérifier le manifeste produit, le SDK cible, les bibliothèques natives et les exigences de la Console.
Ne pas ajouter de serveur ni de contrôle anti-piratage bloquant le jeu hors ligne ; accepter une protection limitée.
**Si déblocage ou cosmétiques retenus ultérieurement :** produits non consommables, prix localisés reçus du store, écran d’achat explicite et bouton de restauration.
Isoler les droits du contenu des paramètres de simulation ; un thème ne modifie aucun coefficient économique.
Godot exige Gradle pour son plugin [S8] ; épingler une release, vérifier sa dépendance Billing réelle et tester l’AAB distribué par Play, pas seulement un APK local.
La date limite de Billing 7 est le 31/08/2026 ; viser une version encore acceptée, au moins Billing 8 sans dérogation [S9] ; ne pas supposer que le dernier plugin suffit.
Accorder le droit uniquement après achat confirmé, gérer attente, annulation, erreur et interruption ; traiter les callbacks de façon idempotente.
Interroger les achats au retour au premier plan et lors d’une restauration ; acquitter le non-consommable sans le consommer, avant le délai de 3 jours [S10].
Conserver localement le droit confirmé pour jouer hors ligne ; première acquisition et restauration après réinstallation nécessitent normalement le store et une connexion.
Une erreur réseau ne doit jamais effacer un droit connu ni la partie ; traiter une révocation confirmée sans détruire la sauvegarde, avec retour au décor inclus.
Google recommande une vérification sur serveur [S10] ; sans serveur, le cache local et le client restent falsifiables, et les remboursements hors ligne ne sont pas détectés immédiatement.
Accepter cette limite pour ce jeu solo ou renoncer aux achats intégrés ; ne pas présenter le JSON local comme une preuve d’achat sécurisée.
**H charge supplémentaire achats intégrés :** Claude 8–15 j pour plugin, droits, boutique/restauration et matrice de tests ; Astra 1–2 j pour écrans et états visuels, hors packs.
**H charge socle publication :** Claude 4–8 j et Astra 2–4 j, déjà comptés au tableau ; démo éventuelle : Claude 3–5 j additionnels pour coupure/transfert/QA.
Ces enveloppes excluent dette actuelle du jeu, juridique, recrutement, délais Google et incidents outils ; aucune date fiable sans essai technique de compilation.
Matrice à exécuter après décision : installation, mise à jour, sauvegarde ancienne, réinstallation, appareil hors ligne, changement de compte ; si Billing, ajouter paiement interrompu/en attente, restauration et remboursement.

## 7. Chemin jusqu’à la publication
A. Alexandre valide modèle, périmètre CPU vendu, public visé, pays, support et identité du vendeur ; vérifier type/date du compte développeur et exigences affichées.
B. Terminer la boucle CPU : tutoriel novice, lecture des décisions, équilibre, vrais objectifs, annonce de fin et mode libre ; finir les éléments gratuits promis.
C. Vérifier tactile, tailles d’écran, performance, reprise après interruption, sauvegarde et migration ; définir des critères de sortie et traiter les défauts bloquants.
D. Préparer la chaîne de publication : identifiant définitif, version, AAB release, clés hors Git, Play App Signing et installation via piste interne [S7].
E. Cibler Android 16/API 36 pour une nouvelle application aujourd’hui [S4] ; vérifier l’AAB accepté et les autres alertes natives de la Console, sans confondre SDK cible et Android minimal.
F. Préparer fiche honnête, captures du vrai jeu, icône/bannière conformes à la Console, support, classification, public cible, déclaration publicité et prix.
G. Publier une politique de confidentialité accessible et renseigner Sécurité des données d’après l’application et ses dépendances, même sans collecte déclarée [S13].
H. Pour un compte personnel créé après le 13/11/2023 : au moins 12 testeurs inscrits sans interruption durant 14 jours avant demande d’accès production [S5].
I. Recueillir leurs retours réels sur apprentissage, valeur perçue, fin et bugs ; corriger puis refaire les scénarios touchés. Les inscriptions seules ne démontrent pas la qualité.
J. Demander l’accès production et soumettre le jeu ; les 14 jours [S5] ne sont ni une autorisation automatique ni un délai total garanti.
K. Publier quand le jeu et le support sont prêts, surveiller incidents et avis ; ouvrir ensuite le PC avec le même socle. Version « 1.0 » = jalon proposé, pas preuve de maturité.
L. Décider d’un éventuel pack seulement après retours et estimation de charge ; ne pas engager une cadence d’événements.

## 8. Risques et parades
| Risque | Parade proposée |
|---|---|
| « Trop court pour un jeu payant » | Annoncer périmètre CPU et fin ; faire terminer le jeu à des testeurs, sans inventer une durée |
| « On me revend les saisons » | Sanctuariser le lot gratuit ; seuls nouveaux thèmes identifiés et prévisualisables peuvent être payants |
| Perte de partie ou d’achat | Migrations testées, secours local, communication claire sauvegarde/restauration ; ne pas mêler leurs données |
| Piratage | Accepter une protection modeste ; consacrer le temps à la qualité et au support plutôt qu’à punir les utilisateurs hors ligne |
| Casse Gradle/plugin ou règle Play | Versionner la configuration non secrète, épingler les dépendances, refaire un test de distribution après mise à jour |
| Charge permanente pour Alexandre | Pas de publicité, compte maison, abonnement ou calendrier de cosmétiques ; support accessible et périmètre public limité |
| Double achat mal compris | Expliquer les droits par plateforme ; ne promettre ni cross-buy ni sauvegarde cloud |
| Revenus faibles | Ne pas financer des obligations durables avec des ventes supposées ; réévaluer sur recettes nettes et temps réellement observés |
| Obligations légales/fiscales | Faire vérifier statut, cumul avec emploi, déclarations et cotisations, TVA, facturation, remboursement/contenu numérique, données et droits des assets |
Ces derniers points sont un mandat de vérification professionnelle, pas un avis juridique ou fiscal ; résidence, statut et territoires de vente ne sont pas établis.
Vérifier aussi licences des images/sons/polices et conditions des outils génératifs ; éviter marques et designs réels non autorisés dans les packs.

## 9. Questions pour Alexandre
1. Valides-tu l’achat initial du jeu CPU complet, sans pubs ni boutique intégrée au lancement, autour de 4,99 € (H) ?
2. Une démo gratuite est-elle indispensable avant de vendre, même si elle ajoute du travail et retarde la sortie ?
3. Acceptes-tu de garder tout le lot saisons/fêtes inclus et de ne promettre aucun DLC GPU/RAM avant validation séparée ?
4. Valides-tu itch.io pour le PC après Android, avec achats distincts clairement annoncés et sans compte commun ?
5. Peux-tu réserver du temps au support, réunir les testeurs exigés si ton compte y est soumis, et faire vérifier ton cadre professionnel/fiscal avant vente ?

## Sources officielles consultées
- [S1 — Game Dev Tycoon, Google Play](https://play.google.com/store/apps/details?id=com.greenheartgames.gdt&hl=en_US).
- [S2 — PC Tycoon 2, Google Play, incluant le renvoi tarifé Pro](https://play.google.com/store/apps/details?id=com.InsignisGames.PCTycoon2&hl=en_US).
- [S3 — Laptop Tycoon, Steam](https://store.steampowered.com/app/1780270/Laptop_Tycoon/).
- [S4 — Exigences API cible, Google](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
- [S5 — Tests des nouveaux comptes personnels, Google](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).
- [S6 — Politique des paiements et exceptions, Google](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en).
- [S7 — Création, App Bundle et signature, Google](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en).
- [S8 — Achats Android, documentation Godot](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_in_app_purchases.html) ; [dépôt du plugin](https://github.com/godot-sdk-integrations/godot-google-play-billing).
- [S9 — Échéances des versions Billing, Google](https://developer.android.com/google/play/billing/deprecation-faq).
- [S10 — Cycle d’achat, restauration et acquittement, Google](https://developer.android.com/google/play/billing/integrate).
- [S11 — Modes de paiement et devises, itch.io](https://itch.io/docs/creators/payments).
- [S12 — Steam Direct Fee](https://partner.steamgames.com/doc/gettingstarted/appfee).
- [S13 — Données utilisateur, confidentialité et Sécurité des données, Google](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).
