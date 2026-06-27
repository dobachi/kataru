"""マップ記法を PNG に可視化する（目視確認用）。

Godot 側のプレースホルダ色に合わせている（S1暫定色）。
"""
from __future__ import annotations

from PIL import Image, ImageDraw

from mapfmt import MapDoc

WALL_COLOR = (69, 61, 82)
FLOOR_COLOR = (107, 158, 92)
GRID_COLOR = (0, 0, 0)
START_COLOR = (242, 217, 77)
NPC_COLOR = (90, 150, 230)


def render(doc: MapDoc, tile: int = 24) -> Image.Image:
    g = doc.grid
    height = len(g)
    width = len(g[0]) if height else 0
    img = Image.new("RGB", (max(width, 1) * tile, max(height, 1) * tile), FLOOR_COLOR)
    d = ImageDraw.Draw(img)
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            x0, y0 = x * tile, y * tile
            rect = [x0, y0, x0 + tile - 1, y0 + tile - 1]
            d.rectangle(rect, fill=(WALL_COLOR if ch == "#" else FLOOR_COLOR))
            d.rectangle(rect, outline=GRID_COLOR)
            pad = tile // 4
            inner = [x0 + pad, y0 + pad, x0 + tile - pad, y0 + tile - pad]
            if ch == "@":
                d.rectangle(inner, fill=START_COLOR)
            elif ch.isalpha() and ch.isupper():
                d.ellipse(inner, fill=NPC_COLOR)
    return img
