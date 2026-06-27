# シナリオ記法（ドラフト v0）

> ⚠️ これは **たたき台** です。S2 で実装しながら確定させます。
> 「人が書きやすく、AIが育てやすく、機械が変換しやすい」ことを目標に調整します。

## 方針

- 1ファイル1要素（マップ1つ、NPC1人 …）を基本とする
- メタ情報は **YAML frontmatter**、本文は **markdown** で書く
- ファイル名 or frontmatter の `id` で相互参照する
- 本文の見出し（`##`）をそのまま意味のある区切りとして使う

## ディレクトリ

```
scenario/
├── world.md          # 世界観・タイトル・導入
├── maps/<id>.md      # マップ
├── npcs/<id>.md      # NPC
└── quests/<id>.md    # クエスト（S5以降）
```

## world.md

```markdown
---
title: 物語のタイトル
start_map: village        # 開始マップの id
---

## あらすじ
ここに世界観や導入を書く。AIで育てる中心。
```

## maps/<id>.md（案）

ASCII でマップを描き、凡例でタイルを定義する案。古風2Dと相性がよく、人もAIも書きやすい。

```markdown
---
id: village
name: はじまりの村
tileset: overworld        # assets 側のタイルセット名
---

## レイアウト
```text
###########
#.........#
#..@......#
#.....N...#
#.........#
###########
```

## 凡例
- `#`: 壁（通行不可）
- `.`: 草地（通行可）
- `@`: プレイヤー初期位置
- `N`: NPC配置点（下記参照）

## 配置
- N: npc=elder      # npcs/elder.md
```

## npcs/<id>.md（案）

```markdown
---
id: elder
name: 村の長老
sprite: elder
---

## 会話
- こんにちは、旅の人。
- この村にようこそ。
```

## quests/<id>.md（案・S5以降）

```markdown
---
id: first-errand
name: 最初のおつかい
---

## 概要
長老から薬草を頼まれる。

## ステップ
1. 長老と話す
2. 森で薬草を拾う
3. 長老に届ける
```

## 変換後データ（data/*.json）のイメージ

変換ツールは上記 markdown を、Godot が読みやすい JSON に落とす。例（マップ）:

```json
{
  "id": "village",
  "name": "はじまりの村",
  "tileset": "overworld",
  "width": 11,
  "height": 6,
  "tiles": [[0,0,0, ...]],
  "player_start": [3, 2],
  "npcs": [{ "id": "elder", "pos": [6, 3] }]
}
```

## 未決事項（S2で詰める）

- タイル種別のコード化（凡例 → 数値 or 名前）
- 複数レイヤー（地面・装飾・コリジョン）の表現
- 大きなマップの扱い（ASCIIの限界 → 別形式 or タイルマップエディタ併用）
- 会話の分岐・条件・フラグの記法
