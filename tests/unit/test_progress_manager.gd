extends GutTest

var _pm: Node = null


func before_each() -> void:
	_pm = load("res://autoloads/progress_manager.gd").new()
	# _ready() を呼ばず EventBus / SaveManager 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_pm.free()


# --- unlock_achievement ---

func test_unlock_achievement_returns_true_on_first_unlock() -> void:
	assert_true(_pm.unlock_achievement("ach_first_battle"))


func test_unlock_achievement_returns_false_when_already_unlocked() -> void:
	_pm.unlock_achievement("ach_001")
	assert_false(_pm.unlock_achievement("ach_001"), "2 回目は false を返すこと")


func test_is_unlocked_true_after_unlock() -> void:
	_pm.unlock_achievement("ach_001")
	assert_true(_pm.is_unlocked("ach_001"))


func test_is_unlocked_false_for_unknown() -> void:
	assert_false(_pm.is_unlocked("not_unlocked"))


# --- increment_stat ---

func test_increment_stat_increases_value() -> void:
	_pm.increment_stat("enemies_killed", 5)
	assert_eq(_pm.get_stat("enemies_killed"), 5)


func test_increment_stat_accumulates() -> void:
	_pm.increment_stat("enemies_killed", 3)
	_pm.increment_stat("enemies_killed", 2)
	assert_eq(_pm.get_stat("enemies_killed"), 5)


func test_increment_stat_default_amount_is_one() -> void:
	_pm.increment_stat("steps")
	assert_eq(_pm.get_stat("steps"), 1)


# --- set_stat / get_stat ---

func test_set_stat_stores_value() -> void:
	_pm.set_stat("play_time", 3600)
	assert_eq(_pm.get_stat("play_time"), 3600)


func test_get_stat_default_when_not_set() -> void:
	assert_eq(_pm.get_stat("unknown_key", 0), 0)


func test_get_stat_custom_default() -> void:
	assert_eq(_pm.get_stat("unknown_key", -1), -1)


# --- reset ---

func test_reset_clears_achievements() -> void:
	_pm.unlock_achievement("ach_001")
	_pm.reset()
	assert_false(_pm.is_unlocked("ach_001"))


func test_reset_clears_statistics() -> void:
	_pm.increment_stat("kills", 10)
	_pm.reset()
	assert_eq(_pm.get_stat("kills"), 0)
