# Prompts IA pour Tech Empire — version adaptée (08/10/2026)

Base : le guide de Gemini (6 sections), adapté à notre jeu, plus 8 prompts nouveaux.

**Ce qui a changé par rapport au guide d'origine :**
- Chaque prompt commence par le même **bloc de contexte**. Sans lui, une IA invente un jeu 3D en C# avec combats et joystick.
- Les parties hors sujet sont retirées : C#, ramasse-miettes .NET, joystick, *coyote time*, combat, LOD, éclairage, passe de combat.
- Chaque prompt exige des **mesures ou des fichiers réels**, distingue *vérifié / supposé*, et finit par des étapes testables (format de nos plans C/T/R/G/A/M).

---

## Bloc de contexte (à coller en tête de chaque prompt)

```text
CONTEXTE — Tech Empire
- Jeu de gestion 2D (fabricant de processeurs, de 1971 à nos jours), solo, hors ligne, sans publicité.
- Godot 4.7.2, 100 % GDScript (aucun C#), rendu gl_compatibility (OpenGL ES 3). Interface en Control/StyleBox, pas de 3D, pas de shader personnalisé.
- Cibles : Android (Pixel 10, paysage, 30/60 images/s) puis PC/Steam.
- Dépôt : github.com/vadorus/addonhardwaregame2d, branche v013/demo-octobre. Règles dans AGENTS.md.
- Personnages : Nora (bras droit), Camille (ingénieure), Noah (production). Ton chaleureux, vouvoiement.
- Références de qualité : Game Dev Tycoon, Devices Tycoon Simulator, PC Tycoon 2.
- Priorité : démo CPU agréable, compréhensible et stable pour fin octobre. Plan en cours : docs/PLAN_CODEX_2026-10-08.md.
- Contraintes : sauvegardes compatibles (migration explicite), un test déterministe par mécanique, rien d'envoyé sur Internet par le jeu.
RÈGLES DE RÉPONSE
- Réponds en français.
- Ne présume rien que tu n'as pas lu : cite le fichier et la ligne, ou dis « supposé ».
- Pas de recommandations génériques : chaque constat doit pointer vers notre code, nos chiffres ou nos captures.
- Termine par des étapes numérotées : contenu, fichiers, critère de réussite chiffré, test.
```

---

## Les 6 prompts d'origine, adaptés

### 1a. Audit d'architecture et de performances
```text
[CONTEXTE]
Rôle : architecte Godot 4 / GDScript pour mobile et PC.
Entrée : [fichiers ou module], et les mesures P0 du Pixel (docs/reviews/P0_PIXEL_*.md).
Analyse :
1. Ce qui coûte à chaque image et à chaque fin de mois (_process, signaux, refresh, duplicate(true), reconstruction de nœuds).
2. Couplage : main.gd, autoloads, écrans qui modifient directement les managers.
3. Ce qui sera trop lent sur un téléphone 2 à 4 fois plus lent qu'un PC.
Résultat : tableau des constats par gravité, avec la mesure qui le prouve ; puis le correctif minimal en GDScript commenté, et le test qui le vérifie. Ne propose pas de refonte si une correction ciblée suffit.
```

### 1b. Entrées : tactile, souris, manette
```text
[CONTEXTE]
Rôle : ingénieur d'interface mobile et PC pour jeux de gestion (pas d'action).
Analyse :
- les tailles réelles des zones tactiles en millimètres sur Pixel 10 (1 px logique ≈ 0,104 mm), avec un objectif de 6 mm minimum et 8 mm pour les actions principales ;
- les infobulles inaccessibles au doigt ;
- les doubles appuis sur des actions payantes ;
- le défilement qui annule les appuis ;
- la navigation clavier et manette (focus, actions ui_*).
Résultat : une couche d'entrée unique (InputRouter) en GDScript, la liste des écrans à corriger par ordre d'impact, et un test par règle.
```

### 2. Son et musique
```text
[CONTEXTE] Audio : AudioStreamPlayer natifs, musique Ogg par époque (normalisée à −20 LUFS), 7 ambiances, 17 effets. Voir docs/AUDIT_AUDIO_2026-10-08.md.
Rôle : directeur audio pour jeux de gestion calmes.
États de jeu à couvrir (pas de combat) : menu, époque, saison, tension financière, suspense du jour J, verdict, célébration, pause.
Résultat :
1. les bus (Master avec limiteur, Musique, Ambiances, Effets) et les règles d'atténuation chiffrées en dB et en ms ;
2. le tableau des transitions entre états ;
3. le budget audio Android et PC (formats, fréquences, voix simultanées) ;
4. une liste de morceaux à créer pour les années 2000 à 2020, avec l'ambiance voulue.
```

### 3. Rendu et images
```text
[CONTEXTE] Rendu 2D : le recouvrement et les appels de rendu coûtent plus que les shaders (il n'y en a pas). Voir docs/AUDIT_RENDU_2026-10-08.md.
Rôle : technical artist 2D mobile.
Analyse : les couches superposées par écran, les StyleBox non partagées, les textures non compressées, les ombres et les animations redessinées à chaque image.
Résultat : un budget par écran (appels de rendu, recouvrement, Mo de textures), les réglages d'import par dossier (ASTC/ETC2 pour Android, BC7 pour PC, sans compression pour les icônes), et les étapes pour l'atteindre sans changer le rendu à l'œil.
```

### 4. Game design, économie et sensations
```text
[CONTEXTE] Boucles : concevoir → développer → fabriquer → finition → jour J → vendre. Sonde : tests/tools/career_probe.tscn. Voir docs/AUDIT_GAME_DESIGN_2026-10-08.md.
Rôle : lead game designer de jeux tycoon.
Données à fournir : sorties de career_probe (graines, difficultés, trésorerie par an, rang, faillites).
Analyse :
1. les frictions (attente, falaises de trésorerie, emballement, absence de 1re place) ;
2. un modèle chiffré : autonomie, retour d'une génération, puits, écart au leader, par période ;
3. les sensations du jour J, des records, de la clôture du mois et des erreurs, en ms, en sons et en vibrations, en respectant les animations réduites.
Résultat : des cibles chiffrées vérifiables par la sonde, et les modifications minimales pour les atteindre.
```

### 5. Modèle économique
```text
[CONTEXTE] Modèle choisi : gratuit, puis version complète en achat unique, extensions de branches, cosmétiques purement visuels. Pas de passe de saison, de boîte à butin, d'énergie, de monnaie premium ni de publicité. Hors ligne. Voir docs/MONETISATION_2026-10-08.md.
Rôle : stratège de monétisation éthique pour jeux premium mobiles.
Résultat : la limite gratuite et l'écran d'offre (texte exact) ; l'architecture des droits (Entitlements, Google Play Billing, Steam DLC) avec le comportement hors ligne ; les risques pour les avis et la confiance ; ce qu'il faut mettre à jour (confidentialité, sécurité des données, classification).
```

### 6. Fiches boutiques
```text
[CONTEXTE] Fiche actuelle : docs/FICHES_BOUTIQUES_2026-10-08.md. Titre retenu : « Tech Empire ».
Rôle : spécialiste ASO Google Play et conversion Steam.
Règles : ne rien promettre que le jeu ne fait pas aujourd'hui ; vouvoiement ; compter les caractères.
Résultat : 3 descriptions courtes (80 caractères au plus) testables en A/B dans la Play Console, la légende de chaque capture, le texte Steam et les 20 tags. Pour chaque tag, dis pourquoi il est juste.
```

---

## 8 prompts nouveaux, utiles pour nous

### 7. Relecture d'un commit (Codex ou autre agent)
```text
[CONTEXTE]
Rôle : relecteur exigeant.
Entrée : le diff du commit, et le passage du plan qu'il prétend réaliser.
Vérifie : que le commit fait ce que dit le plan et rien de plus ; les risques pour les sauvegardes (migration ?) ; les signaux et rafraîchissements ajoutés (coût par image ?) ; les textes affichés au joueur (justes, en français, chiffres cohérents avec le calcul) ; les tests (déterministes, ils échouent bien si on casse la règle) ; les fichiers interdits (.github, AGENTS.md, clés).
Résultat : « à fusionner », « à corriger » ou « à refuser », avec la liste précise et la ligne concernée.
```

### 8. Premières minutes de jeu (FTUE)
```text
[CONTEXTE]
Rôle : designer d'onboarding pour jeux de gestion mobiles.
Entrée : la suite des écrans et des textes de Nora des 15 premières minutes (captures ou description).
Mesure : le temps et le nombre d'actions jusqu'au premier CPU lancé et au premier jour J ; les écrans où un débutant ne sait pas quoi faire ; le jargon non expliqué.
Résultat : un parcours cible (moins de 10 minutes jusqu'au jour J), les textes de Nora réécrits (courts, chaleureux), et ce qu'il faut cacher au début.
```

### 9. Synthèse des retours testeurs
```text
[CONTEXTE]
Rôle : chercheur en expérience joueur.
Entrée : retours bruts des testeurs (messages, avis Play Console, notes vocales retranscrites) + CSV P0 si fournis.
Résultat : thèmes classés par fréquence et par gravité (bloquant, gênant, confort) ; pour chacun, une citation, l'écran concerné, une hypothèse de cause et l'étape du plan qui le traite (ou une nouvelle étape) ; ce qui plaît et qu'il ne faut pas casser.
```

### 10. Lisibilité et accessibilité
```text
[CONTEXTE]
Rôle : spécialiste de l'accessibilité des jeux mobiles.
Entrée : captures 1920×1080 des 7 onglets.
Vérifie : la taille réelle du texte sur Pixel 10, les contrastes (WCAG AA), les couleurs utilisées seules pour porter un sens, les animations (réglage réduit), la lecture d'un écran en moins de 5 secondes (« que dois-je faire ? »).
Résultat : la liste des corrections par onglet, de la plus utile à la moins utile.
```

### 11. Textes, ton et personnages
```text
[CONTEXTE]
Rôle : narrative designer de jeux de gestion chaleureux.
Entrée : les textes de Nora, Camille, Noah, de la presse et des clients (extraits du code).
Vérifie : que chaque personnage a une voix reconnaissable ; les répétitions ; les phrases trop longues pour un téléphone ; les fautes et les accords ; les chiffres affichés qui contredisent le calcul.
Résultat : une fiche de voix par personnage (3 règles, 3 exemples), puis les 30 textes les plus vus réécrits.
```

### 12. Diagnostic d'un ralentissement mesuré par P0
```text
[CONTEXTE]
Rôle : ingénieur de performance Godot.
Entrée : le CSV P0 (colonnes simulation_ms, refresh_ms, other_ms, slow_screen), la sauvegarde de référence et le commit.
Méthode : identifier ce qui domine (la simulation, la reconstruction d'un écran précis ou le rendu) ; proposer une reproduction en headless ; nommer la fonction suspecte. Pas de refonte avant la preuve.
Résultat : le diagnostic, l'expérience pour le confirmer, puis le correctif minimal et la mesure attendue après.
```

### 13. Conformité Play Store avant envoi
```text
[CONTEXTE]
Rôle : responsable de publication Google Play.
Entrée : export_presets.cfg (permissions), page de confidentialité, réponses « Sécurité des données », classification, fiche.
Vérifie : la cohérence entre permissions réelles, confidentialité et sécurité des données ; la mention « achats intégrés » si nécessaire ; les règles du test fermé (12 testeurs, 14 jours) ; le code de version supérieur au précédent ; la cible SDK.
Résultat : une liste « bloquant / à corriger / OK », sans rien envoyer.
```

### 14. Bilan de la semaine (pour Alexandre)
```text
[CONTEXTE]
Rôle : chef de projet.
Entrée : git log de la semaine, les comptes rendus de docs/RETOUR_CODEX_*, les mesures P0.
Résultat, en une page simple, sans jargon :
1. ce qui est fait et vérifié ;
2. ce qui est fait mais pas encore vérifié sur le Pixel ;
3. ce qui bloque et qui doit décider ;
4. les 3 priorités de la semaine suivante.
```
