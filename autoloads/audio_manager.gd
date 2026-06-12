## AudioManager — BGM・SE の一元管理
## AudioStreamPlayerをプールして再利用する。
extends Node

const BGM_BUS: String = "BGM"
const SFX_BUS: String = "SFX"
const SFX_POOL_SIZE: int = 8

var _bgm_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _bgm_cache: Dictionary = {}
var _current_bgm: String = ""

func _ready() -> void:
	_setup_bus_layout()
	_setup_bgm_player()
	_setup_sfx_pool()
	EventBus.bgm_change_requested.connect(play_bgm)
	EventBus.sfx_play_requested.connect(play_sfx)
	EventBus.settings_changed.connect(_on_settings_changed)

func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	if _current_bgm == track_name:
		return
	var stream: AudioStream = _load_bgm(track_name)
	if stream == null:
		Logger.error("BGM not found", {"track": track_name})
		return
	_current_bgm = track_name
	if fade_duration > 0.0 and _bgm_player.playing:
		var tween: Tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		await tween.finished
	_bgm_player.stream = stream
	_bgm_player.volume_db = _volume_to_db(GameManager.settings.get("bgm_volume", 0.8))
	_bgm_player.play()

func stop_bgm(fade_duration: float = 1.0) -> void:
	if not _bgm_player.playing:
		return
	if fade_duration > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		await tween.finished
	_bgm_player.stop()
	_current_bgm = ""

func play_sfx(sound_name: String) -> void:
	var stream: AudioStream = _load_sfx(sound_name)
	if stream == null:
		Logger.error("SFX not found", {"sound": sound_name})
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	if player == null:
		Logger.warn("SFX pool exhausted", {"sound": sound_name})
		return
	player.stream = stream
	player.volume_db = _volume_to_db(GameManager.settings.get("sfx_volume", 1.0))
	player.play()

func set_master_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _volume_to_db(value))

func set_bgm_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BGM_BUS), _volume_to_db(value))

func set_sfx_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), _volume_to_db(value))

func _setup_bus_layout() -> void:
	# BGM と SFX バスが存在しない場合のみ追加
	if AudioServer.get_bus_index(BGM_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, BGM_BUS)
		AudioServer.set_bus_send(AudioServer.get_bus_index(BGM_BUS), "Master")
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, SFX_BUS)
		AudioServer.set_bus_send(AudioServer.get_bus_index(SFX_BUS), "Master")

func _setup_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BGM_BUS
	add_child(_bgm_player)

func _setup_sfx_pool() -> void:
	for i: int in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_pool.append(player)

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player
	return null

func _load_bgm(track_name: String) -> AudioStream:
	if _bgm_cache.has(track_name):
		return _bgm_cache[track_name]
	var path: String = "res://assets/audio/bgm/%s.ogg" % track_name
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/bgm/%s.mp3" % track_name
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	_bgm_cache[track_name] = stream
	return stream

func _load_sfx(sound_name: String) -> AudioStream:
	if _sfx_cache.has(sound_name):
		return _sfx_cache[sound_name]
	var path: String = "res://assets/audio/sfx/%s.wav" % sound_name
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/sfx/%s.ogg" % sound_name
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	_sfx_cache[sound_name] = stream
	return stream

func _volume_to_db(linear: float) -> float:
	return linear_to_db(clampf(linear, 0.0001, 1.0))

func _on_settings_changed(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			set_master_volume(value)
		"bgm_volume":
			set_bgm_volume(value)
		"sfx_volume":
			set_sfx_volume(value)

func _exit_tree() -> void:
	EventBus.bgm_change_requested.disconnect(play_bgm)
	EventBus.sfx_play_requested.disconnect(play_sfx)
	EventBus.settings_changed.disconnect(_on_settings_changed)
