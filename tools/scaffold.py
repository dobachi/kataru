"""空マップの雛形を生成する。外周を壁で囲み '@' を1つ置く。"""
from __future__ import annotations

_TEMPLATE = """---
id: {map_id}
name: {name}
tileset: {tileset}
---

## レイアウト

```
{grid}
```

## 凡例
- `#`: 壁（通行不可）
- `.`: 床（通行可）
- `@`: プレイヤー初期位置
- `A`〜`Z`: NPC配置点（『配置』で npc= に対応づけ）

## 配置
"""


def make_blank(map_id: str, name: str, width: int, height: int, tileset: str = "overworld") -> str:
    width = max(width, 3)
    height = max(height, 3)
    rows: list[str] = []
    for y in range(height):
        if y == 0 or y == height - 1:
            rows.append("#" * width)
        else:
            rows.append("#" + "." * (width - 2) + "#")
    r = list(rows[1])
    r[1] = "@"
    rows[1] = "".join(r)
    return _TEMPLATE.format(map_id=map_id, name=name, tileset=tileset, grid="\n".join(rows))


def ruler(width: int, height: int) -> str:
    """列番号ルーラー（手書き時の桁数え用。標準出力に出す）。"""
    tens = "".join(str((x // 10) % 10) for x in range(width))
    ones = "".join(str(x % 10) for x in range(width))
    return f"     {tens}\n     {ones}   (size: {width}x{height})"
