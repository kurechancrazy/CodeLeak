## CaseManager — ケース進行・タイマー・判決の管理
## process_mode = ALWAYS: get_tree().paused=true でもタイマーが動き続ける
extends Node

var current_case: CaseData = null
var read_evidence_ids: Array[String] = []
var selected_verdict: String = ""
var time_remaining: float = 0.0
var wrong_answer_count: int = 0
var current_step_id: String = ""
var step_id_history: Array[String] = []
var choice_history: Dictionary = {}
var resolved_issue_ids: Array[String] = []
var total_points: int = 0
var chain_complete: bool = false
var citation_history: Dictionary = {}
var _awaiting_citation: bool = false
var _wrong_citation_count: int = 0
var _timer_active: bool = false
var _paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.game_paused.connect(_on_game_paused)


func _on_game_paused(is_paused: bool) -> void:
	_paused = is_paused


func set_current_case(case_data: CaseData) -> void:
	current_case = case_data
	read_evidence_ids.clear()
	selected_verdict = ""
	time_remaining = 0.0
	wrong_answer_count = 0
	_timer_active = false
	current_step_id = ""
	step_id_history.clear()
	choice_history.clear()
	resolved_issue_ids.clear()
	total_points = 0
	chain_complete = false
	citation_history.clear()
	_awaiting_citation = false
	_wrong_citation_count = 0


func start_case() -> void:
	if current_case == null:
		return
	read_evidence_ids.clear()
	selected_verdict = ""
	wrong_answer_count = 0
	time_remaining = current_case.time_limit_seconds
	_paused = false
	_timer_active = true
	EventBus.case_started.emit(current_case)
	start_investigation()


func is_awaiting_citation() -> bool:
	return _awaiting_citation


func cite_evidence(evidence_id: String) -> void:
	if not _awaiting_citation or current_case == null:
		return
	var step: InvestigationStep = current_case.get_step_by_id(current_step_id)
	if step == null:
		return
	if evidence_id == step.correct_evidence_id:
		citation_history[current_step_id] = evidence_id
		_awaiting_citation = false
		EventBus.evidence_cited_correctly.emit(current_step_id, evidence_id)
	else:
		if _wrong_citation_count < 2:
			apply_wrong_citation_penalty()
		_wrong_citation_count += 1
		EventBus.evidence_cited_wrongly.emit(current_step_id, evidence_id)


func apply_wrong_citation_penalty() -> void:
	if current_case == null:
		return
	time_remaining = maxf(0.0, time_remaining - 15.0)
	EventBus.countdown_updated.emit(time_remaining)
	if time_remaining <= 0.0:
		if not chain_complete:
			chain_complete = true
			EventBus.investigation_chain_complete.emit(resolved_issue_ids)


func apply_wrong_answer_penalty() -> void:
	if current_case == null:
		return
	wrong_answer_count += 1
	time_remaining = maxf(0.0, time_remaining - current_case.wrong_answer_time_penalty)
	EventBus.countdown_updated.emit(time_remaining)
	if time_remaining <= 0.0:
		if not chain_complete:
			chain_complete = true
			EventBus.investigation_chain_complete.emit(resolved_issue_ids)


func mark_evidence_read(evidence_id: String) -> void:
	if evidence_id not in read_evidence_ids:
		read_evidence_ids.append(evidence_id)
		EventBus.evidence_read.emit(evidence_id)


func stop_timer() -> void:
	_timer_active = false


func resolve_case() -> void:
	if current_case == null:
		return
	EventBus.case_resolved.emit(current_case.case_id, selected_verdict, read_evidence_ids.size())


func get_unread_evidence() -> Array[EvidenceItem]:
	var unread: Array[EvidenceItem] = []
	if current_case == null:
		return unread
	for e: EvidenceItem in current_case.evidence:
		if e.evidence_id not in read_evidence_ids:
			unread.append(e)
	return unread


func get_alternate_hint(chosen_key: String) -> String:
	if current_case == null:
		return ""
	var alternates: Array[String] = []
	for o: OutcomeData in current_case.outcomes:
		if o.outcome_key != chosen_key:
			var hint: String = o.get_hint_for_replay()
			if not hint.is_empty():
				alternates.append(hint)
	if alternates.is_empty():
		return ""
	return alternates[randi() % alternates.size()]


func get_reached_outcome_count(case_id: String) -> int:
	var verdicts_json: String = SaveManager.get_value("progress", "case_verdicts", "{}")
	var parsed: Variant = JSON.parse_string(verdicts_json)
	if not parsed is Dictionary:
		return 0
	var verdicts: Dictionary = parsed
	var arr: Variant = verdicts.get(case_id, [])
	if not arr is Array:
		return 0
	return (arr as Array).size()


func start_investigation() -> void:
	if current_case == null:
		return
	current_step_id = current_case.entry_step_id
	step_id_history.clear()
	choice_history.clear()
	resolved_issue_ids.clear()
	total_points = 0
	chain_complete = false
	citation_history.clear()
	_wrong_citation_count = 0
	var entry_step: InvestigationStep = current_case.get_step_by_id(current_step_id)
	_awaiting_citation = entry_step != null and not entry_step.correct_evidence_id.is_empty()
	if entry_step != null and not entry_step.reveals_evidence_id.is_empty():
		EventBus.evidence_unlocked.emit(entry_step.reveals_evidence_id)
	EventBus.step_arrived.emit(current_step_id)


func answer_step(choice_key: String) -> void:
	if current_case == null or chain_complete or _awaiting_citation:
		return
	var step: InvestigationStep = current_case.get_step_by_id(current_step_id)
	if step == null:
		return
	var choice: StepChoice = step.get_choice_by_key(choice_key)
	if choice == null:
		return

	step_id_history.append(current_step_id)
	choice_history[current_step_id] = choice_key
	EventBus.step_answered.emit(current_step_id, choice_key)

	if not choice.resolves_issue_id.is_empty():
		if choice.resolves_issue_id not in resolved_issue_ids:
			resolved_issue_ids.append(choice.resolves_issue_id)
			EventBus.issue_resolved.emit(choice.resolves_issue_id)

	total_points += choice.points

	var next_step: InvestigationStep = null
	if not choice.is_terminal():
		next_step = current_case.get_step_by_id(choice.next_step_id)

	if next_step != null and not next_step.reveals_evidence_id.is_empty():
		EventBus.evidence_unlocked.emit(next_step.reveals_evidence_id)

	if choice.is_terminal():
		chain_complete = true
		_timer_active = false
		EventBus.investigation_chain_complete.emit(resolved_issue_ids)
	else:
		current_step_id = choice.next_step_id
		_awaiting_citation = (next_step != null and not next_step.correct_evidence_id.is_empty())
		_wrong_citation_count = 0
		EventBus.step_arrived.emit(current_step_id)


func determine_outcome() -> String:
	if current_case == null:
		return "insufficient"
	for rule: OutcomeRule in current_case.outcome_rules:
		if rule.matches(resolved_issue_ids, total_points):
			return rule.outcome_key
	return "insufficient"


func get_chain_summary() -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	if current_case == null:
		return summary
	for step_id: String in step_id_history:
		var chosen_key: String = choice_history.get(step_id, "")
		var step: InvestigationStep = current_case.get_step_by_id(step_id)
		var resolved_id: String = ""
		var points_earned: int = 0
		if not chosen_key.is_empty() and step != null:
			var choice: StepChoice = step.get_choice_by_key(chosen_key)
			if choice != null:
				resolved_id = choice.resolves_issue_id
				points_earned = choice.points
		(
			summary
			. append(
				{
					"step_id": step_id,
					"choice_key": chosen_key,
					"resolved_issue_id": resolved_id,
					"points_earned": points_earned,
					"timed_out": chosen_key.is_empty(),
					"cited_evidence_id": citation_history.get(step_id, ""),
				}
			)
		)
	return summary



func _tick(delta: float) -> void:
	if not _timer_active or _paused:
		return
	time_remaining -= delta
	EventBus.countdown_updated.emit(time_remaining)
	if time_remaining <= 0.0:
		time_remaining = 0.0
		if not chain_complete:
			chain_complete = true
			EventBus.investigation_chain_complete.emit(resolved_issue_ids)


func _process(delta: float) -> void:
	_tick(delta)


func _exit_tree() -> void:
	EventBus.game_paused.disconnect(_on_game_paused)
