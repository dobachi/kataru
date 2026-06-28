class_name Npc
extends Node2D
## マップ上のNPC/オブジェクト。characters アトラスのスプライトで描画する。

## sprite名 → アトラス列（assets/sprites/characters.png）
const SPRITE_COL := {
	"elder": 1, "merchant": 2, "apothecary": 3,
	"swordsman": 4, "forest-dweller": 5, "herb": 6, "slime": 7, "chest": 8,
}

var cell := Vector2i.ZERO
var data: Dictionary = {}                # { id, name, sprite, dialogue:[...] }
var tile_size: int = 16
var _tex: Texture2D = null

func setup(c: Vector2i, d: Dictionary, ts: int = 16) -> void:
	cell = c
	data = d
	tile_size = ts
	position = Vector2(c.x * ts + ts / 2.0, c.y * ts + ts / 2.0)
	_tex = load("res://assets/sprites/characters.png")
	queue_redraw()

func _draw() -> void:
	if _tex == null:
		return
	var col: int = SPRITE_COL.get(str(data.get("sprite", "")), 1)
	var s := float(tile_size)
	draw_texture_rect_region(_tex, Rect2(-s / 2.0, -s / 2.0, s, s), Rect2(col * 16, 0, 16, 16))
