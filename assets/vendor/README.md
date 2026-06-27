# vendor — 外部CC0素材の保管庫

すべて [Kenney](https://kenney.nl)（**CC0 / Public Domain**）。各ディレクトリに License を同梱。
差し替え・将来利用のために種類別で保管している。`.gdignore` により Godot のインポート対象外。

現在ゲームで使用しているのは **tiny-town** / **tiny-dungeon**（16px）のみ。
差し替えは `tools/buildart.py` の対応表を編集して再生成する。

## 16px（kataru 標準サイズ。そのまま採用可）

| ディレクトリ | 内容 | 使用 |
|---|---|---|
| `tiny-town/` | 地形・建物・木・扉・小物 | ✅ 使用中（地形） |
| `tiny-dungeon/` | ダンジョン・キャラ・スライム・道具 | ✅ 使用中（ダンジョン/キャラ） |
| `roguelike-rpg/` | 地形/ダンジョン/キャラ/道具 総合（単一シート・16px/1px間隔） | 予備 |
| `roguelike-characters/` | キャラクター多数（16px/1px間隔） | 予備 |
| `roguelike-caves-dungeons/` | 洞窟・ダンジョン（16px/1px間隔） | 予備 |
| `roguelike-indoors/` | 屋内（16px/1px間隔） | 予備 |
| `rpg-urban/` | 都市・屋内（16px packed） | 予備 |

## 64px（採用するにはタイルサイズ変更が必要）

| ディレクトリ | 内容 |
|---|---|
| `rpg-base/` | RPG pack（64px・作り込み）。16pxへ縮小すると劣化するため、採用時は描画/カメラの調整が前提 |

> 注: Tiny 系（tiny-town/tiny-dungeon）と Roguelike 系は微妙に画風が異なる。混在させると統一感が落ちるため、まずは Tiny 系で統一している。
