class_name BattleScreen
extends CanvasLayer
## ターン制コマンド戦闘（MVP）。コマンド: たたかう / にげる。
## finished({outcome, player_hp}) を発火する。outcome: "win" | "lose" | "escape"

signal finished(result: Dictionary)

var active := false
var mode := "command"            # "command" | "message"

var _php := 0
var _pmax := 0
var _patk := 0
var _ehp := 0
var _emax := 0
var _eatk := 1
var _ename := ""

var _menu_items := ["たたかう", "にげる"]
var _sel := 0
var _queue: Array = []           # 表示待ちメッセージ
var _after := ""                 # メッセージ消化後の遷移

var _info: Label
var _msg: Label
var _menu: Label

func _ready() -> void:
	layer = 30
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.09, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 14)
	_info.position = Vector2(16, 16)
	add_child(_info)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = -70
	panel.offset_bottom = -8
	add_child(panel)

	_msg = Label.new()
	_msg.add_theme_font_size_override("font_size", 12)
	_msg.position = Vector2(10, 8)
	panel.add_child(_msg)

	_menu = Label.new()
	_menu.add_theme_font_size_override("font_size", 12)
	_menu.position = Vector2(10, 30)
	panel.add_child(_menu)

	visible = false

func start(stats: Dictionary, enemy: Dictionary) -> void:
	_php = int(stats.get("hp", 1))
	_pmax = int(stats.get("max_hp", _php))
	_patk = int(stats.get("atk", 1))
	_ehp = int(enemy.get("hp", 1))
	_emax = _ehp
	_eatk = int(enemy.get("atk", 1))
	_ename = str(enemy.get("name", "てき"))
	_sel = 0
	active = true
	visible = true
	_update_info()
	_show_messages(["%s が あらわれた！" % _ename], "command")

func _update_info() -> void:
	_info.text = "%s    HP %d/%d\nあなた    HP %d/%d" % [_ename, _ehp, _emax, _php, _pmax]

func _render_menu() -> void:
	var t := ""
	for i in _menu_items.size():
		t += ("▶ " if i == _sel else "   ") + _menu_items[i] + "    "
	_menu.text = t

func _show_messages(msgs: Array, after: String) -> void:
	_queue = msgs.duplicate()
	_after = after
	mode = "message"
	_menu.text = ""
	_msg.text = str(_queue[0]) if not _queue.is_empty() else ""

# --- 入力（Main から呼ばれる） ---

func move(dir: int) -> void:
	if mode != "command":
		return
	_sel = (_sel + dir + _menu_items.size()) % _menu_items.size()
	_render_menu()

func confirm() -> void:
	if mode == "message":
		_advance_message()
	elif mode == "command":
		_choose()

func _choose() -> void:
	if _sel == 1:
		_show_messages(["%s は にげだした！" % "あなた"], "escape")
		return
	# たたかう
	_ehp = max(0, _ehp - _patk)
	_update_info()
	var msgs := ["%s に %d の ダメージ！" % [_ename, _patk]]
	if _ehp <= 0:
		msgs.append("%s を たおした！" % _ename)
		_show_messages(msgs, "win")
	else:
		_show_messages(msgs, "enemy")

func _advance_message() -> void:
	_queue.pop_front()
	if not _queue.is_empty():
		_msg.text = str(_queue[0])
		return
	_resolve_after()

func _resolve_after() -> void:
	match _after:
		"command":
			mode = "command"
			_msg.text = "どうする？"
			_render_menu()
		"enemy":
			_php = max(0, _php - _eatk)
			_update_info()
			var msgs := ["%s の こうげき！ %d の ダメージ！" % [_ename, _eatk]]
			if _php <= 0:
				msgs.append("あなたは ちからつきた……")
				_show_messages(msgs, "lose")
			else:
				_show_messages(msgs, "command")
		"win":
			_finish("win")
		"lose":
			_finish("lose")
		"escape":
			_finish("escape")

func _finish(outcome: String) -> void:
	active = false
	visible = false
	mode = "command"
	finished.emit({"outcome": outcome, "player_hp": _php})
