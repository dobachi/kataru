# クレジット / ライセンス

kataru はライセンスを **層ごと** に分けて管理しています。

## コード
- 本体（`src/`, `tools/`, シナリオ記法など）: **Apache License 2.0**（[LICENSE](LICENSE) 参照）

## 素材（フォント・アート・音）
第三者素材はそれぞれのライセンスに従います。利用時はこの一覧に追記してください。

### フォント
- **DotGothic16** — Fontworks Inc.（Google Fonts 提供）
  - ライセンス: SIL Open Font License 1.1
  - ファイル: `assets/fonts/DotGothic16-Regular.ttf`
  - ライセンス全文: `assets/fonts/DotGothic16-OFL.txt`

### アート（タイル・キャラ）
- **Kenney「Tiny Town」「Tiny Dungeon」**（Kenney.nl, **CC0 / Public Domain**）
  - 元データ: `assets/vendor/tiny-town/`, `assets/vendor/tiny-dungeon/`（License.txt 同梱）
  - 生成物: `assets/tiles/overworld.png`, `assets/tiles/dungeon.png`, `assets/sprites/characters.png`
  - ビルド: `python3 tools/buildart.py`（vendor のタイルからアトラスを組み立て）
- 旧・自作プレースホルダ生成器 `tools/genart.py` は参考として残置（現在は未使用）
- `assets/vendor/` に未使用パックも種類別に保管（すべて Kenney CC0。詳細は同ディレクトリ参照）

### 音（BGM・SE）
- （未導入。CC0/CC-BY を予定。導入時にここへ記載）

## シナリオ / 世界観
- `scenario/` のコンテンツは現状コードと同じ Apache-2.0 で配布。
  （将来、コンテンツのみ Creative Commons へ分離する可能性あり）

## 方針メモ
- 素材は **CC0 を最優先**（表示義務なし）。CC-BY を使う場合は本ファイルに必ずクレジットを記載。
- CC-BY-SA / GPL の「素材」は継承条項が付くため、採用時は方針を確認すること。
