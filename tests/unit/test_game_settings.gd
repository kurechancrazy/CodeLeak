extends GutTest

var _settings: GameSettings = null

func before_each() -> void:
	_settings = GameSettings.new()

# --- デフォルト値 ---

func test_default_master_volume_is_one() -> void:
	assert_eq(_settings.master_volume, 1.0, "master_volume のデフォルトが 1.0 であること")

func test_default_bgm_volume_is_point_eight() -> void:
	assert_eq(_settings.bgm_volume, 0.8, "bgm_volume のデフォルトが 0.8 であること")

func test_default_sfx_volume_is_one() -> void:
	assert_eq(_settings.sfx_volume, 1.0, "sfx_volume のデフォルトが 1.0 であること")

func test_default_fullscreen_is_false() -> void:
	assert_false(_settings.fullscreen, "fullscreen のデフォルトが false であること")

func test_default_language_is_ja() -> void:
	assert_eq(_settings.language, "ja", "language のデフォルトが 'ja' であること")

# --- to_dict ---

func test_to_dict_contains_all_keys() -> void:
	var d: Dictionary = _settings.to_dict()
	assert_true(d.has("master_volume"), "to_dict に master_volume があること")
	assert_true(d.has("bgm_volume"), "to_dict に bgm_volume があること")
	assert_true(d.has("sfx_volume"), "to_dict に sfx_volume があること")
	assert_true(d.has("fullscreen"), "to_dict に fullscreen があること")
	assert_true(d.has("language"), "to_dict に language があること")

func test_to_dict_reflects_modified_values() -> void:
	_settings.bgm_volume = 0.3
	_settings.language = "en"
	var d: Dictionary = _settings.to_dict()
	assert_eq(d["bgm_volume"], 0.3, "変更した bgm_volume が to_dict に反映されること")
	assert_eq(d["language"], "en", "変更した language が to_dict に反映されること")

# --- from_dict ---

func test_from_dict_restores_values() -> void:
	var data: Dictionary = {
		"master_volume": 0.5,
		"bgm_volume": 0.2,
		"sfx_volume": 0.7,
		"fullscreen": true,
		"language": "en",
	}
	var s: GameSettings = GameSettings.from_dict(data)
	assert_eq(s.master_volume, 0.5, "master_volume が復元されること")
	assert_eq(s.bgm_volume, 0.2, "bgm_volume が復元されること")
	assert_eq(s.sfx_volume, 0.7, "sfx_volume が復元されること")
	assert_true(s.fullscreen, "fullscreen が復元されること")
	assert_eq(s.language, "en", "language が復元されること")

func test_from_dict_uses_defaults_for_missing_keys() -> void:
	var s: GameSettings = GameSettings.from_dict({})
	assert_eq(s.master_volume, 1.0, "キーなしのとき master_volume がデフォルト値になること")
	assert_eq(s.bgm_volume, 0.8, "キーなしのとき bgm_volume がデフォルト値になること")
	assert_false(s.fullscreen, "キーなしのとき fullscreen がデフォルト値になること")
	assert_eq(s.language, "ja", "キーなしのとき language がデフォルト値になること")

# --- is_valid ---

func test_default_settings_are_valid() -> void:
	assert_true(_settings.is_valid(), "デフォルト設定が有効であること")

func test_settings_with_max_volumes_are_valid() -> void:
	_settings.master_volume = 1.0
	_settings.bgm_volume = 1.0
	_settings.sfx_volume = 1.0
	assert_true(_settings.is_valid(), "最大音量設定が有効であること")

func test_settings_with_zero_volumes_are_valid() -> void:
	_settings.master_volume = 0.0
	_settings.bgm_volume = 0.0
	_settings.sfx_volume = 0.0
	assert_true(_settings.is_valid(), "音量0の設定が有効であること")

# --- 境界値 ---

func test_from_dict_roundtrip_preserves_values() -> void:
	_settings.master_volume = 0.42
	_settings.language = "zh"
	_settings.fullscreen = true
	var restored: GameSettings = GameSettings.from_dict(_settings.to_dict())
	assert_eq(restored.master_volume, 0.42, "ラウンドトリップ後の master_volume が一致すること")
	assert_eq(restored.language, "zh", "ラウンドトリップ後の language が一致すること")
	assert_true(restored.fullscreen, "ラウンドトリップ後の fullscreen が一致すること")
