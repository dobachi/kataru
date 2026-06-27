class_name EnemyLoader
extends RefCounted
## data/enemies/<id>.json（tools/ が生成）を読み込む。

static func load_enemy(id: String) -> Dictionary:
	var path := "res://data/enemies/%s.json" % id
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("敵を開けません: %s" % path)
		return {}
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	return data if typeof(data) == TYPE_DICTIONARY else {}
