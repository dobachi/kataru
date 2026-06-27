class_name SaveManager
extends RefCounted
## セーブデータの読み書き（user:// に JSON で保存）。
## 状態: { "map": String, "cell": [x,y], "flags": { ... } }

const PATH := "user://save_1.json"

static func has_save() -> bool:
	return FileAccess.file_exists(PATH)

static func save_state(state: Dictionary) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("セーブできません: %s" % PATH)
		return false
	f.store_string(JSON.stringify(state, "  "))
	f.close()
	return true

static func load_state() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	return data if typeof(data) == TYPE_DICTIONARY else {}
