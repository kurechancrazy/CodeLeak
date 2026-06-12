## CodePanel — 疑似コードを行番号付きで表示し、行選択を管理する
extends PanelContainer

const _COLOR_BG: Color = Color.html("#0d0d0d")
const _COLOR_TEXT: Color = Color.html("#00ff41")
const _COLOR_LINE_NUM: Color = Color.html("#555555")
const _COLOR_HOVER_BG: Color = Color.html("#1a1a2e")
const _COLOR_SELECTED: Color = Color.html("#ffff00")
const _COLOR_FLASH_GREEN: Color = Color.html("#00ff41")
const _COLOR_FLASH_RED: Color = Color.html("#ff3333")

var _scroll: ScrollContainer
var _code_lines_container: VBoxContainer
var _line_buttons: Array[Button] = []
var _selected_index: int = -1
var _waiting_for_answer: bool = false
var _patched_lines: Array[int] = []
var _hint_lines: Array[int] = []

var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _style_panel: StyleBoxFlat


func _ready() -> void:
	_build_styles()
	_build_layout()
	EventBus.puzzle_loaded.connect(_on_puzzle_loaded)
	EventBus.answer_submitted.connect(_on_answer_submitted)
	EventBus.hint_applied.connect(_on_hint_applied)
	EventBus.level_restarted.connect(_on_level_restarted)


func _build_styles() -> void:
	_style_panel = StyleBoxFlat.new()
	_style_panel.bg_color = _COLOR_BG
	add_theme_stylebox_override("panel", _style_panel)

	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(_COLOR_BG)
	_style_normal.set_content_margin_all(4.0)

	_style_hover = StyleBoxFlat.new()
	_style_hover.bg_color = _COLOR_HOVER_BG
	_style_hover.set_content_margin_all(4.0)

	_style_selected = StyleBoxFlat.new()
	_style_selected.bg_color = Color(0.1, 0.1, 0.0, 0.3)
	_style_selected.set_content_margin_all(4.0)


func _build_layout() -> void:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_code_lines_container = VBoxContainer.new()
	_code_lines_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_code_lines_container)


func _on_puzzle_loaded(puzzle: PuzzleData) -> void:
	_clear_lines()
	_hint_lines = puzzle.hint_lines.duplicate()
	_patched_lines.clear()
	_selected_index = -1
	_waiting_for_answer = false

	var mono_font := SystemFont.new()
	mono_font.font_names = PackedStringArray(
		["Courier New", "Courier", "Liberation Mono", "monospace"]
	)

	for i: int in range(puzzle.code_lines.size()):
		var hbox := HBoxContainer.new()
		_code_lines_container.add_child(hbox)

		var num_label := Label.new()
		num_label.text = "%3d " % (i + 1)
		num_label.add_theme_color_override("font_color", _COLOR_LINE_NUM)
		num_label.add_theme_font_override("font", mono_font)
		num_label.custom_minimum_size = Vector2(40, 0)
		hbox.add_child(num_label)

		var btn := Button.new()
		btn.text = puzzle.code_lines[i]
		btn.flat = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 28)
		btn.add_theme_font_override("font", mono_font)
		btn.add_theme_color_override("font_color", _COLOR_TEXT)
		btn.add_theme_color_override("font_hover_color", _COLOR_TEXT)
		btn.add_theme_color_override("font_pressed_color", _COLOR_TEXT)
		btn.add_theme_stylebox_override("normal", _style_normal)
		btn.add_theme_stylebox_override("hover", _style_hover)
		btn.add_theme_stylebox_override("pressed", _style_hover)
		btn.add_theme_stylebox_override("focus", _style_normal)

		var idx: int = i
		btn.pressed.connect(func() -> void: _on_line_button_pressed(idx))
		_line_buttons.append(btn)
		hbox.add_child(btn)


func _clear_lines() -> void:
	_line_buttons.clear()
	for child: Node in _code_lines_container.get_children():
		child.queue_free()


func _on_line_button_pressed(line_index: int) -> void:
	if _waiting_for_answer:
		return
	if GameManager.state == GameManager.GameState.ANIMATING:
		return
	_waiting_for_answer = true
	_set_selected(line_index)
	PuzzleManager.selected_line = line_index
	EventBus.line_selected.emit(line_index)


func _set_selected(index: int) -> void:
	if _selected_index >= 0 and _selected_index < _line_buttons.size():
		var prev_btn: Button = _line_buttons[_selected_index]
		prev_btn.add_theme_color_override("font_color", _COLOR_TEXT)
		prev_btn.add_theme_stylebox_override("normal", _style_normal)

	_selected_index = index

	if index >= 0 and index < _line_buttons.size():
		var btn: Button = _line_buttons[index]
		btn.add_theme_color_override("font_color", _COLOR_SELECTED)
		btn.add_theme_stylebox_override("normal", _style_selected)


func _on_answer_submitted(correct: bool, _explanation: String) -> void:
	if correct:
		_waiting_for_answer = false
		_patch_selected_line()


func _patch_selected_line() -> void:
	if _selected_index < 0 or _selected_index >= _line_buttons.size():
		return
	var btn: Button = _line_buttons[_selected_index]
	btn.text = btn.text + "  >> PATCHED"
	btn.add_theme_color_override("font_color", _COLOR_TEXT)
	btn.add_theme_stylebox_override("normal", _style_normal)
	_patched_lines.append(_selected_index)
	_selected_index = -1
	_flash_panel(_COLOR_FLASH_GREEN, 0.3)


func _flash_panel(flash_color: Color, duration: float) -> void:
	var tween: Tween = create_tween()
	var flash_style := StyleBoxFlat.new()
	flash_style.bg_color = flash_color
	add_theme_stylebox_override("panel", flash_style)
	tween.tween_interval(duration)
	tween.tween_callback(func() -> void: add_theme_stylebox_override("panel", _style_panel))


func _on_hint_applied(line_index: int) -> void:
	if line_index < 0 or line_index >= _line_buttons.size():
		return
	var btn: Button = _line_buttons[line_index]
	if not btn.text.begins_with("~~"):
		btn.text = "~~ " + btn.text


func _on_level_restarted() -> void:
	_waiting_for_answer = false
	_selected_index = -1


func _input(event: InputEvent) -> void:
	if GameManager.state == GameManager.GameState.ANIMATING:
		return
	if GameManager.state == GameManager.GameState.LEVEL_CLEAR:
		return
	if GameManager.state == GameManager.GameState.GAME_CLEAR:
		return
	if _waiting_for_answer:
		return
	if _line_buttons.is_empty():
		return

	if event.is_action_pressed("move_up"):
		if _selected_index <= 0:
			_selected_index = 0
		else:
			_selected_index -= 1
		_set_selected(_selected_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		var next: int = _selected_index + 1
		if next < 0:
			next = 0
		_selected_index = mini(_line_buttons.size() - 1, next)
		_set_selected(_selected_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm") and _selected_index >= 0:
		_on_line_button_pressed(_selected_index)
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	EventBus.puzzle_loaded.disconnect(_on_puzzle_loaded)
	EventBus.answer_submitted.disconnect(_on_answer_submitted)
	EventBus.hint_applied.disconnect(_on_hint_applied)
	EventBus.level_restarted.disconnect(_on_level_restarted)
