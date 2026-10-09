#!/usr/bin/env python3
"""Generates `apps/web/assets/sounds/gong.wav` (ADR 0017, "Ton").

A small synthetic two-tone "ding-dong" (decaying sine waves), so there are
no licensing questions. Mono 16-bit PCM at 22050 Hz, roughly 2 seconds,
well under 200 KB.

Usage: python3 apps/web/tool/make_gong.py
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050
OUTPUT = Path(__file__).resolve().parent.parent / "assets" / "sounds" / "gong.wav"


def _tone(frequency: float, start: float, duration: float, decay: float) -> list[float]:
    """Samples (−1..1) of a decaying sine starting at [start]s for [duration]s."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        envelope = math.exp(-decay * t)
        samples.append(envelope * math.sin(2 * math.pi * frequency * t))
    return samples


def _mix(total_duration: float, parts: list[tuple[float, list[float]]]) -> list[float]:
    """Mixes [parts] (each a (start_offset_seconds, samples) pair) into one
    buffer spanning [total_duration] seconds."""
    total_n = int(SAMPLE_RATE * total_duration)
    buffer = [0.0] * total_n
    for start, samples in parts:
        offset = int(SAMPLE_RATE * start)
        for i, value in enumerate(samples):
            index = offset + i
            if index < total_n:
                buffer[index] += value
    return buffer


def main() -> None:
    # "Ding" (higher tone) then "dong" (lower tone, slightly overlapping),
    # each a decaying sine -- roughly 2 seconds total.
    ding = _tone(frequency=880.0, start=0.0, duration=1.1, decay=3.5)
    dong = _tone(frequency=587.0, start=0.0, duration=1.3, decay=3.0)
    buffer = _mix(2.0, [(0.0, ding), (0.55, dong)])

    peak = max(abs(v) for v in buffer) or 1.0
    scale = 0.9 / peak
    frames = b"".join(
        struct.pack("<h", max(-32768, min(32767, int(v * scale * 32767))))
        for v in buffer
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(frames)

    size_kb = OUTPUT.stat().st_size / 1024
    print(f"Wrote {OUTPUT} ({size_kb:.1f} KB)")


if __name__ == "__main__":
    main()
