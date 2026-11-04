#!/usr/bin/env python3
"""Generate original deterministic mono pack sounds; no external samples."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050


def write(name, seconds, sample):
    rng = random.Random(724)
    path = ROOT / "assets/audio" / (name + ".wav")
    path.parent.mkdir(parents=True, exist_ok=True)
    data = bytearray()
    for i in range(int(RATE * seconds)):
        t = i / RATE
        value = max(-0.9, min(0.9, sample(t, seconds, rng)))
        data.extend(struct.pack("<h", int(value * 32767)))
    with wave.open(str(path), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(data)
    print(path.relative_to(ROOT), len(data), "PCM bytes")


def tear(t, seconds, rng):
    envelope = math.sin(math.pi * t / seconds) ** 1.4
    rustle = rng.uniform(-1, 1) * (0.35 + 0.3 * math.sin(t * 145))
    swoop = math.sin(2 * math.pi * (220 * t + 330 * t * t)) * 0.12
    return (rustle + swoop) * envelope * 0.4


def elite(t, seconds, rng):
    swell = math.sin(math.pi * t / seconds) ** 1.2
    chord = sum(math.sin(2 * math.pi * f * t) for f in (164.81, 246.94, 329.63)) / 3
    rustle = tear(max(0, t - 0.57), 0.38, rng) if 0.57 < t < 0.95 else 0
    return chord * swell * 0.16 + rustle


def card(t, seconds, rng):
    click = rng.uniform(-1, 1) * math.exp(-t * 95) * 0.35
    shimmer = math.sin(2 * math.pi * 880 * t) * math.exp(-t * 15) * 0.1
    return (click + shimmer) * min(1, t * 1500)


if __name__ == "__main__":
    write("pack_tear", 0.5, tear)
    write("elite_charge", 1.7, elite)
    write("card_reveal", 0.25, card)
