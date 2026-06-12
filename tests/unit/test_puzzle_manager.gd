extends GutTest

var _puzzle_manager: Node = null


func _make_puzzle(num_questions: int = 2) -> PuzzleData:
	var puzzle: PuzzleData = PuzzleData.new()
	puzzle.level_id = "test_level"
	puzzle.title = "Test Puzzle"
	puzzle.flavor_text = "Test flavor."
	puzzle.bug_type = "BACKDOOR"
	var code_lines: Array[String] = ["line_0", "line_1", "line_2"]
	puzzle.code_lines = code_lines
	var hint_lines: Array[int] = [0, 2]
	puzzle.hint_lines = hint_lines
	for i: int in range(num_questions):
		var q: PuzzleQuestion = PuzzleQuestion.new()
		q.prompt = "Question %d" % i
		var choices: Array[String] = ["Wrong A", "Wrong B", "Correct", "Wrong D"]
		q.choices = choices
		q.correct_index = 2
		q.explanation = "Explanation %d" % i
		puzzle.questions.append(q)
	return puzzle


func before_each() -> void:
	_puzzle_manager = preload("res://autoloads/puzzle_manager.gd").new()
	add_child_autofree(_puzzle_manager)


# --- load_puzzle ---


func test_load_puzzle_initializes_state() -> void:
	var puzzle: PuzzleData = _make_puzzle()
	_puzzle_manager.load_puzzle(puzzle)
	assert_eq(_puzzle_manager.current_question_index, 0)
	assert_eq(_puzzle_manager.miss_count, 0)
	assert_eq(_puzzle_manager.hints_remaining, 3)
	assert_eq(_puzzle_manager.hints_used, 0)
	assert_eq(_puzzle_manager.elapsed_time, 0.0)
	assert_true(_puzzle_manager._timer_active)


func test_load_puzzle_stores_reference() -> void:
	var puzzle: PuzzleData = _make_puzzle()
	_puzzle_manager.load_puzzle(puzzle)
	assert_eq(_puzzle_manager.current_puzzle, puzzle)


func test_get_current_question_returns_first_after_load() -> void:
	var puzzle: PuzzleData = _make_puzzle()
	_puzzle_manager.load_puzzle(puzzle)
	var q: PuzzleQuestion = _puzzle_manager.get_current_question()
	assert_not_null(q)
	assert_eq(q.prompt, "Question 0")


# --- submit_answer (正解) ---


func test_correct_answer_advances_question_index() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.submit_answer(2)  # correct_index = 2
	assert_eq(_puzzle_manager.current_question_index, 1)


func test_correct_answer_does_not_increment_miss_count() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.submit_answer(2)
	assert_eq(_puzzle_manager.miss_count, 0)


func test_all_correct_answers_emit_level_cleared() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	watch_signals(EventBus)
	_puzzle_manager.submit_answer(2)  # Q1 correct
	_puzzle_manager.submit_answer(2)  # Q2 correct — last question
	assert_signal_emitted(EventBus, "level_cleared")


func test_level_cleared_stops_timer() -> void:
	var puzzle: PuzzleData = _make_puzzle(1)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.submit_answer(2)
	assert_false(_puzzle_manager._timer_active)


func test_partial_correct_does_not_emit_level_cleared() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	watch_signals(EventBus)
	_puzzle_manager.submit_answer(2)  # Q1 correct, Q2 still pending
	assert_signal_not_emitted(EventBus, "level_cleared")


# --- submit_answer (不正解) ---


func test_wrong_answer_increments_miss_count() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.submit_answer(0)  # wrong (correct is 2)
	assert_eq(_puzzle_manager.miss_count, 1)


func test_wrong_answer_does_not_advance_question_index() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.submit_answer(0)
	assert_eq(_puzzle_manager.current_question_index, 0)


# --- use_hint ---


func test_use_hint_decrements_remaining() -> void:
	var puzzle: PuzzleData = _make_puzzle()
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.use_hint()
	assert_eq(_puzzle_manager.hints_remaining, 2)
	assert_eq(_puzzle_manager.hints_used, 1)


func test_use_hint_at_zero_does_nothing() -> void:
	var puzzle: PuzzleData = _make_puzzle()
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.hints_remaining = 0
	_puzzle_manager.hints_used = 3
	_puzzle_manager.use_hint()
	assert_eq(_puzzle_manager.hints_remaining, 0, "hints_remaining が 0 のとき変化しない")
	assert_eq(_puzzle_manager.hints_used, 3, "hints_used が 0 のとき変化しない")


# --- restart_level ---


func test_restart_level_resets_miss_count() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.miss_count = 5
	_puzzle_manager.restart_level()
	assert_eq(_puzzle_manager.miss_count, 0)


func test_restart_level_resets_elapsed_time() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.elapsed_time = 42.0
	_puzzle_manager.restart_level()
	assert_eq(_puzzle_manager.elapsed_time, 0.0)


func test_restart_level_resets_question_index() -> void:
	var puzzle: PuzzleData = _make_puzzle(2)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.submit_answer(2)
	_puzzle_manager.restart_level()
	assert_eq(_puzzle_manager.current_question_index, 0)


# --- get_current_question 境界値 ---


func test_get_current_question_returns_null_without_puzzle() -> void:
	assert_null(_puzzle_manager.get_current_question())


func test_get_current_question_returns_null_after_all_answered() -> void:
	var puzzle: PuzzleData = _make_puzzle(1)
	_puzzle_manager.load_puzzle(puzzle)
	_puzzle_manager.current_question_index = 1  # past end
	assert_null(_puzzle_manager.get_current_question())
