extends GutTest

var _fm: Node = null


func before_each() -> void:
	_fm = load("res://autoloads/flag_manager.gd").new()
	# _ready() を呼ばず EventBus / SaveManager 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_fm.free()


# --- set_flag / get_flag ---

func test_set_flag_returns_true_on_get() -> void:
	_fm.set_flag("event_001")
	assert_true(_fm.get_flag("event_001"))


func test_get_flag_returns_false_for_unknown_id() -> void:
	assert_false(_fm.get_flag("not_set"))


func test_get_flag_returns_false_after_clear() -> void:
	_fm.set_flag("event_002")
	_fm.clear_flag("event_002")
	assert_false(_fm.get_flag("event_002"))


func test_multiple_flags_independent() -> void:
	_fm.set_flag("flag_a")
	_fm.set_flag("flag_b")
	assert_true(_fm.get_flag("flag_a"))
	assert_true(_fm.get_flag("flag_b"))


func test_clear_flag_does_not_affect_other_flags() -> void:
	_fm.set_flag("flag_a")
	_fm.set_flag("flag_b")
	_fm.clear_flag("flag_a")
	assert_false(_fm.get_flag("flag_a"))
	assert_true(_fm.get_flag("flag_b"))


# --- reset ---

func test_reset_clears_all_flags() -> void:
	_fm.set_flag("flag_a")
	_fm.set_flag("flag_b")
	_fm.reset()
	assert_false(_fm.get_flag("flag_a"))
	assert_false(_fm.get_flag("flag_b"))


# --- resolve_dialog ---

func test_resolve_dialog_returns_default() -> void:
	var result: String = _fm.resolve_dialog("npc_01", "dialog_greeting")
	assert_eq(result, "dialog_greeting")


# --- 境界値 ---

func test_set_flag_with_empty_string() -> void:
	_fm.set_flag("")
	assert_true(_fm.get_flag(""))


func test_clear_flag_non_existent_does_not_crash() -> void:
	_fm.clear_flag("does_not_exist")
	assert_false(_fm.get_flag("does_not_exist"))
