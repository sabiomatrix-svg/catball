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


def _formant_gain(freq, formants):
    """Резонансные пики (Лоренц) — так гармоники окрашиваются в гласную."""
    g = 0.0
    for fc, amp, bw in formants:
        g += amp / (1.0 + ((freq - fc) / bw) ** 2)
    return g


def make_meow(dur=0.62):
    """Мяу голосовой моделью.

    Источник — богатый пилообразный спектр (гармоники 1/n), как связки;
    поверх него три подвижные форманты, которые ведут гласную
    "м" (закрытая, глухая) -> "я/а" (открытая, яркая) -> "у" (тёмная).
    Именно движение формант читается ухом как мяу; одной меняющейся
    частоты для этого мало — получается свист, что и было в прошлой версии.

    Частота основного тона взята кошачья (~300-520 Гц), а не 600-790:
    высокий тон тоже уводил звук в свист.
    """
    n = int(RATE * dur)
    out = []
    phase = 0.0
    noise_lp = 0.0
    rnd = 12345

    for i in range(n):
        t = i / RATE
        u = t / dur

        # --- контур высоты: подъём к четверти длительности, затем спад
        if u < 0.25:
            f0 = 360.0 + 150.0 * (u / 0.25)
        else:
            f0 = 510.0 - 210.0 * ((u - 0.25) / 0.75) ** 1.3
        f0 *= 1.0 + 0.02 * math.sin(2 * math.pi * 6.0 * t)      # вибрато
        phase += 2 * math.pi * f0 / RATE

        # --- гласная: м -> я -> у
        if u < 0.18:                      # "м": носовая, тёмная, тихая
            k = u / 0.18
            f1 = 300.0 + 450.0 * k
            f2 = 1100.0 + 900.0 * k
            f3 = 2600.0
            openness = 0.35 + 0.65 * k
        elif u < 0.55:                    # "я/а": открытая и яркая
            k = (u - 0.18) / 0.37
            f1 = 750.0 + 100.0 * k
            f2 = 2000.0 - 250.0 * k
            f3 = 2800.0
            openness = 1.0
        else:                             # "у": закрывается, темнеет
            k = (u - 0.55) / 0.45
            f1 = 850.0 - 400.0 * k
            f2 = 1750.0 - 850.0 * k
            f3 = 2700.0 - 400.0 * k
            openness = 1.0 - 0.45 * k

        formants = [(f1, 1.0, 110.0), (f2, 0.55, 150.0), (f3, 0.2, 220.0)]

        v = 0.0
        h = 1
        while f0 * h < 9500.0 and h <= 24:
            fh = f0 * h
            v += (_formant_gain(fh, formants) / h) * math.sin(phase * h)
            h += 1

        # лёгкое придыхание — живее, чем чистая периодика
        rnd = (1103515245 * rnd + 12345) % 2147483648
        white = (rnd / 1073741824.0) - 1.0
        noise_lp += 0.12 * (white - noise_lp)
        v = v * 0.42 + noise_lp * 0.05 * openness

        # огибающая: мягкий заход на "м", полный голос в середине, спад
        attack = min(1.0, t / 0.045)
        release = 1.0 if u < 0.62 else max(0.0, 1.0 - (u - 0.62) / 0.38) ** 1.4
        out.append(v * attack * release * openness * 0.9)

    peak = max(abs(x) for x in out) or 1.0
    return [x / peak * 0.85 for x in out]


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
