## SceneManager — シーン遷移の管理
## change_scene_to_file() の薄いラッパー。遷移履歴・トランジションを提供する。
extends Node

signal transition_started(from_path: String, to_path: String)
signal transition_finished(scene_path: String)

var _current_scene_path: String = ""
var _history: Array[String] = []
var _is_transitioning: bool = false

const TRANSITION_FADE: String = "fade"
const TRANSITION_NONE: String = "none"

func _ready() -> void:
	EventBus.scene_change_requested.connect(_on_scene_change_requested)

## シーンを変更する。transition は "fade" または "none"。
func go_to(scene_path: String, transition: String = TRANSITION_FADE) -> void:
	if _is_transitioning:
		Logger.warn("Scene transition already in progress", {"target": scene_path})
		return
	if not ResourceLoader.exists(scene_path):
		Logger.error("Scene not found", {"path": scene_path})
		return
	_is_transitioning = true
	if _current_scene_path != "":
		_history.append(_current_scene_path)
	transition_started.emit(_current_scene_path, scene_path)
	Logger.info("SceneManager.go_to", {"to": scene_path, "transition": transition})
	match transition:
		TRANSITION_FADE:
			await _fade_transition(scene_path)
		_:
			get_tree().change_scene_to_file(scene_path)
			_finish_transition(scene_path)

## 前のシーンに戻る。履歴がない場合は何もしない。
func go_back() -> void:
	if _history.is_empty():
		Logger.warn("No scene history to go back to")
		return
	var previous: String = _history.pop_back()
	go_to(previous, TRANSITION_FADE)

## 履歴を消してシーンを変更する（メインメニューへの復帰など）。
func go_to_root(scene_path: String) -> void:
	_history.clear()
	go_to(scene_path, TRANSITION_FADE)

func _fade_transition(scene_path: String) -> void:
	# トランジションシーンが存在する場合はそれを使う
	# ない場合はシンプルに切り替え
	get_tree().change_scene_to_file(scene_path)
	_finish_transition(scene_path)

func _finish_transition(scene_path: String) -> void:
	_current_scene_path = scene_path
	_is_transitioning = false
	transition_finished.emit(scene_path)
	EventBus.scene_loaded.emit(scene_path)

func _on_scene_change_requested(scene_path: String, transition: String) -> void:
	go_to(scene_path, transition)

func _exit_tree() -> void:
	EventBus.scene_change_requested.disconnect(_on_scene_change_requested)
