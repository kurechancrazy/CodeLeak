extends Node
## 実績・解放・統計を管理する Autoload — 全ジャンル共通。
## 詳細: docs/genres/_index.md

var _achievements: Dictionary = {}  # {achievement_id: bool}
var _statistics: Dictionary = {}  # {key: Variant}


func _ready() -> void:
	EventBus.load_requested.connect(_on_load)
	EventBus.save_requested.connect(_on_save)


func _exit_tree() -> void:
	EventBus.load_requested.disconnect(_on_load)
	EventBus.save_requested.disconnect(_on_save)


# ── 公開 API ──────────────────────────────────────────────


## 実績を解放する。すでに解放済みなら false を返す。
func unlock_achievement(achievement_id: String) -> bool:
	if _achievements.get(achievement_id, false):
		return false
	_achievements[achievement_id] = true
	EventBus.achievement_unlocked.emit(achievement_id)
	Logger.info("Achievement unlocked", {"id": achievement_id})
	return true


func is_unlocked(achievement_id: String) -> bool:
	return _achievements.get(achievement_id, false)


func increment_stat(key: String, amount: int = 1) -> void:
	_statistics[key] = _statistics.get(key, 0) + amount
	EventBus.progress_updated.emit(key)


func set_stat(key: String, value: Variant) -> void:
	_statistics[key] = value
	EventBus.progress_updated.emit(key)


func get_stat(key: String, default: Variant = 0) -> Variant:
	return _statistics.get(key, default)


func reset() -> void:
	_achievements.clear()
	_statistics.clear()


# ── セーブ・ロード ────────────────────────────────────────


func _on_save() -> void:
	SaveManager.set_value("progress", "achievements", JSON.stringify(_achievements))
	SaveManager.set_value("progress", "statistics", JSON.stringify(_statistics))


func _on_load() -> void:
	var ach_raw: Variant = SaveManager.get_value("progress", "achievements", "{}")
	if ach_raw is String:
		var parsed: Variant = JSON.parse_string(ach_raw)
		if parsed is Dictionary:
			_achievements = parsed
	var stat_raw: Variant = SaveManager.get_value("progress", "statistics", "{}")
	if stat_raw is String:
		var parsed: Variant = JSON.parse_string(stat_raw)
		if parsed is Dictionary:
			_statistics = parsed
