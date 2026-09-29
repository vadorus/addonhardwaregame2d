# Lot E — L'équipe parle, les équipes R&D, l'architecture vit (29/09)

Question d'Alexandre : « on a bien la sensation de développer quelque chose, un retour différent
des clients selon le produit, l'équipe de développement voit-elle les défauts d'un CPU, as-tu mis
en place le système architecture / équipes ? » Réponse : partiellement avant ce lot ; complet après.

## E1 — L'équipe de développement te parle (commit 62cb4f6)
- `scripts/TeamLessons.gd` : leçons de la génération précédente (ventes, SAV, notes presse,
  comparaison au meilleur rival) et **conseils de correction** : qualité, thermique, firmware
  stabilité / performance, coût. Un conseil accepté ou refusé ne revient pas.
- Étape « Objectif » du concepteur : carte « Ce que l'équipe a retenu » + bouton « Suivre le conseil ».
- Décision « ÉQUIPE » dans le bureau du PDG, zone ÉQUIPE dans le garage.
- Fiche produit : « Ce que disent les clients » — voix différentes selon le marché
  (pros, scientifiques, grand public).

## E2 — Équipes de recherche Vitesse / Énergie / Fiabilité (commit 617e42c)
- Chaque chercheur R&D appartient à une équipe ou reste libre ; responsable (compte double),
  formation (2 mois, +6 compétence), recrutement d'expert (compétence 86, salaire ×1,8).
- Le niveau d'équipe multiplie la progression de la recherche de son axe (×0,6 à ×1,5).
- Labo > Recherche : panneau des 3 équipes avec membres, niveau, conseil du responsable.
- Migration : les anciennes affectations deviennent des personnes dans les équipes.
  Correctif : l'interface pouvait marquer tout le monde « libre » pendant le chargement ;
  la migration repart maintenant des affectations sauvegardées (clé `research_teams`).

## E3 — L'architecture prend la forme de vos équipes
- **Signature** : au lancement d'un projet, le niveau de chaque équipe donne un bonus/malus
  sur performance / efficacité / fiabilité (de -3 à +6, réduit pour une équipe de 1-2 personnes).
  Investir dans une équipe se voit sur la génération suivante.
- **Tick / tock** pour une suite de gamme :
  - Tick (même architecture, procédé plus fin) : développement ~15 % plus rapide, fiabilité +3.
  - Tock (nouvelle architecture) : ~12 % plus long, performance +4, signature ×1,5.
  - Première puce sur une architecture : fiabilité -3, sauf équipe Fiabilité solide.
- Étape « Architecture » : carte du responsable développement (mode, signature, usure) et
  bouton « Passer sur … (tock) » quand l'architecture de la gamme est fatiguée.

## E4 — Usure de l'architecture
- Une architecture s'use dès qu'une plus récente existe (6 ans pour s'essouffler, +10 % si elle
  a plafonné en maturité). Usure → performance jusqu'à -8, efficacité jusqu'à -4.
- Alerte de l'équipe de développement à 50 % d'usure sur une architecture encore utilisée
  (une fois ; pas de rafale d'alertes au chargement d'une ancienne partie).
- Cartes d'architecture : « Usure : Fatiguée (55 %) — performance -4 ».

## Vérifications
- Smoke test vert + `ResearchTeamsScenario` + `ArchitectureTickTockScenario`.
- Partie d'Alexandre (8/1985) : se charge, 16 objectifs conservés ; 32 chercheurs R&D dont
  2 affectés (Énergie, Fiabilité, niveaux 79/78) et 30 libres → alerte « répartissez-les » ;
  gamme « tv » encore sur 8 bits (usure 100 %) → un tick dessus coûte -8 en performance,
  l'équipe conseille le tock vers 32 bits.

## Ce qui reste (hors lot E)
- Les 30 chercheurs libres d'Alexandre : c'est à lui de les répartir (volontairement pas
  automatique : cela multiplierait d'un coup sa vitesse de recherche).
- Nouvelles illustrations des locaux (paliers 6-8) : toujours à produire.
