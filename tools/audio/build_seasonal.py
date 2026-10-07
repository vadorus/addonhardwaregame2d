#!/usr/bin/env python3
"""Musiques de saison (07/10/2026) — prépare les morceaux libres (CC0) d'Halloween et des fêtes.

Usage : python3 tools/audio/build_seasonal.py <dossier_sources> [dossier_sortie]
  <dossier_sources> contient les fichiers d'origine listés dans SOURCES (voir assets/audio/CREDITS.md).
Même traitement que build_audio.py : volume normalisé (-20 LUFS, sans compression), Ogg Vorbis léger.
Les boucles courtes donnent deux fichiers :
  - menu_<saison>.ogg : la boucle brute, rejouée sans fin sur le menu titre ;
  - <saison>_<nom>.ogg : la boucle jouée trois fois avec un fondu final, pour la liste de lecture en partie.
Nécessite ffmpeg et numpy.
"""
import os, subprocess, sys
import numpy as np

SRC = sys.argv[1]
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
RATE = 32000

# (fichier d'origine, nom dans le jeu, boucle ?)
SOURCES = [
    ("lanterns_in_the_hollowed_forest_loop.flac", "halloween_lanternes", True),
    ("caper_0.mp3", "halloween_caper", False),
    ("Halloween_Hullabaloo.mp3", "halloween_hullabaloo", False),
    ("wintery_loop.wav", "fetes_hiver", True),
    ("Christmas_synths.ogg", "fetes_synthes", False),
    ("JingleBells_0.mp3", "fetes_jingle_bells", False),
]
MENU = {"halloween_lanternes": "menu_halloween", "fetes_hiver": "menu_fetes"}

def load(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "2", "-ar", str(RATE), "-f", "f32le", "-"],
        capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).copy().reshape(-1, 2)

def measure_lufs(raw_path):
    log = subprocess.run(["ffmpeg", "-hide_banner", "-f", "f32le", "-ar", str(RATE), "-ac", "2", "-i", raw_path,
        "-af", "ebur128=framelog=quiet", "-f", "null", "-"], capture_output=True, text=True).stderr
    values = [line.split()[1] for line in log.splitlines() if line.strip().startswith("I:")]
    return float(values[-1])

def save(data, name, lufs=-20.0):
    path = os.path.join(OUT, "music", name + ".ogg")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp.f32"
    data.astype(np.float32).tofile(tmp)
    gain = 10 ** ((lufs - measure_lufs(tmp)) / 20)
    gain = min(gain, 0.7 / max(1e-6, float(np.abs(data).max())))
    (data * gain).astype(np.float32).tofile(tmp)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "2", "-i", tmp,
        "-c:a", "libvorbis", "-q:a", "0", path], check=True)
    os.remove(tmp)
    print("music", name, "%.1fs" % (len(data) / RATE))

def fade_out(data, seconds):
    f = int(seconds * RATE)
    data[-f:] *= np.linspace(1.0, 0.0, f)[:, None]
    return data

for src, name, is_loop in SOURCES:
    data = load(os.path.join(SRC, src))
    # On retire le silence de tête (certains fichiers démarrent après une seconde de vide).
    start = int(np.argmax(np.abs(data).max(1) > 0.003))
    data = data[start:] if not is_loop else data
    if is_loop:
        save(data.copy(), MENU[name])
        data = np.concatenate([data, data, data])
        save(fade_out(data, 4.0), name)
    else:
        save(fade_out(data, 1.5), name)
