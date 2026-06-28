"""kataru ショップ記法 v0 のパースと検証。

frontmatter: id（必須）, name
「## 品揃え」セクションの `- item_id` を販売アイテムとして読む。価格は各アイテムの price。
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from mapfmt import LintIssue, _split_frontmatter


@dataclass
class ShopDoc:
    id: str = ""
    name: str = ""
    items: list = field(default_factory=list)   # 販売アイテムidの配列


def parse(text: str) -> ShopDoc:
    fm, body = _split_frontmatter(text)
    doc = ShopDoc(id=fm.get("id", ""), name=fm.get("name", ""))
    in_section = False
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("#"):
            in_section = s.lstrip("#").strip().startswith("品揃え")
            continue
        if in_section:
            m = re.match(r"-\s+(\S+)", s)
            if m:
                doc.items.append(m.group(1))
    return doc


def lint(doc: ShopDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    if not doc.items:
        issues.append(LintIssue("warning", "『品揃え』が空です"))
    return issues


def to_shop_dict(doc: ShopDoc) -> dict:
    return {"id": doc.id, "name": doc.name, "items": doc.items}
