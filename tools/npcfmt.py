"""kataru NPC記法 v0 のパースと検証。

記法v0:
- frontmatter: id（必須）, name, sprite
- 「## 会話」セクションの箇条書き（- ...）を会話行として順に読む
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from mapfmt import LintIssue, _split_frontmatter


@dataclass
class NpcDoc:
    id: str = ""
    name: str = ""
    sprite: str = ""
    dialogue: list[str] = field(default_factory=list)


def parse(text: str) -> NpcDoc:
    fm, body = _split_frontmatter(text)
    return NpcDoc(
        id=fm.get("id", ""),
        name=fm.get("name", ""),
        sprite=fm.get("sprite", ""),
        dialogue=_section_list(body, "会話"),
    )


def _section_list(body: str, heading: str) -> list[str]:
    out: list[str] = []
    in_section = False
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("#"):
            in_section = s.lstrip("#").strip() == heading
            continue
        if in_section:
            m = re.match(r"-\s+(.*)", s)
            if m:
                out.append(m.group(1).strip())
    return out


def lint(doc: NpcDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    if not doc.dialogue:
        issues.append(LintIssue("warning", "『会話』が空です"))
    return issues


def to_npc_dict(doc: NpcDoc) -> dict:
    return {
        "id": doc.id,
        "name": doc.name,
        "sprite": doc.sprite,
        "dialogue": doc.dialogue,
    }
