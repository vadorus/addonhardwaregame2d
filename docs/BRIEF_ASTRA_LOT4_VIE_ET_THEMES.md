# Brief graphismes — lot 4 pour Astra : des personnages qui bougent vraiment, et des thèmes du moment soignés

Retour d'Alexandre après avoir joué (02/10/2026) : « les bonhommes ne sont pas animés, c'est juste une oscillation » ;
« Noël, t'aurais pu faire mieux : des guirlandes sur les bordures ». Le jeu doit être **au niveau ou au-dessus** de
Game Dev Tycoon, PC Tycoon et Hardware Tycoon en design et en ambiance.

Côté code (Claude, déjà fait le 02/10) : le **thème du moment** suit la vraie date (Halloween du 1er au 31 octobre,
fêtes du 1er novembre au 6 janvier), avec une guirlande lumineuse dessinée en code, les toiles, les citrouilles et le
sapin du lot 3. Voir `docs/reviews/V010_THEME_DU_MOMENT.md` et ses captures. Ton lot remplace ce qui est dessiné en code.

Même style que tout le jeu : peint, chaleureux, rétro années 70-80, bois / crème / ambre, vue isométrique ~30°.
Fond **transparent** (PNG RGBA) sauf mention contraire. Aucune marque, aucun texte lisible.

## K5 — Les personnages s'animent (priorité 1)

Aujourd'hui : 14 personnages (`assets/art/v010/J2_personnages/perso_NN_<pose>.png`, 261 × 272 px, 4 poses fixes :
bureau, réflexion, joie, inquiet). Le code les fait seulement osciller.

À livrer, **en planches de frames** (une image par frame, même cadrage exact, même taille 261 × 272, pieds au même endroit) :

| Animation | Qui | Frames | Fichiers |
|---|---|---|---|
| **Tape au clavier** (bras et mains qui bougent, tête qui suit l'écran) | les 11 salariés (looks 1, 2, 3, 5 à 12) | 4 | `perso_NN_clavier_1.png` … `_4.png` |
| **Marche** vers la droite (profil 3/4) | Nora (4), client (13), journaliste (14) | 6 | `perso_NN_marche_1.png` … `_6.png` |
| **Boire un café** debout | 3 salariés au choix | 4 | `perso_NN_cafe_1.png` … `_4.png` |

Ordre : d'abord **un seul personnage** en « clavier » (le n° 1) pour valider la méthode sur le Pixel, puis les autres.
Le code retournera l'image pour marcher vers la gauche.

Dossier : `assets/art/v010/K5_animations/`.

## J9 — Thèmes du moment soignés (priorité 2)

| Fichier | Ce qu'on doit voir | Taille |
|---|---|---|
| `ecran_titre_halloween.webp` | **le même écran titre** (garage au crépuscule), retouché : citrouilles éclairées sur l'allée, guirlande orange et violette sur le toit du garage, brume légère, lune | 1774 × 887, WebP 85 |
| `ecran_titre_noel.webp` | le même, retouché : neige, guirlandes multicolores sur le toit et la clôture, sapin décoré devant le garage, fenêtres chaudes | 1774 × 887, WebP 85 |
| `bordure_guirlande_noel.png` | **bande de guirlande lumineuse** qui se répète sans couture (bord gauche = bord droit), fil vert sombre, ampoules rétro multicolores, sans halo | 512 × 48 |
| `bordure_guirlande_halloween.png` | même chose en orange et violet, petites chauves-souris en papier accrochées | 512 × 48 |
| `coin_toile.png` | toile d'araignée de coin, plus fine et plus discrète que celle du lot 3 | 160 × 160 |
| `chauve_souris_1.png` … `_4.png` | une chauve-souris en vol, 4 frames d'ailes | 96 × 64 |

Dossier : `assets/art/v010/J9_themes/`.

## Contrôles attendus (comme les lots précédents)

PNG RGBA (ou WebP pour les écrans titre), dimensions exactes, détourage propre, frames parfaitement alignées
(même cadrage : seul ce qui bouge change). Un `LISEZMOI.txt` avec l'inventaire et les empreintes SHA-256.
Claude intègre, vérifie sur le Pixel, fait une capture et renvoie un retour précis.
