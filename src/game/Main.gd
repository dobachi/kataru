extends Node2D
## S3: マップ＋NPC配置＋会話。data/ から読み込み、NPCに話しかけると会話を表示する。
## 操作: 矢印/WASD で移動、Enter/Space(ui_accept) で「向いている先のNPC」と会話／送り。

const TILE_SIZE := 16
const MAP_PATH := "res://data/maps/village.json"

var _player: Player
var _dialogue: DialogueBox
var _npcs: Array = []  # Array[Npc]

func _ready() -> void:
	var map := MapLoader.load_map(MAP_PATH)
	if map == null:
		return

	var renderer := MapRenderer.new()
	renderer.setup(map, TILE_SIZE)
	add_child(renderer)

	_player = Player.new()
	_player.setup(map, map.player_start, TILE_SIZE)
	add_child(_player)

	# data の npcs を配置（マスは占有＝侵入不可にする）
	for entry in map.npcs:
		var pos: Array = entry.get("pos", [1, 1])
		var cell := Vector2i(int(pos[0]), int(pos[1]))
		var npc := Npc.new()
		npc.setup(cell, NpcLoader.load_npc(str(entry.get("id", ""))), TILE_SIZE)
		add_child(npc)
		_npcs.append(npc)
		_player.occupied[cell] = true

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(func() -> void: _player.input_locked = false)

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = map.width * TILE_SIZE
	cam.limit_bottom = map.height * TILE_SIZE
	_player.add_child(cam)
	cam.make_current()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if _dialogue.active:
		_dialogue.advance()
		return
	var npc := _npc_at(_player.cell + _player.facing)
	if npc != null:
		_player.input_locked = true
		_dialogue.start(str(npc.data.get("name", "")), npc.data.get("dialogue", []))

func _npc_at(cell: Vector2i) -> Npc:
	for n in _npcs:
		if n.cell == cell:
			return n
	return null
