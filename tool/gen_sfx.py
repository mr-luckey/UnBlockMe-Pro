import math
import os
import struct
import wave

out = r"d:\Playstore\UnBlockMe-Pro\assets\audio"
os.makedirs(out, exist_ok=True)


def write_wav(path, samples, rate=22050):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)


def envelope(i, n, attack=0.01, release=0.25):
    t = i / max(n, 1)
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return a * r


rate = 22050

# Soft wood knock / thud (blocked hit)
dur = 0.2
n = int(rate * dur)
hit = []
for i in range(n):
    t = i / rate
    thud = math.sin(2 * math.pi * 95 * t) * math.exp(-18 * t)
    thud2 = math.sin(2 * math.pi * 160 * t) * math.exp(-22 * t) * 0.45
    click = math.sin(2 * math.pi * 520 * t) * math.exp(-55 * t) * 0.22
    noise = (
        (1 - 2 * ((i * 1103515245 + 12345) & 0x7FFFFFFF) / 0x7FFFFFFF)
        * math.exp(-40 * t)
        * 0.08
    )
    hit.append((thud + thud2 + click + noise) * 0.6 * envelope(i, n, 0.002, 0.35))
write_wav(os.path.join(out, "sfx_hit.wav"), hit, rate)

# Soft slide / whoosh
dur = 0.11
n = int(rate * dur)
slide = []
for i in range(n):
    t = i / rate
    noise = 1 - 2 * ((i * 1664525 + 1013904223) & 0x7FFFFFFF) / 0x7FFFFFFF
    tone = math.sin(2 * math.pi * (280 + 120 * t) * t) * 0.15
    slide.append(
        (noise * 0.12 + tone) * math.exp(-14 * t) * envelope(i, n, 0.01, 0.4) * 0.38
    )
write_wav(os.path.join(out, "sfx_slide.wav"), slide, rate)

# Soft win chime
dur = 0.55
n = int(rate * dur)
win = []
freqs = [523.25, 659.25, 783.99]
for i in range(n):
    t = i / rate
    s = 0.0
    for k, f in enumerate(freqs):
        delay = k * 0.08
        if t < delay:
            continue
        tt = t - delay
        s += math.sin(2 * math.pi * f * tt) * math.exp(-3.2 * tt) * (0.28 - k * 0.04)
    win.append(s * envelope(i, n, 0.01, 0.35))
write_wav(os.path.join(out, "sfx_win.wav"), win, rate)

# Soft tap / UI
dur = 0.06
n = int(rate * dur)
tap = []
for i in range(n):
    t = i / rate
    s = math.sin(2 * math.pi * 880 * t) * math.exp(-40 * t) * 0.25
    tap.append(s)
write_wav(os.path.join(out, "sfx_tap.wav"), tap, rate)

print("ok", os.listdir(out))
