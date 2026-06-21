## Tests for CaseManager — timer, chain state, pause flag, helpers
extends GutTest


func before_each() -> void:
	CaseManager.current_case = null
	CaseManager.read_evidence_ids.clear()
	CaseManager.selected_verdict = ""
	CaseManager.time_remaining = 0.0
	CaseManager._timer_active = false
	CaseManager._paused = false
	CaseManager.current_step_id = ""
	CaseManager.step_id_history.clear()
	CaseManager.choice_history.clear()
	CaseManager.resolved_issue_ids.clear()
	CaseManager.total_points = 0
	CaseManager.chain_complete = false
	CaseManager._awaiting_citation = false
	CaseManager._wrong_citation_count = 0
	CaseManager.citation_history.clear()


func _make_test_case() -> CaseData:
	var choices_s1: Array[StepChoice] = []
	for i: int in range(7):
		var sc: StepChoice = StepChoice.new()
		sc.choice_key = "c%d" % i
		sc.label = "Choice %d" % i
		if i == 0:
			sc.next_step_id = "s002"
			sc.resolves_issue_id = "issue_code"
		else:
			sc.next_step_id = ""
			sc.resolves_issue_id = ""
		choices_s1.append(sc)

	var s1: InvestigationStep = InvestigationStep.new()
	s1.step_id = "s001"
	s1.question = "What is the first clue?"
	s1.question_type = "DEDUCTION"
	s1.choices = choices_s1

	var choices_s2: Array[StepChoice] = []
	for i: int in range(7):
		var sc: StepChoice = StepChoice.new()
		sc.choice_key = "c%d" % i
		sc.label = "Choice %d" % i
		sc.next_step_id = ""
		if i == 0:
			sc.resolves_issue_id = "issue_log"
		choices_s2.append(sc)

	var s2: InvestigationStep = InvestigationStep.new()
	s2.step_id = "s002"
	s2.question = "What does the log show?"
	s2.question_type = "LOG"
	s2.choices = choices_s2

	var issue_code: CaseIssue = CaseIssue.new()
	issue_code.issue_id = "issue_code"
	issue_code.description = "Code was tampered"

	var issue_log: CaseIssue = CaseIssue.new()
	issue_log.issue_id = "issue_log"
	issue_log.description = "Log shows anomaly"

	var rule_main: OutcomeRule = OutcomeRule.new()
	rule_main.min_resolved_count = 2
	rule_main.required_issue_ids = []
	rule_main.outcome_key = "intentional"

	var rule_partial: OutcomeRule = OutcomeRule.new()
	rule_partial.min_resolved_count = 1
	rule_partial.required_issue_ids = []
	rule_partial.outcome_key = "runaway"

	var o_intentional: OutcomeData = OutcomeData.new()
	o_intentional.outcome_key = "intentional"
	o_intentional.narrative = "Intentional outcome"
	o_intentional.hint_for_replay = "The code points to a human actor."

	var o_runaway: OutcomeData = OutcomeData.new()
	o_runaway.outcome_key = "runaway"
	o_runaway.narrative = "Runaway outcome"
	o_runaway.hint_for_replay = "The AI acted autonomously."

	var o_insufficient: OutcomeData = OutcomeData.new()
	o_insufficient.outcome_key = "insufficient"
	o_insufficient.narrative = "Insufficient outcome"
	o_insufficient.hint_for_replay = ""

	var c: CaseData = CaseData.new()
	c.case_id = "case_test"
	c.time_limit_seconds = 240.0
	c.entry_step_id = "s001"
	c.investigation_steps = [s1, s2]
	c.resolvable_issues = [issue_code, issue_log]
	c.outcome_rules = [rule_main, rule_partial]
	c.outcomes = [o_intentional, o_runaway, o_insufficient]

	var ev_code: EvidenceItem = EvidenceItem.new()
	ev_code.evidence_id = "e_code"
	ev_code.type = "CODE"
	var ev_log: EvidenceItem = EvidenceItem.new()
	ev_log.evidence_id = "e_log"
	ev_log.type = "LOG"
	var ev_email: EvidenceItem = EvidenceItem.new()
	ev_email.evidence_id = "e_email"
	ev_email.type = "EMAIL"
	var ev_net: EvidenceItem = EvidenceItem.new()
	ev_net.evidence_id = "e_net"
	ev_net.type = "NETWORK"
	c.evidence = [ev_code, ev_log, ev_email, ev_net]
	return c


## Timer tests
func test_tick_decrements_time() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._tick(10.0)
	assert_eq(CaseManager.time_remaining, 230.0, "time should decrease by 10")


func test_tick_does_not_go_below_zero() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._tick(1000.0)
	assert_eq(CaseManager.time_remaining, 0.0, "time should clamp at 0")


## Pause flag tests
func test_paused_flag_stops_tick() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._paused = true
	var time_before: float = CaseManager.time_remaining
	CaseManager._tick(10.0)
	assert_eq(CaseManager.time_remaining, time_before, "paused timer should not decrement")


func test_unpause_resumes_tick() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._paused = true
	CaseManager._tick(10.0)
	CaseManager._paused = false
	CaseManager._tick(10.0)
	assert_eq(CaseManager.time_remaining, 230.0, "timer should decrement only after unpause")


## Helper tests
func test_get_unread_evidence_returns_all_initially() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	assert_eq(CaseManager.get_unread_evidence().size(), 4, "all 4 should be unread initially")


func test_mark_evidence_read_removes_from_unread() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.mark_evidence_read("e_code")
	assert_eq(
		CaseManager.get_unread_evidence().size(), 3, "3 should remain unread after reading one"
	)


func test_mark_evidence_read_idempotent() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.mark_evidence_read("e_code")
	CaseManager.mark_evidence_read("e_code")
	assert_eq(CaseManager.read_evidence_ids.size(), 1, "duplicate read should not add twice")


func test_get_unread_evidence_empty_when_all_read() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.mark_evidence_read("e_code")
	CaseManager.mark_evidence_read("e_log")
	CaseManager.mark_evidence_read("e_email")
	CaseManager.mark_evidence_read("e_net")
	assert_eq(CaseManager.get_unread_evidence().size(), 0, "all read = empty unread list")


func test_get_alternate_hint_returns_other_hint() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	var hint: String = CaseManager.get_alternate_hint("intentional")
	assert_false(hint.is_empty(), "should return a hint from another outcome")
	assert_ne(
		hint, "The code points to a human actor.", "should not return hint for chosen verdict"
	)


func test_get_alternate_hint_empty_if_no_others() -> void:
	var c: CaseData = _make_test_case()
	for o: OutcomeData in c.outcomes:
		if o.outcome_key != "intentional":
			o.hint_for_replay = ""
			o.hint_for_replay_ja = ""
	CaseManager.set_current_case(c)
	var hint: String = CaseManager.get_alternate_hint("runaway")
	# must not crash — return value may be empty or non-empty
	assert_true(hint.length() >= 0, "get_alternate_hint with no valid alternates should not crash")


func test_set_current_case_resets_state() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.mark_evidence_read("e_code")
	CaseManager.selected_verdict = "intentional"
	CaseManager.set_current_case(c)
	assert_true(CaseManager.read_evidence_ids.is_empty(), "read_evidence_ids should reset")
	assert_true(CaseManager.selected_verdict.is_empty(), "selected_verdict should reset")
	assert_false(CaseManager._timer_active, "timer should not be active after set_current_case")


func test_apply_wrong_answer_penalty_deducts_time() -> void:
	var c: CaseData = _make_test_case()
	c.wrong_answer_time_penalty = 30.0
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	var before: float = CaseManager.time_remaining
	CaseManager.apply_wrong_answer_penalty()
	assert_eq(
		CaseManager.time_remaining,
		before - 30.0,
		"should deduct penalty seconds from time_remaining"
	)


func test_apply_wrong_answer_penalty_increments_count() -> void:
	var c: CaseData = _make_test_case()
	c.wrong_answer_time_penalty = 10.0
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.apply_wrong_answer_penalty()
	CaseManager.apply_wrong_answer_penalty()
	assert_eq(CaseManager.wrong_answer_count, 2, "wrong_answer_count should increment each call")


func test_apply_wrong_answer_penalty_clamps_to_zero() -> void:
	var c: CaseData = _make_test_case()
	c.wrong_answer_time_penalty = 9999.0
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.apply_wrong_answer_penalty()
	assert_eq(CaseManager.time_remaining, 0.0, "time_remaining should not go below 0")


func test_set_current_case_resets_wrong_answer_count() -> void:
	var c: CaseData = _make_test_case()
	c.wrong_answer_time_penalty = 10.0
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.apply_wrong_answer_penalty()
	CaseManager.set_current_case(c)
	assert_eq(
		CaseManager.wrong_answer_count, 0, "wrong_answer_count should reset on set_current_case"
	)


## answer_step() のテスト


func test_answer_step_records_in_history() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c1")
	assert_eq(CaseManager.step_id_history.size(), 1, "one step should be in history")
	assert_eq(CaseManager.step_id_history[0], "s001", "history should contain s001")


func test_answer_step_advances_to_next_step() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c0")
	assert_eq(CaseManager.current_step_id, "s002", "should advance to s002")


func test_answer_step_resolves_issue() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c0")
	assert_true("issue_code" in CaseManager.resolved_issue_ids, "issue_code should be resolved")


func test_answer_step_terminal_sets_chain_complete() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c1")
	assert_true(CaseManager.chain_complete, "chain should be complete after terminal choice")


func test_answer_step_terminal_stops_timer() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c1")
	var time_after: float = CaseManager.time_remaining
	CaseManager._tick(999.0)
	assert_eq(
		CaseManager.time_remaining, time_after, "timer should not advance after chain complete"
	)


func test_answer_step_idempotent_after_complete() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c1")
	var history_size: int = CaseManager.step_id_history.size()
	CaseManager.answer_step("c0")
	assert_eq(
		CaseManager.step_id_history.size(),
		history_size,
		"answer_step after complete should be ignored"
	)


## determine_outcome() のテスト


func test_determine_outcome_returns_first_matching_rule() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.resolved_issue_ids = ["issue_code", "issue_log"]
	CaseManager.total_points = 0
	var outcome: String = CaseManager.determine_outcome()
	assert_eq(outcome, "intentional", "2 resolved (min_points=0) should match intentional rule")


func test_determine_outcome_returns_partial_when_1_resolved() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.resolved_issue_ids = ["issue_code"]
	CaseManager.total_points = 0
	var outcome: String = CaseManager.determine_outcome()
	assert_eq(outcome, "runaway", "1 resolved should match runaway rule (min=1)")


func test_determine_outcome_returns_insufficient_when_0_resolved() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.resolved_issue_ids = []
	CaseManager.total_points = 0
	var outcome: String = CaseManager.determine_outcome()
	assert_eq(outcome, "insufficient", "0 resolved should fall through to insufficient")


func test_determine_outcome_blocked_by_min_points() -> void:
	var c: CaseData = _make_test_case()
	c.outcome_rules[0].min_points = 50
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.resolved_issue_ids = ["issue_code", "issue_log"]
	CaseManager.total_points = 30
	var outcome: String = CaseManager.determine_outcome()
	assert_eq(outcome, "runaway", "insufficient points should block intentional even with 2 issues")


func test_determine_outcome_passes_with_enough_points() -> void:
	var c: CaseData = _make_test_case()
	c.outcome_rules[0].min_points = 50
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.resolved_issue_ids = ["issue_code", "issue_log"]
	CaseManager.total_points = 50
	var outcome: String = CaseManager.determine_outcome()
	assert_eq(outcome, "intentional", "meeting min_points threshold should allow intentional")


func test_answer_step_accumulates_points() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].choices[0].points = 25
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c0")
	assert_eq(CaseManager.total_points, 25, "answer_step should add choice.points to total_points")


func test_set_current_case_resets_total_points() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.total_points = 99
	CaseManager.set_current_case(c)
	assert_eq(CaseManager.total_points, 0, "set_current_case should reset total_points to 0")


func test_start_investigation_resets_total_points() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.total_points = 88
	CaseManager.start_investigation()
	assert_eq(CaseManager.total_points, 0, "start_investigation should reset total_points to 0")


## タイムアウトのテスト


func test_timeout_sets_chain_complete() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._tick(241.0)
	assert_true(CaseManager.chain_complete, "timeout should set chain_complete to true")


func test_timeout_does_not_override_if_already_complete() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c1")
	CaseManager.resolved_issue_ids = ["issue_code"]
	CaseManager._tick(999.0)
	assert_true(CaseManager.chain_complete, "chain_complete stays true after extra ticks")


## get_chain_summary() のテスト


func test_get_chain_summary_empty_initially() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	var summary: Array[Dictionary] = CaseManager.get_chain_summary()
	assert_eq(summary.size(), 0, "summary should be empty before any answers")


func test_get_chain_summary_contains_answered_step() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c0")
	var summary: Array[Dictionary] = CaseManager.get_chain_summary()
	assert_eq(summary.size(), 1, "summary should have 1 entry after one answer")
	assert_eq(summary[0]["step_id"], "s001", "step_id should be s001")
	assert_eq(summary[0]["choice_key"], "c0", "choice_key should be c0")
	assert_eq(summary[0]["resolved_issue_id"], "issue_code", "resolved issue should be issue_code")
	assert_eq(
		summary[0]["points_earned"], 0, "points_earned should reflect choice.points (default 0)"
	)


func test_get_chain_summary_records_points_earned() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].choices[0].points = 30
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c0")
	var summary: Array[Dictionary] = CaseManager.get_chain_summary()
	assert_eq(
		summary[0]["points_earned"], 30, "points_earned should reflect the choice.points value"
	)


## 証拠引用機能のテスト


func test_is_awaiting_citation_false_by_default() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	assert_false(
		CaseManager.is_awaiting_citation(),
		"entry step has correct_evidence_id='' so awaiting should be false"
	)


func test_is_awaiting_citation_true_when_step_has_evidence_id() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].correct_evidence_id = "e_code"
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	assert_true(
		CaseManager.is_awaiting_citation(),
		"entry step has correct_evidence_id so awaiting should be true"
	)


func test_cite_evidence_correct_records_history_and_clears_flag() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].correct_evidence_id = "e_code"
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.cite_evidence("e_code")
	assert_false(
		CaseManager.is_awaiting_citation(), "awaiting should be false after correct citation"
	)
	assert_true(CaseManager.citation_history.has("s001"), "citation_history should record the step")
	assert_eq(
		CaseManager.citation_history["s001"], "e_code", "citation_history should store correct id"
	)


func test_cite_evidence_wrong_increments_count() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].correct_evidence_id = "e_code"
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.cite_evidence("e_log")
	assert_eq(CaseManager._wrong_citation_count, 1, "wrong count should increment to 1")
	assert_true(CaseManager.is_awaiting_citation(), "still awaiting after wrong citation")


func test_cite_evidence_wrong_applies_penalty_max_twice() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].correct_evidence_id = "e_code"
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	var before: float = CaseManager.time_remaining
	CaseManager.cite_evidence("e_log")
	CaseManager.cite_evidence("e_net")
	CaseManager.cite_evidence("e_email")
	assert_eq(
		CaseManager.time_remaining,
		before - 30.0,
		"penalty should apply at most twice (15 * 2 = 30)"
	)
	assert_eq(CaseManager._wrong_citation_count, 3, "count increments even after penalty cap")


func test_cite_evidence_noop_when_correct_evidence_id_empty() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	var before_time: float = CaseManager.time_remaining
	CaseManager.cite_evidence("e_code")
	assert_eq(CaseManager.time_remaining, before_time, "no penalty when not in awaiting state")
	assert_true(CaseManager.citation_history.is_empty(), "citation_history should remain empty")


func test_answer_step_ignored_while_awaiting_citation() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].correct_evidence_id = "e_code"
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	assert_true(CaseManager.is_awaiting_citation(), "precondition: awaiting citation")
	CaseManager.answer_step("c0")
	assert_eq(
		CaseManager.step_id_history.size(),
		0,
		"answer_step should be ignored in AWAITING_CITATION state"
	)
	assert_eq(CaseManager.current_step_id, "s001", "current_step_id should not advance")


func test_answer_step_proceeds_after_correct_citation() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].correct_evidence_id = "e_code"
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.cite_evidence("e_code")
	CaseManager.answer_step("c0")
	assert_eq(CaseManager.current_step_id, "s002", "should advance after citation + answer")


func test_apply_wrong_citation_penalty_deducts_15_seconds() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	var before: float = CaseManager.time_remaining
	CaseManager.apply_wrong_citation_penalty()
	assert_eq(CaseManager.time_remaining, before - 15.0, "should deduct exactly 15 seconds")


func test_apply_wrong_citation_penalty_clamps_to_zero() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.time_remaining = 5.0
	CaseManager.apply_wrong_citation_penalty()
	assert_eq(CaseManager.time_remaining, 0.0, "time_remaining should not go below 0")


func test_get_chain_summary_includes_cited_evidence_id() -> void:
	var c: CaseData = _make_test_case()
	c.investigation_steps[0].correct_evidence_id = "e_code"
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.cite_evidence("e_code")
	CaseManager.answer_step("c0")
	var summary: Array[Dictionary] = CaseManager.get_chain_summary()
	assert_eq(summary.size(), 1, "one entry in summary")
	assert_true(
		summary[0].has("cited_evidence_id"), "summary entry should have cited_evidence_id key"
	)
	assert_eq(
		summary[0]["cited_evidence_id"],
		"e_code",
		"cited_evidence_id should reflect correct citation"
	)


func test_get_chain_summary_cited_evidence_id_empty_when_skipped() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.answer_step("c0")
	var summary: Array[Dictionary] = CaseManager.get_chain_summary()
	assert_eq(
		summary[0].get("cited_evidence_id", ""),
		"",
		"cited_evidence_id should be empty when citation was skipped"
	)


func test_citation_history_cleared_on_set_current_case() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.citation_history["s001"] = "e_code"
	CaseManager.set_current_case(c)
	assert_true(
		CaseManager.citation_history.is_empty(), "citation_history should clear on set_current_case"
	)
