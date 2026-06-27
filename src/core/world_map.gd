class_name WorldMap
extends RefCounted
## マップ1枚の論理データ。タイルセットで解決済みの内容を持つ。
## tiles = 描画列のグリッド（image アトラスの列）、solid = 通行不可フラグのグリッド。

var id: String = ""
var map_name: String = ""
var tileset: String = "overworld"
var image: String = "overworld.png"      # assets/tiles/ 配下の使用アトラス
var width: int = 0
var height: int = 0
var tiles: Array = []                     # Array[Array[int]]（描画列・行優先）
var solid: Array = []                     # Array[Array[bool]]（通行不可・行優先）
var player_start := Vector2i(1, 1)
var npcs: Array = []                      # [{ "id", "pos":[x,y] }]
var warps: Array = []                     # [{ "pos":[x,y], "map", "to":[x,y] }]

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height

func tile_at(c: Vector2i) -> int:
	return tiles[c.y][c.x]

func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and not bool(solid[c.y][c.x])
