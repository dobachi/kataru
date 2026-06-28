"""kataru アイテム記法 v0 のパースと検証。

記法:
- frontmatter: id（必須）, name
- 「## 説明」セクションの本文を desc にまとめる
"""
from __future__ import annotations

from dataclasses import dataclass

from mapfmt import LintIssue, _split_frontmatter


@dataclass
class ItemDoc:
    id: str = ""
    name: str = ""
    desc: str = ""
    heal_hp: int = 0
    heal_mp: int = 0
    price: int = 0


def _to_int(v, default: int) -> int:
    try:
        return int(str(v).strip())
    except ValueError:
        return default


def parse(text: str) -> ItemDoc:
    fm, body = _split_frontmatter(text)
    return ItemDoc(
        id=fm.get("id", ""),
        name=fm.get("name", ""),
        desc=_desc(body),
        heal_hp=_to_int(fm.get("heal_hp", "0"), 0),
        heal_mp=_to_int(fm.get("heal_mp", "0"), 0),
        price=_to_int(fm.get("price", "0"), 0),
    )


def _desc(body: str) -> str:
    lines: list[str] = []
    in_section = False
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("#"):
            in_section = s.lstrip("#").strip() == "説明"
            continue
        if in_section and s:
            lines.append(s)
    return " ".join(lines)


def lint(doc: ItemDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    return issues


def to_item_dict(doc: ItemDoc) -> dict:
    return {
        "id": doc.id, "name": doc.name, "desc": doc.desc,
        "heal_hp": doc.heal_hp, "heal_mp": doc.heal_mp, "price": doc.price,
    }
