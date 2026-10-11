#!/usr/bin/env python3
"""Генератор звука для CatBox.

Делает WAV-файлы в assets/audio/ стандартной библиотекой Python — без
сторонних пакетов и без скачивания чужих ассетов (никаких вопросов по
лицензиям для стора). Звук намеренно простой, "мультяшный".

Запуск:  python3 tools/generate_audio.py
Файлы коммитятся в репозиторий, в рантайме ничего не генерируется.
"""

import math
import os
import struct
import wave

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")


def write_wav(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32000)) for s in samples)
        w.writeframes(frames)
    print("%-16s %6.1f KB  %5.2f s" % (name, os.path.getsize(path) / 1024.0, len(samples) / RATE))


def tone(freq, dur, amp=0.5, shape="sine", detune=0.0):
    """Один тон с мягкой атакой и затуханием."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        phase = 2 * math.pi * (freq + detune * t) * t
        if shape == "square":
            v = 1.0 if math.sin(phase) >= 0 else -1.0
            v *= 0.45
        elif shape == "tri":
            v = 2.0 / math.pi * math.asin(math.sin(phase))
        else:
            v = math.sin(phase)
        # огибающая: быстрый подъём, плавный спад — иначе слышны щелчки
        attack = min(1.0, t / 0.012)
        release = min(1.0, (dur - t) / (dur * 0.6 + 1e-6))
        out.append(v * amp * attack * release)
    return out


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def make_meow(dur=0.52):
    """Мяу.

    Аддитивный синтез: основной тон с контуром высоты (вверх и плавно
    вниз) плюс гармоники, вес которых задают две "форманты" — так
    получается переход гласной, за счёт которого звук читается как
    мяу, а не как свист. Фаза интегрируется по шагам, иначе при
    меняющейся частоте на стыках появляются щелчки.
    """
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        u = t / dur

        # контур высоты: быстрый подъём, затем спад
        f0 = 600.0 + 190.0 * math.sin(math.pi * min(1.0, u * 1.7))
        f0 -= 250.0 * max(0.0, (u - 0.45) / 0.55)
        f0 *= 1.0 + 0.013 * math.sin(2 * math.pi * 5.5 * t)   # лёгкое вибрато
        phase += 2 * math.pi * f0 / RATE

        # форманты едут вниз: "мя" -> "ау"
        f1 = 760.0 - 320.0 * u
        f2 = 1750.0 - 760.0 * u

        v = 0.0
        for h in range(1, 10):
            fh = f0 * h
            w = math.exp(-((fh - f1) / 330.0) ** 2)
            w += 0.55 * math.exp(-((fh - f2) / 430.0) ** 2)
            w += 0.22 / h
            v += w * math.sin(phase * h)
        v /= 3.2

        attack = min(1.0, t / 0.025)
        release = min(1.0, (dur - t) / (dur * 0.55))
        out.append(v * attack * release * 0.5)
    return out


def make_score():
    """Попадание: две ноты вверх, как маленькая фанфара."""
    return seq(
        tone(660, 0.12, amp=0.42, shape="tri"),
        tone(880, 0.22, amp=0.42, shape="tri"),
    )


def make_tap():
    """Тап по кнопке: короткий мягкий щелчок."""
    return tone(520, 0.06, amp=0.3, shape="sine")


def make_music():
    """Спокойный зацикленный мотив.

    Длина подобрана так, чтобы цикл сходился без щелчка: целое число
    тактов, последняя нота затухает до нуля.
    """
    bpm = 96.0
    beat = 60.0 / bpm
    # пентатоника — почти любое сочетание звучит мирно
    melody = [523, 587, 659, 784, 659, 587, 523, 440]
    bass = [131, 131, 165, 165, 196, 196, 165, 131]

    mel_track = []
    for i, f in enumerate(melody * 2):
        dur = beat * (1.0 if i % 4 != 3 else 1.5)
        mel_track.extend(tone(f, dur, amp=0.17, shape="sine"))
        mel_track.extend(silence(beat * 0.08))

    bass_track = []
    while len(bass_track) < len(mel_track):
        for f in bass:
            bass_track.extend(tone(f, beat * 2.0, amp=0.13, shape="tri"))
            if len(bass_track) >= len(mel_track):
                break

    bass_track = bass_track[:len(mel_track)]
    track = mix(mel_track, bass_track)

    # мягкая склейка краёв, чтобы петля не щёлкала на стыке
    fade = int(RATE * 0.04)
    for i in range(fade):
        k = i / fade
        track[i] *= k
        track[-1 - i] *= k
    return track


if __name__ == "__main__":
    write_wav("meow.wav", make_meow())
    write_wav("score.wav", make_score())
    write_wav("tap.wav", make_tap())
    write_wav("music_loop.wav", make_music())
