# V0.10 / I4 — Lancement et fabrication en cartes claires

Demande : « 3 chiffres qui comptent, le reste replié ; chaque option expliquée ; bouton d'action toujours visible ».

## Lancement (Produits › Vendre)

- Nouvelle carte **PRÊT À LANCER** en haut de la page : « Votre gamme X est prête : N modèles ».
- Trois tuiles : **Ventes attendues** (puces/mois), **Gagné par puce**, **Bénéfice des ventes** (€/mois).
- Une ligne de coût : réservation d'usine et trésorerie restante.
- Gros bouton vert « Lancer les N modèles » (réglages conseillés).
- La veille détaillée (rival, marges) est repliée sous « Prévision détaillée de ce modèle ».
- « Préparer le lancement » arrive directement sur cette carte et efface les bulles d'actualité.

## Fabrication (Produits › Fabriquer)

- La carte du CPU s'ouvre sur le conseil de Nora : « Nora conseille : fabriquer chez X, réglages équilibrés. »
- Le coût en une phrase, puis le bouton vert « Lancer la production chez X ».
- Usine, priorité et tri des puces sont repliés sous « Ajuster moi-même ».
  - Chaque option garde sa phrase d'explication.
  - Les chiffres des fonderies sont expliqués (précision, fiabilité, coût).
- Le résumé passe à « Votre choix : … » dès que le joueur change un réglage.
- Le savoir-faire de l'équipe production (jargon) est replié sous « Équipe production : N personnes • savoir-faire ».
- **Correction** : « Choisir la fabrication » (contexte `Production`) n'ouvrait pas Fabriquer quand un CPU était déjà en vente. La page Vendre s'affichait à la place. C'est corrigé, et le lien arrive maintenant sur la carte, bulles effacées.

## Tests

- `workshop_layout_test` lance le jeu complet en 1616×720 et suit le vrai chemin, de « Choisir la fabrication » à « Préparer le lancement ». Le bouton vert de chacune des deux cartes doit être visible sans défiler.
- `FabricationPageScenario` vérifie trois choses :
  - le conseil de Nora s'affiche d'abord ;
  - les réglages sont repliés, puis ouvrables ;
  - un réglage modifié est bien envoyé.
- Tous les tests passent : smoke, garage, atelier, plafonds d'équilibrage.
