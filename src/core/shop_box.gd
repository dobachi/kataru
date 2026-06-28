class_name ShopBox
extends CanvasLayer
## ショップ（購入）。↑↓で選び、決定で購入。I/Esc で閉じる。
## 購入要求は buy_requested を発火し、ゲーム側が所持金チェック・付与を行う。

signal buy_requested(item: Dictionary)

var active := false
var _items: Array = []
var _gold := 0
var _sel := 0
var _title: Label
var _body: Label

func _ready() -> void:
	layer = 16
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -175
	panel.offset_right = 175
	panel.offset_top = -100
	panel.offset_bottom = 100
	add_child(panel)

	_title = Label.new()
	_title.modulate = Color(1.0, 0.92, 0.6)
	_title.position = Vector2(14, 8)
	add_child_to(panel, _title)

	_body = Label.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 14
	_body.offset_top = 30
	_body.offset_right = -14
	_body.offset_bottom = -10
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_body)

	visible = false

func add_child_to(parent: Node, child: Node) -> void:
	parent.add_child(child)

func open(items: Array, gold: int) -> void:
	_items = items
	_gold = gold
	_sel = 0
	active = true
	visible = true
	_render()

func set_gold(gold: int) -> void:
	_gold = gold
	_render()

func move(dir: int) -> void:
	if _items.is_empty():
		return
	_sel = clampi(_sel + dir, 0, _items.size() - 1)
	_render()

func confirm() -> void:
	if _sel < _items.size():
		buy_requested.emit(_items[_sel])

func close() -> void:
	active = false
	visible = false

func _render() -> void:
	_title.text = "みせ   所持金 %d G   （↑↓選択 / 決定で購入 / Iで閉じる）" % _gold
	var lines: Array = []
	if _items.is_empty():
		lines.append("（売り切れ）")
	else:
		for i in _items.size():
			var it: Dictionary = _items[i]
			lines.append(("▶ " if i == _sel else "   ") + "%s   %d G" % [str(it.get("name", "")), int(it.get("price", 0))])
	_body.text = "\n".join(PackedStringArray(lines))
