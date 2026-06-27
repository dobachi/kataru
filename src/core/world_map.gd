class_name WorldMap
extends RefCounted
## マップ1枚の論理データ。タイルは行優先で tiles[y][x] に整数で持つ。
## S1では Main 側で生成するが、S2以降は data/*.json から読み込んでここに載せる。

var id: String = ""
var map_name: String = ""
var width: int = 0
var height: int = 0
var tiles: Array = []                 # Array[Array[int]]（行優先）
var player_start := Vector2i(1, 1)
var npcs: Array = []                  # [{ "id": String, "pos": [x, y] }]
var warps: Array = []                 # [{ "pos": [x,y], "map": String, "to": [x,y] }]

func _init(rows: Array = []) -> void:
	if not rows.is_empty():
		set_tiles(rows)

func set_tiles(rows: Array) -> void:
	tiles = rows
	height = rows.size()
	width = (rows[0] as Array).size() if height > 0 else 0

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height

func tile_at(c: Vector2i) -> int:
	return tiles[c.y][c.x]

func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and tile_at(c) != TileTypes.WALL
