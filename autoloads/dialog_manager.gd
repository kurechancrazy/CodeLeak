extends Node
## NPC 会話・テキスト表示を管理する Autoload。
## 詳細設計: docs/rpg/dialog-system.md

var _current_dialog: Dictionary = {}
var _current_page: int = 0
var _dialog_layer: CanvasLayer = null

func _ready() -> void:
	EventBus.dialog_requested.connect(_on_dialog_requested)
	# ダイアログ UI シーンはゲーム開始時に add_child する
	# （SceneManager.go_to の前に初期化されるよう startup.md を参照）

func _exit_tree() -> void:
	EventBus.dialog_requested.disconnect(_on_dialog_requested)

# ── 公開 API ──────────────────────────────────────────────

func advance() -> void:
	if _current_dialog.is_empty():
		return
	var pages: Array = _current_dialog.get("pages", [])
	if _current_page >= pages.size() - 1:
		_end_dialog()
		return
	var page: Dictionary = pages[_current_page]
	if page.get("choices") != null:
		return  # 選択肢待ち中は advance しない
	_current_page += 1
	_show_page(_current_page)

func select_choice(index: int) -> void:
	var pages: Array = _current_dialog.get("pages", [])
	if _current_page >= pages.size():
		return
	var choices: Variant = pages[_current_page].get("choices")
	if not choices is Array or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	var flag: Variant = choice.get("flag")
	if flag is String and not flag.is_empty():
		FlagManager.set_flag(flag)
	var next_id: Variant = choice.get("next_id")
	if next_id is String and not next_id.is_empty():
		_on_dialog_requested(next_id)
	else:
		_end_dialog()

# ── プライベート ──────────────────────────────────────────

func _on_dialog_requested(dialog_id: String) -> void:
	var path: String = _resolve_path(dialog_id)
	if not FileAccess.file_exists(path):
		Logger.error("Dialog not found", {"id": dialog_id, "path": path})
		return
	var text: String = FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		Logger.error("Invalid dialog JSON", {"id": dialog_id})
		return
	_start_dialog(data)

func _start_dialog(dialog: Dictionary) -> void:
	_current_dialog = dialog
	_current_page = 0
	GameManager.change_state(GameManager.GameState.DIALOG)
	_show_page(0)

func _end_dialog() -> void:
	var ended_id: String = _current_dialog.get("id", "")
	_current_dialog = {}
	_current_page = 0
	GameManager.change_state(GameManager.GameState.FIELD)
	EventBus.dialog_ended.emit(ended_id)

func _show_page(page_index: int) -> void:
	var pages: Array = _current_dialog.get("pages", [])
	if page_index >= pages.size():
		return
	var page: Dictionary = pages[page_index]
	EventBus.dialog_page_shown.emit(
		_current_dialog.get("speaker", ""),
		_current_dialog.get("portrait", ""),
		page.get("text", ""),
		page.get("choices")
	)

func _resolve_path(dialog_id: String) -> String:
	var parts: PackedStringArray = dialog_id.rsplit("_", false, 1)
	if parts.size() < 2:
		return "res://resources/dialogs/%s.json" % dialog_id
	return "res://resources/dialogs/%s/%s.json" % [parts[0], dialog_id]
