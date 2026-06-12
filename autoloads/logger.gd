extends Node

enum Level { DEBUG, INFO, WARN, ERROR }

var _min_level: Level = Level.INFO
var _log_to_file: bool = false
var _log_file: FileAccess = null
const LOG_PATH: String = "user://logs/game.log"

func _ready() -> void:
	if OS.is_debug_build():
		_min_level = Level.DEBUG
	if _log_to_file:
		_open_log_file()

func debug(message: String, context: Dictionary = {}) -> void:
	_log(Level.DEBUG, message, context)

func info(message: String, context: Dictionary = {}) -> void:
	_log(Level.INFO, message, context)

func warn(message: String, context: Dictionary = {}) -> void:
	_log(Level.WARN, message, context)

func error(message: String, context: Dictionary = {}) -> void:
	_log(Level.ERROR, message, context)

func _log(level: Level, message: String, context: Dictionary) -> void:
	if level < _min_level:
		return
	var level_str: String = Level.keys()[level]
	var timestamp: String = Time.get_datetime_string_from_system()
	var log_line: String = "[%s][%s] %s" % [timestamp, level_str, message]
	if not context.is_empty():
		log_line += " | %s" % str(context)
	match level:
		Level.ERROR:
			push_error(log_line)
		Level.WARN:
			push_warning(log_line)
		_:
			if OS.is_debug_build():
				print(log_line)
	if _log_to_file and _log_file:
		_log_file.store_line(log_line)

func _open_log_file() -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)

func _exit_tree() -> void:
	if _log_file:
		_log_file.close()
