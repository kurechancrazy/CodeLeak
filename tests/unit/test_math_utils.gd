extends GutTest

# --- clamp_int ---

func test_clamp_int_within_range() -> void:
	assert_eq(MathUtils.clamp_int(5, 0, 10), 5)

func test_clamp_int_below_min() -> void:
	assert_eq(MathUtils.clamp_int(-1, 0, 10), 0)

func test_clamp_int_above_max() -> void:
	assert_eq(MathUtils.clamp_int(11, 0, 10), 10)

func test_clamp_int_at_boundary_min() -> void:
	assert_eq(MathUtils.clamp_int(0, 0, 10), 0)

func test_clamp_int_at_boundary_max() -> void:
	assert_eq(MathUtils.clamp_int(10, 0, 10), 10)

# --- seconds_to_time_string ---

func test_seconds_to_time_string_zero() -> void:
	assert_eq(MathUtils.seconds_to_time_string(0.0), "00:00")

func test_seconds_to_time_string_one_minute() -> void:
	assert_eq(MathUtils.seconds_to_time_string(60.0), "01:00")

func test_seconds_to_time_string_ninety_seconds() -> void:
	assert_eq(MathUtils.seconds_to_time_string(90.0), "01:30")

func test_seconds_to_time_string_fractional() -> void:
	assert_eq(MathUtils.seconds_to_time_string(1.9), "00:01")

# --- format_score ---

func test_format_score_zero() -> void:
	assert_eq(MathUtils.format_score(0), "0")

func test_format_score_small() -> void:
	assert_eq(MathUtils.format_score(500), "500")

func test_format_score_thousands() -> void:
	assert_eq(MathUtils.format_score(1500), "1,500")

func test_format_score_millions() -> void:
	assert_eq(MathUtils.format_score(1000000), "1,000,000")

# --- shuffled ---

func test_shuffled_preserves_length() -> void:
	var original: Array = [1, 2, 3, 4, 5]
	var result: Array = MathUtils.shuffled(original)
	assert_eq(result.size(), original.size())

func test_shuffled_does_not_modify_original() -> void:
	var original: Array = [1, 2, 3, 4, 5]
	var _result: Array = MathUtils.shuffled(original)
	assert_eq(original, [1, 2, 3, 4, 5])

func test_shuffled_empty_array() -> void:
	var result: Array = MathUtils.shuffled([])
	assert_eq(result.size(), 0)
