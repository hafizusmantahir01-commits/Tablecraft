"""Makes the game's sound effects in assets/sounds/ (our own sounds, no licence needed).

    pip install numpy
    python tool/make_sounds.py
"""
import os
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'sounds')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def save(name, signal, volume=0.8):
    signal = signal / (np.max(np.abs(signal)) + 1e-9) * volume
    fade = min(len(signal), int(RATE * 0.005))
    signal[-fade:] *= np.linspace(1, 0, fade)  # no click at the end
    data = (signal * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print('wrote assets/sounds/' + name, f'{len(data) / RATE:.2f}s')


def bell(freq, seconds, decay):
    x = t(seconds)
    tone = np.sin(2 * np.pi * freq * x) + 0.35 * np.sin(2 * np.pi * freq * 2 * x) + 0.12 * np.sin(2 * np.pi * freq * 3 * x)
    return tone * np.exp(-x * decay)


# Piece clicks into place: short wooden "tok" (noise burst + low knock).
x = t(0.09)
knock = np.sin(2 * np.pi * 190 * x) * np.exp(-x * 60)
noise = rng.normal(0, 1, len(x)) * np.exp(-x * 140)
save('snap.wav', knock + 0.45 * noise, 0.85)

# Piece lifted from the tray: very soft high tick.
x = t(0.05)
save('pick.wav', np.sin(2 * np.pi * 1300 * x) * np.exp(-x * 120) + 0.2 * rng.normal(0, 1, len(x)) * np.exp(-x * 300), 0.35)

# Hint: two rising sparkly notes.
hint = np.zeros(int(RATE * 0.45))
for i, f in enumerate([1046.5, 1568.0]):
    start = int(RATE * 0.11 * i)
    note = bell(f, 0.34, 9)
    hint[start:start + len(note)] += note
save('hint.wav', hint, 0.5)

# Puzzle complete: happy rising arpeggio C - E - G - C, then a soft chord.
win = np.zeros(int(RATE * 1.6))
for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
    start = int(RATE * 0.12 * i)
    note = bell(f, 0.9, 4.5)
    win[start:start + len(note)] += note
start = int(RATE * 0.55)
for f in [523.25, 659.25, 783.99]:
    note = bell(f, 1.0, 3)
    win[start:start + len(note)] += 0.5 * note
save('win.wav', win, 0.7)
