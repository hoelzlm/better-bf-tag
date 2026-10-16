#!/usr/bin/env python3
"""WCAG-Kontrastrechner (stdlib-only) fuer alle Farbpaare im Designsystem.

Nutzung: python3 docs/design/tools/contrast.py
Gibt fuer jedes definierte Paar das Kontrastverhaeltnis nach der
WCAG-2.x-Formel (relative Luminanz, sRGB) aus. Werte werden 1:1 in
docs/design/design-system.md uebernommen -- bei Aenderung der Hex-Werte
dieses Skript neu laufen lassen und die Tabellen aktualisieren.
"""

from __future__ import annotations


def _channel(c: float) -> float:
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(hex_color: str) -> float:
    hex_color = hex_color.lstrip("#")
    r, g, b = (int(hex_color[i : i + 2], 16) for i in (0, 2, 4))
    r, g, b = _channel(r), _channel(g), _channel(b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(hex_a: str, hex_b: str) -> float:
    la, lb = relative_luminance(hex_a), relative_luminance(hex_b)
    lighter, darker = max(la, lb), min(la, lb)
    return (lighter + 0.05) / (darker + 0.05)


PAIRS: list[tuple[str, str, str]] = [
    # Beschreibung, Vordergrund, Hintergrund
    ("onSurface/surface (hell)", "#1B1F23", "#FFFFFF"),
    ("onSurfaceVariant/surface (hell)", "#4C555C", "#FFFFFF"),
    ("onPrimary/primary (hell)", "#FFFFFF", "#0B5E6B"),
    ("onAlarm/alarm (hell)", "#FFFFFF", "#D32F2F"),
    ("onWarning/warning (hell)", "#FFFFFF", "#B45309"),
    ("onSurface/surface (Monitor/Dunkel)", "#EDEFF1", "#14181C"),
    ("onPrimary/primary (Monitor/Dunkel)", "#06262B", "#4FB8C9"),
    ("onAlarm/alarm (Monitor/Dunkel)", "#1A0000", "#FF5449"),
    ("onWarning/warning (Monitor/Dunkel)", "#1A1100", "#F2A93B"),
    ("fms1 (Einsatzbereit Funk)", "#FFFFFF", "#2E7D32"),
    ("fms2 (Einsatzbereit Wache)", "#0B1F0D", "#43A047"),
    ("fms3 (Einsatz uebernommen)", "#1B1300", "#F2A900"),
    ("fms4 (Am Einsatzort)", "#FFFFFF", "#7A3FC2"),
    ("fms5 (Sprechwunsch)", "#FFFFFF", "#AD1A72"),
    ("fms6 (Nicht einsatzbereit)", "#FFFFFF", "#6B7280"),
    ("fms7 (Patient aufgenommen)", "#FFFFFF", "#2660D1"),
    ("fms8 (Am Transportziel)", "#FFFFFF", "#1455B0"),
    # FMS-Fuellfarben gegen den dunklen Monitor-/App-Dark-Hintergrund
    # (Pruefung: reicht die Flaeche allein als Abgrenzung vom Hintergrund,
    # oder braucht die Pille einen Rahmen? -> Abschnitt 2.4)
    ("fms1 Fuellung vs. Monitor-Hintergrund", "#2E7D32", "#14181C"),
    ("fms2 Fuellung vs. Monitor-Hintergrund", "#43A047", "#14181C"),
    ("fms3 Fuellung vs. Monitor-Hintergrund", "#F2A900", "#14181C"),
    ("fms4 Fuellung vs. Monitor-Hintergrund", "#7A3FC2", "#14181C"),
    ("fms5 Fuellung vs. Monitor-Hintergrund", "#AD1A72", "#14181C"),
    ("fms6 Fuellung vs. Monitor-Hintergrund", "#6B7280", "#14181C"),
    ("fms7 Fuellung vs. Monitor-Hintergrund", "#2660D1", "#14181C"),
    ("fms8 Fuellung vs. Monitor-Hintergrund", "#1455B0", "#14181C"),
]


def main() -> None:
    width = max(len(desc) for desc, _, _ in PAIRS)
    for desc, fg, bg in PAIRS:
        ratio = contrast_ratio(fg, bg)
        print(f"{desc.ljust(width)}  {fg} / {bg}  =  {ratio:.2f}:1")


if __name__ == "__main__":
    main()
