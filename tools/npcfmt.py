"""kataru NPC記法 v0.4 のパースと検証。

記法:
- frontmatter: id（必須）, name, sprite
- 「## 会話」セクション（複数可）。見出しに条件・効果を付けられる:
    ## 会話 if=met:yes if=key:a|key:b set=quest:done set=rep:high
    - if=フラグ:値              … 条件。複数の if= は AND
    - if=フラグ:値|フラグ:値    … 1つの if= 内は OR（いずれか一致でその条件を満たす）
    - set=フラグ:値             … 効果。複数指定でまとめて適用
    未設定フラグは "none" として扱う
- 会話本文:
    - ふつうの会話行
    ? 選択肢ラベル set=flag:value   … 選択肢（直後の「- 行」がその選択の応答。set= 複数可）
  条件・効果・選択肢が一切無ければ、dialogue は文字列配列（後方互換）。

条件(if)のJSON表現: AND の配列。各要素は OR グループ（[flag,value] の配列）。
  if=a:1 if=b:2|c:3  ->  [ [["a","1"]], [["b","2"],["c","3"]] ]
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from mapfmt import LintIssue, _split_frontmatter

_ATTR_TOKEN = re.compile(r"(?:if|set|give|take|has|nohas|battle)=\S+")


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


def _parse_attrs(rest: str) -> tuple[list, dict]:
    """見出し/選択肢の属性から (conds, ops) を取り出す。
    conds: ANDの配列。各要素は OR グループ [[flag,value], ...]。
    ops: { set:[[flag,value]], give:[id], take:[id], has:[id], nohas:[id] }
    """
    conds: list = []
    ops: dict = {"set": [], "give": [], "take": [], "has": [], "nohas": [], "battle": ""}
    for tok in rest.split():
        if tok.startswith("if="):
            group: list = []
            for alt in tok[3:].split("|"):
                if ":" in alt:
                    f, v = alt.split(":", 1)
                    group.append([f, v])
            if group:
                conds.append(group)
        elif tok.startswith("set="):
            body = tok[4:]
            if ":" in body:
                f, v = body.split(":", 1)
                ops["set"].append([f, v])
        elif tok.startswith("give="):
            if tok[5:]:
                ops["give"].append(tok[5:])
        elif tok.startswith("take="):
            if tok[5:]:
                ops["take"].append(tok[5:])
        elif tok.startswith("has="):
            if tok[4:]:
                ops["has"].append(tok[4:])
        elif tok.startswith("nohas="):
            if tok[6:]:
                ops["nohas"].append(tok[6:])
        elif tok.startswith("battle="):
            if tok[7:]:
                ops["battle"] = tok[7:]
    return conds, ops


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
                conds, ops = _parse_attrs(heading[len("会話"):])
                cur = {"if": conds, "lines": [], "choices": []}
                cur.update(ops)
                branches.append(cur)
            else:
                cur = None
            continue
        if cur is None:
            continue
        if s.startswith("?"):
            rest = s[1:].strip()
            _, cops = _parse_attrs(rest)
            label = _ATTR_TOKEN.sub("", rest).strip()
            cur_choice = {"label": label, "lines": []}
            cur_choice.update(cops)
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


_OP_KEYS = ("set", "give", "take", "has", "nohas", "battle")


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


def _has_ops(d: dict) -> bool:
    return any(d.get(k) for k in _OP_KEYS)


def _entry_with_ops(base: dict, src: dict) -> dict:
    for k in _OP_KEYS:
        if src.get(k):
            base[k] = src[k]
    return base


def to_npc_dict(doc: NpcDoc) -> dict:
    only = doc.branches[0] if len(doc.branches) == 1 else None
    plain = only is not None and not only["if"] and not only["choices"] and not _has_ops(only)
    if plain:
        dialogue: list = list(only["lines"])
    else:
        dialogue = []
        for b in doc.branches:
            entry = _entry_with_ops({"if": b["if"], "lines": b["lines"]}, b)
            if b["choices"]:
                entry["choices"] = [
                    _entry_with_ops({"label": c["label"], "lines": c["lines"]}, c) for c in b["choices"]
                ]
            dialogue.append(entry)
    return {
        "id": doc.id,
        "name": doc.name,
        "sprite": doc.sprite,
        "dialogue": dialogue,
    }
