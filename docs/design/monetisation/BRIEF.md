# Brief — Publier Tech Empire sur Google Play, et quel contenu payant ?

Destinataires : **Astra** et **Claude**, chacun de son côté (après le lot graphique des fêtes d'Astra). Coordination et synthèse : **Codex**. Décision : **Alexandre**.
Même protocole que l'étude I5 : voir `PROTOCOLE.md` dans ce dossier. **Personne ne modifie le code du jeu pendant l'étude.**

## 1. Le sujet

Alexandre veut publier Tech Empire sur Google Play, avec du contenu payant. Il faut choisir :
- **le modèle** : gratuit avec des achats, payant une seule fois, démo gratuite puis le jeu complet à acheter, ou un mélange ;
- **ce qui est payant et ce qui reste gratuit** ;
- **le chemin jusqu'à la publication**.

## 2. Ce qu'Alexandre a déjà décidé (contraintes)

- **Des cosmétiques payants sont possibles, mais jamais d'avantage en jeu** (rien qui fasse gagner, aller plus vite ou gagner plus d'argent).
- **Même jeu sur PC et Android.**
- **Une ambiance chaleureuse** : rien d'agressif (pas de minuteurs à payer, pas de pression).
- La ligne du jeu (30/09) : **ni simulation hardcore, ni jeu bidon**. Un novice ne doit pas être perdu.
- **Le contenu technologique a une fin.** Le jeu annonce au joueur qu'il a atteint le niveau final ; la suite viendra par mises à jour ou DLC, et la partie continue en mode libre.
- Alexandre développe le jeu **sur son temps libre** (il travaille à temps plein à côté), avec des IA : Claude pour le code, Astra pour les graphismes, Codex pour la coordination. Il a donc **peu de temps pour animer un jeu en continu**.

## 3. Où en est le jeu (01/10/2026)

- Godot 4.7.2, branche `feature/ui-v09-navigation`. Jouable de 1971 au-delà de 2010 (vertical slice CPU).
- 3 modes : Accessible, Standard, Simulation.
- Locaux : garage → atelier → siège → campus, avec un décor par palier.
- Moments illustrés, équipe visible, saisons, vitrine, trophées.
- **APK de test : 34 Mo.**
- Aucun serveur, aucun compte joueur, aucune connexion requise. Les sauvegardes sont locales (JSON).
- Signature : clé de **test** commune pour l'instant. Il faudra une vraie clé de publication, gardée hors du dépôt.
- Graphismes en cours chez Astra : saisons des décors, objets de fête, vitrine et trophées (`docs/BRIEF_ASTRA_LOT3_SAISONS_FETES.md`, prévus gratuits). Ce lot montre ce qu'un futur « thème payant » pourrait être.

## 4. Faits Google Play (vérifiés le 01/10/2026, à revérifier avant publication)

- **Nouveau compte développeur personnel : test fermé obligatoire avec au moins 12 testeurs pendant 14 jours d'affilée** avant la publication pour tous.
  Sources : [Aide Play Console](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en), [guide 2026](https://dev.to/founder_can/google-play-12-testers-for-14-days-the-complete-guide-2026-18o8).
- **Viser Android 16 (API 36)** pour les nouvelles applis et les mises à jour depuis le 31/08/2026.
  Sources : [Aide Play Console](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [récapitulatif](https://dev.to/dainyjose/google-play-requires-android-16-api-level-36-by-august-31-2026-react-native-migration-guide-1d51).
- **Contenu numérique vendu dans l'appli = système de paiement Google Play obligatoire.** Pour Godot, il existe l'extension [godot-google-play-billing](https://github.com/godot-sdk-integrations/godot-google-play-billing) ([documentation Godot](https://docs.godotengine.org/en/4.4/tutorials/platform/android/android_in_app_purchases.html)). Elle impose l'export Android « Gradle », que le projet n'utilise pas encore (`use_gradle_build=false`).
- La boutique exige aussi :
  - un fichier **AAB** (pas un APK) ;
  - la **signature gérée par Google** ;
  - une **politique de confidentialité** ;
  - le formulaire **Sécurité des données** ;
  - la **classification par âge** ;
  - une fiche boutique : icône 512 px, bannière, captures d'écran.

## 5. Jeux comparables (fiches Google Play consultées le 01/10/2026)

| Jeu | Modèle | Indications publiques |
|---|---|---|
| [Game Dev Tycoon](https://play.google.com/store/apps/details?id=com.greenheartgames.gdt&hl=en_US) | jeu complet, « sans achats intégrés ni pubs » | 1 M+ téléchargements, 4,9 ★ |
| [PC Tycoon 2](https://play.google.com/store/apps/details?id=com.InsignisGames.PCTycoon2&hl=en_US) | gratuit, pubs (récompensées, optionnelles) et achats intégrés ; il existe aussi une version « [Pro](https://play.google.com/store/apps/details?id=com.InsignisGames.PCTycoon2Pro&hl=en-US) » séparée | 1 M+, 3,9 ★ |
| [Laptop Tycoon](https://store.steampowered.com/app/1780270/Laptop_Tycoon/) | jeu payant sur Steam (PC) | — |

Les prix exacts n'ont pas été relevés : à vérifier si un chiffre compte dans votre analyse.

## 6. Les questions

1. **Le modèle** : gratuit avec cosmétiques, payant une seule fois, démo gratuite puis le jeu complet à acheter, ou un mélange ? Avec le pour et le contre pour **ce** jeu et **cette** équipe.
2. **Le prix** : une fourchette, en disant d'où elle vient (comparables, supposition).
3. **Que vendre** :
   - une liste concrète de contenus payants, sans avantage en jeu ;
   - ce qui reste gratuit pour tout le monde (les saisons et les fêtes du lot 3 ?) ;
   - ce qui serait vendu plus tard en DLC (nouveaux composants : GPU, RAM… ?).
4. **La publicité** : oui ou non ? Si oui, quelle forme, et que devient l'ambiance ?
5. **Le PC** : Steam, itch.io ou rien pour l'instant ? Même modèle ? Que deviennent les achats d'un joueur qui joue sur les deux ?
6. **La technique** :
   - ce qu'il faut ajouter au jeu (achats, restauration des achats, fonctionnement hors ligne, protection minimale) ;
   - le coût en travail ;
   - les risques (Gradle, mises à jour de l'extension).
7. **Le chemin jusqu'à la publication** : les étapes dans l'ordre (bêta fermée de 12 testeurs, fiche boutique, version 1.0), et ce qui doit être fini dans le jeu avant.
8. **Les risques** : avis négatifs, piratage, temps d'Alexandre, obligations légales et fiscales. Ces dernières sont **à signaler, pas à trancher** : Alexandre fera vérifier par un professionnel.
9. **Les décisions pour Alexandre** : 5 questions maximum, simples.

## 7. Ce qu'on attend

Un fichier `analyse-<votre nom>.md` dans ce dossier, avec :
1. une recommandation en 5 lignes ;
2. une réponse à chaque question ci-dessus ;
3. un tableau : contenu, gratuit ou payant, prix envisagé, travail pour Astra et Claude ;
4. les étapes jusqu'à la publication ;
5. les risques et les parades ;
6. 5 questions maximum pour Alexandre.

250 lignes maximum. Chaque chiffre dit sa source : site, fait du jeu ou supposition.
