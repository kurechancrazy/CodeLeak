extends GutTest

# --- calculate_base_score ---


func test_base_score_perfect() -> void:
	assert_eq(ScoreCalc.calculate_base_score(0, 0.0), 1000)


func test_base_score_miss_penalty() -> void:
	assert_eq(ScoreCalc.calculate_base_score(3, 0.0), 700)


func test_base_score_time_penalty() -> void:
	assert_eq(ScoreCalc.calculate_base_score(0, 100.0), 800)


func test_base_score_combined_penalties() -> void:
	# 1000 - 200 - 200 = 600
	assert_eq(ScoreCalc.calculate_base_score(2, 100.0), 600)


func test_base_score_minimum_floor() -> void:
	assert_eq(ScoreCalc.calculate_base_score(20, 500.0), 100, "最低スコアは100")


func test_base_score_boundary_exactly_100() -> void:
	# 1000 - 9*100 - 0 = 100  (境界値: ちょうど100)
	assert_eq(ScoreCalc.calculate_base_score(9, 0.0), 100)


func test_base_score_boundary_99_clamps_to_100() -> void:
	# 1000 - 9*100 - 2 = 98 → clamped to 100
	assert_eq(ScoreCalc.calculate_base_score(9, 1.0), 100)


# --- apply_hint_penalty ---


func test_hint_penalty_no_hints() -> void:
	assert_eq(ScoreCalc.apply_hint_penalty(1000, 0), 1000)


func test_hint_penalty_one_hint() -> void:
	assert_eq(ScoreCalc.apply_hint_penalty(1000, 1), 800)


func test_hint_penalty_two_hints() -> void:
	assert_eq(ScoreCalc.apply_hint_penalty(1000, 2), 640)


func test_hint_penalty_zero_base() -> void:
	assert_eq(ScoreCalc.apply_hint_penalty(0, 3), 0)


# --- calculate_final_score ---


func test_final_score_perfect() -> void:
	assert_eq(ScoreCalc.calculate_final_score(0, 0.0, 0), 1000)


func test_final_score_with_miss_and_hint() -> void:
	# base = max(100, 1000 - 100 - 100) = 800
	# hint penalty = int(800 * 0.8) = 640
	assert_eq(ScoreCalc.calculate_final_score(1, 50.0, 1), 640)


func test_final_score_minimum_applies_before_hint_penalty() -> void:
	# base = 100 (clamped), then hint penalty
	var result: int = ScoreCalc.calculate_final_score(20, 500.0, 1)
	assert_eq(result, int(100.0 * 0.8))
