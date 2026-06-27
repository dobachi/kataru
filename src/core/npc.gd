class_name Npc
extends Node2D
## マップ上のNPC。会話データ(data)を持ち、S1暫定の青い丸で描画する。

var cell := Vector2i.ZERO
var data: Dictionary = {}                # { id, name, sprite, dialogue:[...] }
var tile_size: int = 16

func setup(c: Vector2i, d: Dictionary, ts: int = 16) -> void:
	cell = c
	data = d
	tile_size = ts
	position = Vector2(c.x * ts + ts / 2.0, c.y * ts + ts / 2.0)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, tile_size * 0.35, Color(0.35, 0.59, 0.90))
