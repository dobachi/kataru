extends Node2D
## S2: マップを data/maps/*.json から読み込んで表示する（データ駆動）。
## 元の scenario/maps/village.md を tools/kataru.py convert で JSON 化したもの。

const TILE_SIZE := 16  # SNES級を想定した16pxタイル基準（S1は色塗りプレースホルダ）
const MAP_PATH := "res://data/maps/village.json"

func _ready() -> void:
	var map := MapLoader.load_map(MAP_PATH)
	if map == null:
		return

	var renderer := MapRenderer.new()
	renderer.setup(map, TILE_SIZE)
	add_child(renderer)

	var player := Player.new()
	player.setup(map, map.player_start, TILE_SIZE)
	add_child(player)

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
	# マップ外を映さないよう端で止める
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = map.width * TILE_SIZE
	cam.limit_bottom = map.height * TILE_SIZE
	player.add_child(cam)
	cam.make_current()
