# Audit du son et de la musique — 08/10/2026

Base : `v013/demo-octobre` (`3ee49a8`).

Sources :
- lecture de `scripts/SoundManager.gd` ;
- inventaire de `assets/audio/` (39 fichiers, 11,5 Mo) ;
- mesure du volume perçu (norme EBU R128, LUFS) et des crêtes avec `ffmpeg`, dans le cloud.

**Genre et ton :** gestion calme et chaleureuse, du garage des années 70 à l'empire. C'est de la musique d'ambiance par époque, pas de la musique d'action.

**Configuration actuelle :**
- moteur audio natif de Godot, en stéréo ;
- pas de son spatialisé, et il n'en faut pas : c'est un jeu d'interface ;
- pas de bus audio personnalisés : tout passe par `Master`.

## 1. Architecture audio

| Élément | Actuel | Constat |
|---|---|---|
| Bus | Aucun fichier `default_bus_layout.tres` : un seul bus `Master` | **Pas d'atténuation automatique possible** (la musique ne baisse pas sous les sons importants) ; **pas de limiteur** sur la sortie ; les volumes ne se règlent que lecteur par lecteur |
| Voix d'effets sonores | Réserve de 6 `AudioStreamPlayer` ; quand les 6 jouent, `_players[0]` est coupé | Le son interrompu est arbitraire, pas forcément le plus ancien ni le moins important |
| Musique | 1 lecteur ; fondu de 1,2 s pour sortir et de 2,5 s pour entrer ; 6 s de silence entre deux morceaux ; boucle synthétisée de secours | Bon pour le calme. **Rien après les années 1990** : de 2000 à 2030, ce sont les mêmes deux morceaux pendant 30 ans de jeu |
| Ambiances | 7 couches (oiseaux, carillon, grillons, clavier, pluie, orage, vent), mélangées selon la météo, l'heure et les fêtes ; arrêtées quand elles retombent à 0 | Bien conçu. Il faut juste limiter le nombre de couches audibles en même temps sur mobile |
| Effets sonores | 17 fichiers (interface, presse, lancement, fêtes) ; synthèse de secours si un fichier manque | Couverture bonne ; ils sont joués 47 fois dans le code, dont 11 clics |
| Réglages | Volume des effets (0,8) et de la musique (0,45), plus coupure, enregistrés dans `user://settings.cfg` | Pas de volume séparé pour les ambiances |

**Mesures de volume :**
- les **15 musiques sont toutes normalisées à −20 LUFS** (de −21,4 à −20,0), avec des crêtes entre −2,3 et −8,9 dB : c'est très propre ;
- les **ambiances** sont entre −23 et −32 LUFS, bien en dessous de la musique, comme il faut ;
- les **effets** les plus forts (succès à −17,4 LUFS, jour J à −20) passent au-dessus de la musique jouée à 0,45, soit environ −27 LUFS à la sortie ;
- **risque** : sur un haut-parleur de téléphone, effets, musique et jusqu'à 3 ambiances s'additionnent sans limiteur, d'où une saturation possible quand l'orage ou l'ambiance des années 80 (crêtes à −2,3 / −2,4 dB) coïncident avec un effet.

## 2. Musique adaptative

Il n'y a pas de combat ni d'exploration : les **états de jeu** sont ceux de la gestion. On part des morceaux existants et on garde l'ajout de musiques pour plus tard.

| État | Déclencheur | Musique | Transition |
|---|---|---|---|
| Menu | Écran titre | `menu_*` (ou version de saison) | Fondu de 2,5 s |
| Époque (normal) | Année de jeu | Morceaux de l'époque, avec 6 s de silence entre deux | Fondu de 2,5 s au changement d'époque, avec un effet `unlock` |
| Saison | Vraie date (`LiveTheme`) | Morceaux Halloween ou fêtes | Remplace l'époque, fondu de 2,5 s |
| **Tension** | Moins de 3 mois de trésorerie, rappel produit, crise de réputation | **Même morceau, filtré** (passe-bas vers 1,2 kHz) et −3 dB sur le bus Musique | Rampe de 1,5 s ; on revient quand la cause disparaît |
| **Jour J, suspense** | Ouverture des notes de la presse | Musique baissée à −12 dB (atténuation) | 300 ms |
| **Jour J, verdict** | Note moyenne affichée | Court jingle `review_good` ou `review_bad`, puis la musique remonte | Remontée en 1,5 s |
| Célébration | Premier CPU, record, 1re place | Jingle `success` ou `unlock` ; musique baissée à −8 dB pendant 2 s | Remontée en 1,5 s |
| Pause / menu ouvert | Temps arrêté, fenêtre de menu | Musique −6 dB, ambiances −10 dB | 400 ms |

Plus tard, avec de nouvelles musiques :
- **découpage horizontal** : un morceau par époque à partir des années 2000 (2000s, 2010s, 2020s), dans le même esprit calme (lo-fi, synthés doux) ;
- **couches verticales** facultatives : une couche « studio », plus rythmée, qui monte doucement quand l'entreprise grandit (palier de locaux).

## 3. Budget par plateforme

| Catégorie | Android | PC / Steam | Chargement |
|---|---|---|---|
| Musique | Ogg Vorbis, 32 kHz, stéréo, ~96 kbit/s (l'actuel convient) | Ogg Vorbis, 44,1 kHz, stéréo, ~128 à 160 kbit/s (facultatif) | En flux (*streaming*) : un morceau à la fois, plus un en fondu |
| Ambiances | Ogg Vorbis, 32 kHz, **mono**, ~48 kbit/s (l'actuel convient) | Pareil | En flux ; **3 couches audibles au plus** sur mobile, 5 sur PC |
| Effets courts (< 1,5 s) | **WAV en QOA** (compression intégrée à Godot 4.3+, quasi sans latence) ou IMA-ADPCM, 22 à 32 kHz, mono | WAV en QOA, 44,1 kHz, mono | Préchargés en mémoire (≈ 1 Mo au total) |
| Jingles (fêtes, lancement) | Ogg Vorbis, 32 kHz, mono | Ogg Vorbis, 44,1 kHz | Préchargés |
| Voix simultanées | Effets : 8, musique : 2, ambiances : 3 | Effets : 12, musique : 2, ambiances : 5 | — |
| Volume perçu cible | Musique −20 LUFS (déjà) ; effets importants −18 à −16 LUFS ; ambiances −26 à −30 LUFS ; limiteur sur `Master` à −1 dB | Pareil, sans limiteur obligatoire mais conseillé | — |

## 4. Constats, par gravité

| # | Gravité | Constat |
|---|---|---|
| 1 | Élevée | Pas de bus : pas d'atténuation pour le jour J (le suspense prévu en G2 en a besoin), pas de limiteur sur la sortie |
| 2 | Moyenne | Plus de musique nouvelle après 1990 : 40 ans de jeu sur les mêmes deux morceaux |
| 3 | Moyenne | Pas d'état « tension » : la musique ne dit rien quand l'entreprise est en danger |
| 4 | Faible | Quand les 6 voix d'effets sont occupées, le son coupé est arbitraire |
| 5 | Faible | Effets en Ogg : petite latence de décodage sur Android ; le QOA est plus réactif |
| 6 | Faible | Pas de volume séparé pour les ambiances dans les réglages |

Pas de problème de mémoire : 11,5 Mo sur le disque, avec la musique et les ambiances en flux.
