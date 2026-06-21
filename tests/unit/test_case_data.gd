extends GutTest


func after_each() -> void:
	TranslationServer.set_locale("en")


# --- EvidenceItem ---

func test_evidence_get_title_returns_english_by_default() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.title = "Leaked Token"
	ev.title_ja = "漏洩トークン"
	TranslationServer.set_locale("en")
	assert_eq(ev.get_title(), "Leaked Token", "should return English title by default")


func test_evidence_get_title_returns_japanese_when_locale_ja() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.title = "Leaked Token"
	ev.title_ja = "漏洩トークン"
	TranslationServer.set_locale("ja")
	assert_eq(ev.get_title(), "漏洩トークン", "should return Japanese title when locale is ja")


func test_evidence_get_title_returns_english_when_title_ja_empty() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.title = "Leaked Token"
	ev.title_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(
		ev.get_title(), "Leaked Token",
		"should fall back to English when title_ja is empty"
	)


func test_evidence_get_content_returns_english_by_default() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.content = "API key exposed"
	ev.content_ja = "APIキーが露出"
	TranslationServer.set_locale("en")
	assert_eq(ev.get_content(), "API key exposed", "should return English content by default")


func test_evidence_get_content_returns_japanese_when_locale_ja() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.content = "API key exposed"
	ev.content_ja = "APIキーが露出"
	TranslationServer.set_locale("ja")
	assert_eq(
		ev.get_content(), "APIキーが露出",
		"should return Japanese content when locale is ja"
	)


func test_evidence_get_content_returns_english_when_content_ja_empty() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.content = "API key exposed"
	ev.content_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(
		ev.get_content(), "API key exposed",
		"should fall back to English when content_ja is empty"
	)


# --- OutcomeData ---

func test_outcome_get_narrative_returns_english_by_default() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.narrative = "The insider was arrested."
	od.narrative_ja = "内部犯が逮捕された。"
	TranslationServer.set_locale("en")
	assert_eq(
		od.get_narrative(), "The insider was arrested.",
		"should return English narrative by default"
	)


func test_outcome_get_narrative_returns_japanese_when_locale_ja() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.narrative = "The insider was arrested."
	od.narrative_ja = "内部犯が逮捕された。"
	TranslationServer.set_locale("ja")
	assert_eq(
		od.get_narrative(), "内部犯が逮捕された。",
		"should return Japanese narrative when locale is ja"
	)


func test_outcome_get_narrative_returns_english_when_narrative_ja_empty() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.narrative = "The insider was arrested."
	od.narrative_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(
		od.get_narrative(), "The insider was arrested.",
		"should fall back to English when narrative_ja is empty"
	)


func test_outcome_get_hint_returns_english_by_default() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.hint_for_replay = "Check the network logs."
	od.hint_for_replay_ja = "ネットワークログを確認して。"
	TranslationServer.set_locale("en")
	assert_eq(
		od.get_hint_for_replay(), "Check the network logs.",
		"should return English hint by default"
	)


func test_outcome_get_hint_returns_japanese_when_locale_ja() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.hint_for_replay = "Check the network logs."
	od.hint_for_replay_ja = "ネットワークログを確認して。"
	TranslationServer.set_locale("ja")
	assert_eq(
		od.get_hint_for_replay(), "ネットワークログを確認して。",
		"should return Japanese hint when locale is ja"
	)


func test_outcome_get_hint_returns_english_when_hint_ja_empty() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.hint_for_replay = "Check the network logs."
	od.hint_for_replay_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(
		od.get_hint_for_replay(), "Check the network logs.",
		"should fall back to English when hint_for_replay_ja is empty"
	)


# --- CaseData getters ---

func test_case_get_ai_name_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.ai_name = "ARIA"
	cd.ai_name_ja = "アリア"
	TranslationServer.set_locale("en")
	assert_eq(cd.get_ai_name(), "ARIA", "should return English ai_name by default")


func test_case_get_ai_name_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.ai_name = "ARIA"
	cd.ai_name_ja = "アリア"
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_ai_name(), "アリア", "should return Japanese ai_name when locale is ja")


func test_case_get_ai_name_returns_english_when_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.ai_name = "ARIA"
	cd.ai_name_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(
		cd.get_ai_name(), "ARIA",
		"should fall back to English when ai_name_ja is empty"
	)


func test_case_get_briefing_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.briefing = "Investigate the breach."
	cd.briefing_ja = "侵害を調査せよ。"
	TranslationServer.set_locale("en")
	assert_eq(
		cd.get_briefing(), "Investigate the breach.",
		"should return English briefing by default"
	)


func test_case_get_briefing_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.briefing = "Investigate the breach."
	cd.briefing_ja = "侵害を調査せよ。"
	TranslationServer.set_locale("ja")
	assert_eq(
		cd.get_briefing(), "侵害を調査せよ。",
		"should return Japanese briefing when locale is ja"
	)


func test_case_get_briefing_returns_english_when_briefing_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.briefing = "Investigate the breach."
	cd.briefing_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(
		cd.get_briefing(), "Investigate the breach.",
		"should fall back to English when briefing_ja is empty"
	)


func test_case_get_suspects_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.suspects = ["Alice", "Bob"]
	cd.suspects_ja = ["アリス", "ボブ"]
	TranslationServer.set_locale("en")
	assert_eq(cd.get_suspects(), ["Alice", "Bob"], "should return English suspects by default")


func test_case_get_suspects_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.suspects = ["Alice", "Bob"]
	cd.suspects_ja = ["アリス", "ボブ"]
	TranslationServer.set_locale("ja")
	assert_eq(
		cd.get_suspects(), ["アリス", "ボブ"],
		"should return Japanese suspects when locale is ja"
	)


func test_case_get_suspects_returns_english_when_suspects_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.suspects = ["Alice", "Bob"]
	cd.suspects_ja = []
	TranslationServer.set_locale("ja")
	assert_eq(
		cd.get_suspects(), ["Alice", "Bob"],
		"should fall back to English when suspects_ja is empty"
	)


func test_case_get_victims_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.victims = ["Corp X"]
	cd.victims_ja = ["X社"]
	TranslationServer.set_locale("en")
	assert_eq(cd.get_victims(), ["Corp X"], "should return English victims by default")


func test_case_get_victims_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.victims = ["Corp X"]
	cd.victims_ja = ["X社"]
	TranslationServer.set_locale("ja")
	assert_eq(
		cd.get_victims(), ["X社"],
		"should return Japanese victims when locale is ja"
	)


func test_case_get_victims_returns_english_when_victims_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.victims = ["Corp X"]
	cd.victims_ja = []
	TranslationServer.set_locale("ja")
	assert_eq(
		cd.get_victims(), ["Corp X"],
		"should fall back to English when victims_ja is empty"
	)


# --- CaseData.get_outcome() ---

func _make_outcome(key: String) -> OutcomeData:
	var od: OutcomeData = OutcomeData.new()
	od.outcome_key = key
	return od


func test_get_outcome_returns_matching_outcome_data() -> void:
	var cd: CaseData = CaseData.new()
	cd.outcomes.append(_make_outcome("insider"))
	cd.outcomes.append(_make_outcome("insufficient"))
	var result: OutcomeData = cd.get_outcome("insider")
	assert_not_null(result, "should return the matching OutcomeData")
	assert_eq(result.outcome_key, "insider", "returned outcome should have the correct key")


func test_get_outcome_returns_null_when_key_not_found() -> void:
	var cd: CaseData = CaseData.new()
	cd.outcomes.append(_make_outcome("insider"))
	var result: OutcomeData = cd.get_outcome("external_hack")
	assert_null(result, "should return null when key does not match any outcome")


func test_get_outcome_returns_null_on_empty_outcomes() -> void:
	var cd: CaseData = CaseData.new()
	var result: OutcomeData = cd.get_outcome("anything")
	assert_null(result, "should return null when outcomes array is empty")


# --- CaseData 新フィールド helpers ---

func _make_valid_test_case() -> CaseData:
	# InvestigationStep を7つの StepChoice で構成したサンプルを作る
	var choices: Array[StepChoice] = []
	for i: int in range(7):
		var sc: StepChoice = StepChoice.new()
		sc.choice_key = "c%d" % i
		sc.label = "Choice %d" % i
		if i == 0:
			sc.next_step_id = ""  # terminal
			sc.resolves_issue_id = "issue_a"
		else:
			sc.next_step_id = ""  # terminal for simplicity
		choices.append(sc)

	var step: InvestigationStep = InvestigationStep.new()
	step.step_id = "s001"
	step.question = "What happened?"
	step.question_type = "DEDUCTION"
	step.choices = choices

	var issue: CaseIssue = CaseIssue.new()
	issue.issue_id = "issue_a"
	issue.description = "Something bad"

	var rule_main: OutcomeRule = OutcomeRule.new()
	rule_main.min_resolved_count = 1
	rule_main.required_issue_ids = []
	rule_main.outcome_key = "intentional"

	var o_main: OutcomeData = OutcomeData.new()
	o_main.outcome_key = "intentional"
	o_main.narrative = "Main outcome"

	var o_insufficient: OutcomeData = OutcomeData.new()
	o_insufficient.outcome_key = "insufficient"
	o_insufficient.narrative = "Insufficient"

	var c: CaseData = CaseData.new()
	c.case_id = "test_case"
	c.entry_step_id = "s001"
	c.investigation_steps = [step]
	c.resolvable_issues = [issue]
	c.outcome_rules = [rule_main]
	c.outcomes = [o_main, o_insufficient]
	c.time_limit_seconds = 240.0
	return c


# --- CaseData 新フィールド ---

func test_get_step_by_id_returns_correct_step() -> void:
	var c: CaseData = _make_valid_test_case()
	var step: InvestigationStep = c.get_step_by_id("s001")
	assert_not_null(step, "should find step by id")
	assert_eq(step.step_id, "s001", "should return the correct step")


func test_get_step_by_id_returns_null_for_unknown_id() -> void:
	var c: CaseData = _make_valid_test_case()
	var step: InvestigationStep = c.get_step_by_id("unknown")
	assert_null(step, "should return null for unknown step id")


func test_get_issue_by_id_returns_correct_issue() -> void:
	var c: CaseData = _make_valid_test_case()
	var issue: CaseIssue = c.get_issue_by_id("issue_a")
	assert_not_null(issue, "should find issue by id")
	assert_eq(issue.issue_id, "issue_a", "should return the correct issue")


func test_get_issue_by_id_returns_null_for_unknown_id() -> void:
	var c: CaseData = _make_valid_test_case()
	var issue: CaseIssue = c.get_issue_by_id("unknown")
	assert_null(issue, "should return null for unknown issue id")


func test_validate_passes_for_valid_case() -> void:
	var c: CaseData = _make_valid_test_case()
	var errors: Array[String] = c.validate()
	assert_eq(errors.size(), 0, "valid case should have no validation errors")


func test_validate_fails_when_entry_step_id_empty() -> void:
	var c: CaseData = _make_valid_test_case()
	c.entry_step_id = ""
	var errors: Array[String] = c.validate()
	assert_gt(errors.size(), 0, "empty entry_step_id should fail validation")


func test_validate_fails_when_entry_step_id_not_found() -> void:
	var c: CaseData = _make_valid_test_case()
	c.entry_step_id = "nonexistent_step"
	var errors: Array[String] = c.validate()
	assert_gt(errors.size(), 0, "missing entry_step_id should fail validation")


func test_validate_fails_when_step_has_wrong_choice_count() -> void:
	var c: CaseData = _make_valid_test_case()
	c.investigation_steps[0].choices = []  # 0 choices instead of 7
	var errors: Array[String] = c.validate()
	assert_gt(errors.size(), 0, "step with wrong choice count should fail validation")


func test_validate_fails_when_outcome_rule_references_missing_key() -> void:
	var c: CaseData = _make_valid_test_case()
	c.outcome_rules[0].outcome_key = "nonexistent"
	var errors: Array[String] = c.validate()
	assert_gt(errors.size(), 0, "rule with missing outcome_key should fail validation")


func test_validate_fails_when_insufficient_outcome_missing() -> void:
	var c: CaseData = _make_valid_test_case()
	# Remove insufficient outcome
	var filtered: Array[OutcomeData] = []
	for o: OutcomeData in c.outcomes:
		if o.outcome_key != "insufficient":
			filtered.append(o)
	c.outcomes = filtered
	var errors: Array[String] = c.validate()
	assert_gt(errors.size(), 0, "missing insufficient outcome should fail validation")
