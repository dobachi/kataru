class_name InventoryBox
extends CanvasLayer
## メニュー（なかま／もちもの）。内容が多いときは ↑↓ でスクロールできる。I で開閉。

var active := false
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
	_title.text = "メニュー   （↑↓でスクロール / I で閉じる）"
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
	_body.custom_minimum_size = Vector2(322, 0)   # 折り返し幅（縦はコンテンツに追従）
	_scroll.add_child(_body)

	visible = false

## party: stats辞書の配列, items: {name,desc} の配列
func open(party: Array, items: Array) -> void:
	var lines: Array = ["◆ なかま"]
	for m in party:
		lines.append("  %s    Lv %d" % [str(m.get("name", "")), int(m.get("level", 1))])
		lines.append("    HP %d/%d   MP %d/%d" % [
			int(m.get("hp", 0)), int(m.get("max_hp", 0)), int(m.get("mp", 0)), int(m.get("max_mp", 0))])
		lines.append("    ちから %d   まもり %d   けいけんち %d" % [
			int(m.get("atk", 0)), int(m.get("def", 0)), int(m.get("exp", 0))])
	lines.append("")
	lines.append("◆ もちもの")
	if items.is_empty():
		lines.append("  （なし）")
	else:
		for it in items:
			var desc := str(it.get("desc", ""))
			lines.append(("  ・%s … %s" % [str(it.get("name", "")), desc]) if desc != "" else ("  ・%s" % str(it.get("name", ""))))
	_body.text = "\n".join(PackedStringArray(lines))
	_scroll.scroll_vertical = 0
	active = true
	visible = true

func scroll(dir: int) -> void:
	_scroll.scroll_vertical += dir * 16

func close() -> void:
	active = false
	visible = false
