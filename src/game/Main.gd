extends Node2D
## S3+: 複数マップ＋NPC会話＋マップ間移動（warp）。
## 操作: 矢印/WASD で移動、Enter/Space(ui_accept) で会話。移動口を踏むと別マップへ。

const TILE_SIZE := 16
const START_MAP := "village"

var _player: Player
var _dialogue: DialogueBox
var _map_root: Node2D            # 現在マップの描画/NPCを格納（遷移時に作り直す）
var _npcs: Array = []            # Array[Npc]
var _warps: Array = []           # [{ pos:[x,y], map:String, to:[x,y] }]
var _cam: Camera2D
var _flags: Dictionary = {}      # クエスト等の状態（マップ遷移をまたいで保持）

func _ready() -> void:
	_map_root = Node2D.new()
	add_child(_map_root)

	_player = Player.new()
	add_child(_player)
	_player.stepped.connect(_on_player_stepped)

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(func() -> void: _player.input_locked = false)
	_dialogue.choice_selected.connect(_on_choice_selected)

	_cam = Camera2D.new()
	_cam.zoom = Vector2(1.5, 1.5)
	_player.add_child(_cam)
	_cam.make_current()

	_load_map(START_MAP)

## マップを読み込んで現在マップを差し替える。spawn 指定があればそこに、無ければ player_start に立つ。
func _load_map(map_id: String, spawn := Vector2i(-1, -1)) -> void:
	var map := MapLoader.load_map_by_id(map_id)
	if map == null:
		return

	for child in _map_root.get_children():
		child.queue_free()
	_npcs.clear()
	_warps.clear()
	_player.occupied.clear()

	var renderer := MapRenderer.new()
	renderer.setup(map, TILE_SIZE)
	_map_root.add_child(renderer)

	for entry in map.npcs:
		var pos: Array = entry.get("pos", [1, 1])
		var cell := Vector2i(int(pos[0]), int(pos[1]))
		var npc := Npc.new()
		npc.setup(cell, NpcLoader.load_npc(str(entry.get("id", ""))), TILE_SIZE)
		_map_root.add_child(npc)
		_npcs.append(npc)
		_player.occupied[cell] = true

	_warps = map.warps

	var start: Vector2i = spawn if spawn != Vector2i(-1, -1) else map.player_start
	_player.setup(map, start, TILE_SIZE)

	_cam.limit_left = 0
	_cam.limit_top = 0
	_cam.limit_right = map.width * TILE_SIZE
	_cam.limit_bottom = map.height * TILE_SIZE
	_cam.reset_smoothing()

func _on_player_stepped(cell: Vector2i) -> void:
	for w in _warps:
		var p: Array = w.get("pos", [-1, -1])
		if Vector2i(int(p[0]), int(p[1])) == cell:
			var to: Array = w.get("to", [1, 1])
			_load_map(str(w.get("map", "")), Vector2i(int(to[0]), int(to[1])))
			return

func _unhandled_input(event: InputEvent) -> void:
	if _dialogue.active:
		if _dialogue.mode == "choices":
			if event.is_action_pressed("ui_up"):
				_dialogue.move(-1)
			elif event.is_action_pressed("ui_down"):
				_dialogue.move(1)
			elif event.is_action_pressed("ui_accept"):
				_dialogue.confirm()
		elif event.is_action_pressed("ui_accept"):
			_dialogue.advance()
		return
	if not event.is_action_pressed("ui_accept"):
		return
	var npc := _npc_at(_player.cell + _player.facing)
	if npc == null:
		return
	var res := _resolve_dialogue(npc.data.get("dialogue", []))
	var lines: Array = res.get("lines", [])
	var choices: Array = res.get("choices", [])
	if lines.is_empty() and choices.is_empty():
		return
	_apply_effects(res.get("set", []))
	_player.input_locked = true
	_dialogue.start(str(npc.data.get("name", "")), lines, choices)

func _on_choice_selected(choice: Dictionary) -> void:
	_apply_effects(choice.get("set", []))

## 効果（[[flag,value], ...]）をまとめてフラグへ適用する。
func _apply_effects(effects) -> void:
	if effects == null:
		return
	for e in effects:
		_flags[str(e[0])] = str(e[1])

## 条件（ANDの配列。各要素はORグループ [[flag,value], ...]）を評価する。
func _cond_match(conds) -> bool:
	if conds == null:
		return true
	for group in conds:                          # 各グループ（AND）
		var any_ok := false
		for pair in group:                       # グループ内（OR）
			if _flags.get(str(pair[0]), "none") == str(pair[1]):
				any_ok = true
				break
		if not any_ok:
			return false
	return true

## dialogue（文字列配列 or 分岐配列）と現在のフラグから、表示行・効果・選択肢を決める。
func _resolve_dialogue(dialogue: Array) -> Dictionary:
	if dialogue.is_empty():
		return {"lines": [], "set": [], "choices": []}
	if dialogue[0] is String:
		return {"lines": dialogue, "set": [], "choices": []}   # 従来形式（無条件）
	for b in dialogue:                                          # 分岐: 先頭から最初に一致
		if _cond_match(b.get("if", [])):
			return {"lines": b.get("lines", []), "set": b.get("set", []), "choices": b.get("choices", [])}
	return {"lines": [], "set": [], "choices": []}

func _npc_at(cell: Vector2i) -> Npc:
	for n in _npcs:
		if n.cell == cell:
			return n
	return null
