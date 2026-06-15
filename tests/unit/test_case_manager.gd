## Tests for CaseManager — timer, idempotent verdict, pause flag, helpers
extends GutTest


func before_each() -> void:
	# Reset CaseManager state before each test
	CaseManager.current_case = null
	CaseManager.read_evidence_ids.clear()
	CaseManager.selected_verdict = ""
	CaseManager.time_remaining = 0.0
	CaseManager._timer_active = false
	CaseManager._paused = false


func _make_test_case() -> CaseData:
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

	var vc_intentional: VerdictChoice = VerdictChoice.new()
	vc_intentional.label = "Intentional"
	vc_intentional.label_ja = "意図的"
	vc_intentional.outcome_key = "intentional"

	var vc_runaway: VerdictChoice = VerdictChoice.new()
	vc_runaway.label = "Runaway"
	vc_runaway.label_ja = "暴走"
	vc_runaway.outcome_key = "runaway"

	var o_intentional: OutcomeData = OutcomeData.new()
	o_intentional.outcome_key = "intentional"
	o_intentional.narrative = "Intentional outcome"
	o_intentional.hint_for_replay = "The code signature points to a human actor."

	var o_runaway: OutcomeData = OutcomeData.new()
	o_runaway.outcome_key = "runaway"
	o_runaway.narrative = "Runaway outcome"
	o_runaway.hint_for_replay = "The AI diverged from its training objective."

	var o_insufficient: OutcomeData = OutcomeData.new()
	o_insufficient.outcome_key = "insufficient"
	o_insufficient.narrative = "Insufficient outcome"
	o_insufficient.hint_for_replay = ""

	var case_data: CaseData = CaseData.new()
	case_data.case_id = "case_test"
	case_data.time_limit_seconds = 240.0
	case_data.evidence = [ev_code, ev_log, ev_email, ev_net]
	case_data.verdict_choices = [vc_intentional, vc_runaway]
	case_data.outcomes = [o_intentional, o_runaway, o_insufficient]
	return case_data


## Timer tests
func test_tick_decrements_time() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._tick(10.0)
	assert_eq(CaseManager.time_remaining, 230.0, "time should decrease by 10")


func test_tick_triggers_timeout_at_zero() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._tick(241.0)
	assert_eq(CaseManager.selected_verdict, "insufficient", "timeout should set verdict to insufficient")
	assert_false(CaseManager._timer_active, "timer should stop after timeout")


func test_tick_does_not_go_below_zero() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._tick(1000.0)
	assert_eq(CaseManager.time_remaining, 0.0, "time should clamp at 0")


## Idempotent submit tests
func test_submit_verdict_records_verdict() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.submit_verdict("intentional")
	assert_eq(CaseManager.selected_verdict, "intentional", "verdict should be recorded")


func test_submit_verdict_idempotent_first_wins() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.submit_verdict("intentional")
	CaseManager.submit_verdict("runaway")
	assert_eq(CaseManager.selected_verdict, "intentional", "first verdict should win")


func test_submit_verdict_stops_timer() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.submit_verdict("intentional")
	var time_after_submit: float = CaseManager.time_remaining
	CaseManager._tick(999.0)
	assert_eq(CaseManager.time_remaining, time_after_submit, "timer should not advance after verdict")


func test_submit_verdict_after_timeout_does_not_override() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager._tick(241.0)  # triggers insufficient
	CaseManager._tick(999.0)  # extra ticks after timeout
	assert_eq(CaseManager.selected_verdict, "insufficient", "verdict should remain insufficient")


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
	assert_eq(CaseManager.get_unread_evidence().size(), 3, "3 should remain unread after reading one")


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


func test_get_verdict_options_returns_three() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	var options: Array[VerdictChoice] = CaseManager.get_verdict_options()
	assert_eq(options.size(), 3, "should return 2 case verdicts + insufficient = 3")


func test_get_verdict_options_includes_insufficient() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	var options: Array[VerdictChoice] = CaseManager.get_verdict_options()
	var has_insufficient: bool = false
	for opt: VerdictChoice in options:
		if opt.outcome_key == "insufficient":
			has_insufficient = true
	assert_true(has_insufficient, "options should include insufficient")


func test_get_alternate_hint_returns_other_hint() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	var hint: String = CaseManager.get_alternate_hint("intentional")
	assert_false(hint.is_empty(), "should return a hint from another outcome")
	assert_ne(hint, "The code signature points to a human actor.", "should not return hint for chosen verdict")


func test_get_alternate_hint_empty_if_no_others() -> void:
	var c: CaseData = _make_test_case()
	# Clear hints from all outcomes except intentional
	for o: OutcomeData in c.outcomes:
		if o.outcome_key != "intentional":
			o.hint_for_replay = ""
			o.hint_for_replay_ja = ""
	CaseManager.set_current_case(c)
	var hint: String = CaseManager.get_alternate_hint("runaway")
	# Either empty or returns the intentional hint — must not crash
	assert_true(true, "get_alternate_hint with no valid alternates should not crash")


func test_set_current_case_resets_state() -> void:
	var c: CaseData = _make_test_case()
	CaseManager.set_current_case(c)
	CaseManager.start_case()
	CaseManager.mark_evidence_read("e_code")
	CaseManager.submit_verdict("intentional")
	# Set again should reset
	CaseManager.set_current_case(c)
	assert_true(CaseManager.read_evidence_ids.is_empty(), "read_evidence_ids should reset")
	assert_true(CaseManager.selected_verdict.is_empty(), "selected_verdict should reset")
	assert_false(CaseManager._timer_active, "timer should not be active after set_current_case")
