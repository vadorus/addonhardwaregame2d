# Décisions issues de l'audit UX Claude — V0.3.1

## Décision générale

L'audit confirme une direction importante :
- le fond intérieur est une force majeure ;
- l'interface actuelle/conceptuelle doit être allégée ;
- le jeu ne doit pas ressembler à un SaaS ou à un tableau de bord d'entreprise.

Objectif : conserver la richesse du jeu tout en réduisant la charge visuelle.

---

## Décisions adoptées

### 1. Navigation unique
Maximum 6 hubs principaux :
- Bureau / QG
- R&D
- Produits
- Marché
- Équipe
- Finances

Les branches CPU/GPU/RAM/etc. deviennent des onglets ou sous-sections, jamais des entrées principales supplémentaires.

### 2. Bureau = accueil
Le tableau de bord et le bureau sont fusionnés.
Le joueur arrive dans un vrai espace intérieur de l'entreprise.

### 3. Nora devient le guide central
Nora porte :
- l'objectif actuel ;
- le contexte ;
- la prochaine action utile ;
- les notifications importantes ;
- les déblocages de nouveaux hubs.

Pas de tutoriel bloquant par flèches.
Nora explique surtout le pourquoi.

### 4. Un seul objectif principal visible
Les objectifs secondaires restent repliés ou contextuels.

### 5. Fond visible
Cible : conserver environ 60 à 70 % du décor visible sur l'accueil.

Les panneaux doivent être :
- moins nombreux ;
- plus opaques ;
- repliables ;
- contextuels.

### 6. Responsive
Deux dispositions :
- large ;
- compacte.

Le choix dépend de l'espace disponible, pas du système d'exploitation.

Un seul gameplay, une seule logique de données.

### 7. Fonds
Produire les fonds en format large, avec la zone utile centrée.
Éviter tout texte peint directement dans le décor.

Les variantes saisonnières doivent privilégier :
- overlays ;
- décorations ;
- variations lumière/couleurs ;
- objets de scène.

### 8. CPU
Assistant en 4 étapes :
1. Technique
2. Design industriel
3. Branding
4. Lancement

Toujours afficher un panneau de conséquences :
- coût ;
- durée ;
- performance relative ;
- segment visé ;
- risque.

Prévoir "Nouvelle génération à partir de..." pour éviter de refaire tout le workflow à chaque CPU.

### 9. Lecture des composants
Trois niveaux :
1. Carte simple
2. Fiche détaillée
3. Schéma technique

### 10. Progression
Le palier d'entreprise reste la progression principale.
Pas de système concurrent type "niveau du PDG" comme progression majeure.

---

## Décisions à ne pas appliquer aveuglément

### 1. Pas de suppression totale de la personnalité
On garde :
- ambiance chaude ;
- objets personnels ;
- vie dans les locaux ;
- éléments décoratifs ;
- identité visuelle forte.

### 2. Pas de simplification excessive
Le jeu reste profond.
On masque la complexité au début, on ne la supprime pas.

### 3. Pas de 6 hubs rigides éternels
La structure doit rester extensible, mais sans multiplier les menus principaux.

---

## P0 — avant intégration graphique lourde

- thème global Godot ;
- Card générique ;
- StatChip ;
- NavRail ;
- Tooltip ;
- NoraPanel ;
- LayoutManager ;
- gestion de safe area ;
- formatteur de nombres/units ;
- écran garage 1971 ;
- écran compact Android ;
- règles officielles de fonds ;
- plan de déblocage progressif.

---

## P1 — vertical slice CPU

- assistant CPU 4 étapes ;
- ComponentCard ;
- SpecRow ;
- ProgressCard ;
- projet en cours compact ;
- lecture 3 niveaux ;
- responsive large/compact ;
- cohérence unités et format français.

---

## P2 — enrichissement

- animations d'ambiance ;
- employés visibles ;
- cycle jour/nuit ;
- overlays saisonniers ;
- zones cliquables du bureau comme raccourcis ;
- UI évolutive selon l'époque ;
- boutique cosmétique.
