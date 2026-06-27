# シナリオ記法 v0

> S2 で実装・確定した最小記法。`tools/kataru.py` がこの記法をパース・検証・変換する。
> 「人が書きやすく、AIが育てやすく、機械が変換しやすい」ことを目標に、今後拡張していく。

## 方針

- 1ファイル1要素（マップ1つ、NPC1人 …）
- メタ情報は **YAML風 frontmatter**（`key: value` のみ）、本文は markdown
- ファイル名 or frontmatter の `id` で相互参照する

## ディレクトリ

```
scenario/
├── world.md          # 世界観・タイトル・導入
├── maps/<id>.md      # マップ
├── npcs/<id>.md      # NPC（S3で本格利用）
└── quests/<id>.md    # クエスト（S5以降）
```

## maps/<id>.md（実装済み v0）

```markdown
---
id: village
name: はじまりの村
tileset: overworld
---

## レイアウト

(ここにフェンス済みコードブロックでマップを描く)

## 凡例
- `#`: 壁 / `.`: 床 / `@`: プレイヤー初期位置 / `N`: NPC配置点

## 配置
- N: npc=elder
```

### パースの規則（v0）

- **frontmatter**: `id`（必須）、`name`、`tileset` を読む
- **レイアウト**: 本文中の **最初のフェンス済みコードブロック** をマップとみなす
- **固定シンボル表**（v0は固定。凡例節は人間向けの説明）:
  | 記号 | 意味 | タイル |
  |---|---|---|
  | `#` | 壁（通行不可） | WALL(1) |
  | `.` | 床（通行可） | FLOOR(0) |
  | `@` | プレイヤー初期位置 | FLOOR(0) |
  | `A`〜`Z` | NPC配置点 | FLOOR(0) |
  | `a`〜`z` | 移動口（warp） | FLOOR(0) |
- **配置**: `- N: npc=elder` の形で、配置記号(大文字) → NPC id を対応づける
- **接続**: `- f: map=forest x=2 y=4` の形で、移動口(小文字) → 遷移先(マップid・到着座標)を対応づける
  - プレイヤーが移動口のマスを踏むと、指定マップの (x,y) へ移動する
  - 到着座標は「戻り口の隣」にすると往復ループを避けやすい

### lint（検証）が落とす条件

- `id` が無い（error）/ `name` が無い（warning）
- レイアウトが見つからない、矩形でない（error）
- 未知の記号がある（error）
- `@` が 2 個以上（error）/ 0 個（warning。開始マップ以外はwarpで入るので可）
- 配置記号に対応する `npc=` が無い（error）/ 配置にあるがマップに無い（warning）
- 移動口に対応する `接続` が無い（error）/ 接続にあるがマップに無い（warning）

## 変換後データ（data/maps/<id>.json）

```json
{
  "id": "village",
  "name": "はじまりの村",
  "tileset": "overworld",
  "width": 20,
  "height": 12,
  "player_start": [6, 4],
  "tiles": [[1,1,1, ...]],
  "npcs": [{ "id": "elder", "pos": [8, 9] }],
  "warps": [{ "pos": [18, 8], "map": "forest", "to": [2, 4] }]
}
```

Godot 側は `MapLoader.load_map()` がこの JSON を読み `WorldMap` を構築する。

## npcs/<id>.md（案・S3で確定）

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

## 今後の拡張（v1以降の候補）

- 凡例のカスタム定義（固定表をやめ、記号→タイルを宣言できるようにする）
- 複数レイヤー（地面・装飾・コリジョン）
- 会話の分岐・条件・フラグ
- 大きなマップ（ASCIIの限界 → Tiled(TMX) インポート等）
