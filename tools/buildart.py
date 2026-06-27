#!/usr/bin/env python3
"""外部CC0素材（Kenney Tiny Town / Tiny Dungeon, 16x16）から kataru のアトラスを組み立てる。

入力: assets/vendor/<pack>/tilemap_packed.png（16x16・12列・packed）
出力:
- assets/tiles/overworld.png   [grass, stone, tree, water, path, door]
- assets/tiles/dungeon.png     [floor, wall, stairs]
- assets/sprites/characters.png [hero, villager, merchant, apothecary,
                                 swordsman, forest_dweller, herb, slime]

タイル番号は各パックの tile_NNNN（packed の row-major, 12列）に一致。
差し替えたいときはこの対応表を編集して再生成する。
"""
from __future__ import annotations

import os

from PIL import Image

T = 16
COLS = 12
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _sheet(pack: str) -> Image.Image:
    return Image.open(os.path.join(ROOT, "assets/vendor", pack, "tilemap_packed.png")).convert("RGBA")


def _tile(sheet: Image.Image, idx: int) -> Image.Image:
    x = (idx % COLS) * T
    y = (idx // COLS) * T
    return sheet.crop((x, y, x + T, y + T))


def _atlas(tiles, out: str) -> None:
    sheet = Image.new("RGBA", (T * len(tiles), T), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * T, 0))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print("wrote %s (%dx%d)" % (out, sheet.width, sheet.height))


def main() -> None:
    tt = _sheet("tiny-town")
    td = _sheet("tiny-dungeon")

    # overworld: 0grass 1stone 2tree 3water(暫定grass) 4path 5door 6fence
    _atlas(
        [_tile(tt, 0), _tile(tt, 48), _tile(tt, 4), _tile(tt, 0), _tile(tt, 25), _tile(tt, 84), _tile(tt, 44)],
        os.path.join(ROOT, "assets/tiles/overworld.png"),
    )
    # dungeon: floor, wall, stairs(=扉)
    _atlas(
        [_tile(td, 48), _tile(td, 0), _tile(td, 32)],
        os.path.join(ROOT, "assets/tiles/dungeon.png"),
    )
    # characters: hero, villager(elder), merchant, apothecary, swordsman, forest_dweller, herb, slime
    _atlas(
        [
            _tile(td, 96),   # hero（騎士）
            _tile(td, 84),   # villager/elder（魔導士＝長老）
            _tile(td, 85),   # merchant（村人）
            _tile(td, 98),   # apothecary（女性）
            _tile(td, 87),   # swordsman（戦士）
            _tile(td, 100),  # forest_dweller（戦士系）
            _tile(tt, 17),   # herb（草）
            _tile(td, 108),  # slime（緑スライム）
        ],
        os.path.join(ROOT, "assets/sprites/characters.png"),
    )


if __name__ == "__main__":
    main()
