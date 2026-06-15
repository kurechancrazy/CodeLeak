## Tests for SaveManager case verdict persistence
extends GutTest


func before_each() -> void:
	# Clear progress section before each test
	SaveManager.set_value("progress", "cases_resolved", "[]")
	SaveManager.set_value("progress", "case_verdicts", "{}")


func test_on_case_resolved_saves_case_id() -> void:
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	var resolved_raw: String = SaveManager.get_value("progress", "cases_resolved", "[]")
	var resolved: Variant = JSON.parse_string(resolved_raw)
	assert_true(resolved is Array, "cases_resolved should be an array")
	assert_true("case_001" in (resolved as Array), "case_001 should be in cases_resolved")


func test_on_case_resolved_saves_verdict() -> void:
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	var verdicts_raw: String = SaveManager.get_value("progress", "case_verdicts", "{}")
	var verdicts: Variant = JSON.parse_string(verdicts_raw)
	assert_true(verdicts is Dictionary, "case_verdicts should be a dict")
	var arr: Variant = (verdicts as Dictionary).get("case_001", [])
	assert_true(arr is Array, "case_001 verdicts should be an array")
	assert_true("intentional" in (arr as Array), "intentional should be recorded")


func test_on_case_resolved_no_duplicate_case_id() -> void:
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	SaveManager._on_case_resolved("case_001", "runaway", 2)
	var resolved_raw: String = SaveManager.get_value("progress", "cases_resolved", "[]")
	var resolved: Variant = JSON.parse_string(resolved_raw)
	assert_true(resolved is Array)
	var count: int = 0
	for item: Variant in (resolved as Array):
		if item == "case_001":
			count += 1
	assert_eq(count, 1, "case_001 should appear only once in cases_resolved")


func test_on_case_resolved_no_duplicate_verdict() -> void:
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	SaveManager._on_case_resolved("case_001", "intentional", 3)  # same verdict again
	var verdicts_raw: String = SaveManager.get_value("progress", "case_verdicts", "{}")
	var verdicts: Variant = JSON.parse_string(verdicts_raw)
	var arr: Variant = (verdicts as Dictionary).get("case_001", [])
	assert_eq((arr as Array).size(), 1, "intentional should appear only once")


func test_on_case_resolved_multiple_verdicts_accumulate() -> void:
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	SaveManager._on_case_resolved("case_001", "runaway", 4)
	SaveManager._on_case_resolved("case_001", "insufficient", 1)
	var verdicts_raw: String = SaveManager.get_value("progress", "case_verdicts", "{}")
	var verdicts: Variant = JSON.parse_string(verdicts_raw)
	var arr: Variant = (verdicts as Dictionary).get("case_001", [])
	assert_eq((arr as Array).size(), 3, "3 different verdicts should all be stored")


func test_on_case_resolved_corrupt_cases_resolved_does_not_crash() -> void:
	# Simulate corrupted JSON
	SaveManager.set_value("progress", "cases_resolved", "NOT_VALID_JSON")
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	var resolved_raw: String = SaveManager.get_value("progress", "cases_resolved", "[]")
	var resolved: Variant = JSON.parse_string(resolved_raw)
	assert_true(resolved is Array, "should recover from corrupt JSON and create fresh array")
	assert_true("case_001" in (resolved as Array), "case_001 should be added after recovery")


func test_on_case_resolved_corrupt_case_verdicts_does_not_crash() -> void:
	SaveManager.set_value("progress", "case_verdicts", "NOT_VALID_JSON")
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	var verdicts_raw: String = SaveManager.get_value("progress", "case_verdicts", "{}")
	var verdicts: Variant = JSON.parse_string(verdicts_raw)
	assert_true(verdicts is Dictionary, "should recover from corrupt JSON")


func test_multiple_cases_tracked_independently() -> void:
	SaveManager._on_case_resolved("case_001", "intentional", 3)
	SaveManager._on_case_resolved("case_002", "runaway", 2)
	var verdicts_raw: String = SaveManager.get_value("progress", "case_verdicts", "{}")
	var verdicts: Variant = JSON.parse_string(verdicts_raw)
	assert_true((verdicts as Dictionary).has("case_001"), "case_001 should be tracked")
	assert_true((verdicts as Dictionary).has("case_002"), "case_002 should be tracked independently")
