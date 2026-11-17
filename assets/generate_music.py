#!/usr/bin/env python3
"""Generate original, looping chiptune themes for the game stages and bosses."""

import math
import struct
import wave
from pathlib import Path

RATE = 22050
BEAT = 0.5
OUTPUT = Path(__file__).resolve().parents[1] / "src" / "audio"


def midi(note):
    return 440 * 2 ** ((note - 69) / 12)


def add_note(samples, start, length, frequency, volume, voice):
    first = int(start * RATE)
    last = min(len(samples), int((start + length) * RATE))
    for index in range(first, last):
        local = (index - first) / RATE
        remaining = length - local
        attack = min(1.0, local / 0.018)
        release = min(1.0, remaining / 0.06)
        if voice == "bass":
            envelope = attack * release * math.exp(-local * 1.0)
            sample = math.sin(2 * math.pi * frequency * local)
            sample += 0.18 * math.sin(2 * math.pi * frequency * 2 * local)
        elif voice == "pad":
            envelope = attack * release * 0.7
            sample = math.sin(2 * math.pi * frequency * local)
            sample += 0.28 * math.sin(2 * math.pi * frequency * 2 * local)
        elif voice == "lead":
            envelope = attack * release * math.exp(-local * 1.8)
            sample = math.sin(2 * math.pi * frequency * local)
            sample += 0.24 * math.sin(2 * math.pi * frequency * 2.01 * local)
        elif voice == "kick":
            pitch = frequency * (1 + 5 * math.exp(-local * 24))
            envelope = math.exp(-local * 16)
            sample = math.sin(2 * math.pi * pitch * local)
        else:
            envelope = math.exp(-local * 35) * release
            sample = math.sin(2 * math.pi * frequency * local)
            sample += 0.35 * math.sin(2 * math.pi * frequency * 3 * local)
        samples[index] += sample * envelope * volume


def make_track(filename, roots, chords, melody, tempo, lead_voice="lead", percussion=0.08):
    beat = 60 / tempo
    duration = beat * 16
    samples = [0.0] * int(RATE * duration)

    for index in range(16):
        root = roots[index // 4]
        add_note(samples, index * beat, beat * 0.9, midi(root - 12), 0.22, "bass")
        if index % 4 == 0:
            add_note(samples, index * beat, 0.12, 72, percussion, "kick")
        if index % 4 == 2:
            add_note(samples, index * beat, 0.09, 1180, percussion * 0.52, "hat")
        if index % 4 == 3:
            add_note(samples, index * beat, 0.08, 880, percussion * 0.32, "hat")

    for bar, chord in enumerate(chords):
        start = bar * beat * 4
        for note in chord:
            add_note(samples, start, beat * 3.8, midi(note), 0.075, "pad")

    eighth = beat / 2
    for index, note in enumerate(melody):
        if note is not None:
            add_note(samples, index * eighth, eighth * 0.82, midi(note), 0.16, lead_voice)

    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / filename), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        frames = bytearray()
        for index, sample in enumerate(samples):
            edge = min(1.0, index / (RATE * 0.04), (len(samples) - index) / (RATE * 0.04))
            value = max(-0.95, min(0.95, sample * edge))
            frames.extend(struct.pack("<h", int(value * 30000)))
        audio.writeframes(frames)


make_track(
    "music-alley.wav",
    [45, 41, 43, 38],
    [[57, 60, 64], [53, 57, 60], [55, 59, 62], [50, 53, 57]],
    [69, None, 72, 76, None, 72, 67, None, 69, 72, None, 76, 79, None, 76, None,
     67, None, 71, 74, None, 71, 67, None, 65, None, 69, 72, None, 69, 65, None],
    120,
)
make_track(
    "music-backyard.wav",
    [48, 43, 45, 41],
    [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]],
    [72, None, 74, 76, 79, None, 76, None, 67, 71, None, 74, 76, None, 74, None,
     69, None, 72, 76, 79, None, 76, None, 65, 69, None, 72, 74, None, 72, None],
    104,
    lead_voice="pad",
    percussion=0.1,
)
make_track(
    "music-cave.wav",
    [41, 36, 39, 34],
    [[53, 56, 60], [48, 51, 55], [51, 55, 58], [46, 49, 53]],
    [65, None, None, 68, 72, None, 68, None, 63, None, 67, None, 70, 67, None, None,
     60, None, 63, None, 67, None, 70, None, 65, None, 68, 72, None, 68, None, None],
    88,
    lead_voice="pad",
    percussion=0.045,
)
make_track(
    "music-central.wav",
    [50, 45, 47, 43],
    [[62, 65, 69], [57, 60, 64], [59, 62, 66], [55, 59, 62]],
    [74, 77, 81, None, 77, 74, 72, None, 69, 72, 76, None, 79, 76, 72, None,
     74, 77, 81, None, 84, 81, 77, None, 71, 74, 79, None, 81, 79, 74, None],
    128,
)
make_track(
    "music-valley.wav",
    [34, 36, 31, 29],
    [[46, 49, 53], [48, 51, 55], [43, 46, 50], [41, 45, 48]],
    [58, None, 65, None, 62, 65, None, 69, 67, None, 62, None, 58, 62, 65, None,
     55, None, 62, 65, None, 62, 58, None, 53, None, 58, 62, 65, None, 62, None],
    76,
    lead_voice="pad",
    percussion=0.035,
)
make_track(
    "music-boss-alley.wav",
    [45, 46, 43, 38],
    [[57, 60, 64], [58, 62, 65], [55, 59, 62], [50, 53, 57]],
    [81, 79, 76, 72, 79, 81, 84, None, 79, 76, 72, 67, 76, 79, 81, None,
     84, 81, 79, 76, 72, 76, 79, None, 81, 79, 76, 72, 67, 72, 76, None],
    156,
    percussion=0.15,
)
make_track(
    "music-boss-backyard.wav",
    [48, 50, 45, 41],
    [[60, 64, 67], [62, 65, 69], [57, 60, 64], [53, 57, 60]],
    [84, None, 79, 76, 81, 84, None, 86, 79, 83, 79, None, 76, 79, 83, None,
     84, None, 81, 76, 79, 83, None, 86, 81, 84, 81, None, 76, 79, 84, None],
    148,
    percussion=0.14,
)
make_track(
    "music-boss-cave.wav",
    [41, 43, 39, 34],
    [[53, 56, 60], [55, 58, 62], [51, 55, 58], [46, 49, 53]],
    [77, 74, None, 72, 80, 77, 72, None, 75, None, 79, 75, 82, 79, None, 75,
     80, 77, 72, None, 84, 80, 77, None, 79, 75, None, 72, 77, 74, 70, None],
    140,
    lead_voice="pad",
    percussion=0.12,
)
make_track(
    "music-boss-central.wav",
    [50, 53, 47, 43],
    [[62, 65, 69], [65, 69, 72], [59, 62, 66], [55, 59, 62]],
    [86, 84, 81, 79, 84, 86, 89, None, 81, 84, 88, None, 91, 88, 84, None,
     86, 89, 93, None, 89, 86, 84, 81, 79, 84, 88, None, 89, 86, 81, None],
    164,
    percussion=0.16,
)
make_track(
    "music-boss-valley.wav",
    [34, 36, 31, 29],
    [[46, 49, 53], [48, 51, 55], [43, 46, 50], [41, 45, 48]],
    [70, None, 77, 74, 82, 77, None, 86, 82, 79, 74, None, 77, 82, 86, None,
     89, 86, 82, 77, 74, 77, 82, None, 86, 82, 79, 74, 70, 74, 77, None],
    136,
    lead_voice="pad",
    percussion=0.13,
)
