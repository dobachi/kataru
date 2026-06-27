# tools

`scenario/*.md`（markdown・真実の源）を `data/*.json`（Godot が読む構造化データ）へ
変換・検証する、開発時の制作支援ツール（Python）。

## セットアップ

```bash
pip3 install -r tools/requirements.txt   # preview(PNG生成)に Pillow を使用
```

## コマンド（リポジトリ直下から）

```bash
# 検証（lint）: 矩形・記号・@の数・配置/接続をチェック
python3 tools/kataru.py lint --all

# クロス参照検証: npc/item/enemy/character/map/tileset の参照切れを検出
python3 tools/kataru.py xref

# 変換: scenario/maps/*.md -> data/maps/*.json（lintエラーがあればスキップ）
python3 tools/kataru.py convert --all

# 可視化: マップを PNG 化（目視確認用）
python3 tools/kataru.py preview scenario/maps/village.md -o build/village.png

# 雛形生成: 外周壁つき空マップを生成（座標ルーラーは標準エラーに出力）
python3 tools/kataru.py scaffold town --name 港町 --width 24 --height 16 -o scenario/maps/town.md
```

`make build` / `make lint`（リポジトリ直下の Makefile）でも実行可能。

## 構成

| ファイル | 役割 |
|---|---|
| `kataru.py` | CLI エントリ（lint / convert / preview / scaffold） |
| `mapfmt.py` | マップ記法v0のパースと検証・JSON変換 |
| `preview.py` | マップ → PNG（Pillow） |
| `scaffold.py` | 空マップ雛形の生成 |

記法の仕様は [../docs/scenario-schema.md](../docs/scenario-schema.md) を参照。
