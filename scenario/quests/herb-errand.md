---
id: herb-errand
name: 薬草のおつかい
flag: quest_herb
---

## 概要

村の薬屋に頼まれ、東の森で薬草を採って届ける、最初の小さなおつかい。

## ステップ

1. 薬屋(apothecary)に話しかける → 受注（`quest_herb=started`）
2. 東の森の薬草(herb-spot)を調べる → 採取（`quest_herb=collected`）
3. 薬屋に戻って話しかける → 納品・完了（`quest_herb=done`）

## 関連

- フラグ: `quest_herb`（none → started → collected → done）
- 実装: NPCの条件付き会話（[../../docs/scenario-schema.md](../../docs/scenario-schema.md)）で表現

> 注: 現状エンジンは quests/*.md を直接は読まない（フラグと条件付き会話で動く）。
> このファイルはクエスト設計の記録・育成の足場として置いている。
