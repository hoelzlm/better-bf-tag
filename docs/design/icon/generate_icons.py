#!/usr/bin/env python3
"""Render platform icon assets (web/android/ios) from docs/design/icon/*.svg.

Usage: python3 docs/design/icon/generate_icons.py
Requires: cairosvg, Pillow (pip install cairosvg pillow).

Source of truth: docs/design/icon/app-icon.svg (rounded square, full icon),
favicon.svg (same motif, full-bleed square, no corner rounding) and
app-icon-mono.svg (monochrome Android 13+ / dark-mode variant).
Primary color: #0B5E6B (docs/design/design-system.md).
"""
import io
import os

import cairosvg
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
ICON_DIR = os.path.dirname(os.path.abspath(__file__))
PRIMARY = "#0B5E6B"

APP_ICON_SVG = os.path.join(ICON_DIR, "app-icon.svg")
FAVICON_SVG = os.path.join(ICON_DIR, "favicon.svg")
MONO_SVG = os.path.join(ICON_DIR, "app-icon-mono.svg")
ICON_1024_PNG = os.path.join(ICON_DIR, "app-icon-1024.png")

# Foreground-only motif (no background rect) for the Android adaptive icon's
# foreground layer. Matches app-icon.svg's shield+F, already within the 66%
# safe zone per the comment in app-icon.svg (visible bbox ~170..854 of 1024).
FOREGROUND_SVG = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <path d="M512 150 L774 236 V516 C774 690 658 814 512 862 C366 814 250 690 250 516 V236 Z" fill="#FFFFFF"/>
  <g fill="{primary}">
    <rect x="422" y="328" width="80" height="380" rx="20"/>
    <rect x="422" y="328" width="260" height="92" rx="20"/>
    <rect x="422" y="488" width="210" height="92" rx="20"/>
  </g>
</svg>""".format(primary=PRIMARY)


def render_svg(svg_path_or_str, size, is_file=True):
    kwargs = dict(output_width=size, output_height=size)
    if is_file:
        png_bytes = cairosvg.svg2png(url=svg_path_or_str, **kwargs)
    else:
        png_bytes = cairosvg.svg2png(bytestring=svg_path_or_str.encode("utf-8"), **kwargs)
    return Image.open(io.BytesIO(png_bytes)).convert("RGBA")


def render_mono(size, color="#000000"):
    svg = open(MONO_SVG, encoding="utf-8").read().replace("currentColor", color)
    return render_svg(svg, size, is_file=False)


def save(img, path, strip_alpha=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if strip_alpha:
        bg = Image.new("RGB", img.size, (255, 255, 255))
        bg.paste(img, mask=img.split()[3] if img.mode == "RGBA" else None)
        bg.save(path)
    else:
        img.save(path)
    print("wrote", path, img.size, "alpha" if not strip_alpha else "no-alpha")


def gen_web():
    web = os.path.join(ROOT, "apps", "web", "web")
    save(render_svg(FAVICON_SVG, 32), os.path.join(web, "favicon.png"))
    save(render_svg(APP_ICON_SVG, 192), os.path.join(web, "icons", "Icon-192.png"))
    save(render_svg(APP_ICON_SVG, 512), os.path.join(web, "icons", "Icon-512.png"))
    # Maskable: full-bleed square background, motif within the safe zone
    # (favicon.svg is the same motif without app-icon's rx corner rounding).
    save(render_svg(FAVICON_SVG, 192), os.path.join(web, "icons", "Icon-maskable-192.png"))
    save(render_svg(FAVICON_SVG, 512), os.path.join(web, "icons", "Icon-maskable-512.png"))
    with open(FAVICON_SVG, encoding="utf-8") as f:
        favicon_svg_content = f.read()
    with open(os.path.join(web, "favicon.svg"), "w", encoding="utf-8") as f:
        f.write(favicon_svg_content)


ANDROID_LEGACY_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ANDROID_FOREGROUND_SIZES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}


def gen_android():
    res = os.path.join(ROOT, "apps", "mobile", "android", "app", "src", "main", "res")
    for density, size in ANDROID_LEGACY_SIZES.items():
        save(render_svg(APP_ICON_SVG, size), os.path.join(res, "mipmap-" + density, "ic_launcher.png"))
    for density, size in ANDROID_FOREGROUND_SIZES.items():
        save(render_svg(FOREGROUND_SVG, size, is_file=False), os.path.join(res, "mipmap-" + density, "ic_launcher_foreground.png"))
        save(render_mono(size), os.path.join(res, "mipmap-" + density, "ic_launcher_monochrome.png"))

    colors_path = os.path.join(res, "values", "colors.xml")
    colors_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">{primary}</color>\n'
        "</resources>\n"
    ).format(primary=PRIMARY)
    with open(colors_path, "w", encoding="utf-8") as f:
        f.write(colors_xml)
    print("wrote", colors_path)

    anydpi_dir = os.path.join(res, "mipmap-anydpi-v26")
    os.makedirs(anydpi_dir, exist_ok=True)
    adaptive_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        "</adaptive-icon>\n"
    )
    adaptive_path = os.path.join(anydpi_dir, "ic_launcher.xml")
    with open(adaptive_path, "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    print("wrote", adaptive_path)


IOS_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def gen_ios():
    appiconset = os.path.join(
        ROOT, "apps", "mobile", "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
    )
    source = Image.open(ICON_1024_PNG).convert("RGB")  # no alpha: App Store rejects alpha
    assert source.size == (1024, 1024), source.size
    for filename, size in IOS_SIZES.items():
        resized = source.resize((size, size), Image.LANCZOS)
        path = os.path.join(appiconset, filename)
        resized.save(path)
        print("wrote", path, resized.size, resized.mode)


if __name__ == "__main__":
    gen_web()
    gen_android()
    gen_ios()
