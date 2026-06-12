## 数学ユーティリティ — 純粋関数のみ。副作用なし。
class_name MathUtils
extends RefCounted

## 値を [min_val, max_val] にクランプして返す（型安全版）
static func clamp_int(value: int, min_val: int, max_val: int) -> int:
	return clampi(value, min_val, max_val)

## 線形補間（weight: 0.0〜1.0）
static func lerp_float(from: float, to: float, weight: float) -> float:
	return lerpf(from, to, clampf(weight, 0.0, 1.0))

## 秒数を "MM:SS" 形式の文字列に変換する
static func seconds_to_time_string(seconds: float) -> String:
	var total: int = int(seconds)
	var minutes: int = total / 60
	var secs: int = total % 60
	return "%02d:%02d" % [minutes, secs]

## 配列をシャッフルして返す（元の配列は変更しない）
static func shuffled(array: Array) -> Array:
	var copy: Array = array.duplicate()
	copy.shuffle()
	return copy

## スコアを "1,500" 形式の文字列に変換する
static func format_score(score: int) -> String:
	var score_str: String = str(score)
	var result: String = ""
	var count: int = 0
	for i: int in range(score_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = score_str[i] + result
		count += 1
	return result
