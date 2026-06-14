## ResultScreen — レベルクリア後のスコア・ランク・ハイスコア演出画面
extends MarginContainer

var _COLOR_BG: Color = Color.html("#0d0d0d")
var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_DIM: Color = Color.html("#555555")
var _COLOR_GOLD: Color = Color.html("#ffd700")

var _result_score: int = 0
var _result_miss: int = 0
var _result_time: float = 0.0
var _result_hints: int = 0
var _result_is_new_high: bool = false
var _rank: String = ""
var _animation_done: bool = false

var _rank_label: Label
var _score_label: Label
var _new_high_label: Label
var _buttons: HBoxContainer
var _retry_btn: Button
var _main_menu_btn: Button

var _title_label: Label
var _level_label: Label
var _bug_type_label: Label
var _time_label: Label
var _miss_label: Label
var _hints_label: Label
var _sep1: HSeparator
var _sep2: HSeparator


func _ready() -> void:
	_load_result_data()
	_build_layout()
	_apply_styles()
	EventBus.game_state_change_requested.emit(GameManager.GameState.RESULT)
	EventBus.settings_changed.connect(_on_settings_changed)
	_play_intro_sequence()


func _load_result_data() -> void:
	_result_score = int(GameManager.last_result.get("score", 0))
	_result_miss = int(GameManager.last_result.get("miss_count", 0))
	_result_time = float(GameManager.last_result.get("elapsed_time", 0.0))
	_result_hints = int(GameManager.last_result.get("hints_used", 0))
	_result_is_new_high = bool(GameManager.last_result.get("is_new_high_score", false))
	_rank = ScoreCalc.calculate_rank(_result_score)


func _build_layout() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.size_flags_vertical = SIZE_EXPAND_FILL
	center.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.visible = false
	vbox.add_child(_title_label)

	_level_label = Label.new()
	var puzzle_title: String = ""
	if PuzzleManager.current_puzzle != null:
		puzzle_title = PuzzleManager.current_puzzle.title
	_level_label.text = puzzle_title
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.visible = false
	vbox.add_child(_level_label)

	_bug_type_label = Label.new()
	var puzzle_bug: String = ""
	if PuzzleManager.current_puzzle != null:
		puzzle_bug = "[%s]" % PuzzleManager.current_puzzle.bug_type
	_bug_type_label.text = puzzle_bug
	_bug_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bug_type_label.visible = false
	vbox.add_child(_bug_type_label)

	_sep1 = HSeparator.new()
	_sep1.visible = false
	vbox.add_child(_sep1)

	_rank_label = Label.new()
	_rank_label.text = _rank
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.visible = false
	vbox.add_child(_rank_label)

	_score_label = Label.new()
	_score_label.visible = false
	vbox.add_child(_score_label)

	_time_label = Label.new()
	_time_label.visible = false
	vbox.add_child(_time_label)

	_miss_label = Label.new()
	_miss_label.visible = false
	vbox.add_child(_miss_label)

	_hints_label = Label.new()
	_hints_label.visible = false
	vbox.add_child(_hints_label)

	_new_high_label = Label.new()
	_new_high_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_new_high_label.visible = false
	vbox.add_child(_new_high_label)

	_sep2 = HSeparator.new()
	_sep2.visible = false
	vbox.add_child(_sep2)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.visible = false
	vbox.add_child(_buttons)

	_retry_btn = Button.new()
	_retry_btn.flat = true
	_retry_btn.custom_minimum_size = Vector2(160, 44)
	_retry_btn.pressed.connect(_on_retry_pressed)
	_buttons.add_child(_retry_btn)

	_main_menu_btn = Button.new()
	_main_menu_btn.flat = true
	_main_menu_btn.custom_minimum_size = Vector2(160, 44)
	_main_menu_btn.pressed.connect(_on_main_menu_pressed)
	_buttons.add_child(_main_menu_btn)

	var bg := ColorRect.new()
	bg.color = _COLOR_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.z_index = -1
	add_child(bg)
	move_child(bg, 0)

	var mono_font_ref: SystemFont = _make_mono_font()
	_apply_label_style(_title_label, mono_font_ref, _COLOR_TEXT, 24)
	_apply_label_style(_level_label, mono_font_ref, _COLOR_TEXT, 18)
	_apply_label_style(_bug_type_label, mono_font_ref, _COLOR_DIM, 16)
	_apply_label_style(_rank_label, mono_font_ref, _COLOR_TEXT, 72)
	_apply_label_style(_score_label, mono_font_ref, _COLOR_TEXT, 20)
	_apply_label_style(_time_label, mono_font_ref, _COLOR_TEXT, 20)
	_apply_label_style(_miss_label, mono_font_ref, _COLOR_TEXT, 20)
	_apply_label_style(_hints_label, mono_font_ref, _COLOR_TEXT, 20)
	_apply_label_style(_new_high_label, mono_font_ref, _COLOR_TEXT, 20)

	if _result_is_new_high:
		_score_label.add_theme_color_override("font_color", _COLOR_GOLD)
		_new_high_label.add_theme_color_override("font_color", _COLOR_GOLD)

	_apply_button_style(_retry_btn, mono_font_ref)
	_apply_button_style(_main_menu_btn, mono_font_ref)

	_refresh_labels()


func _make_mono_font() -> SystemFont:
	var mono_font := SystemFont.new()
	mono_font.font_names = PackedStringArray(
		["Courier New", "Courier", "Liberation Mono", "monospace"]
	)
	return mono_font


func _apply_label_style(label: Label, font: SystemFont, color: Color, size: int) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)


func _apply_button_style(btn: Button, font: SystemFont) -> void:
	btn.add_theme_color_override("font_color", _COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_override("font", font)


func _apply_styles() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = _COLOR_BG
	add_theme_stylebox_override("panel", bg_style)


func _refresh_labels() -> void:
	_title_label.text = tr("RESULT_TITLE")
	_score_label.text = "%s %d" % [tr("RESULT_SCORE_PREFIX"), _result_score]
	_time_label.text = "%s %s" % [tr("RESULT_TIME_PREFIX"), _format_time(_result_time)]
	_miss_label.text = "%s %d" % [tr("RESULT_MISS_PREFIX"), _result_miss]
	_hints_label.text = "%s %d" % [tr("RESULT_HINTS_PREFIX"), _result_hints]
	_new_high_label.text = tr("RESULT_NEW_HIGH")
	_retry_btn.text = tr("BTN_RETRY")
	_main_menu_btn.text = tr("BTN_MAIN_MENU")


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language":
		_refresh_labels()


func _play_intro_sequence() -> void:
	var items: Array[Control] = [
		_title_label,
		_level_label,
		_bug_type_label,
		_sep1,
		_rank_label,
		_score_label,
		_time_label,
		_miss_label,
		_hints_label,
	]
	var tween: Tween = create_tween()
	for item: Control in items:
		tween.tween_callback(func() -> void: item.visible = true)
		tween.tween_interval(0.1)
	if _result_is_new_high:
		tween.tween_callback(func() -> void: _new_high_label.visible = true)
		tween.tween_interval(0.1)
		_play_blink_animation()
	tween.tween_interval(0.1)
	tween.tween_callback(func() -> void: _sep2.visible = true)
	tween.tween_callback(func() -> void: _buttons.visible = true)
	tween.tween_callback(func() -> void: _animation_done = true)


func _play_blink_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(_new_high_label, "modulate:a", 0.0, 0.25)
	tween.tween_property(_new_high_label, "modulate:a", 1.0, 0.25)


func _format_time(secs: float) -> String:
	var minutes: int = int(secs) / 60
	var seconds: int = int(secs) % 60
	return "%02d:%02d" % [minutes, seconds]


func _on_retry_pressed() -> void:
	EventBus.game_state_change_requested.emit(GameManager.GameState.PLAYING)
	EventBus.scene_change_requested.emit("res://scenes/game/game_screen.tscn", "fade")


func _on_main_menu_pressed() -> void:
	EventBus.game_state_change_requested.emit(GameManager.GameState.MAIN_MENU)
	EventBus.scene_change_requested.emit("res://scenes/ui/main_menu.tscn", "fade")


func _input(event: InputEvent) -> void:
	if not _animation_done:
		return
	if event.is_action_pressed("confirm"):
		_on_retry_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cancel"):
		_on_main_menu_pressed()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
