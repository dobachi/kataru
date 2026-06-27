extends Node2D
## S3+: 複数マップ＋NPC会話＋マップ間移動（warp）。
## 操作: 矢印/WASD で移動、Enter/Space(ui_accept) で会話。移動口を踏むと別マップへ。

const TILE_SIZE := 16
const START_MAP := "village"
const START_CHAR := "hero"

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
var _party: Array = []            # パーティ（各要素がキャラのstats）。先頭がリーダー
var _stats: Dictionary = {}       # リーダーのstatsへの参照（戦闘・マップ表示に使用）
var _battle: BattleScreen
var _pending_battle := ""         # 会話終了後に開始する戦闘の敵id
var _pending_remove := false      # 会話終了後に相手NPCを除去する（加入時）
var _talking_npc: Npc = null      # 直近に話しかけた相手（戦闘勝利・加入時に除去）

const DEFAULT_STATS := {
	"name": "あなた", "level": 1, "exp": 0, "hp": 20, "max_hp": 20,
	"mp": 5, "max_mp": 5, "atk": 5, "def": 1,
	"exp_base": 10, "exp_growth": 10, "hp_growth": 5, "atk_growth": 1,
	"def_growth": 0, "mp_growth": 2,
}

func _ready() -> void:
	_map_root = Node2D.new()
	add_child(_map_root)

	_player = Player.new()
	add_child(_player)
	_player.stepped.connect(_on_player_stepped)

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)
	_dialogue.choice_selected.connect(_on_choice_selected)

	_inv_box = InventoryBox.new()
	add_child(_inv_box)

	_battle = BattleScreen.new()
	add_child(_battle)
	_battle.finished.connect(_on_battle_finished)

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
		_party = [_new_character_stats(START_CHAR)]
		_stats = _party[0]
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
		var data := NpcLoader.load_npc(str(entry.get("id", "")))
		if _npc_hidden(data):
			continue
		var pos: Array = entry.get("pos", [1, 1])
		var cell := Vector2i(int(pos[0]), int(pos[1]))
		var npc := Npc.new()
		npc.setup(cell, data, TILE_SIZE)
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
	if _battle.active:
		if _battle.mode == "command":
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
				_battle.move(-1)
			elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
				_battle.move(1)
			elif event.is_action_pressed("ui_accept"):
				_battle.confirm()
		elif event.is_action_pressed("ui_accept"):
			_battle.confirm()
		return
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
		if event.is_action_pressed("ui_up"):
			_inv_box.scroll(-1)
		elif event.is_action_pressed("ui_down"):
			_inv_box.scroll(1)
		elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
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
	_talking_npc = npc
	_apply_ops(res)
	_player.input_locked = true
	_dialogue.start(str(npc.data.get("name", "")), lines, choices)

func _on_choice_selected(choice: Dictionary) -> void:
	_apply_ops(choice)

func _on_dialogue_finished() -> void:
	if _pending_remove:
		_pending_remove = false
		_remove_talking_npc()
	if _pending_battle != "":
		var id := _pending_battle
		_pending_battle = ""
		_start_battle(id)
	else:
		_player.input_locked = false

func _start_battle(id: String) -> void:
	var enemy := EnemyLoader.load_enemy(id)
	if enemy.is_empty():
		_player.input_locked = false
		return
	_player.input_locked = true
	_battle.start(_stats, enemy)

func _on_battle_finished(result: Dictionary) -> void:
	_stats["hp"] = int(result.get("player_hp", _stats.get("hp", 1)))
	var outcome := str(result.get("outcome", ""))
	if outcome == "win":
		_remove_talking_npc()
		_gain_exp(int(result.get("exp", 0)))
	elif outcome == "lose":
		_stats["hp"] = int(_stats.get("max_hp", 1))
		_toast("気を失った……村で目を覚ました")
		_load_map(START_MAP)
	else:
		_toast("にげだした")
	_talking_npc = null
	_player.input_locked = false

## 開始キャラクターの実行用ステータスを作る（データが無ければ既定値）。
func _new_character_stats(id: String) -> Dictionary:
	var c := CharacterLoader.load_character(id)
	if c.is_empty():
		return DEFAULT_STATS.duplicate()
	return CharacterLoader.make_stats(c)

## 次レベルに必要な経験値（キャラごとの曲線）: exp_base + (level-1)*exp_growth
func _exp_to_next_of(m: Dictionary) -> int:
	return int(m.get("exp_base", 10)) + (int(m.get("level", 1)) - 1) * int(m.get("exp_growth", 10))

## 1キャラに経験値を加算。レベルアップした数を返す。
func _gain_exp_member(m: Dictionary, amount: int) -> int:
	m["exp"] = int(m.get("exp", 0)) + amount
	var leveled := 0
	while int(m.get("exp", 0)) >= _exp_to_next_of(m):
		m["exp"] = int(m["exp"]) - _exp_to_next_of(m)
		m["level"] = int(m.get("level", 1)) + 1
		m["max_hp"] = int(m.get("max_hp", 1)) + int(m.get("hp_growth", 5))
		m["atk"] = int(m.get("atk", 1)) + int(m.get("atk_growth", 1))
		m["def"] = int(m.get("def", 0)) + int(m.get("def_growth", 0))
		m["max_mp"] = int(m.get("max_mp", 0)) + int(m.get("mp_growth", 0))
		m["hp"] = int(m["max_hp"])
		m["mp"] = int(m["max_mp"])
		leveled += 1
	return leveled

## 経験値をパーティ全員に加算する。
func _gain_exp(amount: int) -> void:
	if amount <= 0:
		_toast("敵をたおした")
		return
	var leveled_names: Array = []
	for m in _party:
		if _gain_exp_member(m, amount) > 0:
			leveled_names.append(str(m.get("name", "")))
	if not leveled_names.is_empty():
		_toast("レベルアップ！ %s" % ", ".join(PackedStringArray(leveled_names)))
	else:
		_toast("けいけんち %d を えた" % amount)

func _open_inventory() -> void:
	var items: Array = []
	for id in _inventory:
		items.append(ItemLoader.load_item(str(id)))
	_inv_box.open(_party, items)
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
	if str(d.get("battle", "")) != "":
		_pending_battle = str(d.get("battle"))
	var joins: Array = d.get("join", [])
	for cid in joins:
		_recruit(str(cid))
	if not joins.is_empty():
		_pending_remove = true

## 仲間を加入させる（既にパーティにいれば何もしない）。
func _recruit(cid: String) -> void:
	for m in _party:
		if str(m.get("char", "")) == cid:
			return
	var c := CharacterLoader.load_character(cid)
	if not c.is_empty():
		_party.append(CharacterLoader.make_stats(c))
		_toast("%s が なかまに くわわった！" % str(c.get("name", cid)))

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

## hide_if 条件（[flag,value]）が現在のフラグと一致すれば、そのNPCは配置しない。
func _npc_hidden(data: Dictionary) -> bool:
	var h = data.get("hide_if", null)
	if h == null:
		return false
	return _flags.get(str(h[0]), "none") == str(h[1])

## 現在話している相手をマップから取り除く（加入・撃破時）。
func _remove_talking_npc() -> void:
	if _talking_npc != null and is_instance_valid(_talking_npc):
		_player.occupied.erase(_talking_npc.cell)
		_npcs.erase(_talking_npc)
		_talking_npc.queue_free()
	_talking_npc = null

func _save() -> void:
	var ok := SaveManager.save_state({
		"map": _current_map_id,
		"cell": [_player.cell.x, _player.cell.y],
		"flags": _flags,
		"inventory": _inventory,
		"party": _party,
	})
	_toast("セーブしました" if ok else "セーブ失敗")

func _load() -> void:
	var s := SaveManager.load_state()
	if s.is_empty():
		_toast("セーブデータがありません")
		return
	_flags = s.get("flags", {})
	_inventory = s.get("inventory", [])
	_party = s.get("party", [])
	if _party.is_empty():
		_party = [s.get("stats", DEFAULT_STATS.duplicate())]   # 旧セーブ互換
	_stats = _party[0]
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
