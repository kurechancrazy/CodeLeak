## GameManager — グローバルゲーム状態の管理
## ゲームの進行状態・スコア・設定などセッション横断のデータを保持する。
extends Node

enum GameState {
	BOOT,
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	# --- RPG・ジャンル拡張用ステート（RPG Autoload が使用） ---
	FIELD,
	DIALOG,
	BATTLE_START,
	BATTLE_COMMAND,
	BATTLE_EXECUTE,
	BATTLE_END,
	# --- パズルゲーム拡張ステート ---
	LEVEL_SELECT,
	ANIMATING,
	LEVEL_CLEAR,
	RESULT,
	GAME_CLEAR,
}

var state: GameState = GameState.BOOT
var score: int = 0
var high_score: int = 0
var last_result: Dictionary = {
	"score": 0,
	"miss_count": 0,
	"elapsed_time": 0.0,
	"hints_used": 0,
	"is_new_high_score": false,
}

# 設定値（SaveManagerで永続化）
var settings: Dictionary = {
	"master_volume": 1.0,
	"bgm_volume": 0.8,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"language": "en",
}


func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.game_state_change_requested.connect(_on_game_state_change_requested)


func transition_to(new_state: GameState) -> void:
	Logger.info("GameState", {"from": GameState.keys()[state], "to": GameState.keys()[new_state]})
	state = new_state


## transition_to() のエイリアス。RPG Autoload（BattleManager・DialogManager 等）との互換性を保つ。
func change_state(new_state: GameState) -> void:
	transition_to(new_state)


func add_score(points: int) -> void:
	score += points
	if score > high_score:
		high_score = score


func reset_score() -> void:
	score = 0


func update_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		Logger.warn("Unknown setting key", {"key": key})
		return
	settings[key] = value
	EventBus.settings_changed.emit(key, value)


func _on_game_started() -> void:
	reset_score()
	transition_to(GameState.PLAYING)


func _on_game_over(final_score: int) -> void:
	add_score(final_score)
	transition_to(GameState.GAME_OVER)
	EventBus.save_requested.emit()


func _on_game_paused(is_paused: bool) -> void:
	if is_paused:
		transition_to(GameState.PAUSED)
		get_tree().paused = true
	else:
		transition_to(GameState.PLAYING)
		get_tree().paused = false


func _on_settings_changed(key: String, value: Variant) -> void:
	settings[key] = value
	if key == "language":
		TranslationServer.set_locale(str(value))


func _on_game_state_change_requested(new_state: int) -> void:
	transition_to(new_state as GameState)


func _exit_tree() -> void:
	EventBus.game_started.disconnect(_on_game_started)
	EventBus.game_over.disconnect(_on_game_over)
	EventBus.game_paused.disconnect(_on_game_paused)
	EventBus.settings_changed.disconnect(_on_settings_changed)
	EventBus.game_state_change_requested.disconnect(_on_game_state_change_requested)
