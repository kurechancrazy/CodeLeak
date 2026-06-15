## GameManager — グローバルゲーム状態の管理
## ゲームの進行状態・設定などセッション横断のデータを保持する。
extends Node

enum GameState {
	BOOT,
	MAIN_MENU,
	CASE_SELECT,
	BRIEFING,
	INVESTIGATING,
	VERDICT,
	OUTCOME,
	PAUSED,
}

const IS_DEMO: bool = true
const STORE_URL: String = "https://store.steampowered.com/app/PLACEHOLDER"
const WISHLIST_URL: String = "https://store.steampowered.com/app/PLACEHOLDER"

var state: GameState = GameState.BOOT
var high_score: int = 0

var settings: Dictionary = {
	"master_volume": 1.0,
	"bgm_volume": 0.8,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"language": "en",
}

var _state_before_pause: GameState = GameState.INVESTIGATING


func _ready() -> void:
	TranslationServer.set_locale(str(settings.get("language", "en")))
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.game_state_change_requested.connect(_on_game_state_change_requested)


func transition_to(new_state: GameState) -> void:
	Logger.info("GameState", {"from": GameState.keys()[state], "to": GameState.keys()[new_state]})
	state = new_state


func change_state(new_state: GameState) -> void:
	transition_to(new_state)


func update_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		Logger.warn("Unknown setting key", {"key": key})
		return
	settings[key] = value
	EventBus.settings_changed.emit(key, value)


func _on_game_paused(is_paused: bool) -> void:
	if is_paused:
		_state_before_pause = state
		transition_to(GameState.PAUSED)
		get_tree().paused = true
	else:
		transition_to(_state_before_pause)
		get_tree().paused = false


func _on_settings_changed(key: String, value: Variant) -> void:
	settings[key] = value
	if key == "language":
		TranslationServer.set_locale(str(value))


func _on_game_state_change_requested(new_state: int) -> void:
	transition_to(new_state as GameState)


func _exit_tree() -> void:
	EventBus.game_paused.disconnect(_on_game_paused)
	EventBus.settings_changed.disconnect(_on_settings_changed)
	EventBus.game_state_change_requested.disconnect(_on_game_state_change_requested)
