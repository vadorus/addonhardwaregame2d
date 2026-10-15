# Audit Claude V0.6 — seconde passe et résolution des blocants

- **Audit externe :** Claude
- **Commit audité :** `67e1ddcd7bc12792c20beea5b49f49ccfd0f0e87`
- **Date :** 25 septembre 2026
- **Correctifs issus de l'audit :** jusqu'au commit `b5d670c464e467e4cd676cf3ffcd37d05b60f6f3`

> Ce document résume la seconde passe d'audit et trace les corrections prises dans le dépôt. Le rapport complet original reste conservé dans `CLAUDE_AUDIT_RESULT.md` sur la copie locale d'audit.

## Ce que l'audit a confirmé

La base V0.6 est techniquement saine : import, boot et smoke test passent sous Godot 4.7.2. Le playtest de départ est reproductible : en Standard, le premier mois du garage consomme 4 452 € et laisse 95 548 €.

Les corrections précédentes sur les revues prototype/validation, le double comptage des salaires et la visibilité des décisions bloquantes ont été confirmées.

## Blocants trouvés

### 1. Économie post-lancement trop généreuse

Au commit audité, un premier CPU pouvait générer plusieurs centaines de milliers d'euros de résultat par mois. Un prix multiplié par cinq conservait encore une demande significative et augmenter la capacité ne demandait aucun engagement financier.

**Cause principale :**
- part de marché de base trop élevée pour une marque inconnue ;
- élasticité prix trop faible ;
- capacité commerciale gratuite ;
- coût de production payé uniquement sur les unités vendues.

**Correction appliquée :**
- part de marché initiale abaissée et davantage liée à l'avantage produit et à la notoriété ;
- ajout d'une fonction d'élasticité prix dédiée : au-delà du prix de référence, la demande décroît fortement ; à 3–5× le prix de marché elle devient résiduelle ;
- engagement financier lors du lancement selon la capacité choisie ;
- coût mensuel de réservation de capacité, avec pénalité supplémentaire sur la capacité inutilisée ;
- ces coûts sont affichés dans la veille avant lancement ;
- nouveau garde-fou CI : un CPU à 5× le prix de référence ne doit plus conserver une demande significative et la capacité doit coûter de l'argent.

### 2. Mode Réaliste trop étroit avant la première vente

L'audit a montré que les briefs guidés à 45 k€ et 55 k€ ne survivaient pas jusqu'au lancement au commit audité.

Le capital Réaliste réel est **95 000 €** ; la valeur 70 000 € provenait d'une ancienne demande d'audit et était périmée.

**Correction appliquée :**
- capital inchangé à 95 000 € ;
- réduction des surcoûts artificiels cumulés du profil Réaliste ;
- la difficulté reste assurée par une trésorerie inférieure au Standard, une demande plus faible et des concurrents plus réactifs ;
- la matrice CI teste maintenant aussi un brief Réaliste équilibré à 45 k€ et un brief pionnier à 55 k€ ;
- le brief pionnier doit conserver au moins 2 500 € après industrialisation : le test n'accepte pas une survie à quelques euros près.

Profil Réaliste actuel :
- fonctionnement : ×1,04 ;
- salaires : ×1,03 ;
- R&D : ×1,02 ;
- industrie : ×1,03 ;
- demande : ×0,92 ;
- capital : 95 000 €.

## UX corrigée après audit

Le lancement du premier CPU était le dernier grand jalon non signalé dans le garage.

Désormais :
- un produit `READY` crée une décision bloquante ;
- le sous-titre du garage indique **Décision requise • Lancement CPU** ;
- **Stock & production** reçoit le même signal visuel que les revues et la route de fabrication ;
- l'action **Préparer le lancement commercial** ouvre directement la zone produit ;
- le temps reste en pause jusqu'au lancement ;
- l'écran de lancement affiche le coût d'engagement de capacité et la réservation mensuelle estimée.

## Garde-fous ajoutés

Le CI vérifie désormais :
- plusieurs trajectoires Accessible / Standard / Réaliste ;
- Réaliste 35 k€, 45 k€ et 55 k€ ;
- élasticité d'un prix extrême (5× la référence) ;
- coût croissant de la capacité ;
- débit réel d'un engagement de capacité au lancement ;
- coût mensuel de réservation de capacité ;
- parcours complet CPU jusqu'à la génération suivante.

Au commit `b5d670c...` :
- **Godot CI : succès** ;
- **Windows : succès** ;
- **Android : succès**.

## Points encore ouverts après cette passe

Ils ne sont pas considérés comme résolus par les correctifs ci-dessus :

- approches PURCHASE / LICENSE / SUBCONTRACT / PARTNER encore potentiellement trop dangereuses au garage et à mieux avertir ;
- recrutement et déménagement : le conseil financier doit anticiper la vraie trésorerie après engagement ;
- intensité R&D : la plage haute doit rester utile et avoir un effet lisible, sans faux choix ;
- coût des SKU supplémentaires, stock réel et logistique à approfondir ;
- breakpoints mobile à revalider sur appareil réel ;
- plusieurs mois/années de ventes doivent encore être rejoués sur Pixel pour confirmer la nouvelle économie post-lancement.

## Décision de design retenue

La difficulté ne doit pas venir d'un capital artificiellement énorme ou minuscule. Elle doit émerger des décisions du joueur, de la concurrence, des coûts réellement engagés, de la demande et de la croissance de l'entreprise.

Une correction économique ne doit pas être compensée par « donner plus d'argent ». Il faut corriger la source : coût, demande, capacité, risque ou information joueur.
