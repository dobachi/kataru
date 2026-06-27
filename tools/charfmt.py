"""kataru キャラクター記法 v0 のパースと検証。

frontmatter:
- id（必須）, name
- hp, atk            … 初期能力
- exp_base           … Lv1→2 に必要な経験値
- exp_growth         … レベルごとに必要経験値へ加える量（need = exp_base + (level-1)*exp_growth）
- hp_growth, atk_growth … レベルアップ時の上昇量
"""
from __future__ import annotations

from dataclasses import dataclass

from mapfmt import LintIssue, _split_frontmatter

_DEFAULTS = {
    "hp": 20, "atk": 5,
    "exp_base": 10, "exp_growth": 10,
    "hp_growth": 5, "atk_growth": 1,
}


@dataclass
class CharDoc:
    id: str = ""
    name: str = ""
    hp: int = 20
    atk: int = 5
    exp_base: int = 10
    exp_growth: int = 10
    hp_growth: int = 5
    atk_growth: int = 1


def _to_int(v, default: int) -> int:
    try:
        return int(str(v).strip())
    except ValueError:
        return default


def parse(text: str) -> CharDoc:
    fm, _ = _split_frontmatter(text)
    return CharDoc(
        id=fm.get("id", ""),
        name=fm.get("name", ""),
        hp=_to_int(fm.get("hp", _DEFAULTS["hp"]), _DEFAULTS["hp"]),
        atk=_to_int(fm.get("atk", _DEFAULTS["atk"]), _DEFAULTS["atk"]),
        exp_base=_to_int(fm.get("exp_base", _DEFAULTS["exp_base"]), _DEFAULTS["exp_base"]),
        exp_growth=_to_int(fm.get("exp_growth", _DEFAULTS["exp_growth"]), _DEFAULTS["exp_growth"]),
        hp_growth=_to_int(fm.get("hp_growth", _DEFAULTS["hp_growth"]), _DEFAULTS["hp_growth"]),
        atk_growth=_to_int(fm.get("atk_growth", _DEFAULTS["atk_growth"]), _DEFAULTS["atk_growth"]),
    )


def lint(doc: CharDoc) -> list[LintIssue]:
    issues: list[LintIssue] = []
    if not doc.id:
        issues.append(LintIssue("error", "frontmatter に id がありません"))
    if not doc.name:
        issues.append(LintIssue("warning", "frontmatter に name がありません"))
    if doc.hp <= 0:
        issues.append(LintIssue("error", "hp は 1 以上にしてください"))
    if doc.exp_base <= 0:
        issues.append(LintIssue("error", "exp_base は 1 以上にしてください"))
    return issues


def to_char_dict(doc: CharDoc) -> dict:
    return {
        "id": doc.id, "name": doc.name, "hp": doc.hp, "atk": doc.atk,
        "exp_base": doc.exp_base, "exp_growth": doc.exp_growth,
        "hp_growth": doc.hp_growth, "atk_growth": doc.atk_growth,
    }
