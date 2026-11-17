#!/usr/bin/env python3
"""Generate the game's small, original synthesizer sound effects."""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUTPUT = Path(__file__).resolve().parents[1] / "src" / "audio"
random.seed(1481)


def synth(name, duration, events, noise=0.0, sweep=0.0):
    samples = []
    count = int(RATE * duration)
    for i in range(count):
        t = i / RATE
        envelope = min(1.0, t * 90) * math.exp(-t * 5.2)
        value = 0.0
        for start, frequency, gain, length in events:
            local = t - start
            if 0 <= local < length:
                note_env = min(1.0, local * 65) * math.exp(-local * 4.0)
                bend = frequency + sweep * local
                phase = 2 * math.pi * bend * local
                value += math.sin(phase) * gain * note_env
                value += math.sin(phase * 2.01) * gain * 0.16 * note_env
        if noise:
            value += random.uniform(-1, 1) * noise * envelope
        samples.append(max(-1.0, min(1.0, value * envelope)))

    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(b"".join(struct.pack("<h", int(sample * 26000)) for sample in samples))


synth("shot", 0.16, [(0, 780, 0.35, 0.13)], sweep=-2300, noise=0.06)
synth("hit", 0.16, [(0, 165, 0.56, 0.14), (0, 92, 0.28, 0.13)], noise=0.3, sweep=-500)
synth("pickup", 0.42, [(0, 660, 0.28, 0.18), (0.09, 880, 0.25, 0.2),
                       (0.18, 1320, 0.22, 0.22)], noise=0.015)
synth("levelup", 0.82, [(0, 523, 0.24, 0.45), (0.13, 659, 0.22, 0.48),
                        (0.26, 784, 0.2, 0.5), (0.4, 1047, 0.19, 0.52),
                        (0.56, 1319, 0.17, 0.45)], noise=0.01)
synth("fire", 0.38, [(0, 145, 0.25, 0.34), (0.04, 260, 0.15, 0.28)], noise=0.24, sweep=260)
synth("ice", 0.52, [(0, 880, 0.23, 0.36), (0.07, 1175, 0.2, 0.36),
                    (0.16, 1568, 0.15, 0.32)], noise=0.015)
synth("lightning", 0.28, [(0, 1250, 0.32, 0.23), (0.04, 460, 0.2, 0.2)],
      noise=0.13, sweep=-2700)
synth("shadow", 0.4, [(0, 196, 0.25, 0.34), (0.07, 293, 0.2, 0.3)], noise=0.045, sweep=-130)
synth("hurt", 0.32, [(0, 115, 0.35, 0.28), (0.02, 78, 0.22, 0.27)], noise=0.2, sweep=-240)
synth("gameover", 0.9, [(0, 392, 0.24, 0.78), (0.18, 294, 0.2, 0.69),
                        (0.36, 220, 0.17, 0.5)], noise=0.025, sweep=-70)
synth("boss", 0.95, [(0, 82, 0.42, 0.82), (0.14, 110, 0.28, 0.7),
                     (0.32, 164, 0.2, 0.58)], noise=0.22, sweep=-48)
synth("horde", 1.25, [(0, 55, 0.48, 1.12), (0.12, 73, 0.32, 0.92),
                      (0.34, 110, 0.2, 0.74)], noise=0.32, sweep=-36)
synth("attack-warrior", 0.32, [(0, 210, 0.35, 0.24), (0.04, 130, 0.24, 0.23)],
      noise=0.12, sweep=-520)
synth("attack-mage", 0.46, [(0, 523, 0.22, 0.34), (0.08, 784, 0.2, 0.32),
                            (0.16, 1047, 0.18, 0.28)], noise=0.025)
synth("attack-archer", 0.25, [(0, 880, 0.24, 0.16), (0.035, 1320, 0.17, 0.15)],
      noise=0.04, sweep=-600)
synth("attack-lango", 0.42, [(0, 165, 0.25, 0.32), (0.08, 330, 0.16, 0.24),
                             (0.17, 247, 0.2, 0.22)], noise=0.16, sweep=-180)
synth("attack-kalengue", 0.34, [(0, 740, 0.21, 0.22), (0.07, 988, 0.2, 0.2),
                                (0.14, 1480, 0.16, 0.18)], noise=0.035)
synth("attack-bronha", 0.22, [(0, 210, 0.32, 0.12), (0.035, 1560, 0.2, 0.09),
                              (0.08, 1120, 0.16, 0.08)], noise=0.14, sweep=-1400)
synth("upgrade-warrior", 0.68, [(0, 196, 0.25, 0.52), (0.12, 294, 0.2, 0.48),
                                (0.28, 392, 0.18, 0.38)], noise=0.08)
synth("upgrade-mage", 0.7, [(0, 659, 0.2, 0.52), (0.12, 880, 0.19, 0.5),
                            (0.28, 1319, 0.17, 0.4)], noise=0.015)
synth("upgrade-archer", 0.64, [(0, 440, 0.18, 0.5), (0.13, 587, 0.2, 0.45),
                               (0.3, 784, 0.18, 0.36)], noise=0.025)
synth("upgrade-lango", 0.72, [(0, 110, 0.28, 0.55), (0.16, 165, 0.23, 0.48),
                              (0.34, 220, 0.18, 0.36)], noise=0.12, sweep=28)
synth("upgrade-kalengue", 0.68, [(0, 587, 0.2, 0.5), (0.14, 784, 0.19, 0.46),
                                 (0.3, 1175, 0.18, 0.36)], noise=0.025)
synth("upgrade-bronha", 0.72, [(0, 392, 0.2, 0.48), (0.12, 587, 0.2, 0.44),
                               (0.28, 784, 0.18, 0.4), (0.42, 1175, 0.16, 0.35)],
      noise=0.035)
synth("stage", 0.62, [(0, 440, 0.2, 0.4), (0.12, 554, 0.2, 0.42),
                      (0.24, 659, 0.19, 0.42)], noise=0.01)
synth("victory", 1.0, [(0, 523, 0.22, 0.85), (0.14, 659, 0.22, 0.8),
                       (0.28, 784, 0.2, 0.72), (0.46, 1047, 0.18, 0.65),
                       (0.62, 1319, 0.16, 0.6)], noise=0.01)
