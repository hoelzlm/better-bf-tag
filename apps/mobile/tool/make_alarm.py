#!/usr/bin/env python3
"""Generates apps/mobile/assets/sounds/alarm.wav: a synthetic, loopable
siren-like two-tone alarm sound (ADR 0017, "Ton") -- no licensing
questions, reproducible from this script.

22050 Hz mono 16-bit PCM, ~2 s total, alternating between two tones so the
loop point (end -> start) is seamless (both edges cross zero at the same
phase). Keeps the file well under 200 KB.
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050
TONE_HZ_LOW = 600.0
TONE_HZ_HIGH = 900.0
SEGMENT_SECONDS = 0.5  # four segments (low, high, low, high) = ~2s total
AMPLITUDE = 0.6  # of full scale, leaves headroom
FADE_SAMPLES = 80  # short fade at each segment edge to avoid clicks


def _tone_segment(freq: float, seconds: float) -> list[float]:
    n = int(SAMPLE_RATE * seconds)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        value = math.sin(2 * math.pi * freq * t)
        # Fade in/out at segment edges so concatenation has no clicks and
        # the final loop (end -> start) is seamless.
        if i < FADE_SAMPLES:
            value *= i / FADE_SAMPLES
        elif i >= n - FADE_SAMPLES:
            value *= (n - 1 - i) / FADE_SAMPLES
        samples.append(value)
    return samples


def build_samples() -> list[float]:
    segments = [
        _tone_segment(TONE_HZ_LOW, SEGMENT_SECONDS),
        _tone_segment(TONE_HZ_HIGH, SEGMENT_SECONDS),
        _tone_segment(TONE_HZ_LOW, SEGMENT_SECONDS),
        _tone_segment(TONE_HZ_HIGH, SEGMENT_SECONDS),
    ]
    samples: list[float] = []
    for segment in segments:
        samples.extend(segment)
    return samples


def main() -> None:
    out_path = Path(__file__).resolve().parent.parent / "assets" / "sounds" / "alarm.wav"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    samples = build_samples()
    frames = bytearray()
    for value in samples:
        clamped = max(-1.0, min(1.0, value * AMPLITUDE))
        frames += struct.pack("<h", int(clamped * 32767))

    with wave.open(str(out_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(bytes(frames))

    size = out_path.stat().st_size
    print(f"Wrote {out_path} ({size} bytes, {len(samples) / SAMPLE_RATE:.2f}s)")
    assert size < 200_000, "alarm.wav must stay under 200 KB"


if __name__ == "__main__":
    main()
