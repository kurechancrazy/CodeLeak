extends GutTest

var _wm: Node = null


func before_each() -> void:
	_wm = load("res://autoloads/wave_manager.gd").new()


func after_each() -> void:
	_wm.free()


# --- 初期状態 ---

func test_initial_current_wave_is_zero() -> void:
	assert_eq(_wm.current_wave, 0)


func test_initial_spawn_complete() -> void:
	assert_true(_wm.is_spawn_complete(), "初期状態ではスポーン完了扱い")


# --- start_wave ---

func test_start_wave_sets_current_wave() -> void:
	var wave: WaveData = WaveData.new()
	wave.wave_number = 3
	wave.spawn_count = 5
	_wm.start_wave(wave)
	assert_eq(_wm.current_wave, 3)


func test_start_wave_not_spawn_complete() -> void:
	var wave: WaveData = WaveData.new()
	wave.wave_number = 1
	wave.spawn_count = 2
	_wm.start_wave(wave)
	assert_false(_wm.is_spawn_complete(), "スポーン開始直後は未完了")


func test_start_wave_guard_when_already_active() -> void:
	var wave: WaveData = WaveData.new()
	wave.wave_number = 1
	wave.spawn_count = 5
	_wm.start_wave(wave)
	var wave2: WaveData = WaveData.new()
	wave2.wave_number = 99
	wave2.spawn_count = 1
	_wm.start_wave(wave2)
	assert_eq(_wm.current_wave, 1, "アクティブ中は 2 回目の start_wave を無視すること")


# --- on_enemy_spawned ---

func test_on_enemy_spawned_completes_spawn() -> void:
	var wave: WaveData = WaveData.new()
	wave.wave_number = 1
	wave.spawn_count = 2
	_wm.start_wave(wave)
	_wm.on_enemy_spawned()
	_wm.on_enemy_spawned()
	assert_true(_wm.is_spawn_complete(), "全スポーン後は完了")


func test_on_enemy_spawned_does_not_underflow() -> void:
	_wm.on_enemy_spawned()
	assert_true(_wm.is_spawn_complete())


# --- on_enemy_killed / ウェーブクリア ---

func test_all_enemies_killed_allows_new_wave() -> void:
	var wave: WaveData = WaveData.new()
	wave.wave_number = 1
	wave.spawn_count = 2
	_wm.start_wave(wave)
	_wm.on_enemy_killed()
	_wm.on_enemy_killed()  # kill_remaining = 0 → wave complete
	var wave2: WaveData = WaveData.new()
	wave2.wave_number = 2
	wave2.spawn_count = 1
	_wm.start_wave(wave2)
	assert_eq(_wm.current_wave, 2, "ウェーブクリア後は次のウェーブを開始できること")


func test_on_enemy_killed_does_not_underflow() -> void:
	_wm.on_enemy_killed()
	assert_eq(_wm.current_wave, 0)


# --- reset ---

func test_reset_clears_state() -> void:
	var wave: WaveData = WaveData.new()
	wave.wave_number = 2
	wave.spawn_count = 4
	_wm.start_wave(wave)
	_wm.reset()
	assert_eq(_wm.current_wave, 0, "reset 後 current_wave が 0")
	assert_true(_wm.is_spawn_complete(), "reset 後はスポーン完了扱い")
