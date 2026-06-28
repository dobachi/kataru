class_name InventoryBox
extends CanvasLayer
## メニュー（なかま＝ステータス／もちもの）。アイテムは ↑↓ で選び、決定で使用。I で開閉。

var active := false
var _party: Array = []
var _items: Array = []
var _sel := 0
var _item_line0 := 0
var _title: Label
var _body: Label
var _scroll: ScrollContainer

func _ready() -> void:
	layer = 15
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -175
	panel.offset_right = 175
	panel.offset_top = -110
	panel.offset_bottom = 110
	add_child(panel)

	_title = Label.new()
	_title.text = "メニュー   （↑↓選択 / 決定で使用 / I で閉じる）"
	_title.modulate = Color(1.0, 0.92, 0.6)
	_title.position = Vector2(14, 8)
	panel.add_child(_title)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_left = 14
	_scroll.offset_top = 30
	_scroll.offset_right = -14
	_scroll.offset_bottom = -12
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(_scroll)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(322, 0)
	_scroll.add_child(_body)

	visible = false

func open(party: Array, items: Array) -> void:
	_party = party
	_items = items
	_sel = 0
	_render()
	active = true
	visible = true
	call_deferred("_scroll_to_sel")

func move(dir: int) -> void:
	if _items.is_empty():
		return
	_sel = clampi(_sel + dir, 0, _items.size() - 1)
	_render()
	_scroll_to_sel()

func selected() -> Dictionary:
	return _items[_sel] if _sel < _items.size() else {}

func _render() -> void:
	var lines: Array = ["◆ なかま"]
	for m in _party:
		lines.append("  %s    Lv %d" % [str(m.get("name", "")), int(m.get("level", 1))])
		lines.append("    HP %d/%d   MP %d/%d" % [
			int(m.get("hp", 0)), int(m.get("max_hp", 0)), int(m.get("mp", 0)), int(m.get("max_mp", 0))])
		lines.append("    ちから %d   まもり %d   けいけんち %d" % [
			int(m.get("atk", 0)), int(m.get("def", 0)), int(m.get("exp", 0))])
	lines.append("")
	lines.append("◆ もちもの")
	_item_line0 = lines.size()
	if _items.is_empty():
		lines.append("  （なし）")
	else:
		for i in _items.size():
			var it: Dictionary = _items[i]
			var desc := str(it.get("desc", ""))
			var label := ("%s … %s" % [str(it.get("name", "")), desc]) if desc != "" else str(it.get("name", ""))
			lines.append(("▶ " if i == _sel else "   ") + label)
	_body.text = "\n".join(PackedStringArray(lines))

func _scroll_to_sel() -> void:
	if _items.is_empty():
		return
	var line_h := 18
	var y := (_item_line0 + _sel) * line_h
	var vh := int(_scroll.size.y)
	_scroll.scroll_vertical = clampi(y - vh / 2, 0, 100000)

func close() -> void:
	active = false
	visible = false
