extends GutTest

var _game_manager: Node = null
var _event_bus: Node = null

func before_each() -> void:
	_event_bus = preload("res://autoloads/event_bus.gd").new()
	add_child_autofree(_event_bus)
	_game_manager = preload("res://autoloads/game_manager.gd").new()
	add_child_autofree(_game_manager)

# --- スコア計算 ---

func test_add_score_increases_score() -> void:
	_game_manager.score = 0
	_game_manager.add_score(100)
	assert_eq(_game_manager.score, 100, "スコアが加算されること")

func test_add_score_updates_high_score() -> void:
	_game_manager.score = 0
	_game_manager.high_score = 0
	_game_manager.add_score(500)
	assert_eq(_game_manager.high_score, 500, "高スコアが更新されること")

func test_high_score_not_overwritten_by_lower_score() -> void:
	_game_manager.high_score = 1000
	_game_manager.score = 0
	_game_manager.add_score(200)
	assert_eq(_game_manager.high_score, 1000, "低いスコアでハイスコアが上書きされないこと")

func test_reset_score_sets_to_zero() -> void:
	_game_manager.score = 300
	_game_manager.reset_score()
	assert_eq(_game_manager.score, 0, "スコアリセットで0になること")

# --- 状態遷移 ---

func test_transition_to_changes_state() -> void:
	_game_manager.state = _game_manager.GameState.BOOT
	_game_manager.transition_to(_game_manager.GameState.MAIN_MENU)
	assert_eq(_game_manager.state, _game_manager.GameState.MAIN_MENU, "状態が遷移すること")

func test_transition_to_same_state_is_idempotent() -> void:
	_game_manager.state = _game_manager.GameState.PLAYING
	_game_manager.transition_to(_game_manager.GameState.PLAYING)
	assert_eq(_game_manager.state, _game_manager.GameState.PLAYING, "同じ状態への遷移が安全なこと")

# --- 設定更新 ---

func test_update_setting_changes_value() -> void:
	_game_manager.settings["bgm_volume"] = 0.8
	_game_manager.update_setting("bgm_volume", 0.5)
	assert_eq(_game_manager.settings["bgm_volume"], 0.5, "設定値が更新されること")

func test_update_setting_with_unknown_key_does_not_crash() -> void:
	_game_manager.update_setting("non_existent_key", 42)
	pass  # クラッシュしなければOK

# --- 境界値 ---

func test_add_score_with_zero() -> void:
	_game_manager.score = 100
	_game_manager.add_score(0)
	assert_eq(_game_manager.score, 100, "0加算でスコアが変わらないこと")

func test_add_score_with_negative() -> void:
	_game_manager.score = 100
	_game_manager.add_score(-50)
	assert_eq(_game_manager.score, 50, "負のスコア加算が機能すること")

# --- change_state エイリアス ---

func test_change_state_is_alias_for_transition_to() -> void:
	_game_manager.state = _game_manager.GameState.BOOT
	_game_manager.change_state(_game_manager.GameState.MAIN_MENU)
	assert_eq(_game_manager.state, _game_manager.GameState.MAIN_MENU, "change_state が状態を遷移させること")

func test_change_state_rpg_states_accessible() -> void:
	_game_manager.change_state(_game_manager.GameState.FIELD)
	assert_eq(_game_manager.state, _game_manager.GameState.FIELD, "RPG 拡張ステートに遷移できること")
