# Lot G2 — Tutoriel court guidé par Nora

## But
Guider les premières minutes sans fenêtre bloquante ni second système de quêtes.
Le tutoriel réutilise le premier objectif Produit du lot C : « Lancer votre premier CPU ».

## Parcours
1. **Idée** : toucher l'établi, choisir un marché et lancer le premier projet.
2. **Développement** : lancer le temps ; Nora signale uniquement les vraies décisions.
3. **Industrialisation / lancement** : suivre la fabrication puis lancer le CPU dans Produits.

Une fois le premier CPU lancé, le mini-tutoriel disparaît et les trois pistes normales Produit / Croissance / Marché prennent le relais.

## UX
- Avant le premier lancement : un seul objectif visible au lieu des trois objectifs long terme.
- Les messages du garage affichent clairement `Étape 1/3`, `2/3`, `3/3`.
- Aucune sauvegarde spécifique au tutoriel : l'étape est reconstruite depuis le projet, la production et les produits.

## Validation
`GarageScenario.gd` vérifie les quatre états : idée → développement → industrialisation → tutoriel terminé après lancement.
Smoke complet Godot 4.7.2 : vert le 30/09/2026.
