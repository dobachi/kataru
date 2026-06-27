class_name ItemLoader
extends RefCounted
## data/items/<id>.json（tools/ が生成）を読み込む。

static func load_item(id: String) -> Dictionary:
	var path := "res://data/items/%s.json" % id
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("アイテムを開けません: %s" % path)
		return {"id": id, "name": id, "desc": ""}
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	return data if typeof(data) == TYPE_DICTIONARY else {"id": id, "name": id, "desc": ""}
