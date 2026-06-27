"""kataru マップ記法 v0.1 のパースと検証。

記法:
- frontmatter: id（必須）, name, tileset
- 本文中の最初のフェンス済みコードブロックを「レイアウト」とみなす
- シンボル表:
    '#' = 壁(WALL) / '.' = 床(FLOOR) / '@' = プレイヤー初期位置(床扱い)
    'A'..'Z' = NPC配置点（床扱い。『配置』で npc= に解決）
    'a'..'z' = 移動口/warp（床扱い。『接続』で map/x/y に解決）
- 『配置』: "- N: npc=elder"            配置記号(大文字) -> NPC id
- 『接続』: "- f: map=forest x=2 y=4"    移動口(小文字) -> 遷移先(map,x,y)
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

WALL = 1
FLOOR = 0

_KNOWN = re.compile(r"[#.@A-Za-z]")
_PLACEMENT = re.compile(r"\s*-\s*([A-Z])\s*:\s*npc\s*=\s*(\S+)")
_CONNECTION = re.compile(r"\s*-\s*([a-z])\s*:\s*map\s*=\s*(\w+)\s+x\s*=\s*(\d+)\s+y\s*=\s*(\d+)")


@dataclass
class MapDoc:
    id: str = ""
    name: str = ""
    tileset: str = "overworld"
    grid: list[str] = field(default_factory=list)
    placements: dict[str, str] = field(default_factory=dict)         # 記号 -> npc id
    connections: dict[str, dict] = field(default_factory=dict)        # 記号 -> {map,x,y}


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


def lint(doc: MapDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))

    g = doc.grid
    if not g:
        issues.append(LintIssue("error", "レイアウト（コードブロック）が見つかりません"))
        return issues

    widths = sorted({len(r) for r in g})
    if len(widths) != 1:
        issues.append(LintIssue("error", f"マップが矩形ではありません（行の長さ: {widths}）"))

    npc_markers: set[str] = set()
    warp_markers: set[str] = set()
    starts = 0
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            if not _KNOWN.fullmatch(ch):
                shown = repr(ch).strip("'")
                issues.append(LintIssue("error", f"未知の記号 '{shown}' at ({x},{y})"))
            if ch == "@":
                starts += 1
            elif ch.isalpha() and ch.isupper():
                npc_markers.add(ch)
            elif ch.isalpha() and ch.islower():
                warp_markers.add(ch)

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


def to_map_dict(doc: MapDoc) -> dict:
    """検証済みの MapDoc を、Godot が読む JSON 構造へ変換する。"""
    g = doc.grid
    height = len(g)
    width = len(g[0]) if height else 0
    tiles: list[list[int]] = []
    player_start = [1, 1]
    npcs: list[dict] = []
    warps: list[dict] = []
    for y, row in enumerate(g):
        trow: list[int] = []
        for x, ch in enumerate(row):
            trow.append(WALL if ch == "#" else FLOOR)
            if ch == "@":
                player_start = [x, y]
            elif ch.isalpha() and ch.isupper():
                npc_id = doc.placements.get(ch)
                if npc_id:
                    npcs.append({"id": npc_id, "pos": [x, y]})
            elif ch.isalpha() and ch.islower():
                conn = doc.connections.get(ch)
                if conn:
                    warps.append({"pos": [x, y], "map": conn["map"], "to": [conn["x"], conn["y"]]})
        tiles.append(trow)
    return {
        "id": doc.id,
        "name": doc.name,
        "tileset": doc.tileset,
        "width": width,
        "height": height,
        "player_start": player_start,
        "tiles": tiles,
        "npcs": npcs,
        "warps": warps,
    }
