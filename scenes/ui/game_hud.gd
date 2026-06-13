## GameHUD — ゲームプレイ中の上部ステータスバー
extends CanvasLayer

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_DIM: Color = Color.html("#555555")
var _COLOR_BG: Color = Color.html("#0d0d0d")

var _level_label: Label
var _bug_type_label: Label
var _timer_label: Label
var _score_label: Label
var _hints_label: Label
var _pause_button: Button


func _ready() -> void:
	_build_hud()
	EventBus.puzzle_loaded.connect(_on_puzzle_loaded)
	EventBus.hint_applied.connect(_on_hint_applied)
	EventBus.answer_submitted.connect(_on_answer_submitted)


func _process(_delta: float) -> void:
	if PuzzleManager.current_puzzle == null:
		return
	var secs: int = int(PuzzleManager.elapsed_time)
	_timer_label.text = "%02d:%02d" % [secs / 60, secs % 60]


func _build_hud() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = _COLOR_BG

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)

	_level_label = _make_label("LEVEL - / -")
	_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_level_label)

	_bug_type_label = _make_label("[---]")
	hbox.add_child(_bug_type_label)

	_timer_label = _make_label("00:00")
	hbox.add_child(_timer_label)

	_score_label = _make_label("SCORE: 1000")
	hbox.add_child(_score_label)

	_hints_label = _make_label("HINTS: |||")
	hbox.add_child(_hints_label)

	_pause_button = Button.new()
	_pause_button.text = "[||]"
	_pause_button.flat = true
	_pause_button.add_theme_color_override("font_color", _COLOR_TEXT)
	_pause_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_pause_button.pressed.connect(_on_pause_pressed)
	hbox.add_child(_pause_button)


func _make_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", _COLOR_TEXT)
	return label


func _on_puzzle_loaded(puzzle: PuzzleData) -> void:
	_level_label.text = "LEVEL 1 / 1"
	_bug_type_label.text = "[%s]" % puzzle.bug_type
	_timer_label.text = "00:00"
	_score_label.text = "SCORE: 1000"
	_hints_label.text = "HINTS: |||"


func _on_hint_applied(_line_index: int) -> void:
	var remaining: int = PuzzleManager.hints_remaining
	var bars: String = ""
	for i: int in range(remaining):
		bars += "|"
	if bars.is_empty():
		bars = "---"
	_hints_label.text = "HINTS: " + bars


func _on_answer_submitted(correct: bool, _explanation: String) -> void:
	if not correct:
		var score: int = ScoreCalc.calculate_final_score(
			PuzzleManager.miss_count, PuzzleManager.elapsed_time, PuzzleManager.hints_used
		)
		_score_label.text = "SCORE: %d" % score


func _on_pause_pressed() -> void:
	EventBus.game_paused.emit(GameManager.state != GameManager.GameState.PAUSED)


func _exit_tree() -> void:
	EventBus.puzzle_loaded.disconnect(_on_puzzle_loaded)
	EventBus.hint_applied.disconnect(_on_hint_applied)
	EventBus.answer_submitted.disconnect(_on_answer_submitted)
