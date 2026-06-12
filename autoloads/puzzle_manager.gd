## PuzzleManager — パズルの進行状態を管理する Autoload
extends Node

var current_puzzle: PuzzleData = null
var current_question_index: int = 0
var miss_count: int = 0
var hints_remaining: int = 3
var hints_used: int = 0
var selected_line: int = -1
var elapsed_time: float = 0.0
var _timer_active: bool = false


func _ready() -> void:
	EventBus.level_restarted.connect(_on_level_restarted)
	EventBus.hint_requested.connect(_on_hint_requested)


func _process(delta: float) -> void:
	if _timer_active and GameManager.state == GameManager.GameState.PLAYING:
		elapsed_time += delta


func load_puzzle(puzzle: PuzzleData) -> void:
	current_puzzle = puzzle
	current_question_index = 0
	miss_count = 0
	hints_remaining = 3
	hints_used = 0
	selected_line = -1
	elapsed_time = 0.0
	_start_timer()
	EventBus.puzzle_loaded.emit(puzzle)


func submit_answer(choice_index: int) -> void:
	if current_puzzle == null:
		return
	if current_question_index >= current_puzzle.questions.size():
		return

	var question: PuzzleQuestion = current_puzzle.questions[current_question_index]
	if choice_index == question.correct_index:
		current_question_index += 1
		EventBus.answer_submitted.emit(true, question.explanation)
		if current_question_index >= current_puzzle.questions.size():
			_stop_timer()
			EventBus.level_cleared.emit()
	else:
		miss_count += 1
		EventBus.answer_submitted.emit(false, "")

	EventBus.game_state_change_requested.emit(GameManager.GameState.ANIMATING)


func use_hint() -> void:
	if hints_remaining <= 0:
		return
	hints_remaining -= 1
	hints_used += 1
	if current_puzzle == null or current_puzzle.hint_lines.is_empty():
		return
	var hint_line_idx: int = mini(hints_used - 1, current_puzzle.hint_lines.size() - 1)
	EventBus.hint_applied.emit(current_puzzle.hint_lines[hint_line_idx])


func get_current_question() -> PuzzleQuestion:
	if current_puzzle == null:
		return null
	if current_question_index >= current_puzzle.questions.size():
		return null
	return current_puzzle.questions[current_question_index]


func restart_level() -> void:
	if current_puzzle != null:
		load_puzzle(current_puzzle)


func _start_timer() -> void:
	_timer_active = true


func _stop_timer() -> void:
	_timer_active = false


func _on_level_restarted() -> void:
	restart_level()


func _on_hint_requested() -> void:
	use_hint()


func _exit_tree() -> void:
	EventBus.level_restarted.disconnect(_on_level_restarted)
	EventBus.hint_requested.disconnect(_on_hint_requested)
