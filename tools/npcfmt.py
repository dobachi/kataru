"""kataru NPC記法 v0.2 のパースと検証。

記法:
- frontmatter: id（必須）, name, sprite
- 「## 会話」セクション（複数可）の箇条書き（- ...）を会話行として読む
- 見出しに条件・効果を付けられる:
    ## 会話 if=quest_herb:started set=quest_herb:collected
    - if=フラグ:値   … そのフラグが指定値のとき表示（未設定は "none" 扱い）
    - set=フラグ:値  … 表示時にそのフラグを設定する
  条件付きが1つも無ければ、dialogue は従来どおり文字列配列（後方互換）。
  条件付きがあれば、dialogue は分岐配列 [{if,set,lines}] となり、先頭から最初に
  条件一致した分岐が選ばれる。
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from mapfmt import LintIssue, _split_frontmatter

_KV = re.compile(r"(if|set)=(\w+):(\w+)")


@dataclass
class NpcDoc:
    id: str = ""
    name: str = ""
    sprite: str = ""
    branches: list[dict] = field(default_factory=list)  # [{if:[k,v]|None, set:[k,v]|None, lines:[...]}]


def parse(text: str) -> NpcDoc:
    fm, body = _split_frontmatter(text)
    return NpcDoc(
        id=fm.get("id", ""),
        name=fm.get("name", ""),
        sprite=fm.get("sprite", ""),
        branches=_parse_dialogue(body),
    )


def _parse_dialogue(body: str) -> list[dict]:
    branches: list[dict] = []
    cur: dict | None = None
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("#"):
            heading = s.lstrip("#").strip()
            if heading.startswith("会話"):
                rest = heading[len("会話"):]
                cond = None
                effect = None
                for m in _KV.finditer(rest):
                    if m.group(1) == "if":
                        cond = [m.group(2), m.group(3)]
                    else:
                        effect = [m.group(2), m.group(3)]
                cur = {"if": cond, "set": effect, "lines": []}
                branches.append(cur)
            else:
                cur = None
            continue
        if cur is not None:
            m = re.match(r"-\s+(.*)", s)
            if m:
                cur["lines"].append(m.group(1).strip())
    return [b for b in branches if b["lines"]]


def lint(doc: NpcDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    if not doc.branches:
        issues.append(LintIssue("warning", "『会話』が空です"))
    return issues


def to_npc_dict(doc: NpcDoc) -> dict:
    # 条件・効果が一切なければ従来形式（文字列配列）で後方互換に保つ
    plain = len(doc.branches) == 1 and doc.branches[0]["if"] is None and doc.branches[0]["set"] is None
    if plain:
        dialogue: list = list(doc.branches[0]["lines"])
    else:
        dialogue = [{"if": b["if"], "set": b["set"], "lines": b["lines"]} for b in doc.branches]
    return {
        "id": doc.id,
        "name": doc.name,
        "sprite": doc.sprite,
        "dialogue": dialogue,
    }
