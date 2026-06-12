extends GutTest

var _dm: Node = null


func before_each() -> void:
	_dm = load("res://autoloads/dialog_manager.gd").new()
	# _ready() を呼ばず EventBus / GameManager 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_dm.free()


# --- advance (ダイアログなし) ---

func test_advance_does_nothing_when_no_dialog() -> void:
	_dm.advance()  # クラッシュしないこと
	assert_eq(_dm._current_page, 0)


# --- select_choice (ダイアログなし) ---

func test_select_choice_does_nothing_when_no_dialog() -> void:
	_dm.select_choice(99)  # クラッシュしないこと
	assert_eq(_dm._current_page, 0)



# --- _resolve_path ---

func test_resolve_path_single_word_id() -> void:
	var path: String = _dm._resolve_path("greeting")
	assert_eq(path, "res://resources/dialogs/greeting.json")


func test_resolve_path_with_underscore_suffix() -> void:
	var path: String = _dm._resolve_path("event_001")
	assert_eq(path, "res://resources/dialogs/event/event_001.json")


func test_resolve_path_multiple_underscores_uses_last_split() -> void:
	var path: String = _dm._resolve_path("area_event_001")
	assert_eq(path, "res://resources/dialogs/area_event/area_event_001.json")
