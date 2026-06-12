extends GutTest

var _logger: Node = null


func before_each() -> void:
	_logger = load("res://autoloads/logger.gd").new()
	# _ready() を呼ばず OS.is_debug_build() による _min_level 変更を回避


func after_each() -> void:
	_logger.free()


# --- Level enum ---

func test_level_debug_is_lowest() -> void:
	assert_eq(_logger.Level.DEBUG, 0)


func test_level_order_ascending() -> void:
	assert_lt(_logger.Level.DEBUG, _logger.Level.INFO)
	assert_lt(_logger.Level.INFO, _logger.Level.WARN)
	assert_lt(_logger.Level.WARN, _logger.Level.ERROR)


# --- _min_level フィルタ ---

func test_default_min_level_is_info() -> void:
	assert_eq(_logger._min_level, _logger.Level.INFO)


func test_debug_does_not_crash_when_filtered_out() -> void:
	_logger._min_level = _logger.Level.WARN
	_logger.debug("filtered message")  # クラッシュしないこと


func test_info_does_not_crash_when_filtered_out() -> void:
	_logger._min_level = _logger.Level.ERROR
	_logger.info("filtered")
	_logger.warn("filtered")


func test_error_always_passes_filter() -> void:
	_logger._min_level = _logger.Level.ERROR
	_logger.error("error message")  # push_error が呼ばれるがクラッシュしないこと


# --- コンテキスト付きログ ---

func test_log_with_context_does_not_crash() -> void:
	_logger._min_level = _logger.Level.DEBUG
	_logger.info("test", {"key": "value", "count": 1})
