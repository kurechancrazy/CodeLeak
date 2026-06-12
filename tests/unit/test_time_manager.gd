extends GutTest

var _tm: Node = null


func before_each() -> void:
	_tm = load("res://autoloads/time_manager.gd").new()
	# _ready() を呼ばず EventBus 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_tm.free()


func test_initial_hour_is_six() -> void:
	assert_eq(_tm.hour, 6)


func test_initial_day_is_one() -> void:
	assert_eq(_tm.day, 1)


func test_get_formatted_time() -> void:
	_tm.hour = 9
	_tm._minutes = 5
	assert_eq(_tm.get_formatted_time(), "09:05")


func test_is_daytime_at_noon() -> void:
	_tm.hour = 12
	assert_true(_tm.is_daytime())


func test_is_daytime_false_at_night() -> void:
	_tm.hour = 0
	assert_false(_tm.is_daytime())


func test_set_time_clamps_hour() -> void:
	_tm.set_time(30, 1, 0)
	assert_eq(_tm.hour, _tm.HOURS_PER_DAY - 1)


func test_set_time_sets_season() -> void:
	_tm.set_time(6, 1, 2)  # Season.AUTUMN = 2
	assert_eq(_tm.season, _tm.Season.AUTUMN)


func test_pause_stops_accumulation() -> void:
	_tm.set_time_scale(1000.0)
	_tm.pause_time()
	_tm._process(10.0)
	assert_eq(_tm._minutes, 0)


func test_advance_minute_wraps_to_next_hour() -> void:
	_tm.hour = 6
	_tm._minutes = 59
	_tm._advance_minute()
	assert_eq(_tm._minutes, 0)
	assert_eq(_tm.hour, 7)


func test_advance_day_wraps_season_after_last_day() -> void:
	_tm.day = _tm.DAYS_PER_SEASON
	_tm.season = _tm.Season.SPRING
	_tm._advance_day()
	assert_eq(_tm.day, 1)
	assert_eq(_tm.season, _tm.Season.SUMMER)
