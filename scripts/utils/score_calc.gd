class_name ScoreCalc
## Puzzle score calculations. All functions are static with no side effects.


static func calculate_base_score(miss_count: int, elapsed_secs: float) -> int:
	return maxi(100, 1000 - miss_count * 100 - int(elapsed_secs * 2.0))


static func apply_hint_penalty(base_score: int, hints_used: int) -> int:
	return int(float(base_score) * pow(0.8, float(hints_used)))


static func calculate_final_score(miss_count: int, elapsed_secs: float, hints_used: int) -> int:
	var base: int = calculate_base_score(miss_count, elapsed_secs)
	return apply_hint_penalty(base, hints_used)


static func calculate_rank(score: int) -> String:
	if score >= 900:
		return "S"
	if score >= 700:
		return "A"
	if score >= 500:
		return "B"
	if score >= 300:
		return "C"
	return "D"
