extends Node

func _ready() -> void:
	SaveManager.load_game()
	_apply_settings()
	await get_tree().process_frame
	SceneManager.go_to("res://scenes/ui/main_menu.tscn", SceneManager.TRANSITION_NONE)

func _apply_settings() -> void:
	AudioManager.set_master_volume(GameManager.settings.get("master_volume", 1.0))
	AudioManager.set_bgm_volume(GameManager.settings.get("bgm_volume", 0.8))
	AudioManager.set_sfx_volume(GameManager.settings.get("sfx_volume", 1.0))
	var locale: String = GameManager.settings.get("language", "ja")
	TranslationServer.set_locale(locale)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Logger.info("app_closing")
		SaveManager.save_game()
		get_tree().quit()
