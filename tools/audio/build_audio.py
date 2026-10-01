#!/usr/bin/env python3
"""Lot L — prépare les sons libres (CC0) du jeu à partir des fichiers d'origine.

Usage : python3 tools/audio/build_audio.py <dossier_sources> [dossier_sortie]
  <dossier_sources> contient les fichiers d'origine (voir assets/audio/CREDITS.md) et les zips
  Kenney / unicae déjà extraits dans un sous-dossier x/.
Le script : normalise le volume (EBU R128), fabrique des boucles sans coupure (fondu croisé),
génère le vent et les clochettes (créés ici, donc libres) et encode en Ogg Vorbis léger.
Nécessite ffmpeg et numpy.
"""
import os, subprocess, sys
import numpy as np

SRC = sys.argv[1]
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
X = os.path.join(SRC, "x")
RATE = 32000

def load(path, rate=RATE, channels=1):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", str(channels), "-ar", str(rate),
        "-f", "f32le", "-"], capture_output=True, check=True).stdout
    data = np.frombuffer(raw, dtype=np.float32).copy()
    return data.reshape(-1, channels)

def save(data, path, rate=RATE, quality=0, lufs=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    channels = data.shape[1]
    tmp = path + ".tmp.f32"
    data.astype(np.float32).tofile(tmp)
    if lufs is not None:
        # Gain linéaire (pas de compression) : on vise `lufs` sans dépasser -3 dB de crête.
        gain = 10 ** ((lufs - measure_lufs(tmp, rate, channels)) / 20)
        gain = min(gain, 0.7 / max(1e-6, float(np.abs(data).max())))
        (data * gain).astype(np.float32).tofile(tmp)
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(rate), "-ac", str(channels), "-i", tmp]
    cmd += ["-c:a", "libvorbis", "-q:a", str(quality), path]
    subprocess.run(cmd, check=True)
    os.remove(tmp)

def measure_lufs(raw_path, rate, channels):
    log = subprocess.run(["ffmpeg", "-hide_banner", "-f", "f32le", "-ar", str(rate), "-ac", str(channels), "-i", raw_path,
        "-af", "ebur128=framelog=quiet", "-f", "null", "-"], capture_output=True, text=True).stderr
    values = [line.split()[1] for line in log.splitlines() if line.strip().startswith("I:")]
    return float(values[-1])

def loop(data, fade_s=2.0, rate=RATE, length_s=None):
    """Boucle sans coupure : la fin se fond dans le début."""
    if length_s is not None:
        data = data[: int((length_s + fade_s) * rate)]
    f = int(fade_s * rate)
    body = data[f:].copy()
    ramp = np.linspace(0.0, 1.0, f)[:, None]
    # equal-power
    body[-f:] = body[-f:] * np.cos(ramp * np.pi / 2) + data[:f] * np.sin(ramp * np.pi / 2)
    return body

def music(name, src, out_name):
    data = load(os.path.join(SRC, src), rate=RATE, channels=2)
    if not out_name.startswith("menu"):  # le thème du menu est une boucle : pas de fondu
        # fondu de 1,5 s à la fin pour enchaîner en douceur
        f = int(1.5 * RATE)
        data[-f:] *= np.linspace(1.0, 0.0, f)[:, None]
    save(data, os.path.join(OUT, "music", out_name), quality=0, lufs=-20)
    print("music", out_name)

def ambience(src, out_name, lufs, length_s=None, fade_s=2.0):
    data = load(os.path.join(SRC, src))
    save(loop(data, fade_s, length_s=length_s), os.path.join(OUT, "ambience", out_name), quality=0, lufs=lufs)
    print("ambience", out_name)

def wind(out_name, seconds=30.0, seed=7):
    rng = np.random.default_rng(seed)
    n = int((seconds + 3.0) * RATE)
    white = rng.standard_normal(n)
    brown = np.cumsum(white)
    brown -= np.convolve(brown, np.ones(4001) / 4001, mode="same")  # retire la dérive
    # passe-bas doux (souffle) + rafales lentes
    pink = brown + 0.08 * np.convolve(white, np.ones(6) / 6, mode="same")  # un peu de souffle aigu
    k = np.exp(-np.arange(60) / 12.0); k /= k.sum()
    soft = np.convolve(pink, k, mode="same")
    t = np.arange(n) / RATE
    gust = 0.55 + 0.25 * np.sin(2 * np.pi * t / 11.0) + 0.2 * np.sin(2 * np.pi * t / 4.3 + 1.0)
    data = (soft * gust)[:, None]
    data /= np.abs(data).max()
    save(loop(data, 3.0), os.path.join(OUT, "ambience", out_name), quality=0, lufs=-28)
    print("ambience", out_name, "(généré)")

def chimes(out_name, seconds=24.0, seed=11):
    """Clochettes de fête très légères : notes de cloche (partiels inharmoniques) au hasard."""
    rng = np.random.default_rng(seed)
    n = int(seconds * RATE)
    data = np.zeros(n + RATE * 3)
    scale = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0]  # pentatonique de do, aigu
    t_note = np.arange(int(2.5 * RATE)) / RATE
    at = 0.3
    while at < seconds:
        f = scale[rng.integers(len(scale))]
        tone = (np.sin(2 * np.pi * f * t_note) + 0.35 * np.sin(2 * np.pi * f * 2.76 * t_note) * np.exp(-t_note / 0.25)
            + 0.18 * np.sin(2 * np.pi * f * 5.4 * t_note) * np.exp(-t_note / 0.12))
        tone *= np.exp(-t_note / 0.7) * np.minimum(1.0, t_note / 0.003) * rng.uniform(0.4, 1.0)
        i = int(at * RATE)
        data[i:i + len(tone)] += tone
        at += rng.uniform(0.35, 1.6)
    # la queue retombe au début : boucle continue
    data[:3 * RATE] += data[n:n + 3 * RATE]
    data = data[:n, None]
    data /= np.abs(data).max()
    save(data, os.path.join(OUT, "ambience", out_name), quality=0, lufs=-30)
    print("ambience", out_name, "(généré)")

def keyboard(out_name, seconds=24.0, seed=5):
    """L'équipe qui tape : des passages de frappe humaine séparés par des silences."""
    rng = np.random.default_rng(seed)
    base = os.path.join(X, "unicae_games_keyboard_soundpack_1_0", "Human Typing")
    takes = [load(os.path.join(base, "human_vel-%03d.wav" % i))[:, 0] for i in (4, 5, 6, 7)]
    n = int(seconds * RATE)
    data = np.zeros(n + 10 * RATE)
    at = 0.5
    while at < seconds:
        take = takes[rng.integers(len(takes))]
        cut = take[: int(rng.uniform(1.5, 3.5) * RATE)].copy()
        f = int(0.15 * RATE)
        cut[:f] *= np.linspace(0, 1, f); cut[-f:] *= np.linspace(1, 0, f)
        i = int(at * RATE)
        data[i:i + len(cut)] += cut * rng.uniform(0.5, 1.0)
        at += len(cut) / RATE + rng.uniform(1.5, 4.0)
    data[: 10 * RATE] += data[n:n + 10 * RATE]
    data = data[:n, None]
    save(data, os.path.join(OUT, "ambience", out_name), quality=0, lufs=-30)
    print("ambience", out_name)

def sfx(src, out_name, peak_db=-6.0):
    data = load(src, rate=44100)
    data = data / max(1e-6, np.abs(data).max()) * (10 ** (peak_db / 20))
    save(data, os.path.join(OUT, "sfx", out_name), rate=44100, quality=3)
    print("sfx", out_name)

MUSIC = [
    ("Ambient-Loop-isaiah658_0.ogg", "menu_ambient.ogg"),
    ("Contemplation.mp3", "1970s_contemplation.ogg"),
    ("003_Vaporware_2.mp3", "1970s_calm_piano.ogg"),
    ("002_Synthwave_15k_0.mp3", "1980s_calm_ambient.ogg"),
    ("013_Another_August_0.mp3", "1980s_another_august.ogg"),
    ("chilllofir-loop.ogg", "1990s_chill_lofi.ogg"),
    ("apple_cider.ogg", "1990s_apple_cider.ogg"),
]
UI = os.path.join(X, "kenney_interface-sounds", "Audio")
JG = os.path.join(X, "kenney_music-jingles", "Audio")
SFX = [
    (os.path.join(UI, "click_002.ogg"), "click.ogg", -10.0),
    (os.path.join(UI, "maximize_008.ogg"), "open.ogg", -9.0),
    (os.path.join(UI, "minimize_008.ogg"), "close.ogg", -10.0),
    (os.path.join(UI, "confirmation_001.ogg"), "notify.ogg", -8.0),
    (os.path.join(UI, "question_002.ogg"), "decision.ogg", -8.0),
    (os.path.join(UI, "error_006.ogg"), "error.ogg", -9.0),
    (os.path.join(UI, "confirmation_004.ogg"), "success.ogg", -8.0),
    (os.path.join(JG, "Steel jingles", "jingles_STEEL10.ogg"), "launch.ogg", -6.0),
    (os.path.join(JG, "Steel jingles", "jingles_STEEL02.ogg"), "review_good.ogg", -6.0),
    (os.path.join(JG, "Pizzicato jingles", "jingles_PIZZI11.ogg"), "review_bad.ogg", -9.0),
    (os.path.join(JG, "Pizzicato jingles", "jingles_PIZZI16.ogg"), "unlock.ogg", -7.0),
    (os.path.join(JG, "Steel jingles", "jingles_STEEL15.ogg"), "fete_noel.ogg", -7.0),
    (os.path.join(JG, "Sax jingles", "jingles_SAX10.ogg"), "fete_nouvel_an.ogg", -7.0),
    (os.path.join(JG, "Pizzicato jingles", "jingles_PIZZI12.ogg"), "fete_halloween.ogg", -7.0),
    (os.path.join(JG, "Pizzicato jingles", "jingles_PIZZI10.ogg"), "fete_paques.ogg", -7.0),
    (os.path.join(JG, "Steel jingles", "jingles_STEEL08.ogg"), "fete_ete.ogg", -7.0),
    (os.path.join(JG, "Sax jingles", "jingles_SAX02.ogg"), "fete_anniversaire.ogg", -7.0),
]

if __name__ == "__main__":
    for src, name in MUSIC:
        music(name, src, name)
    ambience("amb_rain_loop_1.ogg", "rain.ogg", -24, length_s=40)
    ambience("rain-thunder.ogg", "storm.ogg", -22)
    ambience("birds-isaiah658.ogg", "birds.ogg", -26)
    ambience("crickets-oneloop.mp3", "crickets.ogg", -28, fade_s=1.0)
    wind("wind.ogg")
    chimes("chimes.ogg")
    keyboard("keyboard.ogg")
    for src, name, peak in SFX:
        sfx(src, name, peak)
