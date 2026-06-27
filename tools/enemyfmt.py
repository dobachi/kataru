"""kataru 敵データ記法 v0 のパースと検証。

記法:
- frontmatter: id（必須）, name, hp, atk
"""
from __future__ import annotations

from dataclasses import dataclass

from mapfmt import LintIssue, _split_frontmatter


@dataclass
class EnemyDoc:
    id: str = ""
    name: str = ""
    hp: int = 1
    atk: int = 1
    defense: int = 0
    exp: int = 0


def _to_int(v: str, default: int) -> int:
    try:
        return int(str(v).strip())
    except ValueError:
        return default


def parse(text: str) -> EnemyDoc:
    fm, _ = _split_frontmatter(text)
    return EnemyDoc(
        id=fm.get("id", ""),
        name=fm.get("name", ""),
        hp=_to_int(fm.get("hp", "1"), 1),
        atk=_to_int(fm.get("atk", "1"), 1),
        defense=_to_int(fm.get("def", "0"), 0),
        exp=_to_int(fm.get("exp", "0"), 0),
    )


def lint(doc: EnemyDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    if doc.hp <= 0:
        issues.append(LintIssue("error", "hp は 1 以上にしてください"))
    return issues


def to_enemy_dict(doc: EnemyDoc) -> dict:
    return {"id": doc.id, "name": doc.name, "hp": doc.hp, "atk": doc.atk, "def": doc.defense, "exp": doc.exp}
