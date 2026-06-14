extends GutTest

const TEST_SAVE_PATH: String = "user://test_save_data.cfg"
const TEST_SETTINGS_PATH: String = "user://test_settings.cfg"

var _save_manager: Node = null
var _game_manager: Node = null
var _event_bus: Node = null


func before_each() -> void:
	_event_bus = preload("res://autoloads/event_bus.gd").new()
	add_child_autofree(_event_bus)
	_game_manager = preload("res://autoloads/game_manager.gd").new()
	add_child_autofree(_game_manager)
	_save_manager = preload("res://autoloads/save_manager.gd").new()
	_save_manager.SAVE_PATH = TEST_SAVE_PATH
	_save_manager.SETTINGS_PATH = TEST_SETTINGS_PATH
	add_child_autofree(_save_manager)
	GameManager.high_score = 0


func after_each() -> void:
	GameManager.high_score = 0
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_SETTINGS_PATH)


# --- セーブ・ロード ---


func test_has_save_returns_false_when_no_file() -> void:
	assert_false(_save_manager.has_save(), "セーブファイルがない場合は false を返すこと")


func test_save_game_creates_file() -> void:
	GameManager.high_score = 500
	_save_manager.save_game()
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH), "save_game() でファイルが作成されること")


func test_has_save_returns_true_after_save() -> void:
	_save_manager.save_game()
	assert_true(_save_manager.has_save(), "保存後は has_save() が true を返すこと")


func test_load_game_restores_high_score() -> void:
	GameManager.high_score = 1200
	_save_manager.save_game()

	GameManager.high_score = 0
	_save_manager.load_game()
	assert_eq(GameManager.high_score, 1200, "ロード後に高スコアが復元されること")


func test_delete_save_removes_file() -> void:
	_save_manager.save_game()
	_save_manager.delete_save()
	assert_false(FileAccess.file_exists(TEST_SAVE_PATH), "delete_save() でファイルが削除されること")
	assert_false(_save_manager.has_save())


# --- 汎用データアクセス ---


func test_set_and_get_value() -> void:
	_save_manager.set_value("player", "level", 5)
	var result: Variant = _save_manager.get_value("player", "level", 0)
	assert_eq(result, 5, "set した値が get で取得できること")


func test_get_value_returns_default_when_not_set() -> void:
	var result: Variant = _save_manager.get_value("player", "coins", 99)
	assert_eq(result, 99, "未設定のキーはデフォルト値を返すこと")


# --- 境界値 ---


func test_load_game_with_no_file_does_not_crash() -> void:
	_save_manager.load_game()
	assert_eq(GameManager.high_score, 0, "ファイルなしのロードでデフォルト値のまま")


func test_save_and_load_zero_score() -> void:
	GameManager.high_score = 0
	_save_manager.save_game()
	GameManager.high_score = 999
	_save_manager.load_game()
	assert_eq(GameManager.high_score, 0, "スコア0が正しく保存・復元されること")


# --- パズル進捗保存 ---


func test_puzzle_completed_saves_score_for_level() -> void:
	var puzzle: PuzzleData = PuzzleData.new()
	puzzle.level_id = "test_level_score"
	PuzzleManager.current_puzzle = puzzle
	_save_manager._on_puzzle_completed(750, 1, 30.0)
	var scores_json: String = _save_manager.get_value("progress", "scores", "{}")
	var scores: Variant = JSON.parse_string(scores_json)
	assert_true(scores is Dictionary, "scores は Dictionary であること")
	assert_eq(int(scores.get("test_level_score", 0)), 750, "スコアが保存されること")
	PuzzleManager.current_puzzle = null


func test_puzzle_completed_higher_score_overwrites() -> void:
	var puzzle: PuzzleData = PuzzleData.new()
	puzzle.level_id = "test_level_overwrite"
	PuzzleManager.current_puzzle = puzzle
	_save_manager._on_puzzle_completed(500, 2, 60.0)
	_save_manager._on_puzzle_completed(800, 0, 20.0)
	var scores_json: String = _save_manager.get_value("progress", "scores", "{}")
	var scores: Variant = JSON.parse_string(scores_json)
	assert_eq(int(scores.get("test_level_overwrite", 0)), 800, "高いスコアで上書きされること")
	PuzzleManager.current_puzzle = null


func test_puzzle_completed_lower_score_not_saved() -> void:
	var puzzle: PuzzleData = PuzzleData.new()
	puzzle.level_id = "test_level_lower"
	PuzzleManager.current_puzzle = puzzle
	_save_manager._on_puzzle_completed(900, 0, 10.0)
	_save_manager._on_puzzle_completed(400, 5, 120.0)
	var scores_json: String = _save_manager.get_value("progress", "scores", "{}")
	var scores: Variant = JSON.parse_string(scores_json)
	assert_eq(int(scores.get("test_level_lower", 0)), 900, "低いスコアで上書きされないこと")
	PuzzleManager.current_puzzle = null


func test_puzzle_completed_marks_level_cleared() -> void:
	var puzzle: PuzzleData = PuzzleData.new()
	puzzle.level_id = "test_level_cleared"
	PuzzleManager.current_puzzle = puzzle
	_save_manager._on_puzzle_completed(600, 1, 45.0)
	var cleared_json: String = _save_manager.get_value("progress", "levels_cleared", "[]")
	var cleared: Variant = JSON.parse_string(cleared_json)
	assert_true(cleared is Array, "levels_cleared は Array であること")
	assert_true("test_level_cleared" in cleared, "レベルがクリア済みとしてマークされること")
	PuzzleManager.current_puzzle = null


func test_puzzle_completed_no_puzzle_does_not_crash() -> void:
	PuzzleManager.current_puzzle = null
	_save_manager._on_puzzle_completed(500, 0, 10.0)
	assert_true(true, "current_puzzle が null でもクラッシュしないこと")
