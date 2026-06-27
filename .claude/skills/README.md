# .claude/skills

シナリオを「育てる」ための AI スキル（開発時に使用）。

スキルは `<name>/SKILL.md` 形式（frontmatter の `name`/`description` ＋ 手順）。

## スキル一覧

| スキル | 役割 | 状態 |
|---|---|---|
| [scenario-grow](scenario-grow/SKILL.md) | 種・要望からマップ/NPC/会話を生成・拡張し、lint→convert で検証 | ✅ |
| scenario-new（予定） | 対話で新規シナリオ一式を立ち上げる初期セット作成ウィザード | ⬜ |
| map-template（予定） | テンプレ集から希望に沿ったマップを生成 | ⬜ |

記法は [docs/scenario-schema.md](../../docs/scenario-schema.md)、ツールは [tools/README.md](../../tools/README.md) を参照。

> 注: ゲーム実行時はAI非依存。スキルはあくまで開発時に markdown / data を生成・検証するためのもの。
