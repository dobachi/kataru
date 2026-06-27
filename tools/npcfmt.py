"""kataru NPC記法 v0.3 のパースと検証。

記法:
- frontmatter: id（必須）, name, sprite
- 「## 会話」セクション（複数可）。見出しに条件・効果:
    ## 会話 if=quest_herb:started set=quest_herb:collected
- 会話本文の行:
    - ふつうの会話行
    ? 選択肢ラベル set=flag:value   … 選択肢（直後の「- 行」がその選択の応答）
  条件・効果・選択肢が一切無ければ、dialogue は文字列配列（後方互換）。
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from mapfmt import LintIssue, _split_frontmatter

_KV = re.compile(r"(if|set)=(\w+):(\w+)")
_SET = re.compile(r"set=(\w+):(\w+)")


@dataclass
class NpcDoc:
    id: str = ""
    name: str = ""
    sprite: str = ""
    branches: list[dict] = field(default_factory=list)


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
    cur_choice: dict | None = None
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("#"):
            heading = s.lstrip("#").strip()
            cur_choice = None
            if heading.startswith("会話"):
                rest = heading[len("会話"):]
                cond = None
                effect = None
                for m in _KV.finditer(rest):
                    if m.group(1) == "if":
                        cond = [m.group(2), m.group(3)]
                    else:
                        effect = [m.group(2), m.group(3)]
                cur = {"if": cond, "set": effect, "lines": [], "choices": []}
                branches.append(cur)
            else:
                cur = None
            continue
        if cur is None:
            continue
        if s.startswith("?"):
            rest = s[1:].strip()
            cset = None
            sm = _SET.search(rest)
            if sm:
                cset = [sm.group(1), sm.group(2)]
                rest = _SET.sub("", rest).strip()
            cur_choice = {"label": rest, "set": cset, "lines": []}
            cur["choices"].append(cur_choice)
            continue
        m = re.match(r"-\s+(.*)", s)
        if m:
            text = m.group(1).strip()
            if cur_choice is not None:
                cur_choice["lines"].append(text)
            else:
                cur["lines"].append(text)
    return [b for b in branches if b["lines"] or b["choices"]]


def lint(doc: NpcDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    if not doc.branches:
        issues.append(LintIssue("warning", "『会話』が空です"))
    for b in doc.branches:
        for c in b["choices"]:
            if not c["label"]:
                issues.append(LintIssue("error", "選択肢のラベルが空です"))
    return issues


def to_npc_dict(doc: NpcDoc) -> dict:
    only = doc.branches[0] if len(doc.branches) == 1 else None
    plain = only is not None and only["if"] is None and only["set"] is None and not only["choices"]
    if plain:
        dialogue: list = list(only["lines"])
    else:
        dialogue = []
        for b in doc.branches:
            entry = {"if": b["if"], "set": b["set"], "lines": b["lines"]}
            if b["choices"]:
                entry["choices"] = [
                    {"label": c["label"], "set": c["set"], "lines": c["lines"]} for c in b["choices"]
                ]
            dialogue.append(entry)
    return {
        "id": doc.id,
        "name": doc.name,
        "sprite": doc.sprite,
        "dialogue": dialogue,
    }
