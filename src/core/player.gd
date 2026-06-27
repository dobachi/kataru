class_name Player
extends Node2D
## グリッド単位で移動するプレイヤー。古風RPG風に、1マスずつ滑らかに歩く。
## 壁判定は WorldMap.is_walkable に、NPC等の占有は occupied に委ねる。

signal stepped(cell: Vector2i)          # 1マス歩き終えたとき（移動口判定に使う）

const STEP_TIME := 0.14  # 1マスの歩行時間。将来ダッシュ時は短縮する想定

var map: WorldMap = null
var tile_size: int = 32
var cell := Vector2i.ZERO
var facing := Vector2i(0, 1)            # 既定は下向き。会話の対象判定に使う
var input_locked := false               # 会話中などは移動を止める
var occupied: Dictionary = {}           # Vector2i -> true（NPC等が居るマス）
var _moving := false
var _tex: Texture2D = null              # characters アトラス（col0=hero）

func setup(m: WorldMap, start: Vector2i, ts: int = 32) -> void:
	map = m
	tile_size = ts
	cell = start
	position = _cell_to_pos(cell)
	_tex = load("res://assets/sprites/characters.png")
	queue_redraw()

func _cell_to_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * tile_size + tile_size / 2.0, c.y * tile_size + tile_size / 2.0)

func _process(_delta: float) -> void:
	if _moving or input_locked or map == null:
		return
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("ui_up"):
		dir = Vector2i(0, -1)
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2i(0, 1)
	elif Input.is_action_pressed("ui_left"):
		dir = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_right"):
		dir = Vector2i(1, 0)
	if dir != Vector2i.ZERO:
		facing = dir                    # 移動できなくても向きは変える（壁/NPCを向ける）
		_try_move(dir)

func _try_move(dir: Vector2i) -> void:
	var target := cell + dir
	if not map.is_walkable(target) or occupied.has(target):
		return
	_moving = true
	cell = target
	var tween := create_tween()
	tween.tween_property(self, "position", _cell_to_pos(cell), STEP_TIME)
	tween.finished.connect(func() -> void:
		_moving = false
		stepped.emit(cell)
	)

func _draw() -> void:
	if _tex == null:
		return
	var s := float(tile_size)
	draw_texture_rect_region(_tex, Rect2(-s / 2.0, -s / 2.0, s, s), Rect2(0, 0, 16, 16))
