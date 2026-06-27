class_name NpcLoader
extends RefCounted
## data/npcs/<id>.json（tools/ が生成）を読み込む。

static func load_npc(id: String) -> Dictionary:
	var path := "res://data/npcs/%s.json" % id
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("NPCを開けません: %s（tools/kataru.py convert を実行しましたか？）" % path)
		return {}
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("NPC JSONの解析に失敗: %s" % path)
		return {}
	return data
