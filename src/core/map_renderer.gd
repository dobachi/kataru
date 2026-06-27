class_name MapRenderer
extends Node2D
## WorldMap を、解決済みの描画列(tiles)とアトラス画像(image)で描画する。
## どの記号がどのタイルになるかはビルド時にタイルセットで解決済み。

const TILE_PX := 16

var map: WorldMap = null
var tile_size: int = 16
var _tex: Texture2D = null

func setup(m: WorldMap, ts: int = 16) -> void:
	map = m
	tile_size = ts
	_tex = load("res://assets/tiles/%s" % m.image)
	queue_redraw()

func _draw() -> void:
	if map == null or _tex == null:
		return
	for y in map.height:
		for x in map.width:
			var col := map.tile_at(Vector2i(x, y))
			var dst := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			var src := Rect2(col * TILE_PX, 0, TILE_PX, TILE_PX)
			draw_texture_rect_region(_tex, dst, src)
