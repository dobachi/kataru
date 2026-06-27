"""kataru マップ記法のパースと検証（タイルセット対応）。

記法:
- frontmatter: id（必須）, name, tileset（参照するタイルセットid）
- 本文中の最初のフェンス済みコードブロックを「レイアウト」とみなす
- 記号の意味:
    '@'        = プレイヤー初期位置（下は default 地形）
    'A'..'Z'   = NPC配置点（『配置』で npc= に解決。下は default 地形）
    'a'..'z'   = 移動口/warp（『接続』で map/x/y に解決。下は default 地形）
    それ以外   = 地形記号。タイルセットの『タイル』で 列(col)/通行可否(solid) が決まる
- 『配置』: "- N: npc=elder"
- 『接続』: "- f: map=forest x=2 y=4"

描画列・通行可否は **タイルセット** が決めるため、同じ記号でもタイルセットを変えれば
見た目（街/森/ダンジョン）と当たり判定を変えられる。
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

_PLACEMENT = re.compile(r"\s*-\s*([A-Z])\s*:\s*npc\s*=\s*(\S+)")
_CONNECTION = re.compile(r"\s*-\s*([a-z])\s*:\s*map\s*=\s*(\w+)\s+x\s*=\s*(\d+)\s+y\s*=\s*(\d+)")


@dataclass
class MapDoc:
    id: str = ""
    name: str = ""
    tileset: str = "overworld"
    grid: list[str] = field(default_factory=list)
    placements: dict[str, str] = field(default_factory=dict)
    connections: dict[str, dict] = field(default_factory=dict)


@dataclass
class LintIssue:
    level: str  # "error" | "warning"
    msg: str

    def __str__(self) -> str:
        mark = "✗" if self.level == "error" else "⚠"
        return f"  {mark} {self.msg}"


def parse(text: str) -> MapDoc:
    fm, body = _split_frontmatter(text)
    return MapDoc(
        id=fm.get("id", ""),
        name=fm.get("name", ""),
        tileset=fm.get("tileset", "overworld"),
        grid=_first_code_block(body),
        placements=_parse_placements(body),
        connections=_parse_connections(body),
    )


def _split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", text, re.DOTALL)
    if not m:
        return {}, text
    fm: dict[str, str] = {}
    for line in m.group(1).splitlines():
        line = line.strip()
        if not line or ":" not in line:
            continue
        k, v = line.split(":", 1)
        fm[k.strip()] = v.strip()
    return fm, m.group(2)


def _first_code_block(body: str) -> list[str]:
    out: list[str] = []
    in_block = False
    for line in body.splitlines():
        if line.strip().startswith("```"):
            if not in_block:
                in_block = True
                continue
            break
        if in_block:
            out.append(line)
    return out


def _parse_placements(body: str) -> dict[str, str]:
    res: dict[str, str] = {}
    for line in body.splitlines():
        m = _PLACEMENT.match(line)
        if m:
            res[m.group(1)] = m.group(2)
    return res


def _parse_connections(body: str) -> dict[str, dict]:
    res: dict[str, dict] = {}
    for line in body.splitlines():
        m = _CONNECTION.match(line)
        if m:
            res[m.group(1)] = {"map": m.group(2), "x": int(m.group(3)), "y": int(m.group(4))}
    return res


def _is_overlay(ch: str) -> bool:
    return ch == "@" or (ch.isalpha() and (ch.isupper() or ch.islower()))


def _under_symbol(grid: list[str], x: int, y: int, terrain: dict, default_sym: str) -> str:
    """オーバーレイ(キャラ/移動口)マスの下に敷く地形記号を隣接から推定する。
    優先: 左右が同じ地形/上下が同じ地形（＝道や帯を貫通）→ その地形。
    次点: 4近傍の地形の多数派。無ければ default（キャラの下に地形を置けるように）。
    """
    def terr(nx: int, ny: int):
        if 0 <= ny < len(grid) and 0 <= nx < len(grid[ny]):
            c = grid[ny][nx]
            if c in terrain and not _is_overlay(c):
                return c
        return None

    left, right = terr(x - 1, y), terr(x + 1, y)
    up, down = terr(x, y - 1), terr(x, y + 1)
    # 通り抜け（左右が同地形／上下が同地形）の候補。道などを通すため default 以外を優先。
    cands: list[str] = []
    if left is not None and left == right:
        cands.append(left)
    if up is not None and up == down:
        cands.append(up)
    for c in cands:
        if c != default_sym:
            return c
    if cands:
        return cands[0]
    counts: dict[str, int] = {}
    for c in (left, right, up, down):
        if c is not None:
            counts[c] = counts.get(c, 0) + 1
    if counts:
        return max(counts, key=lambda k: counts[k])
    return default_sym


def lint(doc: MapDoc, tileset: dict | None) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    if not tileset or not tileset.get("tiles"):
        issues.append(LintIssue("error", f"タイルセット '{doc.tileset}' が見つかりません"))
        tileset = {"tiles": {}, "default": "."}

    g = doc.grid
    if not g:
        issues.append(LintIssue("error", "レイアウト（コードブロック）が見つかりません"))
        return issues

    widths = sorted({len(r) for r in g})
    if len(widths) != 1:
        issues.append(LintIssue("error", f"マップが矩形ではありません（行の長さ: {widths}）"))

    terrain = tileset.get("tiles", {})
    npc_markers: set[str] = set()
    warp_markers: set[str] = set()
    starts = 0
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            if ch == "@":
                starts += 1
            elif ch.isalpha() and ch.isupper():
                npc_markers.add(ch)
            elif ch.isalpha() and ch.islower():
                warp_markers.add(ch)
            elif ch not in terrain:
                issues.append(LintIssue("error", f"未知の地形記号 '{ch}' at ({x},{y})（タイルセット '{doc.tileset}' に無い）"))

    if starts == 0:
        issues.append(LintIssue("warning", "プレイヤー初期位置 '@' がありません（開始マップなら必須）"))
    elif starts > 1:
        issues.append(LintIssue("error", f"プレイヤー初期位置 '@' が複数あります（{starts}個）"))

    for mk in sorted(npc_markers):
        if mk not in doc.placements:
            issues.append(LintIssue("error", f"配置記号 '{mk}' に対応する『配置』(npc=...) がありません"))
    for mk in sorted(doc.placements):
        if mk not in npc_markers:
            issues.append(LintIssue("warning", f"『配置』の '{mk}' がマップ上にありません"))
    for mk in sorted(warp_markers):
        if mk not in doc.connections:
            issues.append(LintIssue("error", f"移動口 '{mk}' に対応する『接続』(map=... x=.. y=..) がありません"))
    for mk in sorted(doc.connections):
        if mk not in warp_markers:
            issues.append(LintIssue("warning", f"『接続』の '{mk}' がマップ上にありません"))

    return issues


def to_map_dict(doc: MapDoc, tileset: dict) -> dict:
    """検証済みの MapDoc を、タイルセットで解決して Godot 用 JSON に変換する。
    tiles=描画列のグリッド, solid=通行不可フラグのグリッド を出力する。
    """
    terrain = tileset.get("tiles", {})
    default_sym = tileset.get("default", ".")
    g = doc.grid
    height = len(g)
    width = len(g[0]) if height else 0
    tiles: list[list[int]] = []
    solid: list[list[bool]] = []
    player_start = [1, 1]
    npcs: list[dict] = []
    warps: list[dict] = []
    for y, row in enumerate(g):
        trow: list[int] = []
        srow: list[bool] = []
        for x, ch in enumerate(row):
            if _is_overlay(ch):
                # キャラ/移動口の下は近傍から地形を推定（既定固定をやめる）
                sym = _under_symbol(g, x, y, terrain, default_sym)
                if ch == "@":
                    player_start = [x, y]
                elif ch.isupper():
                    npc_id = doc.placements.get(ch)
                    if npc_id:
                        npcs.append({"id": npc_id, "pos": [x, y]})
                elif ch.islower():
                    conn = doc.connections.get(ch)
                    if conn:
                        warps.append({"pos": [x, y], "map": conn["map"], "to": [conn["x"], conn["y"]]})
                tdef = terrain.get(sym, {"col": 0, "solid": False})
                col = int(tdef.get("col", 0))
                # 移動口マスは入口タイル(warp_col)で描く
                if ch.isalpha() and ch.islower() and int(tileset.get("warp_col", -1)) >= 0:
                    col = int(tileset["warp_col"])
                trow.append(col)
                srow.append(False)            # オーバーレイ上は通行可（NPCはoccupiedで別途ブロック）
            else:
                tdef = terrain.get(ch, {"col": 0, "solid": False})
                trow.append(int(tdef.get("col", 0)))
                srow.append(bool(tdef.get("solid", False)))
        tiles.append(trow)
        solid.append(srow)
    return {
        "id": doc.id,
        "name": doc.name,
        "tileset": doc.tileset,
        "image": tileset.get("image", "overworld.png"),
        "width": width,
        "height": height,
        "player_start": player_start,
        "tiles": tiles,
        "solid": solid,
        "npcs": npcs,
        "warps": warps,
    }
