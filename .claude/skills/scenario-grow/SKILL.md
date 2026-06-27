---
name: scenario-grow
description: kataru のシナリオ(markdown)をAIで育てる。種や要望から、記法v0に沿ってマップ・NPC・会話を生成/拡張し、lint→convert で検証する。ゲーム実行時はAI非依存で、これは開発時に使う。
---

# scenario-grow — シナリオ育成スキル

kataru の `scenario/*.md`（真実の源）を、既存設定と矛盾しないように育てるスキル。
「種となるテキストをAIで成長させる」という本プロジェクトの核を担う。

## 使うタイミング

- 「村に〇〇なNPCを追加して」「会話を増やして」
- 「この世界観を膨らませて、新しいマップを足して」
- `world.md` の種を具体化したいとき

## 前提

- 記法は [docs/scenario-schema.md](../../../docs/scenario-schema.md)（v0）に従う
- 生成後は必ず lint→convert を通し、壊れた状態を残さない
- ゲーム実行時にAIは使わない。生成物は確定的な markdown / JSON として残す

## 手順

1. **既存把握**: `scenario/world.md` と `scenario/maps/*`・`scenario/npcs/*` を読み、世界観・口調・既存 id を把握する
2. **要望の確認**: 何を/どこに足すか（マップ / NPC / 会話）。曖昧な点だけ最小限に確認する
3. **生成**
   - NPC追加: `scenario/npcs/<id>.md` を作成（frontmatter `id`/`name`/`sprite`、`## 会話` に箇条書き）
   - マップ配置: 対象 `scenario/maps/<map>.md` のレイアウトに配置記号(`A`〜`Z`)を1つ置き、`## 配置` に `- X: npc=<id>` を追記。**床(`.`)のマスにだけ**置き、`@` や既存記号と衝突させない。矩形を崩さない（1文字を1文字で置換）
   - 新マップ: 必要なら scaffold で雛形を作ってから肉付け
     `python3 tools/kataru.py scaffold <id> --name <名> --width W --height H -o scenario/maps/<id>.md`
4. **検証**: `python3 tools/kataru.py lint --all` を実行し、`error` を全て解消する（`warning` は内容次第）
5. **反映**: `python3 tools/kataru.py convert --all` で `data/` を再生成する
6. **確認(任意)**: `python3 tools/kataru.py preview scenario/maps/<map>.md -o build/<map>.png` で配置を目視
7. **報告**: 追加/変更したファイルと内容を要約し、人のレビューを促す

## 原則

- **lore整合**: 既存の世界観・命名・口調に合わせる
- **小さく育てる**: 一度に盛りすぎない。差分でレビューできる粒度にする
- **源を壊さない**: 生成は「追記/新規」を基本とし、既存の大幅改変は提案ベースで
- **id 規則**: id は英小文字＋ハイフン。日本語名は `name` に書く
- **検証必須**: lint を通さずに data を生成しない

## 関連

- 記法: [docs/scenario-schema.md](../../../docs/scenario-schema.md)
- ツール: [tools/README.md](../../../tools/README.md)（lint / convert / preview / scaffold）
- 新規シナリオの立ち上げは `scenario-new`（初期セット作成ウィザード）
