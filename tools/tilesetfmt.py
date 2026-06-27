"""kataru タイルセット・パッケージ記法 v0 のパースと検証。

タイルセットは「記号 → (アトラス列, 通行可否)」を束ねたパッケージ。
マップは記号で書き、描画と当たり判定はタイルセットが決める。
同じ記号でもタイルセットを変えれば見た目/通行可否を変えられる。

記法:
---
id: overworld
image: overworld.png   # assets/tiles/ 配下の画像
default: .             # @ / NPC / 移動口 の下に敷く地形記号（通行可であること）
---

## タイル
- .: col=0          # 床（通行可）
- #: col=1 solid    # 壁（通行不可）

注意: 地形記号は非英字を使う（@ / A-Z=NPC / a-z=移動口 は予約）。
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from mapfmt import LintIssue, _split_frontmatter

_TILE = re.compile(r"-\s*(\S)\s*:\s*col=(\d+)(.*)$")


@dataclass
class TilesetDoc:
    id: str = ""
    image: str = ""
    default: str = "."
    warp_col: int = -1                          # 移動口マスの描画列（-1なら床と同じ）
    tiles: dict = field(default_factory=dict)   # sym -> {"col": int, "solid": bool}


def _to_int(v, default: int) -> int:
    try:
        return int(str(v).strip())
    except ValueError:
        return default


def parse(text: str) -> TilesetDoc:
    fm, body = _split_frontmatter(text)
    doc = TilesetDoc(
        id=fm.get("id", ""),
        image=fm.get("image", ""),
        default=(fm.get("default", ".") or ".")[0],
        warp_col=_to_int(fm.get("warp_col", "-1"), -1),
    )
    in_section = False
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("#") and not s.startswith("- "):
            in_section = s.lstrip("#").strip().startswith("タイル")
            continue
        if not in_section:
            continue
        m = _TILE.match(s)
        if m:
            doc.tiles[m.group(1)] = {"col": int(m.group(2)), "solid": "solid" in m.group(3)}
    return doc


def lint(doc: TilesetDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.image:
        issues.append(LintIssue("error", "frontmatter に image がありません"))
    if not doc.tiles:
        issues.append(LintIssue("error", "『タイル』が空です"))
    if doc.default not in doc.tiles:
        issues.append(LintIssue("error", "default の記号 '%s' が『タイル』にありません" % doc.default))
    elif doc.tiles[doc.default]["solid"]:
        issues.append(LintIssue("error", "default の記号 '%s' は通行可(solidでない)にしてください" % doc.default))
    return issues


def to_tileset_dict(doc: TilesetDoc) -> dict:
    return {
        "id": doc.id, "image": doc.image, "default": doc.default,
        "warp_col": doc.warp_col, "tiles": doc.tiles,
    }
