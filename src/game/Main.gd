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
var _current_map_id := ""
var _toast_label: Label
var _inventory: Array = []        # 所持アイテムid（セーブ対象）
var _inv_box: InventoryBox

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

	_inv_box = InventoryBox.new()
	add_child(_inv_box)

	_cam = Camera2D.new()
	_cam.zoom = Vector2(1.5, 1.5)
	_player.add_child(_cam)
	_cam.make_current()

	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	_toast_label = Label.new()
	_toast_label.position = Vector2(8, 6)
	_toast_label.add_theme_font_size_override("font_size", 12)
	ui.add_child(_toast_label)

	if GameBoot.load_on_start and SaveManager.has_save():
		GameBoot.load_on_start = false
		_load()
	else:
		GameBoot.load_on_start = false
		_load_map(START_MAP)

## マップを読み込んで現在マップを差し替える。spawn 指定があればそこに、無ければ player_start に立つ。
func _load_map(map_id: String, spawn := Vector2i(-1, -1)) -> void:
	var map := MapLoader.load_map_by_id(map_id)
	if map == null:
		return
	_current_map_id = map_id

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
	if _inv_box.active:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
			_inv_box.close()
			_player.input_locked = false
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			_save()
			return
		if event.keycode == KEY_F9:
			_load()
			return
		if event.keycode == KEY_I:
			_open_inventory()
			return
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://src/game/Title.tscn")
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
	_apply_ops(res)
	_player.input_locked = true
	_dialogue.start(str(npc.data.get("name", "")), lines, choices)

func _on_choice_selected(choice: Dictionary) -> void:
	_apply_ops(choice)

func _open_inventory() -> void:
	var entries: Array = []
	for id in _inventory:
		var item := ItemLoader.load_item(str(id))
		var desc := str(item.get("desc", ""))
		entries.append("%s — %s" % [str(item.get("name", id)), desc] if desc != "" else str(item.get("name", id)))
	_inv_box.open(entries)
	_player.input_locked = true

## 効果（set/give/take）をまとめて適用する。
func _apply_ops(d: Dictionary) -> void:
	for e in d.get("set", []):
		_flags[str(e[0])] = str(e[1])
	for it in d.get("give", []):
		if not _inventory.has(str(it)):
			_inventory.append(str(it))
	for it in d.get("take", []):
		_inventory.erase(str(it))

## 分岐の条件（フラグの AND/OR ＋ 所持アイテム has/nohas）を評価する。
func _branch_match(b: Dictionary) -> bool:
	if not _cond_match(b.get("if", [])):
		return false
	for it in b.get("has", []):
		if not _inventory.has(str(it)):
			return false
	for it in b.get("nohas", []):
		if _inventory.has(str(it)):
			return false
	return true

## フラグ条件（ANDの配列。各要素はORグループ [[flag,value], ...]）を評価する。
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

## dialogue（文字列配列 or 分岐配列）と現在の状態から、一致した分岐を返す。
func _resolve_dialogue(dialogue: Array) -> Dictionary:
	if dialogue.is_empty():
		return {"lines": [], "choices": []}
	if dialogue[0] is String:
		return {"lines": dialogue, "choices": []}   # 従来形式（無条件）
	for b in dialogue:                              # 分岐: 先頭から最初に一致
		if _branch_match(b):
			return b
	return {"lines": [], "choices": []}

func _npc_at(cell: Vector2i) -> Npc:
	for n in _npcs:
		if n.cell == cell:
			return n
	return null

func _save() -> void:
	var ok := SaveManager.save_state({
		"map": _current_map_id,
		"cell": [_player.cell.x, _player.cell.y],
		"flags": _flags,
		"inventory": _inventory,
	})
	_toast("セーブしました" if ok else "セーブ失敗")

func _load() -> void:
	var s := SaveManager.load_state()
	if s.is_empty():
		_toast("セーブデータがありません")
		return
	_flags = s.get("flags", {})
	_inventory = s.get("inventory", [])
	var c: Array = s.get("cell", [1, 1])
	_load_map(str(s.get("map", START_MAP)), Vector2i(int(c[0]), int(c[1])))
	_toast("ロードしました")

func _toast(msg: String) -> void:
	if _toast_label == null:
		return
	_toast_label.text = msg
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func() -> void:
		if _toast_label != null and _toast_label.text == msg:
			_toast_label.text = ""
	)
