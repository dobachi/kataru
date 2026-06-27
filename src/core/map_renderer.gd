class_name MapRenderer
extends Node2D
## WorldMap を 16x16 タイル画像（assets/tiles/overworld.png）で描画する。
## アトラス順: 0=grass, 1=stone, 2=tree, 3=water, 4=path

const TILE_PX := 16
const COL_GRASS := 0
const COL_STONE := 1
const COL_TREE := 2

var map: WorldMap = null
var tile_size: int = 16
var _tex: Texture2D = null

func setup(m: WorldMap, ts: int = 16) -> void:
	map = m
	tile_size = ts
	_tex = load("res://assets/tiles/overworld.png")
	queue_redraw()

func _draw() -> void:
	if map == null or _tex == null:
		return
	var wall_col := COL_TREE if map.tileset == "forest" else COL_STONE
	for y in map.height:
		for x in map.width:
			var col := wall_col if map.tile_at(Vector2i(x, y)) == TileTypes.WALL else COL_GRASS
			var dst := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			var src := Rect2(col * TILE_PX, 0, TILE_PX, TILE_PX)
			draw_texture_rect_region(_tex, dst, src)
