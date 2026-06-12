extends GutTest

var _em: Node = null


func before_each() -> void:
	_em = load("res://autoloads/encounter_manager.gd").new()
	# _ready() を呼ばず EventBus / GameManager / BattleManager 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_em.free()


# --- 初期状態 ---

func test_initial_table_id_is_empty() -> void:
	assert_eq(_em._current_table_id, "")


func test_initial_step_counter_is_zero() -> void:
	assert_eq(_em._step_counter, 0)


# --- set_encounter_table ---

func test_set_encounter_table_stores_table_id() -> void:
	_em.set_encounter_table("town")
	assert_eq(_em._current_table_id, "town")


func test_set_encounter_table_resets_step_counter() -> void:
	_em._step_counter = 99
	_em.set_encounter_table("dungeon")
	assert_eq(_em._step_counter, 0)


func test_set_encounter_table_sets_threshold_in_range() -> void:
	_em.set_encounter_table("forest")
	assert_gte(_em._encounter_threshold, _em.MIN_STEPS)
	assert_lte(_em._encounter_threshold, _em.MAX_STEPS)


# --- disable_encounters ---

func test_disable_encounters_clears_table_id() -> void:
	_em._current_table_id = "town"
	_em.disable_encounters()
	assert_eq(_em._current_table_id, "")


# --- 境界値 ---

func test_set_encounter_table_empty_string_disables() -> void:
	_em.set_encounter_table("town")
	_em.set_encounter_table("")
	assert_eq(_em._current_table_id, "")
