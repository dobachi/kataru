#!/usr/bin/env python3
"""自作のCC0ドット絵を生成する（16x16）。

出力:
- assets/tiles/overworld.png   … [grass, stone, tree, water, path]
- assets/sprites/characters.png … [hero, villager, merchant, apothecary,
                                    swordsman, forest_dweller, herb, slime]

簡易な自作プレースホルダ。将来 Kenney 等の外部CC0素材へ差し替え可能（PNGとアトラス順を合わせるだけ）。
"""
from __future__ import annotations

import os

from PIL import Image

T = 16
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLACK = (30, 26, 38, 255)


def _img():
    return Image.new("RGBA", (T, T), (0, 0, 0, 0))


def _rect(im, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(T, y1)):
        for x in range(max(0, x0), min(T, x1)):
            im.putpixel((x, y), c)


def _scatter(im, coords, c):
    for (x, y) in coords:
        if 0 <= x < T and 0 <= y < T:
            im.putpixel((x, y), c)


def _outline(im):
    """不透明ピクセルの外周に暗い縁取りを付ける。"""
    src = im.copy()
    for y in range(T):
        for x in range(T):
            if src.getpixel((x, y))[3] != 0:
                continue
            near = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < T and 0 <= ny < T and src.getpixel((nx, ny))[3] != 0:
                    near = True
                    break
            if near:
                im.putpixel((x, y), BLACK)


# --- タイル ---

def grass():
    im = _img()
    _rect(im, 0, 0, T, T, (86, 150, 78, 255))
    _scatter(im, [(2, 3), (10, 2), (5, 8), (13, 11), (8, 13), (3, 12), (12, 5)], (70, 132, 66, 255))
    _scatter(im, [(6, 4), (11, 9), (2, 9), (9, 6), (14, 14)], (110, 174, 96, 255))
    return im


def stone():
    im = _img()
    _rect(im, 0, 0, T, T, (120, 114, 132, 255))
    _rect(im, 0, 0, T, 1, (150, 144, 160, 255))
    for y in (0, 5, 10, 15):
        _rect(im, 0, y, T, y + 1, (84, 80, 96, 255))
    for x, y in ((8, 0), (4, 5), (12, 5), (8, 10), (0, 10)):
        _rect(im, x, y, x + 1, y + 5, (84, 80, 96, 255))
    return im


def tree():
    im = grass()
    _rect(im, 7, 9, 9, 15, (96, 64, 40, 255))          # trunk
    _rect(im, 3, 1, 13, 10, (52, 116, 60, 255))        # canopy
    _scatter(im, [(5, 3), (9, 2), (11, 6), (4, 7), (8, 8), (10, 4)], (74, 146, 78, 255))
    _scatter(im, [(6, 5), (9, 6)], (38, 92, 48, 255))
    return im


def water():
    im = _img()
    _rect(im, 0, 0, T, T, (66, 116, 196, 255))
    for y in (3, 8, 13):
        _rect(im, 1, y, 7, y + 1, (120, 168, 224, 255))
        _rect(im, 9, y + 1, 15, y + 2, (120, 168, 224, 255))
    return im


def path():
    im = _img()
    _rect(im, 0, 0, T, T, (176, 154, 112, 255))
    _scatter(im, [(3, 4), (11, 2), (6, 9), (13, 12), (8, 14), (2, 11)], (150, 128, 90, 255))
    return im


# --- キャラ/オブジェクト ---

def person(hair, skin, cloth, legs=(60, 56, 78, 255)):
    im = _img()
    _rect(im, 5, 3, 11, 8, skin)        # head
    _rect(im, 5, 2, 11, 4, hair)        # hair
    im.putpixel((6, 6), BLACK)          # eyes
    im.putpixel((9, 6), BLACK)
    _rect(im, 4, 8, 12, 13, cloth)      # body
    _rect(im, 5, 13, 7, 16, legs)       # legs
    _rect(im, 9, 13, 11, 16, legs)
    _outline(im)
    return im


def slime():
    im = _img()
    _rect(im, 3, 7, 13, 14, (90, 170, 220, 255))
    _rect(im, 4, 5, 12, 8, (90, 170, 220, 255))
    _rect(im, 5, 9, 7, 11, (220, 240, 255, 255))   # highlight
    im.putpixel((6, 10), BLACK)
    im.putpixel((10, 10), BLACK)
    _outline(im)
    return im


def cave_floor():
    im = _img()
    _rect(im, 0, 0, T, T, (78, 72, 86, 255))
    _scatter(im, [(3, 4), (11, 2), (6, 9), (13, 12), (8, 14), (2, 11), (9, 6)], (62, 56, 70, 255))
    _scatter(im, [(5, 3), (12, 8)], (96, 90, 104, 255))
    return im


def cave_wall():
    im = _img()
    _rect(im, 0, 0, T, T, (54, 50, 64, 255))
    _rect(im, 0, 0, T, 1, (78, 74, 90, 255))
    for y in (0, 5, 10, 15):
        _rect(im, 0, y, T, y + 1, (34, 30, 44, 255))
    for x, y in ((6, 0), (12, 5), (3, 10), (10, 10)):
        _rect(im, x, y, x + 1, y + 5, (34, 30, 44, 255))
    return im


def herb():
    im = _img()
    _rect(im, 7, 9, 9, 15, (90, 120, 60, 255))     # stem
    _rect(im, 4, 5, 7, 10, (96, 184, 96, 255))     # leaves
    _rect(im, 9, 5, 12, 10, (96, 184, 96, 255))
    _rect(im, 6, 3, 10, 7, (120, 208, 110, 255))
    _outline(im)
    return im


def _atlas(tiles, path_out):
    sheet = Image.new("RGBA", (T * len(tiles), T), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * T, 0))
    os.makedirs(os.path.dirname(path_out), exist_ok=True)
    sheet.save(path_out)
    print("wrote %s (%dx%d)" % (path_out, sheet.width, sheet.height))


def main():
    _atlas(
        [grass(), stone(), tree(), water(), path()],
        os.path.join(ROOT, "assets/tiles/overworld.png"),
    )
    _atlas(
        [cave_floor(), cave_wall()],
        os.path.join(ROOT, "assets/tiles/dungeon.png"),
    )
    _atlas(
        [
            person((90, 60, 40, 255), (240, 200, 160, 255), (70, 110, 200, 255)),    # hero
            person((60, 50, 40, 255), (240, 200, 160, 255), (150, 130, 90, 255)),    # villager(elder)
            person((40, 40, 50, 255), (240, 200, 160, 255), (180, 120, 60, 255)),    # merchant
            person((120, 120, 130, 255), (240, 200, 160, 255), (90, 160, 120, 255)), # apothecary
            person((110, 90, 60, 255), (240, 200, 160, 255), (150, 60, 60, 255)),    # swordsman
            person((70, 100, 60, 255), (220, 190, 150, 255), (80, 120, 70, 255)),    # forest_dweller
            herb(),                                                                  # herb
            slime(),                                                                 # slime
        ],
        os.path.join(ROOT, "assets/sprites/characters.png"),
    )


if __name__ == "__main__":
    main()
