# Système visuel des composants — Tech Empire

## Objectif

Les fonds créent l'ambiance, mais les composants doivent porter l'identité du jeu.
Le rendu visuel des produits doit être qualitatif, cohérent, chaleureux et crédible sans exiger du photoréalisme.

Le joueur doit prendre plaisir à regarder ses produits évoluer.

---

## 1. Principes visuels

- style semi-réaliste / illustré haut de gamme ;
- éclairage chaleureux, lisible et cohérent avec l'UI ;
- silhouettes et formes clairement reconnaissables ;
- pas d'aspect "asset générique" ou stock photo ;
- détails techniques visibles sans devenir illisibles ;
- palette cohérente avec la marque du joueur ;
- même famille graphique pour tous les composants ;
- variantes suffisamment nombreuses pour éviter la répétition.

---

## 2. Catégories visuelles à produire

### CPU
- package ;
- die ;
- substrat ;
- pins / contacts ;
- heatspreader ;
- marquage ;
- couleur ;
- famille / série ;
- édition spéciale ;
- variantes par époque.

### GPU
- carte nue ;
- radiateur ;
- ventilateurs ;
- backplate ;
- logo / série ;
- format compact / standard / haut de gamme ;
- variantes générationnelles.

### RAM
- module simple ;
- dissipateur ;
- couleur ;
- hauteur ;
- nombre de puces ;
- gamme standard / premium / serveur.

### Cartes mères
- format ;
- socket ;
- chipset ;
- slots ;
- VRM ;
- dissipateurs ;
- connectique ;
- palette et branding.

### Stockage
- HDD ;
- SSD SATA ;
- SSD M.2 ;
- stockage entreprise ;
- variantes grand public / professionnel.

### Serveurs / datacenters
- racks ;
- blades ;
- cartes accélératrices ;
- alimentation redondante ;
- refroidissement ;
- baie complète.

### IA / accélérateurs
- cartes spécialisées ;
- modules ;
- puces dédiées ;
- racks IA ;
- variantes expérimentales.

### Robotique
- cartes de contrôle ;
- capteurs ;
- actionneurs ;
- modules ;
- bras / prototypes.

---

## 3. Système modulaire

Ne pas dessiner chaque produit comme un asset isolé.

Chaque famille doit être composée de modules combinables :
- forme de base ;
- finition ;
- couleur ;
- marquage ;
- niveau de gamme ;
- génération ;
- accessoires ;
- éléments fonctionnels visibles.

L'objectif est qu'un nombre limité de modules puisse produire beaucoup de variantes crédibles.

---

## 4. Schémas techniques

Les schémas doivent être eux aussi cohérents et qualitatifs.

Types :
- vue éclatée ;
- bloc fonctionnel ;
- plan de package ;
- schéma de die ;
- coupe simplifiée ;
- flux de données ;
- alimentation ;
- thermique ;
- implantation carte ;
- architecture logique.

Ils ne doivent pas ressembler à des documents industriels illisibles.
Ils doivent donner une impression technique tout en restant compréhensibles par le joueur.

---

## 5. Variantes par époque

Les composants doivent évoluer visuellement avec le temps.

Exemple CPU :
- années 1970 : package simple, céramique / DIP, marquage technique ;
- années 1980-1990 : packages plus denses ;
- années 2000 : heatspreaders / sockets modernes ;
- années 2010-2020 : design plus premium et branding fort ;
- futur : packaging avancé, chiplets, interposers, empilement.

Cette progression doit rester cohérente avec la technologie réellement débloquée.

---

## 6. Qualité minimale

Un asset produit est validé seulement s'il :
- reste lisible en vignette ;
- reste beau en vue agrandie ;
- correspond au style global ;
- possède une identité visuelle claire ;
- ne ressemble pas à une copie directe d'une marque réelle ;
- peut être réutilisé dans l'UI ;
- permet au joueur de distinguer rapidement plusieurs gammes.

---

## 7. Personnalisation

Le joueur doit pouvoir personnaliser progressivement :
- couleur ;
- marquage ;
- nom de série ;
- style de package ;
- finition ;
- gamme ;
- branding ;
- éléments décoratifs ;
- skins premium éventuels.

Certaines variantes sont gratuites et déblocables.
Les variantes premium restent uniquement cosmétiques.

---

## 8. Ordre de production

Priorité actuelle :
1. CPU
2. schémas CPU
3. variantes CPU par génération
4. éléments de branding CPU
5. cartes mères / socket
6. RAM
7. GPU
8. stockage
9. serveurs / datacenters
10. IA / robotique

Les branches non jouables peuvent être préparées en concept sans être intégrées immédiatement.

---

## 9. Pipeline

Pour chaque nouvelle famille :
1. définir le style ;
2. créer 3 à 5 bases solides ;
3. créer les modules de variation ;
4. produire les schémas ;
5. valider en petite taille et grande taille ;
6. classer dans Git ;
7. intégrer dans Godot ;
8. tester en situation réelle.

---

## 10. Ambition visuelle

Le jeu n'a pas besoin d'être ultra-photoréaliste.
Il doit être beau, cohérent, chaleureux, propre et immédiatement reconnaissable.

La priorité est une identité visuelle forte et constante, pas la sophistication technique maximale.
