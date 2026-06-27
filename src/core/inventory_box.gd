class_name InventoryBox
extends CanvasLayer
## 持ち物を一覧表示するウィンドウ。I キーで開閉する想定。

var active := false
var _title: Label
var _body: Label

func _ready() -> void:
	layer = 15
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -150
	panel.offset_right = 150
	panel.offset_top = -80
	panel.offset_bottom = 80
	add_child(panel)

	_title = Label.new()
	_title.text = "もちもの"
	_title.add_theme_font_size_override("font_size", 14)
	_title.modulate = Color(1.0, 0.92, 0.6)
	_title.position = Vector2(12, 8)
	panel.add_child(_title)

	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 12)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 12
	_body.offset_top = 30
	_body.offset_right = -12
	_body.offset_bottom = -10
	panel.add_child(_body)

	visible = false

## entries: ["薬草 — 東の森に生える…", ...]
func open(entries: Array) -> void:
	_body.text = "（なし）" if entries.is_empty() else "\n".join(PackedStringArray(entries))
	active = true
	visible = true

func close() -> void:
	active = false
	visible = false
