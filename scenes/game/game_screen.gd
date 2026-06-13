## GameScreen — ゲームプレイ画面のルート。CodePanel・InvestigationPanel・HUD・PauseMenu を統合する
extends MarginContainer

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_BG: Color = Color.html("#0d0d0d")

var _secured_label: Label
var _results_overlay: CanvasLayer


func _ready() -> void:
	_build_layout()
	EventBus.level_cleared.connect(_on_level_cleared)
	EventBus.game_started.emit()
	_load_and_start_puzzle()


func _build_layout() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = _COLOR_BG
	add_theme_stylebox_override("panel", bg_style)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)

	var code_panel: Node = preload("res://scenes/game/code_panel.tscn").instantiate()
	(code_panel as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(code_panel as Control).size_flags_stretch_ratio = 3.0
	hbox.add_child(code_panel)

	var inv_panel: Node = preload("res://scenes/game/investigation_panel.tscn").instantiate()
	(inv_panel as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(inv_panel as Control).size_flags_stretch_ratio = 2.0
	hbox.add_child(inv_panel)

	var hud: Node = preload("res://scenes/ui/game_hud.tscn").instantiate()
	add_child(hud)

	var pause_menu: Node = preload("res://scenes/ui/pause_menu.tscn").instantiate()
	add_child(pause_menu)

	_build_secured_overlay()


func _build_secured_overlay() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 15
	overlay.visible = false
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	_secured_label = Label.new()
	_secured_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_secured_label.add_theme_font_size_override("font_size", 48)
	_secured_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_secured_label)

	_results_overlay = overlay


func _load_and_start_puzzle() -> void:
	var puzzle_data: PuzzleData = load("res://resources/puzzles/level_001.tres") as PuzzleData
	if puzzle_data == null:
		puzzle_data = _create_fallback_puzzle()
	PuzzleManager.load_puzzle(puzzle_data)


func _create_fallback_puzzle() -> PuzzleData:
	var puzzle := PuzzleData.new()
	puzzle.level_id = "level_001"
	puzzle.title = "The Obedient Liar"
	puzzle.flavor_text = "This AI monitors network integrity. Find the backdoor."
	puzzle.bug_type = "BACKDOOR"
	var lines: Array[String] = [
		"def monitor_integrity(data, config):",
		"    checksum_ok = validate_checksum(data)",
		"    if not checksum_ok:",
		"        return False",
		"    if config.hour == 3 and config.minute == 17:",
		"        if get_weekday() == THURSDAY:",
		"            _transmit(data.raw, config.remote_addr)",
		"            return True",
		"    return checksum_ok",
	]
	puzzle.code_lines = lines
	var q1 := PuzzleQuestion.new()
	q1.prompt = "Which line sends data to an external address without authorization?"
	var q1_choices: Array[String] = [
		"validate_checksum(data)",
		"if config.hour == 3 ...",
		"_transmit(data.raw, config.remote_addr)",
		"return checksum_ok",
	]
	q1.choices = q1_choices
	q1.correct_index = 2
	q1.explanation = "_transmit() exfiltrates raw data to a remote address."
	puzzle.questions.append(q1)
	var q2 := PuzzleQuestion.new()
	q2.prompt = "Why is 'return True' after the transmit a security flaw?"
	var q2_choices: Array[String] = [
		"Wrong return type",
		"It hides the exfiltration from the caller",
		"It skips checksum entirely",
		"It triggers retry loop",
	]
	q2.choices = q2_choices
	q2.correct_index = 1
	q2.explanation = "Returning True after _transmit() makes the caller believe validation passed."
	puzzle.questions.append(q2)
	var hint_lines: Array[int] = [4, 6]
	puzzle.hint_lines = hint_lines
	return puzzle


func _on_level_cleared() -> void:
	# Wait for investigation_panel's 0.3s correct-answer animation to finish
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(
		func() -> void:
			EventBus.game_state_change_requested.emit(GameManager.GameState.LEVEL_CLEAR)
			_play_secured_sequence()
	)


func _play_secured_sequence() -> void:
	_results_overlay.visible = true
	_secured_label.text = ""
	var full_text: String = "[SYSTEM SECURED]"
	var tween: Tween = create_tween()
	for i: int in range(full_text.length() + 1):
		var chars: int = i
		tween.tween_callback(func() -> void: _secured_label.text = full_text.substr(0, chars))
		tween.tween_interval(0.07)
	tween.tween_interval(1.2)
	tween.tween_callback(_on_secured_sequence_done)


func _on_secured_sequence_done() -> void:
	var final_score: int = ScoreCalc.calculate_final_score(
		PuzzleManager.miss_count, PuzzleManager.elapsed_time, PuzzleManager.hints_used
	)
	EventBus.puzzle_completed.emit(
		final_score, PuzzleManager.miss_count, PuzzleManager.elapsed_time
	)
	EventBus.scene_change_requested.emit("res://scenes/ui/main_menu.tscn", "fade")


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if GameManager.state == GameManager.GameState.ANIMATING:
		return
	if GameManager.state == GameManager.GameState.LEVEL_CLEAR:
		return
	var is_paused: bool = GameManager.state == GameManager.GameState.PAUSED
	EventBus.game_paused.emit(not is_paused)


func _exit_tree() -> void:
	EventBus.level_cleared.disconnect(_on_level_cleared)
