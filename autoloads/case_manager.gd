## CaseManager — ケース進行・タイマー・判決の管理
## process_mode = ALWAYS: get_tree().paused=true でもタイマーが動き続ける
extends Node

var current_case: CaseData = null
var read_evidence_ids: Array[String] = []
var selected_verdict: String = ""
var time_remaining: float = 0.0
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
	_timer_active = false


func start_case() -> void:
	if current_case == null:
		return
	read_evidence_ids.clear()
	selected_verdict = ""
	time_remaining = current_case.time_limit_seconds
	_paused = false
	_timer_active = true
	EventBus.case_started.emit(current_case)


func mark_evidence_read(evidence_id: String) -> void:
	if evidence_id not in read_evidence_ids:
		read_evidence_ids.append(evidence_id)
		EventBus.evidence_read.emit(evidence_id)


func submit_verdict(outcome_key: String) -> void:
	if not selected_verdict.is_empty():
		return
	selected_verdict = outcome_key
	_timer_active = false
	EventBus.verdict_submitted.emit(outcome_key)


func stop_timer() -> void:
	_timer_active = false


func resolve_case() -> void:
	if current_case == null:
		return
	EventBus.case_resolved.emit(
		current_case.case_id,
		selected_verdict,
		read_evidence_ids.size()
	)


func get_unread_evidence() -> Array[EvidenceItem]:
	var unread: Array[EvidenceItem] = []
	if current_case == null:
		return unread
	for e: EvidenceItem in current_case.evidence:
		if e.evidence_id not in read_evidence_ids:
			unread.append(e)
	return unread


func get_verdict_options() -> Array[VerdictChoice]:
	var options: Array[VerdictChoice] = []
	if current_case == null:
		return options
	for vc: VerdictChoice in current_case.verdict_choices:
		options.append(vc)
	var insufficient: VerdictChoice = VerdictChoice.new()
	insufficient.label = "Insufficient Evidence"
	insufficient.label_ja = "証拠不十分"
	insufficient.outcome_key = "insufficient"
	options.append(insufficient)
	return options


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


func _tick(delta: float) -> void:
	if not _timer_active or _paused:
		return
	time_remaining -= delta
	EventBus.countdown_updated.emit(time_remaining)
	if time_remaining <= 0.0:
		time_remaining = 0.0
		submit_verdict("insufficient")


func _process(delta: float) -> void:
	_tick(delta)


func _exit_tree() -> void:
	EventBus.game_paused.disconnect(_on_game_paused)
