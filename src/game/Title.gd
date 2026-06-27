extends Control
## タイトル画面。「はじめから」と、セーブがあれば「つづきから」を出す。
## ↑↓で選択、Enter/Space で決定。

var _items: Array = []           # [{label, action}]
var _sel := 0
var _menu: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "kataru"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 36
	title.offset_bottom = 86
	add_child(title)

	var sub := Label.new()
	sub.text = "markdown-driven 2D RPG"
	sub.add_theme_font_size_override("font_size", 10)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.7, 0.7, 0.8)
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = 84
	sub.offset_bottom = 102
	add_child(sub)

	_menu = Label.new()
	_menu.add_theme_font_size_override("font_size", 14)
	_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.offset_left = -120
	_menu.offset_right = 120
	_menu.offset_top = 8
	_menu.offset_bottom = 80
	add_child(_menu)

	_items = [{"label": "はじめから", "action": "new"}]
	if SaveManager.has_save():
		_items.append({"label": "つづきから", "action": "load"})
	_render()

func _render() -> void:
	var t := ""
	for i in _items.size():
		t += ("▶ " if i == _sel else "   ") + str(_items[i].label)
		if i < _items.size() - 1:
			t += "\n\n"
	_menu.text = t

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_sel = (_sel - 1 + _items.size()) % _items.size()
		_render()
	elif event.is_action_pressed("ui_down"):
		_sel = (_sel + 1) % _items.size()
		_render()
	elif event.is_action_pressed("ui_accept"):
		GameBoot.load_on_start = (_items[_sel].action == "load")
		get_tree().change_scene_to_file("res://src/game/Main.tscn")
