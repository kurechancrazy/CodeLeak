extends Node
## 入力バッファ — 格闘・アクションゲームのコンボ判定向け。
## 詳細: docs/genres/fighting.md, docs/genres/3d-action.md

const BUFFER_WINDOW_MS: int = 250

var _buffer: Array[Dictionary] = []  # [{action: String, time_ms: int}]


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	_buffer = _buffer.filter(
		func(entry: Dictionary) -> bool: return (now - entry.get("time_ms", 0)) <= BUFFER_WINDOW_MS
	)


## 入力アクションを記録する。_input() または _unhandled_input() から呼ぶ。
func record(action: String) -> void:
	_buffer.append({"action": action, "time_ms": Time.get_ticks_msec()})


## BUFFER_WINDOW_MS 以内に sequence の順序で入力されたか判定する。
func matches_sequence(sequence: Array[String]) -> bool:
	if sequence.is_empty():
		return false
	var now: int = Time.get_ticks_msec()
	var recent: Array[String] = []
	for entry: Dictionary in _buffer:
		if (now - entry.get("time_ms", 0)) <= BUFFER_WINDOW_MS:
			recent.append(entry.get("action", ""))
	if recent.size() < sequence.size():
		return false
	var offset: int = recent.size() - sequence.size()
	for i: int in sequence.size():
		if recent[offset + i] != sequence[i]:
			return false
	return true


func clear() -> void:
	_buffer.clear()
