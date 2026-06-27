class_name MapLoader
extends RefCounted
## data/maps/*.json（tools/ が生成）を読み込み WorldMap を構築する。
## JSON はビルド時に scenario/maps/*.md ＋ タイルセットから解決された写し。

static func load_map_by_id(id: String) -> WorldMap:
	return load_map("res://data/maps/%s.json" % id)

static func load_map(path: String) -> WorldMap:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("マップを開けません: %s（tools/kataru.py convert を実行しましたか？）" % path)
		return null
	var text := f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("マップJSONの解析に失敗: %s" % path)
		return null

	var map := WorldMap.new()
	var rows: Array = []
	for row in data.get("tiles", []):
		var trow: Array = []
		for v in row:
			trow.append(int(v))
		rows.append(trow)
	var srows: Array = []
	for row in data.get("solid", []):
		var srow: Array = []
		for v in row:
			srow.append(bool(v))
		srows.append(srow)

	map.tiles = rows
	map.solid = srows
	map.height = rows.size()
	map.width = (rows[0] as Array).size() if map.height > 0 else 0
	map.id = str(data.get("id", ""))
	map.map_name = str(data.get("name", ""))
	map.tileset = str(data.get("tileset", "overworld"))
	map.image = str(data.get("image", "overworld.png"))
	var ps: Array = data.get("player_start", [1, 1])
	map.player_start = Vector2i(int(ps[0]), int(ps[1]))
	map.npcs = data.get("npcs", [])
	map.warps = data.get("warps", [])
	return map
