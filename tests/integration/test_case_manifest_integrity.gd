## Integration test: all cases in case_manifest pass CaseData.validate()
extends GutTest

const _MANIFEST_PATH: String = "res://resources/cases/case_manifest.tres"


func test_manifest_loads_as_correct_type() -> void:
	assert_true(ResourceLoader.exists(_MANIFEST_PATH), "case_manifest.tres must exist")
	var manifest: Resource = load(_MANIFEST_PATH)
	assert_not_null(manifest, "manifest must not be null")
	assert_true(manifest is CaseManifest, "manifest must be CaseManifest type")


func test_manifest_has_at_least_one_case() -> void:
	if not ResourceLoader.exists(_MANIFEST_PATH):
		pass_test("skipped: manifest not found")
		return
	var manifest: CaseManifest = load(_MANIFEST_PATH) as CaseManifest
	assert_gt(manifest.cases.size(), 0, "manifest must have at least one case")


func test_all_cases_pass_validation() -> void:
	if not ResourceLoader.exists(_MANIFEST_PATH):
		pass_test("skipped: manifest not found")
		return
	var manifest: CaseManifest = load(_MANIFEST_PATH) as CaseManifest
	for case_data: CaseData in manifest.cases:
		var errors: Array[String] = case_data.validate()
		assert_eq(errors.size(), 0,
			"Case '%s' must have no validation errors, got: %s" % [case_data.case_id, str(errors)])


func test_all_cases_have_non_empty_case_id() -> void:
	if not ResourceLoader.exists(_MANIFEST_PATH):
		pass_test("skipped: manifest not found")
		return
	var manifest: CaseManifest = load(_MANIFEST_PATH) as CaseManifest
	for case_data: CaseData in manifest.cases:
		assert_ne(case_data.case_id, "", "case_id must not be empty")


func test_all_cases_have_four_evidence_items() -> void:
	if not ResourceLoader.exists(_MANIFEST_PATH):
		pass_test("skipped: manifest not found")
		return
	var manifest: CaseManifest = load(_MANIFEST_PATH) as CaseManifest
	for case_data: CaseData in manifest.cases:
		assert_eq(case_data.evidence.size(), 4,
			"Case '%s' must have exactly 4 evidence items" % case_data.case_id)


func test_all_cases_have_insufficient_outcome() -> void:
	if not ResourceLoader.exists(_MANIFEST_PATH):
		pass_test("skipped: manifest not found")
		return
	var manifest: CaseManifest = load(_MANIFEST_PATH) as CaseManifest
	for case_data: CaseData in manifest.cases:
		var has_insufficient: bool = false
		for o: OutcomeData in case_data.outcomes:
			if o.outcome_key == "insufficient":
				has_insufficient = true
				break
		assert_true(has_insufficient,
			"Case '%s' must have an 'insufficient' outcome" % case_data.case_id)


func test_all_cases_have_minimum_three_outcomes() -> void:
	if not ResourceLoader.exists(_MANIFEST_PATH):
		pass_test("skipped: manifest not found")
		return
	var manifest: CaseManifest = load(_MANIFEST_PATH) as CaseManifest
	for case_data: CaseData in manifest.cases:
		assert_gte(case_data.outcomes.size(), 3,
			"Case '%s' must have at least 3 outcomes (including insufficient)" % case_data.case_id)


func test_all_cases_have_non_empty_briefing() -> void:
	if not ResourceLoader.exists(_MANIFEST_PATH):
		pass_test("skipped: manifest not found")
		return
	var manifest: CaseManifest = load(_MANIFEST_PATH) as CaseManifest
	for case_data: CaseData in manifest.cases:
		assert_ne(case_data.briefing, "",
			"Case '%s' must have a non-empty briefing" % case_data.case_id)
		assert_ne(case_data.briefing_ja, "",
			"Case '%s' must have a non-empty briefing_ja" % case_data.case_id)
