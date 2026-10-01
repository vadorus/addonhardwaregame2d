# V0.10 — Lot L : sons libres, ambiance détente

Demande d'Alexandre (01/10) : « banque de sons libres mais détente ». Puis : le son doit suivre aussi les fêtes et le temps dehors, en mélange.

## Ce qui change

- **Banque libre CC0**, choisie et téléchargée avec l'accord d'Alexandre. Elle vient de Kenney.nl et OpenGameArt.org, et les crédits sont dans `assets/audio/CREDITS.md`. Elle ajoute environ 7 Mo à l'APK.
- **Musique calme par époque** : 2 morceaux enchaînés par décennie, avec 6 s de silence entre deux, et une boucle d'ambiance sur l'écran d'accueil. Le changement d'époque se fait en fondu. Sans fichier, l'ancienne musique générée prend le relais.
- **Petits sons plus doux** : clic, ouverture, fermeture, notification, décision, erreur. Il y a aussi des **jingles** (steel drum, pizzicato, sax) pour le lancement, la presse (bonne ou mauvaise) et les déblocages. Le son `success` manquait (il ne jouait rien) : il est corrigé.
- **Le QG s'entend**, et le mélange suit ce qu'on voit (`ui/GarageSound.gd`) :

  | Situation | Son |
  |---|---|
  | Beau temps de jour | oiseaux (moins en hiver) |
  | Nuageux | quelques oiseaux, un peu de vent |
  | Pluie | pluie |
  | Orage | tonnerre et pluie |
  | Neige, brouillard | vent doux (généré) |
  | Nuit de mai à septembre (temps sec) | grillons |
  | Équipe présente | clavier, très bas ; plus présent le jour et quand l'équipe grandit |
  | Décembre | clochettes légères (générées) |
  | Début d'une fête | un jingle, une seule fois : Noël, Nouvel An, Halloween, Pâques, été, anniversaire |

  Les couches passent de l'une à l'autre en fondu de 2,5 s. Hors du QG, l'ambiance s'éteint.
- Le réglage du menu devient « **Musique et ambiance** ». Il règle les deux ensemble, sans ligne de plus, pour que le menu tienne toujours sur le téléphone.

## Préparation des fichiers

`tools/audio/build_audio.py` prépare les fichiers :
- volume réglé sans compression (musique −20 LUFS, ambiances −24 à −30 LUFS) ;
- boucles sans coupure, par fondu croisé ;
- vent et clochettes générés ;
- encodage Ogg Vorbis léger.

Les fichiers d'origine ne sont pas dans le dépôt.

## Tests

- `SoundBankScenario` (smoke) vérifie :
  - que les sons viennent bien de la banque ;
  - qu'il y a 2 morceaux par époque et une boucle d'accueil ;
  - les 7 couches d'ambiance ;
  - le mélange : soleil, pluie, orage, neige, nuit d'été, hiver, équipe jour/nuit, Noël ;
  - les jingles de fête, le mixeur et les crédits.
- En mode sans affichage (tests, CI), rien n'est réellement lu : seuls les niveaux sont suivis. Les tests se ferment donc proprement, sans lecture audio restée ouverte.
- Une sonde sous xvfb a vérifié l'enchaînement des morceaux (Contemplation, puis Calm Piano) et les fondus d'ambiance.

## À vérifier à l'oreille sur le Pixel

Les sons ont été choisis sur mesures (volume, brillance, mélodie montante ou descendante), pas à l'écoute. Si un son déplaît, il suffit de changer une ligne dans `build_audio.py` : la banque Kenney compte 100 sons d'interface et 85 jingles.
