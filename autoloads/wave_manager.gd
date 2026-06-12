extends Node
## ウェーブ進行管理 Autoload — シューティング・タワーディフェンス向け。
## 詳細: docs/genres/shmup.md, docs/genres/tower-defense.md

var current_wave: int = 0

var _spawn_remaining: int = 0
var _kill_remaining: int = 0
var _is_active: bool = false

# ── 公開 API ──────────────────────────────────────────────


func start_wave(wave: WaveData) -> void:
	if _is_active:
		Logger.warn("WaveManager: wave already active")
		return
	current_wave = wave.wave_number
	_spawn_remaining = wave.spawn_count
	_kill_remaining = wave.spawn_count
	_is_active = true
	EventBus.wave_started.emit(current_wave)
	Logger.info("Wave started", {"wave": current_wave})


## 敵を 1 体スポーンしたときに呼ぶ。
func on_enemy_spawned() -> void:
	_spawn_remaining = maxi(0, _spawn_remaining - 1)


## 敵を 1 体倒したときに呼ぶ。ウェーブクリア判定を行う。
func on_enemy_killed() -> void:
	_kill_remaining = maxi(0, _kill_remaining - 1)
	_check_wave_complete()


func is_spawn_complete() -> bool:
	return _spawn_remaining <= 0


func reset() -> void:
	current_wave = 0
	_spawn_remaining = 0
	_kill_remaining = 0
	_is_active = false


# ── プライベート ──────────────────────────────────────────


func _check_wave_complete() -> void:
	if not _is_active:
		return
	if _kill_remaining > 0:
		return
	_is_active = false
	EventBus.wave_completed.emit(current_wave)
	Logger.info("Wave completed", {"wave": current_wave})
