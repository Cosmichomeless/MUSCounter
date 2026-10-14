#!/usr/bin/env python3
"""Genera el icono de la app (marcador de cinco rayas sobre fieltro verde) con los colores de la paleta.

Uso: python3 scripts/make-icon.py
Escribe tres PNG de 1024x1024 (claro, oscuro y monocromo) en App/Assets.xcassets/AppIcon.appiconset.
"""
import json
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SIZE = 1024
SCALE = 2  # supermuestreo para suavizar bordes
OUT = os.path.join(os.path.dirname(__file__), "..", "App", "Assets.xcassets", "AppIcon.appiconset")

# Paleta (DesignTokens.swift, tema oscuro)
FELT_CENTER = (0x21, 0x52, 0x3A)
FELT_EDGE = (0x12, 0x30, 0x1F)
CREAM = (0xF6, 0xF0, 0xDC)
GOLD = (0xE8, 0xC5, 0x6A)
CORAL = (0xE0, 0x73, 0x5B)
BLUE = (0x5A, 0xA0, 0xE6)


def radial_background(center, edge):
    n = SIZE * SCALE
    small = Image.radial_gradient("L").resize((n, n))  # 0 en el centro, 255 en las esquinas
    return Image.composite(Image.new("RGB", (n, n), edge), Image.new("RGB", (n, n), center), small)


def stroke_layer(color, box, radius):
    layer = Image.new("RGBA", (SIZE * SCALE,) * 2, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, radius=radius, fill=color + (255,))
    return layer


def tally(background, colors, shadow=True):
    n = SIZE * SCALE
    canvas = background.convert("RGBA")
    s = SCALE
    width, height, gap = 96 * s, 470 * s, 70 * s
    total = 4 * width + 3 * gap
    left = (n - total) // 2 - 10 * s
    top = (n - height) // 2
    layers = []
    for i in range(4):
        x = left + i * (width + gap)
        layers.append(stroke_layer(colors[i], (x, top, x + width, top + height), width // 2))
    # Raya diagonal que cruza las cuatro
    diag = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(diag).line(
        [(left - 70 * s, top + height - 60 * s), (left + total + 70 * s, top + 60 * s)],
        fill=colors[4] + (255,), width=96 * s, joint="curve",
    )
    for x, y in [(left - 70 * s, top + height - 60 * s), (left + total + 70 * s, top + 60 * s)]:
        ImageDraw.Draw(diag).ellipse((x - 48 * s, y - 48 * s, x + 48 * s, y + 48 * s), fill=colors[4] + (255,))
    layers.append(diag)

    if shadow:
        mask = Image.new("L", (n, n), 0)
        for layer in layers:
            mask = ImageChops.lighter(mask, layer.getchannel("A"))
        blurred = mask.filter(ImageFilter.GaussianBlur(22 * s))
        shade = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        shade.putalpha(blurred.point(lambda v: int(v * 0.45)))
        canvas.alpha_composite(shade, dest=(0, 14 * s))
    for layer in layers:
        canvas.alpha_composite(layer)
    return canvas.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)


def save(image, name):
    os.makedirs(OUT, exist_ok=True)
    image.save(os.path.join(OUT, name), "PNG")


def main():
    light = tally(radial_background(FELT_CENTER, FELT_EDGE), [CORAL, CORAL, BLUE, BLUE, GOLD])
    save(light, "AppIcon.png")

    dark = tally(radial_background((0x0E, 0x24, 0x17), (0x07, 0x14, 0x0C)), [CORAL, CORAL, BLUE, BLUE, GOLD])
    save(dark, "AppIcon-dark.png")

    # Monocromo: iOS lo tiñe; trazos claros sobre fondo negro
    mono = tally(Image.new("RGB", (SIZE * SCALE,) * 2, (0, 0, 0)), [CREAM] * 4 + [(200, 200, 200)], shadow=False)
    save(mono, "AppIcon-tinted.png")

    contents = {
        "images": [
            {"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "AppIcon-dark.png",
             "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "tinted"}], "filename": "AppIcon-tinted.png",
             "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(OUT, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
        f.write("\n")
    with open(os.path.join(OUT, "..", "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
