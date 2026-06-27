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

## npcs/<id>.md（v0.2：条件付き会話）

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

### 条件付き会話・フラグ

見出しに `if=` / `set=` を付けると、状態（フラグ）で会話を出し分けできる。
採取オブジェクト等も「NPC」として同じ仕組みで表現する。

```markdown
## 会話 if=quest_herb:done
- 先日は助かったよ。

## 会話 if=quest_herb:collected set=quest_herb:done
- おお、採ってきてくれたか！

## 会話 if=quest_herb:started
- 薬草はまだかい？

## 会話 set=quest_herb:started
- 東の森で薬草を採ってきてくれないか？
```

- `if=フラグ:値` … そのフラグが指定値のとき表示（未設定は `none` 扱い）
- `set=フラグ:値` … 表示した瞬間にそのフラグを設定する
- 分岐は**先頭から最初に条件一致したもの**が選ばれる（具体的＝進んだ状態を上に書く）
- 条件・効果が1つも無ければ、従来どおり単純な会話（後方互換）

#### 複数フラグ（AND / OR / 複数 set）

```markdown
## 会話 if=quest_herb:done if=met_dweller:yes set=reward:given set=rep:high
- 鍵も薬草も揃ったな。礼をしよう。
```

- **複数の `if=`** … すべて満たす（**AND**）
- **1つの `if=` 内で `a:1|b:2`** … いずれか満たす（**OR**）。例: `if=quest:started|quest:collected`
- **複数の `set=`** … まとめて適用（選択肢 `?` の `set=` も同様）

#### アイテムの授受・所持条件

- `give=item_id` … そのアイテムを所持品に加える（会話・選択肢の効果）
- `take=item_id` … 所持品から取り除く
- `has=item_id` … そのアイテムを持っているとき表示（条件・複数指定でAND）
- `nohas=item_id` … 持っていないとき表示

```markdown
## 会話 if=quest_herb:started set=quest_herb:collected give=herb
- 薬草を摘んで袋に入れた。

## 会話 has=herb take=herb set=quest:done
- 薬草を渡した。ありがとう。
```

所持品（インベントリ）は実行中保持され、セーブにも含まれる。アイテムは `scenario/items/<id>.md` で定義する。

#### 戦闘の開始

- `battle=enemy_id` … その会話を見終えると戦闘を開始する（敵は `scenario/enemies/<id>.md`）

```markdown
## 会話 battle=slime
- スライムが ぶつかってきた！
```

勝つと、話しかけた相手（敵NPC）はマップから取り除かれる。敗北すると全回復して村で目覚める。

変換後 JSON の `if` は「ANDの配列（各要素はORグループ）」、`set` は「`[flag,value]` の配列」:

```json
"dialogue": [
  { "if": [[["quest_herb","done"]], [["met_dweller","yes"]]], "set": [],
    "lines": ["森の住人にも会ったんだな。"] },
  { "if": [[["quest_herb","started"],["quest_herb","collected"]]], "set": [["met_dweller","yes"]],
    "lines": ["薬草を探しているのかい？"] },
  { "if": [], "set": [["quest_herb","started"]], "lines": ["…採ってきてくれないか？"] }
]
```

（`if: [[A,B],[C]]` は「(A または B) かつ C」。`if: []` は無条件。）

フラグはゲーム実行中に保持され（マップ遷移をまたぐ）、クエスト進行に使う。

### 選択肢（プレイヤーの分岐）

会話本文のあとに `? ラベル` で選択肢を置ける。各選択肢の直後の `- 行` が、その選択の応答。
選択肢にも `set=` を付けられる。

```markdown
## 会話 if=quest_herb:none
- 東の森で薬草を採ってきてくれないか？
? 引き受ける set=quest_herb:started
- ありがとう、助かるよ。
? 今はやめておく
- そうかい。気が向いたら、また来ておくれ。
```

- 会話＝本文（送り）→ 選択（↑↓で選び ui_accept で決定）→ 選んだ応答（送り）→ 終了
- 変換後 JSON では分岐に `choices: [{label, set, lines}]` が付く
- 選んだ瞬間に、その選択肢の `set` が適用される

## items/<id>.md（アイテム）

```markdown
---
id: herb
name: 薬草
---

## 説明
東の森に生える、よく効く薬草。
```

会話の `give=`/`take=`/`has=`/`nohas=` から id で参照する。変換後 `data/items/<id>.json`。

## enemies/<id>.md（敵）

```markdown
---
id: slime
name: スライム
hp: 8
atk: 3
def: 1
exp: 5
---
```

会話の `battle=` から id で参照する。変換後 `data/enemies/<id>.json`。
戦闘はターン制（たたかう／にげる）。勝つと `exp` を得る。

## characters/<id>.md（キャラクター）

プレイヤーは「キャラクター」として定義する。レベルカーブ（必要経験値・上昇量）を
**キャラごとに**設定できる。

```markdown
---
id: hero
name: 主人公
hp: 20            # 初期最大HP
atk: 5            # 初期ちから
def: 2            # 初期まもり（防御）
mp: 8             # 初期最大MP
exp_base: 10      # Lv1→2 に必要な経験値
exp_growth: 10    # レベルごとに必要経験値へ加える量
hp_growth: 5      # レベルアップ時の最大HP上昇
atk_growth: 1     # レベルアップ時のちから上昇
def_growth: 1     # レベルアップ時のまもり上昇
mp_growth: 2      # レベルアップ時の最大MP上昇
---
```

ダメージは `max(1, こうげき - 相手のまもり)`。レベルアップで HP/MP は全回復。
MP はステータスに保持・表示（消費するスキル/呪文は将来追加）。

- 次レベルに必要な経験値 = `exp_base + (level-1) * exp_growth`
- 開始キャラは `Main.gd` の `START_CHAR`（現在 `hero`）
- 実行中のステータス（level/exp/hp/max_hp/atk と曲線）はセーブに含まれる
- ステータスは「もちもの」(I) で確認できる
- 例: `knight` は HP が高く成長は遅い、という別曲線を持つ

### パーティ（仲間）

- `join=charid`（会話の効果）で、そのキャラがパーティに加わる（重複加入しない）
- パーティの先頭がリーダー（マップ表示・戦闘担当）
- 経験値は戦闘勝利でパーティ全員に入る（各自の曲線でレベルアップ）
- 「もちもの」(I) で全員のステータスを表示。パーティはセーブに含まれる

```markdown
## 会話 set=joined_knight:yes join=knight
- 私も旅の仲間に加えてくれ！
```

加入すると、その相手NPCはマップから消える。再訪やロード後も出さないよう、
NPCの frontmatter に `hide_if: flag:value` を書くと、その条件下では配置されない。

```markdown
---
id: swordsman
name: 旅の剣士
hide_if: joined_knight:yes   # 仲間にした後は出現しない
---
```

## 今後の拡張（v1以降の候補）

- 凡例のカスタム定義（固定表をやめ、記号→タイルを宣言できるようにする）
- 複数レイヤー（地面・装飾・コリジョン）
- 会話の分岐・条件・フラグ
- 大きなマップ（ASCIIの限界 → Tiled(TMX) インポート等）
