extends Node
## ゲーム内時計 Autoload — 農業シム・3D RPG・ホラー向け。
## 詳細: docs/genres/farming-sim.md, docs/genres/3d-rpg.md

signal hour_changed(new_hour: int)
signal day_changed(new_day: int, new_season: int)
signal season_changed(new_season: int)

enum Season { SPRING = 0, SUMMER = 1, AUTUMN = 2, WINTER = 3 }

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_SEASON: int = 7

var hour: int = 6
var day: int = 1
var season: Season = Season.SPRING

var _minutes: int = 0
var _time_scale: float = 60.0  # ゲーム内分 / 実時間秒
var _accumulator: float = 0.0
var _is_paused: bool = false


func _process(delta: float) -> void:
	if _is_paused:
		return
	_accumulator += delta * _time_scale
	while _accumulator >= 1.0:
		_accumulator -= 1.0
		_advance_minute()


func set_time(new_hour: int, new_day: int, new_season: int) -> void:
	hour = clampi(new_hour, 0, HOURS_PER_DAY - 1)
	day = maxi(1, new_day)
	_minutes = 0
	_accumulator = 0.0
	_set_season_from_int(new_season)


func set_time_scale(scale: float) -> void:
	_time_scale = maxf(0.0, scale)


func pause_time() -> void:
	_is_paused = true


func resume_time() -> void:
	_is_paused = false


func get_formatted_time() -> String:
	return "%02d:%02d" % [hour, _minutes]


func is_daytime() -> bool:
	return hour >= 6 and hour < 20


# ── プライベート ──────────────────────────────────────────


func _advance_minute() -> void:
	_minutes += 1
	if _minutes < MINUTES_PER_HOUR:
		return
	_minutes = 0
	_advance_hour()


func _advance_hour() -> void:
	hour = (hour + 1) % HOURS_PER_DAY
	hour_changed.emit(hour)
	if hour != 0:
		return
	_advance_day()


func _advance_day() -> void:
	day += 1
	if day <= DAYS_PER_SEASON:
		day_changed.emit(day, int(season))
		return
	day = 1
	_advance_season()
	day_changed.emit(day, int(season))


func _advance_season() -> void:
	_set_season_from_int((int(season) + 1) % 4)
	season_changed.emit(int(season))


func _set_season_from_int(value: int) -> void:
	match value % 4:
		0:
			season = Season.SPRING
		1:
			season = Season.SUMMER
		2:
			season = Season.AUTUMN
		_:
			season = Season.WINTER
