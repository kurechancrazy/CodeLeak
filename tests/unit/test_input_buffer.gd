extends GutTest

var _buf: Node = null


func before_each() -> void:
	_buf = load("res://autoloads/input_buffer.gd").new()


func after_each() -> void:
	_buf.free()


func test_matches_empty_sequence_false() -> void:
	assert_false(_buf.matches_sequence([]))


func test_matches_single_action() -> void:
	_buf.record("attack")
	assert_true(_buf.matches_sequence(["attack"]))


func test_matches_sequence_in_order() -> void:
	_buf.record("down")
	_buf.record("right")
	_buf.record("attack")
	assert_true(_buf.matches_sequence(["down", "right", "attack"]))


func test_does_not_match_wrong_order() -> void:
	_buf.record("right")
	_buf.record("down")
	_buf.record("attack")
	assert_false(_buf.matches_sequence(["down", "right", "attack"]))


func test_clear_removes_all_entries() -> void:
	_buf.record("attack")
	_buf.clear()
	assert_false(_buf.matches_sequence(["attack"]))


func test_empty_buffer_no_match() -> void:
	assert_false(_buf.matches_sequence(["attack", "special"]))
