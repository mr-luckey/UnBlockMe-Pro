"""Clearly different soft BGM — slow arpeggio + warm drone."""
import math
import os
import struct
import wave

out = r"d:\Playstore\UnBlockMe-Pro\assets\audio\bgm_forest.wav"
rate = 22050
dur = 60.0
n = int(rate * dur)

# Distinct from previous pad: slow rising arpeggio in D major-ish
arp = [146.83, 185.00, 220.00, 293.66, 369.99, 293.66, 220.00, 185.00]
note_dur = 0.75
drone = [73.42, 110.00]  # D2 A2


def noise(i):
    x = (i * 214013 + 2531011) & 0x7FFFFFFF
    return 1.0 - 2.0 * x / 0x7FFFFFFF


samples = []
for i in range(n):
    t = i / rate
    s = 0.0

    # Warm drone bed
    for f in drone:
        s += math.sin(2 * math.pi * f * t) * 0.09
        s += math.sin(2 * math.pi * f * 1.004 * t) * 0.05

    # Soft plucked arpeggio
    ni = int(t / note_dur) % len(arp)
    local = t - int(t / note_dur) * note_dur
    env = math.exp(-3.5 * local) * (1.0 if local < note_dur else 0.0)
    # slight attack
    if local < 0.02:
        env *= local / 0.02
    f = arp[ni]
    s += math.sin(2 * math.pi * f * t) * 0.11 * env
    s += math.sin(2 * math.pi * f * 2 * t) * 0.03 * env

    s += noise(i) * 0.005
    breathe = 0.9 + 0.1 * math.sin(2 * math.pi * t / 18.0)
    loop = 1.0
    if t < 2.0:
        loop = t / 2.0
    elif t > dur - 2.0:
        loop = (dur - t) / 2.0

    samples.append(s * breathe * max(0.0, loop) * 0.95)

with wave.open(out, "w") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(rate)
    w.writeframes(
        b"".join(
            struct.pack("<h", max(-32767, min(32767, int(v * 32767))))
            for v in samples
        )
    )
print("wrote", out, os.path.getsize(out))
