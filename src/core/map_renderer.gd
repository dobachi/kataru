class_name MapRenderer
extends Node2D
## WorldMap を矩形で描画する。S1暫定の色塗りレンダラ。
## S2以降で TileMapLayer + 実タイルセットに差し替える想定。

var map: WorldMap = null
var tile_size: int = 32

func setup(m: WorldMap, ts: int = 32) -> void:
	map = m
	tile_size = ts
	queue_redraw()

func _draw() -> void:
	if map == null:
		return
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			draw_rect(rect, TileTypes.color_of(map.tile_at(cell)), true)
			draw_rect(rect, Color(0, 0, 0, 0.12), false, 1.0)  # うっすらグリッド線
