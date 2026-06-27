#!/usr/bin/env python3
"""kataru 制作支援ツール CLI。

使い方（リポジトリ直下から）:
  python3 tools/kataru.py lint --all
  python3 tools/kataru.py convert --all
  python3 tools/kataru.py preview scenario/maps/village.md -o build/village.png
  python3 tools/kataru.py scaffold town --name 港町 --width 24 --height 16 -o scenario/maps/town.md
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import charfmt  # noqa: E402
import enemyfmt  # noqa: E402
import itemfmt  # noqa: E402
import mapfmt  # noqa: E402
import npcfmt  # noqa: E402
import scaffold  # noqa: E402
import tilesetfmt  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SCENARIO_MAPS = ROOT / "scenario" / "maps"
SCENARIO_NPCS = ROOT / "scenario" / "npcs"
SCENARIO_ITEMS = ROOT / "scenario" / "items"
SCENARIO_ENEMIES = ROOT / "scenario" / "enemies"
SCENARIO_CHARS = ROOT / "scenario" / "characters"
SCENARIO_TILESETS = ROOT / "scenario" / "tilesets"
DATA_MAPS = ROOT / "data" / "maps"
DATA_NPCS = ROOT / "data" / "npcs"
DATA_ITEMS = ROOT / "data" / "items"
DATA_ENEMIES = ROOT / "data" / "enemies"
DATA_CHARS = ROOT / "data" / "characters"
DATA_TILESETS = ROOT / "data" / "tilesets"


def _kind_of(path: Path) -> str:
    if "npcs" in path.parts:
        return "npc"
    if "items" in path.parts:
        return "item"
    if "enemies" in path.parts:
        return "enemy"
    if "characters" in path.parts:
        return "character"
    if "tilesets" in path.parts:
        return "tileset"
    return "map"


def _targets(args) -> list[tuple[Path, str]]:
    """処理対象を (パス, 種別) で返す。"""
    if getattr(args, "all", False):
        return (
            [(p, "tileset") for p in sorted(SCENARIO_TILESETS.glob("*.md"))]
            + [(p, "map") for p in sorted(SCENARIO_MAPS.glob("*.md"))]
            + [(p, "npc") for p in sorted(SCENARIO_NPCS.glob("*.md"))]
            + [(p, "item") for p in sorted(SCENARIO_ITEMS.glob("*.md"))]
            + [(p, "enemy") for p in sorted(SCENARIO_ENEMIES.glob("*.md"))]
            + [(p, "character") for p in sorted(SCENARIO_CHARS.glob("*.md"))]
        )
    return [(Path(p), _kind_of(Path(p))) for p in args.files]


def _tileset_for(doc) -> dict:
    """マップが参照するタイルセットを読み込む（無ければ空dict）。"""
    path = SCENARIO_TILESETS / f"{doc.tileset}.md"
    if not path.exists():
        return {}
    return tilesetfmt.to_tileset_dict(tilesetfmt.parse(path.read_text(encoding="utf-8")))


def _parse_and_lint(path: Path, kind: str):
    text = path.read_text(encoding="utf-8")
    if kind == "npc":
        doc = npcfmt.parse(text)
        return doc, npcfmt.lint(doc)
    if kind == "item":
        doc = itemfmt.parse(text)
        return doc, itemfmt.lint(doc)
    if kind == "enemy":
        doc = enemyfmt.parse(text)
        return doc, enemyfmt.lint(doc)
    if kind == "character":
        doc = charfmt.parse(text)
        return doc, charfmt.lint(doc)
    if kind == "tileset":
        doc = tilesetfmt.parse(text)
        return doc, tilesetfmt.lint(doc)
    doc = mapfmt.parse(text)
    return doc, mapfmt.lint(doc, _tileset_for(doc))


def cmd_lint(args) -> int:
    targets = _targets(args)
    if not targets:
        print("対象ファイルがありません（--all か ファイル指定を）", file=sys.stderr)
        return 2
    had_error = False
    for path, kind in targets:
        doc, issues = _parse_and_lint(path, kind)
        errors = [i for i in issues if i.level == "error"]
        print(f"[{'OK' if not errors else 'NG'}] ({kind}) {path}")
        for i in issues:
            print(i)
        had_error = had_error or bool(errors)
    return 1 if had_error else 0


def cmd_convert(args) -> int:
    targets = _targets(args)
    if not targets:
        print("対象ファイルがありません（--all か ファイル指定を）", file=sys.stderr)
        return 2
    DATA_MAPS.mkdir(parents=True, exist_ok=True)
    DATA_NPCS.mkdir(parents=True, exist_ok=True)
    DATA_ITEMS.mkdir(parents=True, exist_ok=True)
    DATA_ENEMIES.mkdir(parents=True, exist_ok=True)
    DATA_CHARS.mkdir(parents=True, exist_ok=True)
    DATA_TILESETS.mkdir(parents=True, exist_ok=True)
    had_error = False
    for path, kind in targets:
        doc, issues = _parse_and_lint(path, kind)
        errors = [i for i in issues if i.level == "error"]
        if errors:
            had_error = True
            print(f"[skip] ({kind}) {path}（lintエラーのため変換しません）")
            for e in errors:
                print(e)
            continue
        if kind == "npc":
            data = npcfmt.to_npc_dict(doc)
            out = DATA_NPCS / f"{doc.id}.json"
        elif kind == "item":
            data = itemfmt.to_item_dict(doc)
            out = DATA_ITEMS / f"{doc.id}.json"
        elif kind == "enemy":
            data = enemyfmt.to_enemy_dict(doc)
            out = DATA_ENEMIES / f"{doc.id}.json"
        elif kind == "character":
            data = charfmt.to_char_dict(doc)
            out = DATA_CHARS / f"{doc.id}.json"
        elif kind == "tileset":
            data = tilesetfmt.to_tileset_dict(doc)
            out = DATA_TILESETS / f"{doc.id}.json"
        else:
            data = mapfmt.to_map_dict(doc, _tileset_for(doc))
            out = DATA_MAPS / f"{doc.id}.json"
        out.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"[ok] ({kind}) {path} -> {out.relative_to(ROOT)}")
    return 1 if had_error else 0


def cmd_preview(args) -> int:
    import preview  # 遅延import（Pillow未導入でも他コマンドは動く）

    doc = mapfmt.parse(Path(args.file).read_text(encoding="utf-8"))
    img = preview.render(doc, tile=args.tile)
    out = Path(args.out) if args.out else ROOT / "build" / f"{doc.id or 'map'}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"[ok] preview -> {out}")
    return 0


def _collect_ids(directory: Path, fmt) -> set:
    ids: set = set()
    if not directory.exists():
        return ids
    for p in sorted(directory.glob("*.md")):
        ids.add(fmt.parse(p.read_text(encoding="utf-8")).id)
    return ids


def cmd_xref(args) -> int:
    """シナリオ間の参照（npc/item/enemy/character/map/tileset）の存在を検証する。"""
    maps = _collect_ids(SCENARIO_MAPS, mapfmt)
    npcs = _collect_ids(SCENARIO_NPCS, npcfmt)
    items = _collect_ids(SCENARIO_ITEMS, itemfmt)
    enemies = _collect_ids(SCENARIO_ENEMIES, enemyfmt)
    chars = _collect_ids(SCENARIO_CHARS, charfmt)
    tilesets = _collect_ids(SCENARIO_TILESETS, tilesetfmt)
    errors: list[str] = []

    def need(kind_set: set, ref: str, where: str, label: str):
        if ref and ref not in kind_set:
            errors.append(f"{where}: {label} '{ref}' が見つかりません")

    # マップ: tileset / npc配置 / 接続先マップ
    for p in sorted(SCENARIO_MAPS.glob("*.md")):
        doc = mapfmt.parse(p.read_text(encoding="utf-8"))
        w = f"maps/{p.name}"
        need(tilesets, doc.tileset, w, "tileset")
        for sym, npc_id in doc.placements.items():
            need(npcs, npc_id, w, f"配置 {sym}: npc")
        for sym, conn in doc.connections.items():
            need(maps, conn["map"], w, f"接続 {sym}: map")

    # NPC: give/take/has/nohas(item) / battle(enemy) / join(character)
    for p in sorted(SCENARIO_NPCS.glob("*.md")):
        doc = npcfmt.parse(p.read_text(encoding="utf-8"))
        w = f"npcs/{p.name}"
        for b in doc.branches:
            sources = [b] + list(b.get("choices", []))
            for src in sources:
                for it in src.get("give", []) + src.get("take", []) + src.get("has", []) + src.get("nohas", []):
                    need(items, it, w, "item")
            if b.get("battle"):
                need(enemies, b["battle"], w, "battle: enemy")
            for cid in b.get("join", []):
                need(chars, cid, w, "join: character")

    # world.md: start_map
    world = ROOT / "scenario" / "world.md"
    if world.exists():
        fm, _ = mapfmt._split_frontmatter(world.read_text(encoding="utf-8"))
        need(maps, fm.get("start_map", ""), "world.md", "start_map")

    if errors:
        print("[xref] 参照エラー:")
        for e in errors:
            print(f"  ✗ {e}")
        return 1
    print("[xref] OK（参照切れなし）")
    return 0


def cmd_scaffold(args) -> int:
    md = scaffold.make_blank(args.id, args.name or args.id, args.width, args.height)
    if args.out:
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(md, encoding="utf-8")
        print(f"[ok] scaffold -> {out}")
    else:
        sys.stdout.write(md)
    print(scaffold.ruler(args.width, args.height), file=sys.stderr)
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="kataru", description="kataru 制作支援ツール")
    sub = p.add_subparsers(dest="cmd", required=True)

    lp = sub.add_parser("lint", help="マップ記法を検証")
    lp.add_argument("files", nargs="*")
    lp.add_argument("--all", action="store_true", help="scenario/maps/*.md すべて")
    lp.set_defaults(func=cmd_lint)

    cp = sub.add_parser("convert", help="md -> data/maps/*.json")
    cp.add_argument("files", nargs="*")
    cp.add_argument("--all", action="store_true", help="scenario/maps/*.md すべて")
    cp.set_defaults(func=cmd_convert)

    xp = sub.add_parser("xref", help="シナリオ間の参照切れを検証")
    xp.set_defaults(func=cmd_xref)

    pp = sub.add_parser("preview", help="マップを PNG 化")
    pp.add_argument("file")
    pp.add_argument("-o", "--out")
    pp.add_argument("--tile", type=int, default=24)
    pp.set_defaults(func=cmd_preview)

    sp = sub.add_parser("scaffold", help="空マップ雛形を生成")
    sp.add_argument("id")
    sp.add_argument("--name")
    sp.add_argument("--width", type=int, default=20)
    sp.add_argument("--height", type=int, default=12)
    sp.add_argument("-o", "--out")
    sp.set_defaults(func=cmd_scaffold)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
