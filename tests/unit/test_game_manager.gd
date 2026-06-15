extends GutTest

var _game_manager: Node = null
var _event_bus: Node = null


func before_each() -> void:
	_event_bus = preload("res://autoloads/event_bus.gd").new()
	add_child_autofree(_event_bus)
	_game_manager = preload("res://autoloads/game_manager.gd").new()
	add_child_autofree(_game_manager)


# --- 状態遷移 ---


func test_transition_to_changes_state() -> void:
	_game_manager.state = _game_manager.GameState.BOOT
	_game_manager.transition_to(_game_manager.GameState.MAIN_MENU)
	assert_eq(_game_manager.state, _game_manager.GameState.MAIN_MENU, "状態が遷移すること")


func test_transition_to_same_state_is_idempotent() -> void:
	_game_manager.state = _game_manager.GameState.MAIN_MENU
	_game_manager.transition_to(_game_manager.GameState.MAIN_MENU)
	assert_eq(_game_manager.state, _game_manager.GameState.MAIN_MENU, "同じ状態への遷移が安全なこと")


func test_change_state_is_alias_for_transition_to() -> void:
	_game_manager.state = _game_manager.GameState.BOOT
	_game_manager.change_state(_game_manager.GameState.MAIN_MENU)
	assert_eq(_game_manager.state, _game_manager.GameState.MAIN_MENU, "change_state が状態を遷移させること")


# --- GameState enum の存在確認 ---


func test_boot_state_exists() -> void:
	assert_true(
		_game_manager.GameState.BOOT in _game_manager.GameState.values(),
		"BOOT ステートが GameState enum に存在すること"
	)


func test_main_menu_state_exists() -> void:
	assert_true(
		_game_manager.GameState.MAIN_MENU in _game_manager.GameState.values(),
		"MAIN_MENU ステートが GameState enum に存在すること"
	)


func test_case_select_state_exists() -> void:
	assert_true(
		_game_manager.GameState.CASE_SELECT in _game_manager.GameState.values(),
		"CASE_SELECT ステートが GameState enum に存在すること"
	)


func test_investigating_state_exists() -> void:
	assert_true(
		_game_manager.GameState.INVESTIGATING in _game_manager.GameState.values(),
		"INVESTIGATING ステートが GameState enum に存在すること"
	)


func test_verdict_state_exists() -> void:
	assert_true(
		_game_manager.GameState.VERDICT in _game_manager.GameState.values(),
		"VERDICT ステートが GameState enum に存在すること"
	)


func test_paused_state_exists() -> void:
	assert_true(
		_game_manager.GameState.PAUSED in _game_manager.GameState.values(),
		"PAUSED ステートが GameState enum に存在すること"
	)


func test_transition_to_investigating() -> void:
	_game_manager.state = _game_manager.GameState.BRIEFING
	_game_manager.transition_to(_game_manager.GameState.INVESTIGATING)
	assert_eq(_game_manager.state, _game_manager.GameState.INVESTIGATING, "INVESTIGATING に遷移できること")


func test_transition_to_verdict() -> void:
	_game_manager.state = _game_manager.GameState.INVESTIGATING
	_game_manager.transition_to(_game_manager.GameState.VERDICT)
	assert_eq(_game_manager.state, _game_manager.GameState.VERDICT, "VERDICT に遷移できること")


# --- 設定更新 ---


func test_update_setting_changes_value() -> void:
	_game_manager.settings["bgm_volume"] = 0.8
	_game_manager.update_setting("bgm_volume", 0.5)
	assert_eq(_game_manager.settings["bgm_volume"], 0.5, "設定値が更新されること")


func test_update_setting_with_unknown_key_does_not_crash() -> void:
	_game_manager.update_setting("non_existent_key", 42)
	assert_eq(_game_manager.settings.has("non_existent_key"), false, "未知のキーは追加されない")


# --- 定数 ---


func test_is_demo_constant_exists() -> void:
	assert_true(_game_manager.IS_DEMO is bool, "IS_DEMO 定数が bool 型で存在すること")


func test_store_url_constant_exists() -> void:
	assert_true(_game_manager.STORE_URL is String, "STORE_URL 定数が String 型で存在すること")
