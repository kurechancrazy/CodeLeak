extends GutTest


func test_matches_returns_true_when_min_zero_and_required_empty() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 0
	rule.min_points = 0
	rule.required_issue_ids = []
	assert_true(rule.matches([], 0), "min=0 and required=[] should always match")


func test_matches_returns_true_when_resolved_meets_min_count() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 2
	rule.min_points = 0
	rule.required_issue_ids = []
	assert_true(
		rule.matches(["issue_a", "issue_b"], 0),
		"should match when resolved count equals min_resolved_count"
	)


func test_matches_returns_true_when_resolved_exceeds_min_count() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 2
	rule.min_points = 0
	rule.required_issue_ids = []
	assert_true(
		rule.matches(["issue_a", "issue_b", "issue_c"], 0),
		"should match when resolved count exceeds min_resolved_count"
	)


func test_matches_returns_false_when_resolved_below_min_count() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 3
	rule.min_points = 0
	rule.required_issue_ids = []
	assert_false(
		rule.matches(["issue_a", "issue_b"], 0),
		"should not match when resolved count is below min_resolved_count"
	)


func test_matches_returns_true_when_all_required_ids_present() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 0
	rule.min_points = 0
	rule.required_issue_ids = ["issue_a", "issue_b"]
	assert_true(
		rule.matches(["issue_a", "issue_b", "issue_c"], 0),
		"should match when all required_issue_ids are in resolved_ids"
	)


func test_matches_returns_false_when_required_id_missing() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 0
	rule.min_points = 0
	rule.required_issue_ids = ["issue_a", "issue_b"]
	assert_false(
		rule.matches(["issue_a"], 0),
		"should not match when a required_issue_id is missing from resolved_ids"
	)


func test_matches_requires_both_min_and_required_conditions() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 3
	rule.min_points = 0
	rule.required_issue_ids = ["issue_a"]

	# required present but count too low
	assert_false(
		rule.matches(["issue_a", "issue_b"], 0),
		"should not match when count is below min even if required ids are present"
	)

	# count met but required missing
	assert_false(
		rule.matches(["issue_b", "issue_c", "issue_d"], 0),
		"should not match when required id is absent even if count meets min"
	)

	# both conditions satisfied
	assert_true(
		rule.matches(["issue_a", "issue_b", "issue_c"], 0),
		"should match only when both min count and required ids are satisfied"
	)


func test_matches_fails_when_points_below_min_points() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 0
	rule.min_points = 100
	rule.required_issue_ids = []
	assert_false(rule.matches([], 99), "should not match when total_points is below min_points")


func test_matches_passes_when_points_meet_min_points() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 0
	rule.min_points = 100
	rule.required_issue_ids = []
	assert_true(rule.matches([], 100), "should match when total_points equals min_points")


func test_matches_requires_both_points_and_count() -> void:
	var rule: OutcomeRule = OutcomeRule.new()
	rule.min_resolved_count = 2
	rule.min_points = 50
	rule.required_issue_ids = []

	# enough points, not enough issues
	assert_false(
		rule.matches(["issue_a"], 60),
		"should not match when issues are below min even with enough points"
	)

	# enough issues, not enough points
	assert_false(
		rule.matches(["issue_a", "issue_b"], 30),
		"should not match when points are below min even with enough issues"
	)

	# both satisfied
	assert_true(
		rule.matches(["issue_a", "issue_b"], 50),
		"should match only when both points and issue count meet their minimums"
	)
