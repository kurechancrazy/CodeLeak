extends GutTest


func test_weighted_random_returns_valid_index() -> void:
	var weights: Array[float] = [1.0, 2.0, 3.0]
	var idx: int = RngUtils.weighted_random(weights)
	assert_between(idx, 0, weights.size() - 1)


func test_weighted_random_empty_returns_minus_one() -> void:
	assert_eq(RngUtils.weighted_random([]), -1)


func test_weighted_random_all_zero_returns_minus_one() -> void:
	assert_eq(RngUtils.weighted_random([0.0, 0.0, 0.0]), -1)


func test_weighted_random_single_weight_returns_zero() -> void:
	assert_eq(RngUtils.weighted_random([5.0]), 0)


func test_random_element_from_array() -> void:
	var arr: Array = [10, 20, 30]
	var elem: Variant = RngUtils.random_element(arr)
	assert_true(arr.has(elem))


func test_random_element_empty_returns_null() -> void:
	assert_null(RngUtils.random_element([]))


func test_shuffled_preserves_all_elements() -> void:
	var arr: Array = [1, 2, 3, 4, 5]
	var result: Array = RngUtils.shuffled(arr)
	assert_eq(result.size(), arr.size())
	for elem: int in arr:
		assert_true(result.has(elem))


func test_shuffled_does_not_modify_original() -> void:
	var arr: Array = [1, 2, 3]
	var original: Array = arr.duplicate()
	RngUtils.shuffled(arr)
	assert_eq(arr, original)


func test_random_bool_probability_one_always_true() -> void:
	assert_true(RngUtils.random_bool(1.0))


func test_random_bool_probability_zero_always_false() -> void:
	assert_false(RngUtils.random_bool(0.0))


func test_random_bool_clamps_above_one() -> void:
	assert_true(RngUtils.random_bool(999.0))
