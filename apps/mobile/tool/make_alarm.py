#!/usr/bin/env python3
"""Generates the synthetic, loopable siren-like two-tone alarm sound (ADR
0017, "Ton") -- no licensing questions, reproducible from this script.

Two outputs:
- apps/mobile/assets/sounds/alarm.wav: the ~2 s in-app loop (Flutter
  `AlarmSound`, played while the app is in the foreground).
- Android `res/raw/alarm.wav` and iOS `Runner/alarm.wav`: a ~10 s
  notification variant of the same tones (ADR 0018), looped long enough
  to carry a push notification/APNs alert without being silent for most
  of it. Both platforms accept WAV/Linear PCM; iOS requires <= 30 s.

22050 Hz mono 16-bit PCM; alternates between two tones so the loop point
(end -> start) is seamless (both edges cross zero at the same phase).
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050
TONE_HZ_LOW = 600.0
TONE_HZ_HIGH = 900.0
SEGMENT_SECONDS = 0.5  # one low+high pair = 1s; four segments = ~2s total
AMPLITUDE = 0.6  # of full scale, leaves headroom
FADE_SAMPLES = 80  # short fade at each segment edge to avoid clicks

APP_LOOP_REPEATS = 2  # -> ~2s (matches the previous apps/mobile asset)
NOTIFICATION_REPEATS = 10  # -> ~10s notification sound (<= 30s, ADR 0018)


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


def build_samples(repeats: int) -> list[float]:
    low = _tone_segment(TONE_HZ_LOW, SEGMENT_SECONDS)
    high = _tone_segment(TONE_HZ_HIGH, SEGMENT_SECONDS)
    samples: list[float] = []
    for _ in range(repeats):
        samples.extend(low)
        samples.extend(high)
    return samples


def write_wav(out_path: Path, repeats: int, max_bytes: int) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    samples = build_samples(repeats)
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
    duration = len(samples) / SAMPLE_RATE
    print(f"Wrote {out_path} ({size} bytes, {duration:.2f}s)")
    assert size < max_bytes, f"{out_path} must stay under {max_bytes} bytes"
    assert duration <= 30.0, f"{out_path} must stay at or under 30s"


def main() -> None:
    mobile_root = Path(__file__).resolve().parent.parent

    write_wav(
        mobile_root / "assets" / "sounds" / "alarm.wav",
        APP_LOOP_REPEATS,
        max_bytes=200_000,
    )
    write_wav(
        mobile_root / "android" / "app" / "src" / "main" / "res" / "raw" / "alarm.wav",
        NOTIFICATION_REPEATS,
        max_bytes=1_000_000,
    )
    write_wav(
        mobile_root / "ios" / "Runner" / "alarm.wav",
        NOTIFICATION_REPEATS,
        max_bytes=1_000_000,
    )


if __name__ == "__main__":
    main()
