# kataru

**Markdown-driven 2D RPG**（Godot 4 製）。

シナリオを **markdown** で書き、AI（Claude Code など）で育てながら、古風な2D RPGとして遊べるようにすることを目指すプロジェクトです。

## コンセプト

- 古風な2Dゲーム風の見た目
- クロスプラットフォーム（Godot 4 のエクスポートを活用）
- **シナリオは markdown が真実の源（source of truth）**。人もAIも読み書きする
- 種となるテキストを書くと、**開発時に**AIでシナリオを育成・拡張できる
- ゲーム実行時はAIに依存せず動作する（再現性・配布性・コストの面で有利）
- アジャイル／インクリメンタルに開発する

詳細は [docs/concept.md](docs/concept.md) を参照。制作支援ツールの計画は [docs/authoring-tools.md](docs/authoring-tools.md) に集約している。

## データフロー

```
作者が種を書く ──▶ AI（Claude Code スキル）で markdown を育成・検証
                        │
                  scenario/*.md   ← 真実の源（人もAIも読み書き）
                        │ tools/ で変換（ビルド時）
                        ▼
                   data/*.json    ← Godot が読む構造化データ
                        │
                        ▼
                  Godot 4 ゲーム（実行時はAI不要・再現性あり）
```

## ディレクトリ構成

| パス | 役割 |
|---|---|
| `docs/` | コンセプト・ロードマップ・シナリオ記法の設計文書 |
| `scenario/` | markdown で書くシナリオ（真実の源） |
| `tools/` | markdown → JSON 変換ツール（ビルド時） |
| `data/` | 変換で生成された、Godot が読むデータ |
| `src/core/` | 将来エンジンとして抽出する汎用部分 |
| `src/game/` | この作品固有の部分 |
| `assets/` | タイルセット・スプライト・BGM など |
| `.claude/skills/` | シナリオ育成用のAIスキル |

## 開発環境

- [Godot 4](https://godotengine.org/)（GL Compatibility レンダラ前提）
- Python 3（制作支援ツール用。`pip3 install -r tools/requirements.txt`）

## 動かす

```bash
# シナリオ(markdown) -> データ(JSON) へ変換
make build           # = python3 tools/kataru.py convert --all

# ゲームを起動
make run             # = godot --path .   ※ Godotエディタで project.godot を開いて実行でも可
```

操作: 矢印キー/WASD=移動、Enter/Space=会話・選択決定、↑↓=選択肢、**I=もちもの**、**F5=セーブ / F9=ロード**、Esc=タイトル。

マップを編集したら `make build` で `data/` を再生成してから起動します。
制作支援ツールの詳細は [tools/README.md](tools/README.md) を参照。

## ロードマップ

[docs/roadmap.md](docs/roadmap.md) を参照。「まず歩いてNPCと話せる」を最初のマイルストーンにしています。

## ライセンス

[Apache License 2.0](LICENSE)
