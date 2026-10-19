#!/usr/bin/env python3
"""Añade un titular corto a cada captura de docs/capturas y deja el resultado en docs/capturas/titulares.

Uso: python3 scripts/make-capturas.py
Las capturas originales (1320x2868, sin marco) no se tocan. Cada resultado mide lo mismo, así que sirve
tal cual para el tamaño de iPhone 6,9". Los titulares se leen de TITULARES; cambia ahí el texto.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..", "docs", "capturas")
OUT = os.path.join(ROOT, "titulares")
W, H = 1320, 2868
FONT = "/System/Library/Fonts/Avenir Next.ttc"  # índice 8 = Heavy

# Paleta (DesignTokens.swift, tema oscuro)
FELT_CENTER = (0x21, 0x52, 0x3A)
FELT_EDGE = (0x12, 0x30, 0x1F)
CREAM = (0xF6, 0xF0, 0xDC)
GOLD = (0xE8, 0xC5, 0x6A)

TITULARES = {
    "01-marcador": ("Tanteo grande,", "para toda la mesa."),
    "02-cantidad": ("Anota cada lance", "en dos toques."),
    "03-jugadas": ("Un deshacer", "que no falla."),
    "04-nueva-partida": ("A 30 o a 40,", "con o sin vacas."),
    "05-victoria": ("Revancha", "en un toque."),
    "06-claro": ("Claro u oscuro,", "como prefieras."),
    "07-jugadores": ("Cuatro jugadores,", "una mano que rota."),
    "08-estadisticas": ("Mira quién gana más", "y en qué lance."),
    "09-grafica": ("Revive cómo", "fue la partida."),
}

SHOT_W = 1056  # la captura entra al 80 % del ancho; la base queda cortada por el borde, como en las fichas de la guía
SHOT_TOP = 620
RADIUS = 70


def background():
    small = Image.radial_gradient("L").resize((W, H))  # 0 en el centro, 255 en las esquinas
    return Image.composite(Image.new("RGB", (W, H), FELT_EDGE), Image.new("RGB", (W, H), FELT_CENTER), small)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    font = ImageFont.truetype(FONT, 104, index=8)
    for name, (line1, line2) in TITULARES.items():
        shot = Image.open(os.path.join(ROOT, f"{name}.png")).convert("RGB")
        shot = shot.resize((SHOT_W, round(shot.height * SHOT_W / shot.width)), Image.LANCZOS)
        card = Image.new("RGBA", (SHOT_W + 16, shot.height + 16), GOLD + (255,))  # filete dorado de 8 px
        card = rounded(card, RADIUS + 8)
        card.alpha_composite(rounded(shot, RADIUS), (8, 8))

        canvas = background().convert("RGBA")
        draw = ImageDraw.Draw(canvas)
        for i, (line, fill) in enumerate(((line1, CREAM), (line2, GOLD))):
            width = draw.textlength(line, font=font)
            assert width <= W - 120, f"{name}: el titular «{line}» no cabe ({width:.0f} px)"
            draw.text(((W - width) / 2, 200 + i * 130), line, font=font, fill=fill)
        canvas.alpha_composite(card, ((W - card.width) // 2, SHOT_TOP))
        canvas.convert("RGB").save(os.path.join(OUT, f"{name}.png"), optimize=True)
        print(name)


if __name__ == "__main__":
    main()
