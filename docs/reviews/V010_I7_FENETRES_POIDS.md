# V0.10 / I7 — Une seule grande fenêtre par mois, et un jeu 4 fois plus léger

## Les fenêtres

Le test sur le Pixel (01/10) a montré qu'après le premier mois de ventes, trois fenêtres s'enchaînaient : les notes de la presse, « À la une » et « Les étagères sont vides ».

- **Un triomphe dans la presse** (moyenne ≥ 78) s'affiche maintenant dans la fenêtre des notes : l'illustration « À la une » est en bandeau et le titre devient « À LA UNE • LA PRESSE A TESTÉ ». Il n'y a plus de fenêtre séparée.
- **Une seule grande fenêtre par mois.** Un moment clé (rupture, premier contrat, nouvelle architecture…) qui arrive le même mois qu'une autre grande fenêtre attend la clôture suivante. Il n'est pas perdu : sa condition est vérifiée à nouveau le mois suivant.
- **Test** dans `workshop_layout_test`, sur le vrai parcours : après les notes du premier mois, aucune autre grande fenêtre ne s'ouvre. Sans la correction, le test échoue.

## Le poids

L'APK était passé de 41 à 59 Mo parce que Godot importait les grandes illustrations (décors, moments, titre, puces) **sans perte** : environ 2 Mo chacune.

- `project.godot` importe désormais les images **avec perte** (WebP, qualité 0,82). Les fichiers importés passent de 53 Mo à 6,4 Mo.
- Comparaison côte à côte du QG : aucune différence visible (personnages, décor, icônes).
- `build_all.ps1` supprime une fois les anciens réglages « sans perte » de chaque PC (fichiers `.import`, non versionnés), et Godot les recrée avec le nouveau réglage.

Tous les tests passent.
