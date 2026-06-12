extends GutTest


func test_rank_s_at_900() -> void:
	assert_eq(ScoreCalc.calculate_rank(900), "S")


func test_rank_s_at_1000() -> void:
	assert_eq(ScoreCalc.calculate_rank(1000), "S")


func test_rank_a_at_700() -> void:
	assert_eq(ScoreCalc.calculate_rank(700), "A")


func test_rank_a_at_899() -> void:
	assert_eq(ScoreCalc.calculate_rank(899), "A")


func test_rank_b_at_500() -> void:
	assert_eq(ScoreCalc.calculate_rank(500), "B")


func test_rank_b_at_699() -> void:
	assert_eq(ScoreCalc.calculate_rank(699), "B")


func test_rank_c_at_300() -> void:
	assert_eq(ScoreCalc.calculate_rank(300), "C")


func test_rank_c_at_499() -> void:
	assert_eq(ScoreCalc.calculate_rank(499), "C")


func test_rank_d_at_299() -> void:
	assert_eq(ScoreCalc.calculate_rank(299), "D")


func test_rank_d_at_0() -> void:
	assert_eq(ScoreCalc.calculate_rank(0), "D")


func test_rank_d_at_100() -> void:
	assert_eq(ScoreCalc.calculate_rank(100), "D")
