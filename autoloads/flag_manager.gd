extends Node
## ゲーム進行フラグ（イベントスイッチ）を管理する Autoload。
## フラグは SaveManager 経由でセーブデータに永続化される。
## 詳細: docs/rpg/field-system.md

var _flags: Dictionary = {}   # {flag_id: bool}

func _ready() -> void:
	EventBus.load_requested.connect(_on_load)
	EventBus.save_requested.connect(_on_save)

func _exit_tree() -> void:
	EventBus.load_requested.disconnect(_on_load)
	EventBus.save_requested.disconnect(_on_save)

# ── 公開 API ──────────────────────────────────────────────

func set_flag(flag_id: String) -> void:
	_flags[flag_id] = true
	Logger.debug("Flag set", {"id": flag_id})

func clear_flag(flag_id: String) -> void:
	_flags[flag_id] = false
	Logger.debug("Flag cleared", {"id": flag_id})

func get_flag(flag_id: String) -> bool:
	return _flags.get(flag_id, false)

func resolve_dialog(_npc_id: String, default_dialog_id: String) -> String:
	# フラグに応じてNPCのダイアログIDを切り替える
	# ゲーム固有のロジックはここを拡張する
	return default_dialog_id

func reset() -> void:
	_flags.clear()

# ── セーブ・ロード ────────────────────────────────────────

func _on_save() -> void:
	SaveManager.set_value("flags", "switches", JSON.stringify(_flags))

func _on_load() -> void:
	var raw: Variant = SaveManager.get_value("flags", "switches", "{}")
	if not raw is String:
		return
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		_flags = parsed
