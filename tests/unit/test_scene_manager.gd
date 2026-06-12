extends GutTest

var _scene_manager: Node = null
var _event_bus: Node = null

func before_each() -> void:
	_event_bus = preload("res://autoloads/event_bus.gd").new()
	add_child_autofree(_event_bus)
	_scene_manager = preload("res://autoloads/scene_manager.gd").new()
	add_child_autofree(_scene_manager)

# --- 初期状態 ---

func test_initial_state_is_not_transitioning() -> void:
	assert_false(_scene_manager._is_transitioning, "初期状態でトランジション中でないこと")

func test_initial_history_is_empty() -> void:
	assert_true(_scene_manager._history.is_empty(), "初期状態で遷移履歴が空であること")

# --- go_to のバリデーション ---

func test_go_to_nonexistent_scene_does_not_crash() -> void:
	_scene_manager.go_to("res://scenes/nonexistent_scene.tscn")
	pass  # ResourceLoader.exists() チェックでエラーログを出すだけでOK

func test_go_to_while_transitioning_is_ignored() -> void:
	_scene_manager._is_transitioning = true
	_scene_manager.go_to("res://scenes/nonexistent.tscn")
	# トランジション中は無視される（クラッシュしない）
	assert_true(_scene_manager._is_transitioning)

# --- go_back ---

func test_go_back_with_empty_history_does_not_crash() -> void:
	_scene_manager.go_back()
	pass

func test_history_remains_empty_after_go_back_on_empty() -> void:
	_scene_manager.go_back()
	assert_true(_scene_manager._history.is_empty())

# --- go_to_root ---

func test_go_to_root_clears_history() -> void:
	_scene_manager._history = ["res://a.tscn", "res://b.tscn"]
	_scene_manager.go_to_root("res://scenes/nonexistent.tscn")
	assert_true(_scene_manager._history.is_empty(), "go_to_root で履歴がクリアされること")

# --- 定数 ---

func test_transition_constants_are_defined() -> void:
	assert_eq(_scene_manager.TRANSITION_FADE, "fade")
	assert_eq(_scene_manager.TRANSITION_NONE, "none")
