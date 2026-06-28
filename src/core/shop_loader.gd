class_name ShopLoader
extends RefCounted
## data/shops/<id>.json（tools/ が生成）を読み込む。

static func load_shop(id: String) -> Dictionary:
	var path := "res://data/shops/%s.json" % id
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ショップを開けません: %s" % path)
		return {}
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	return data if typeof(data) == TYPE_DICTIONARY else {}
