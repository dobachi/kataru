class_name DialogueBox
extends CanvasLayer
## 画面下部の会話ウィンドウ。
## 本文は1文字ずつ送る（タイプライタ）。表示途中に決定で全文表示、表示済みで決定すると次へ。
## モード: "lines"（本文送り） / "choices"（選択） / "response"（選択後の応答送り）

signal finished
signal choice_selected(choice: Dictionary)

const REVEAL_CPS := 40.0          # 1秒あたりの表示文字数

var active := false
var mode := "lines"

var _lines: Array = []
var _choices: Array = []
var _resp: Array = []
var _index := 0
var _sel := 0
var _revealing := false
var _reveal := 0.0
var _name_label: Label
var _body_label: Label

func _ready() -> void:
	layer = 10
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = -76
	panel.offset_bottom = -8
	add_child(panel)

	_name_label = Label.new()
	_name_label.position = Vector2(10, 6)
	_name_label.modulate = Color(1.0, 0.92, 0.6)
	panel.add_child(_name_label)

	_body_label = Label.new()
	_body_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body_label.offset_left = 10
	_body_label.offset_top = 28
	_body_label.offset_right = -10
	_body_label.offset_bottom = -8
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_body_label)

	visible = false

func _process(delta: float) -> void:
	if not active or not _revealing:
		return
	_reveal += delta * REVEAL_CPS
	var total := _body_label.get_total_character_count()
	if int(_reveal) >= total:
		_body_label.visible_characters = -1
		_revealing = false
	else:
		_body_label.visible_characters = int(_reveal)

func start(speaker: String, lines: Array, choices: Array = []) -> void:
	if lines.is_empty() and choices.is_empty():
		return
	_lines = lines
	_choices = choices
	_resp = []
	_index = 0
	_sel = 0
	_name_label.text = speaker
	active = true
	visible = true
	if _lines.is_empty():
		_enter_choices_or_finish()
	else:
		mode = "lines"
		_set_line(str(_lines[0]))

## 本文の送り（ui_accept）
func advance() -> void:
	if not active:
		return
	if _revealing:
		_reveal_all()
		return
	if mode == "lines":
		_index += 1
		if _index < _lines.size():
			_set_line(str(_lines[_index]))
		else:
			_enter_choices_or_finish()
	elif mode == "response":
		_index += 1
		if _index < _resp.size():
			_set_line(str(_resp[_index]))
		else:
			_finish()

## 選択カーソルの移動
func move(dir: int) -> void:
	if mode != "choices":
		return
	_sel = clampi(_sel + dir, 0, _choices.size() - 1)
	_render_choices()

## 選択の決定（ui_accept）
func confirm() -> void:
	if mode != "choices":
		return
	var choice: Dictionary = _choices[_sel]
	choice_selected.emit(choice)
	_resp = choice.get("lines", [])
	_index = 0
	if _resp.is_empty():
		_finish()
	else:
		mode = "response"
		_set_line(str(_resp[0]))

func _set_line(text: String) -> void:
	_body_label.text = text
	_body_label.visible_characters = 0
	_reveal = 0.0
	_revealing = true

func _reveal_all() -> void:
	_body_label.visible_characters = -1
	_revealing = false

func _enter_choices_or_finish() -> void:
	if _choices.is_empty():
		_finish()
	else:
		mode = "choices"
		_sel = 0
		_render_choices()

func _render_choices() -> void:
	_revealing = false
	_body_label.visible_characters = -1
	var t := ""
	for i in _choices.size():
		t += ("▶ " if i == _sel else "   ") + str(_choices[i].get("label", ""))
		if i < _choices.size() - 1:
			t += "\n"
	_body_label.text = t

func _finish() -> void:
	active = false
	visible = false
	mode = "lines"
	_revealing = false
	finished.emit()
