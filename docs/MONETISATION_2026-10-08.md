# Modèle économique et monétisation — proposition du 08/10/2026

**Statut :** proposition de conception. Rien n'est implémenté et rien ne sera vendu dans la démo de fin octobre. Les décisions marquées « à valider » reviennent à Alexandre.

## Cadre

Ce qui est déjà décidé ou imposé :
- **Décisions d'Alexandre** :
  - téléchargement gratuit, puis une partie payante débloquable dans le jeu (extensions et personnalisation) ;
  - jamais de « payer pour gagner » ;
  - gagner un peu (rembourser le temps passé, financer la suite), pas maximiser le revenu ;
  - Play Store d'abord, Steam plus tard.
- **Contraintes du dépôt** (`AGENTS.md`) : le jeu doit fonctionner **hors ligne** ; les sauvegardes restent compatibles.
- **Confidentialité** : la page publiée (`PrivacyPolicy.gd` et `confidentialite.html`) promet aujourd'hui aucune collecte de données et aucune permission Android. Tout ajout payant devra mettre à jour cette page, la section « Sécurité des données » de la Play Console et la classification (mention « achats intégrés »).
- **Déjà présent dans le jeu** : la carte des branches (`CompanyBranches.gd`) distingue « Jouable », « Version complète » (Défense en 1980, Aérospatial en 1990) et « Extension à venir » (Mobile, Consoles, Cartes mères, Serveurs). Ce sont les emplacements prévus pour le contenu payant.

## 1. Ce qui est payant, et ce qui ne l'est jamais

### Les piliers, sans payer pour gagner

| Pilier | Contenu | Prix indicatif (à valider) | Pourquoi c'est juste |
|---|---|---|---|
| **Version complète** (achat unique) | La carrière entière et les branches marquées « Version complète » : Défense et Aérospatial | 4,99 à 7,99 € | Le prix d'un jeu de gestion premium sur mobile. On paie pour *plus de jeu*, pas pour gagner plus vite |
| **Extensions** | Une nouvelle branche par extension (Mobile, Consoles, Cartes mères, Serveurs), avec ses mécaniques, ses marchés et ses événements | 2,99 à 4,99 € chacune, ou en lot | Contenu neuf et testé, une vraie boucle différente, comme un DLC classique sur Steam |
| **Cosmétiques** | Thèmes de garage et de bureaux, finitions de boîtier supplémentaires (couleurs, logos, matières : la planche 6 existe déjà), décors de saison, portraits alternatifs | 0,99 à 1,99 € le pack | Purement visuel : aucun effet sur les notes, les ventes ou la réputation (la finition actuelle a un effet presse ; les finitions payantes n'auront **que** l'apparence) |
| **Soutien** (facultatif) | « Offrir un café au développeur » : un merci dans le jeu et la musique du générique | 1,99 € | Pour ceux qui veulent soutenir, sans rien de plus |

### Ce qu'on ne fait pas

- **Pas de passe de combat ni de saison payante.** C'est un jeu solo, hors ligne, développé par une seule personne : un passe crée une obligation de connexion et une pression à jouer tous les jours, contraire à l'esprit du jeu et lourde à alimenter. À la place, des **défis du moment gratuits**, calés sur la vraie date (le thème du moment existe déjà : Halloween, fêtes), qui donnent des cosmétiques gratuits.
- **Pas de boîtes à butin, pas d'énergie ni de minuteurs à accélérer, pas de monnaie premium** (qui masque les vrais prix).
- **Pas de publicité** : elle demanderait un SDK qui collecte des données et casserait la promesse de confidentialité.
- **Pas de confort qui touche à la difficulté** (argent, accélération des recherches, réussite garantie). La seule commodité envisageable : des emplacements de sauvegarde supplémentaires, et encore, le jeu de base doit en avoir assez (3 au moins).

### Où placer la limite gratuite (à valider)

| Option | Gratuit | Payant | Avantage | Risque |
|---|---|---|---|---|
| **A, recommandée** | Toute la carrière CPU et Logiciel de 1971 à **1985** (garage, atelier, premiers bureaux, ère 8 et 16 bits) | La suite de la carrière (1985 → fin) et les branches « Version complète » | On joue des heures avant de payer ; la limite tombe à un moment fort (le passage au PC personnel) | Il faut que 1971–1985 soit riche (c'est le cœur de la démo) |
| B | Toute la carrière CPU | Logiciel, branches et extensions | Le jeu de base est complet | Moins de raisons d'acheter ; le Logiciel est pourtant dans le cœur du jeu |
| C | Démo de 2 heures, puis tout payant | Tout le reste | Le plus simple | Ressemble à une démo, mauvaise image « gratuit » sur le Play Store |

Avec l'option A, la sauvegarde gratuite continue telle quelle après l'achat : rien n'est perdu ni recommencé.

## 2. Architecture des droits et du contenu (Android et PC/Steam)

**Principe : tout le contenu est livré dans le jeu, le droit d'y accéder est vérifié localement.** Pas de téléchargement de contenu à part : cela reste simple, hors ligne et compatible avec les sauvegardes.

```text
                    ┌──────────────────────────────┐
  Écrans du jeu ──► │ Entitlements (autoload)      │ ◄── tests : FakeStore
  (carte des        │  owns("full_game") -> bool   │
   branches,        │  owns("ext_mobile") -> bool  │
   finition…)       │  products() / purchase(id)   │
                    │  restore()                   │
                    └──────┬─────────────┬─────────┘
                           │             │
               PlayBillingStore     SteamStore
          (plugin Google Play     (GodotSteam :
           Billing pour Godot 4)   DLC « droit seul »)
```

- **`scripts/Entitlements.gd`** :
  - une liste fermée d'identifiants de produits (`full_game`, `ext_mobile`, `ext_consoles`, `ext_motherboards`, `ext_servers`, `cos_garage_retro`, `cos_finish_metal`…) ;
  - `owns(id)` et le signal `entitlements_changed` ;
  - un **cache local** des achats confirmés dans `user://entitlements.cfg`, pour jouer hors ligne ;
  - une revérification auprès de la boutique quand le réseau est là.
  - Un débloquage forcé en modifiant le cache local est accepté comme risque : le jeu est solo et le prix est bas.
- **Boutiques interchangeables** :
  - `PlayBillingStore` : plugin officiel *Google Play Billing* pour Godot 4. Achats « non consommables », restauration au démarrage, confirmation (*acknowledge*) obligatoire sous 3 jours.
  - `SteamStore` : GodotSteam. Un DLC Steam par produit, en « droit seul » (sans fichiers), vérifié avec l'API Steam de possession des DLC.
  - `FakeStore` : pour les tests et les versions de développement.
- **Le contenu se branche sur les droits, jamais l'inverse** :
  - `CompanyBranches` lit `Entitlements.owns()` pour passer un nœud de « Version complète » à « Jouable » ;
  - la limite de 1985 (option A) se lit au même endroit ;
  - les finitions cosmétiques filtrent leur liste.
- **Sauvegardes** : elles ne stockent **pas** les droits. Une sauvegarde faite avec une extension, ouverte sans elle, reste lisible : les éléments de l'extension sont figés, avec la mention « nécessite l'extension », et le reste de la partie continue. Test obligatoire.
- **Ajouter une extension = ajouter des données**, en cohérence avec l'architecture Software (catalogues de définitions) : un identifiant de produit, un nœud de la carte et des fiches de contenu, sans nouveau gestionnaire.

## 3. Rétention et conversion

On ne mesure pas les joueurs : aucune analyse embarquée, pour rester fidèle à la promesse de confidentialité. On s'appuie sur les statistiques de la Play Console (installations, désinstallations, notes, avis) et sur les retours des testeurs.

| Moment | Objectif | Leviers dans le jeu |
|---|---|---|
| **10 premières minutes** | Le premier CPU conçu et lancé, le premier jour J | Parcours guidé par Nora et Camille (existe), jour J fort (G2), objectifs courts visibles |
| **Jour 1** | Revenir pour voir la suite | Fin de séance sur un suspense : un prototype en cours, une offre client, la presse qui arrive ; Nora résume « ce qui vous attend » au retour |
| **Jour 7** | Un premier palier de croissance | Déménagement du garage vers l'atelier, première 2e génération, première branche Logiciel, carnet de Nora qui se remplit |
| **Jour 30** | Une vraie carrière | Changements d'époque (musique, décors), rang mondial, records, défis du moment liés à la vraie date, mises à jour de contenu régulières (une petite toutes les 4 à 6 semaines) |

**Conversion sans pression :**
- **Une seule proposition à un moment fort**, en 1985 (option A) : Nora annonce l'ère du PC personnel, avec un écran qui montre ce que contient la version complète, le prix réel et un bouton « Plus tard » toujours visible. Cela ne revient pas avant un nouveau palier.
- **La carte des branches** reste l'endroit calme où l'on voit et achète les extensions, avec un aperçu de ce qu'elles apportent.
- **Les cosmétiques** se voient sur l'établi de finition : la finition payante s'affiche à côté des gratuites, avec un aperçu sur le boîtier, sans fenêtre surgissante.
- **Restaurer les achats** est toujours accessible (Menu, puis Achats), et obligatoire pour la boutique.

## Points à valider par Alexandre

1. La limite gratuite : option A (1985), B ou C.
2. Les prix : version complète, extensions, cosmétiques.
3. Le soutien « café » : oui ou non.
4. La première extension à produire après la version complète (Cartes mères ? Mobile ?).
5. La mise à jour de la page de confidentialité et de la Play Console au moment de l'ajout des achats (et non avant).

Les taux de commission (Google, Steam) et les règles des boutiques sont à revérifier au moment de l'intégration : ils évoluent.
