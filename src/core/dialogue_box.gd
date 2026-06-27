class_name DialogueBox
extends CanvasLayer
## 画面下部の会話ウィンドウ。start() で開始し、advance() で次の行へ。
## 全行を読み終えると finished を発火する。

signal finished

var active := false
var _lines: Array = []
var _index := 0
var _name_label: Label
var _body_label: Label

func _ready() -> void:
	layer = 10
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = -70
	panel.offset_bottom = -8
	add_child(panel)

	_name_label = Label.new()
	_name_label.position = Vector2(10, 6)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.modulate = Color(1.0, 0.92, 0.6)
	panel.add_child(_name_label)

	_body_label = Label.new()
	_body_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body_label.offset_left = 10
	_body_label.offset_top = 28
	_body_label.offset_right = -10
	_body_label.offset_bottom = -8
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(_body_label)

	visible = false

func start(speaker: String, lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_name_label.text = speaker
	_body_label.text = str(_lines[0])
	active = true
	visible = true

func advance() -> void:
	if not active:
		return
	_index += 1
	if _index >= _lines.size():
		active = false
		visible = false
		finished.emit()
	else:
		_body_label.text = str(_lines[_index])
