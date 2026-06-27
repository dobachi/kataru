# tools

`scenario/*.md`（markdown・真実の源）を `data/*.json`（Godot が読む構造化データ）へ
変換・検証するビルド時ツールを置く。

S2 で実装予定。実装言語は未定（Python か Godot のツールスクリプトを検討）。

## 想定する責務

- frontmatter とマップ記法のパース
- 記法の検証（lint）：未定義の凡例、存在しない npc 参照 など
- `data/` への JSON 出力
