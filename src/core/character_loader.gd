class_name CharacterLoader
extends RefCounted
## data/characters/<id>.json（tools/ が生成）を読み込む。

static func load_character(id: String) -> Dictionary:
	var path := "res://data/characters/%s.json" % id
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("キャラクターを開けません: %s" % path)
		return {}
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	return data if typeof(data) == TYPE_DICTIONARY else {}

## キャラクター定義から、実行用ステータス（level/exp 等を含む）を作る。
static func make_stats(c: Dictionary) -> Dictionary:
	var max_hp := int(c.get("hp", 20))
	var max_mp := int(c.get("mp", 5))
	return {
		"char": str(c.get("id", "")),
		"name": str(c.get("name", "あなた")),
		"level": 1,
		"exp": 0,
		"hp": max_hp,
		"max_hp": max_hp,
		"mp": max_mp,
		"max_mp": max_mp,
		"atk": int(c.get("atk", 5)),
		"def": int(c.get("def", 1)),
		"exp_base": int(c.get("exp_base", 10)),
		"exp_growth": int(c.get("exp_growth", 10)),
		"hp_growth": int(c.get("hp_growth", 5)),
		"atk_growth": int(c.get("atk_growth", 1)),
		"def_growth": int(c.get("def_growth", 0)),
		"mp_growth": int(c.get("mp_growth", 2)),
	}
