## InvestigationPanel — 調査ターミナル：フレーバーテキスト・質問・選択肢・ヒントを表示する
extends PanelContainer

const _COLOR_FLASH_GREEN: Color = Color(0.0, 0.8, 0.2, 1.0)
const _COLOR_FLASH_RED: Color = Color(0.8, 0.1, 0.1, 1.0)
var _COLOR_BG: Color = Color.html("#0a0a1a")
var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_DIM: Color = Color.html("#555555")

var _style_panel: StyleBoxFlat
var _flavor_label: RichTextLabel
var _prompt_label: Label
var _choices_container: VBoxContainer
var _hint_button: Button
var _hints_count_label: Label
var _feedback_label: Label

var _choice_buttons: Array[Button] = []
var _level_cleared: bool = false


func _ready() -> void:
	_build_styles()
	_build_layout()
	EventBus.puzzle_loaded.connect(_on_puzzle_loaded)
	EventBus.line_selected.connect(_on_line_selected)
	EventBus.answer_submitted.connect(_on_answer_submitted)
	EventBus.hint_applied.connect(_on_hint_applied)
	EventBus.level_cleared.connect(_on_level_cleared)
	EventBus.level_restarted.connect(_on_level_restarted)
	EventBus.settings_changed.connect(_on_settings_changed)


func _build_styles() -> void:
	_style_panel = StyleBoxFlat.new()
	_style_panel.bg_color = _COLOR_BG
	add_theme_stylebox_override("panel", _style_panel)


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	_flavor_label = RichTextLabel.new()
	_flavor_label.bbcode_enabled = false
	_flavor_label.fit_content = true
	_flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flavor_label.add_theme_color_override("default_color", _COLOR_DIM)
	_flavor_label.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(_flavor_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_prompt_label = Label.new()
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_prompt_label.visible = false
	vbox.add_child(_prompt_label)

	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 6)
	_choices_container.visible = false
	vbox.add_child(_choices_container)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 12)
	vbox.add_child(hint_row)

	_hint_button = Button.new()
	_hint_button.text = tr("BTN_HINT")
	_hint_button.flat = true
	_hint_button.custom_minimum_size = Vector2(0, 40)
	_hint_button.add_theme_color_override("font_color", _COLOR_TEXT)
	_hint_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_hint_button.pressed.connect(_on_hint_pressed)
	hint_row.add_child(_hint_button)

	_hints_count_label = Label.new()
	_hints_count_label.text = "|||"
	_hints_count_label.add_theme_color_override("font_color", _COLOR_TEXT)
	hint_row.add_child(_hints_count_label)

	_feedback_label = Label.new()
	_feedback_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_feedback_label.visible = false
	vbox.add_child(_feedback_label)


func _on_puzzle_loaded(puzzle: PuzzleData) -> void:
	_flavor_label.text = puzzle.flavor_text
	_prompt_label.visible = false
	_choices_container.visible = false
	_feedback_label.visible = false
	_level_cleared = false
	_update_hint_display()


func _on_line_selected(_line_index: int) -> void:
	var question: PuzzleQuestion = PuzzleManager.get_current_question()
	if question == null:
		return
	_show_question(question)


func _show_question(question: PuzzleQuestion) -> void:
	_prompt_label.text = question.prompt
	_prompt_label.visible = true

	_clear_choices()
	var labels: Array[String] = ["[A]", "[B]", "[C]", "[D]"]
	for i: int in range(question.choices.size()):
		var btn := Button.new()
		btn.text = "%s  %s" % [labels[i], question.choices[i]]
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_color_override("font_color", _COLOR_TEXT)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		var idx: int = i
		btn.pressed.connect(func() -> void: _on_choice_pressed(idx))
		_choices_container.add_child(btn)
		_choice_buttons.append(btn)

	_choices_container.visible = true
	_feedback_label.visible = false


func _clear_choices() -> void:
	_choice_buttons.clear()
	for child: Node in _choices_container.get_children():
		child.queue_free()


func _on_choice_pressed(choice_index: int) -> void:
	if GameManager.state == GameManager.GameState.ANIMATING:
		return
	if GameManager.state == GameManager.GameState.LEVEL_CLEAR:
		return
	_set_choices_interactive(false)
	PuzzleManager.submit_answer(choice_index)


func _set_choices_interactive(enabled: bool) -> void:
	for btn: Button in _choice_buttons:
		btn.disabled = not enabled


func _on_answer_submitted(correct: bool, explanation: String) -> void:
	if correct:
		_show_feedback_and_animate_correct(explanation)
	else:
		_show_feedback_and_animate_wrong()


func _show_feedback_and_animate_correct(explanation: String) -> void:
	_flash_panel(
		_COLOR_FLASH_GREEN,
		0.3,
		func() -> void:
			_feedback_label.text = "%s\n   %s" % [tr("FEEDBACK_PATCHED"), explanation]
			_feedback_label.visible = true
			_choices_container.visible = false
			_prompt_label.visible = false
			if not _level_cleared:
				EventBus.game_state_change_requested.emit(GameManager.GameState.PLAYING)
	)


func _show_feedback_and_animate_wrong() -> void:
	_flash_panel(
		_COLOR_FLASH_RED,
		0.2,
		func() -> void:
			_feedback_label.text = tr("FEEDBACK_DENIED")
			_feedback_label.visible = true
			_set_choices_interactive(true)
			EventBus.game_state_change_requested.emit(GameManager.GameState.PLAYING)
	)


func _flash_panel(flash_color: Color, duration: float, on_done: Callable) -> void:
	var tween: Tween = create_tween()
	var flash_style := StyleBoxFlat.new()
	flash_style.bg_color = flash_color
	add_theme_stylebox_override("panel", flash_style)
	tween.tween_interval(duration)
	tween.tween_callback(
		func() -> void:
			add_theme_stylebox_override("panel", _style_panel)
			on_done.call()
	)


func _on_hint_pressed() -> void:
	EventBus.hint_requested.emit()


func _on_hint_applied(_line_index: int) -> void:
	_update_hint_display()


func _update_hint_display() -> void:
	var remaining: int = PuzzleManager.hints_remaining
	if remaining <= 0:
		_hint_button.disabled = true
		_hints_count_label.text = "---"
	else:
		_hint_button.disabled = false
		var bars: String = ""
		for i: int in range(remaining):
			bars += "|"
		_hints_count_label.text = bars


func _on_level_cleared() -> void:
	_level_cleared = true


func _on_level_restarted() -> void:
	_level_cleared = false
	_clear_choices()
	_prompt_label.visible = false
	_choices_container.visible = false
	_feedback_label.visible = false
	_update_hint_display()


func _input(event: InputEvent) -> void:
	if GameManager.state == GameManager.GameState.ANIMATING:
		return
	if GameManager.state == GameManager.GameState.LEVEL_CLEAR:
		return
	if not _choices_container.visible:
		return
	var key_map: Dictionary = {
		KEY_A: 0,
		KEY_B: 1,
		KEY_C: 2,
		KEY_D: 3,
	}
	for key: int in key_map:
		if event is InputEventKey and event.keycode == key and event.pressed and not event.echo:
			var idx: int = key_map[key]
			if idx < _choice_buttons.size():
				_on_choice_pressed(idx)
				get_viewport().set_input_as_handled()
			return


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language":
		_hint_button.text = tr("BTN_HINT")


func _exit_tree() -> void:
	EventBus.puzzle_loaded.disconnect(_on_puzzle_loaded)
	EventBus.line_selected.disconnect(_on_line_selected)
	EventBus.answer_submitted.disconnect(_on_answer_submitted)
	EventBus.hint_applied.disconnect(_on_hint_applied)
	EventBus.level_cleared.disconnect(_on_level_cleared)
	EventBus.level_restarted.disconnect(_on_level_restarted)
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
