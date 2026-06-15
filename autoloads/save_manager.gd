## SaveManager — セーブデータの永続化
## ConfigFileをベースにしたシリアライズ層。機密データは別途暗号化を行うこと。
extends Node

var SAVE_PATH: String = "user://save_data.cfg"
var SETTINGS_PATH: String = "user://settings.cfg"

var _save_config: ConfigFile = ConfigFile.new()
var _settings_config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	EventBus.save_requested.connect(save_game)
	EventBus.load_requested.connect(load_game)
	EventBus.case_resolved.connect(_on_case_resolved)
	_load_settings()


# --- ゲームデータ ---


func save_game() -> void:
	_save_config.set_value("player", "high_score", GameManager.high_score)
	_save_config.set_value("meta", "saved_at", Time.get_datetime_string_from_system())
	var err: Error = _save_config.save(SAVE_PATH)
	var success: bool = err == OK
	if not success:
		Logger.error("Save failed", {"error": err})
	EventBus.save_completed.emit(success)


func load_game() -> void:
	var err: Error = _save_config.load(SAVE_PATH)
	if err != OK:
		Logger.info("No save file found, using defaults")
		return
	GameManager.high_score = _save_config.get_value("player", "high_score", 0)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		_save_config = ConfigFile.new()
		Logger.info("Save data deleted")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# --- 設定データ ---


func save_settings() -> void:
	for key: String in GameManager.settings:
		_settings_config.set_value("settings", key, GameManager.settings[key])
	var err: Error = _settings_config.save(SETTINGS_PATH)
	if err != OK:
		Logger.error("Settings save failed", {"error": err})


func _load_settings() -> void:
	var err: Error = _settings_config.load(SETTINGS_PATH)
	if err != OK:
		return
	for key: String in GameManager.settings:
		if _settings_config.has_section_key("settings", key):
			GameManager.settings[key] = _settings_config.get_value("settings", key)
	TranslationServer.set_locale(str(GameManager.settings["language"]))


# --- 汎用データアクセス ---


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return _save_config.get_value(section, key, default)


func set_value(section: String, key: String, value: Variant) -> void:
	_save_config.set_value(section, key, value)


func _on_case_resolved(case_id: String, outcome_key: String, _read_count: int) -> void:
	# cases_resolved: JSON array with duplicate prevention
	var resolved_raw: String = _save_config.get_value("progress", "cases_resolved", "[]")
	var resolved: Variant = JSON.parse_string(resolved_raw)
	if not resolved is Array:
		resolved = []
	if case_id not in (resolved as Array):
		(resolved as Array).append(case_id)
	_save_config.set_value("progress", "cases_resolved", JSON.stringify(resolved))

	# case_verdicts: JSON dict mapping case_id → array of outcome_keys
	var verdicts_raw: String = _save_config.get_value("progress", "case_verdicts", "{}")
	var verdicts: Variant = JSON.parse_string(verdicts_raw)
	if not verdicts is Dictionary:
		verdicts = {}
	var arr: Variant = (verdicts as Dictionary).get(case_id, [])
	if not arr is Array:
		arr = []
	if outcome_key not in (arr as Array):
		(arr as Array).append(outcome_key)
	(verdicts as Dictionary)[case_id] = arr
	_save_config.set_value("progress", "case_verdicts", JSON.stringify(verdicts))

	save_game()


func _exit_tree() -> void:
	EventBus.save_requested.disconnect(save_game)
	EventBus.load_requested.disconnect(load_game)
	EventBus.case_resolved.disconnect(_on_case_resolved)
