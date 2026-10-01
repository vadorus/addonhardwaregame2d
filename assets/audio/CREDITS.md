# Sons du jeu : crédits et licences

Tous les sons de ce dossier sont **libres de droits (CC0, domaine public)**. On peut les utiliser dans un jeu vendu, sans attribution obligatoire. On remercie quand même les auteurs ici.

Ils ont été choisis le 01/10/2026 (lot L) pour une ambiance **calme et détente**. Ils sont préparés par `tools/audio/build_audio.py`, qui :
- règle le volume ;
- fabrique les boucles sans coupure ;
- encode en Ogg Vorbis léger.

## Musique (`music/`)

| Fichier du jeu | Morceau d'origine | Auteur | Source |
|---|---|---|---|
| `menu_ambient.ogg` | Ambient Relaxing Loop | isaiah658 | https://opengameart.org/content/ambient-relaxing-loop |
| `1970s_contemplation.ogg` | Contemplation | joth | https://opengameart.org/content/contemplation-0 |
| `1970s_calm_piano.ogg` | Calm Piano 1 (Vaporware) | cynicmusic | https://opengameart.org/content/calm-piano-1-vaporware |
| `1980s_calm_ambient.ogg` | Calm Ambient 2 (Synthwave 15k) | cynicmusic | https://opengameart.org/content/calm-ambient-2-synthwave-15k |
| `1980s_another_august.ogg` | Another August | cynicmusic | https://opengameart.org/content/another-august |
| `1990s_chill_lofi.ogg` | Chill lofi inspired [loop edit] | qubodup | https://opengameart.org/content/chill-lofi-inspired-loop-edit |
| `1990s_apple_cider.ogg` | Apple Cider | Zane Little Music | https://opengameart.org/content/apple-cider |

## Ambiances du QG (`ambience/`)

| Fichier du jeu | Origine | Auteur | Source |
|---|---|---|---|
| `rain.ogg` | AMB Rain Loop 1 | kresiek-the-furry | https://opengameart.org/content/amb-rain-loop-1 |
| `storm.ogg` | Rain + Long Thunder | wuxiascrub | https://opengameart.org/content/rain-long-thunder |
| `birds.ogg` | Ambient Bird Sounds | isaiah658 | https://opengameart.org/content/ambient-bird-sounds |
| `crickets.ogg` | Crickets Ambient Noise (loopable) | wolfgang | https://opengameart.org/content/crickets-ambient-noise-loopable |
| `keyboard.ogg` | Keyboard Soundpack #1 (extraits « Human Typing », remontés en boucle) | unicaegames | https://opengameart.org/content/keyboard-soundpack-1-typing-and-single-keystrokes |
| `wind.ogg` | généré par `build_audio.py` (bruit filtré) | Tech Empire | — |
| `chimes.ogg` | généré par `build_audio.py` (clochettes de synthèse) | Tech Empire | — |

## Petits sons et jingles (`sfx/`)

| Fichier du jeu | Origine | Auteur | Source |
|---|---|---|---|
| `click`, `open`, `close`, `notify`, `decision`, `error`, `success` | Interface Sounds (`click_002`, `maximize_008`, `minimize_008`, `confirmation_001`, `question_002`, `error_006`, `confirmation_004`) | Kenney | https://kenney.nl/assets/interface-sounds |
| `launch`, `review_good`, `review_bad`, `unlock` | Music Jingles (`STEEL10`, `STEEL02`, `PIZZI11`, `PIZZI16`) | Kenney | https://kenney.nl/assets/music-jingles |
| `fete_noel`, `fete_nouvel_an`, `fete_halloween`, `fete_paques`, `fete_ete`, `fete_anniversaire` | Music Jingles (`STEEL15`, `SAX10`, `PIZZI12`, `PIZZI10`, `STEEL08`, `SAX02`) | Kenney | https://kenney.nl/assets/music-jingles |

Les sons « mois », « trésorerie » et « note de la presse » restent synthétisés dans `scripts/SoundManager.gd`.
