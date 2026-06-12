extends GutTest

var _audio_manager: Node = null
var _event_bus: Node = null
var _game_manager: Node = null

func before_each() -> void:
	_event_bus = preload("res://autoloads/event_bus.gd").new()
	add_child_autofree(_event_bus)
	_game_manager = preload("res://autoloads/game_manager.gd").new()
	add_child_autofree(_game_manager)
	_audio_manager = preload("res://autoloads/audio_manager.gd").new()
	add_child_autofree(_audio_manager)

# --- SFX プール ---

func test_sfx_pool_initialized_with_correct_size() -> void:
	assert_eq(_audio_manager._sfx_pool.size(), _audio_manager.SFX_POOL_SIZE,
		"SFXプールが正しいサイズで初期化されること")

func test_play_sfx_with_nonexistent_sound_does_not_crash() -> void:
	_audio_manager.play_sfx("this_sound_does_not_exist")
	pass  # クラッシュせずにエラーログを出すだけでOK

# --- BGM ---

func test_play_bgm_with_nonexistent_track_does_not_crash() -> void:
	_audio_manager.play_bgm("this_track_does_not_exist")
	pass

func test_stop_bgm_when_not_playing_does_not_crash() -> void:
	_audio_manager.stop_bgm()
	pass

func test_play_same_bgm_twice_is_idempotent() -> void:
	# 存在しないトラックでも2回呼んでクラッシュしないことを確認
	_audio_manager.play_bgm("nonexistent")
	_audio_manager.play_bgm("nonexistent")
	pass

# --- 音量 ---

func test_set_master_volume_zero_does_not_crash() -> void:
	_audio_manager.set_master_volume(0.0)
	pass

func test_set_master_volume_max_does_not_crash() -> void:
	_audio_manager.set_master_volume(1.0)
	pass

func test_set_bgm_volume_does_not_crash() -> void:
	_audio_manager.set_bgm_volume(0.5)
	pass

func test_set_sfx_volume_does_not_crash() -> void:
	_audio_manager.set_sfx_volume(0.5)
	pass

# --- キャッシュ ---

func test_bgm_cache_is_empty_initially() -> void:
	assert_true(_audio_manager._bgm_cache.is_empty(), "BGMキャッシュが初期状態で空であること")

func test_sfx_cache_is_empty_initially() -> void:
	assert_true(_audio_manager._sfx_cache.is_empty(), "SFXキャッシュが初期状態で空であること")
