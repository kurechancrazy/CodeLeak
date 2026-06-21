class_name CaseData
extends Resource

@export var case_id: String = ""
@export var ai_name: String = ""
@export var ai_name_ja: String = ""
@export var threat_level: String = "MED"  # LOW / MED / HIGH / CRITICAL
@export_multiline var briefing: String = ""
@export_multiline var briefing_ja: String = ""
@export var suspects: Array[String] = []
@export var suspects_ja: Array[String] = []
@export var victims: Array[String] = []
@export var victims_ja: Array[String] = []
@export var evidence: Array[EvidenceItem] = []
@export var outcomes: Array[OutcomeData] = []
@export var time_limit_seconds: float = 240.0
@export var wrong_answer_time_penalty: float = 45.0
@export var entry_step_id: String = ""
@export var investigation_steps: Array[InvestigationStep] = []
@export var resolvable_issues: Array[CaseIssue] = []
@export var outcome_rules: Array[OutcomeRule] = []

func get_ai_name() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not ai_name_ja.is_empty():
		return ai_name_ja
	return ai_name

func get_briefing() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not briefing_ja.is_empty():
		return briefing_ja
	return briefing

func get_suspects() -> Array[String]:
	if TranslationServer.get_locale().begins_with("ja") and not suspects_ja.is_empty():
		return suspects_ja
	return suspects

func get_victims() -> Array[String]:
	if TranslationServer.get_locale().begins_with("ja") and not victims_ja.is_empty():
		return victims_ja
	return victims

func get_outcome(key: String) -> OutcomeData:
	for o: OutcomeData in outcomes:
		if o.outcome_key == key:
			return o
	return null

func get_step_by_id(step_id: String) -> InvestigationStep:
	for step: InvestigationStep in investigation_steps:
		if step.step_id == step_id:
			return step
	return null


func get_issue_by_id(issue_id: String) -> CaseIssue:
	for issue: CaseIssue in resolvable_issues:
		if issue.issue_id == issue_id:
			return issue
	return null

func validate() -> Array[String]:
	var errors: Array[String] = []

	# 1. entry_step_id
	if entry_step_id.is_empty():
		errors.append("entry_step_id must not be empty")
	else:
		var found_entry: bool = false
		for step: InvestigationStep in investigation_steps:
			if step.step_id == entry_step_id:
				found_entry = true
				break
		if not found_entry:
			errors.append("entry_step_id '%s' not found in investigation_steps" % entry_step_id)

	# 2. 全ステップの choices が7件
	for step: InvestigationStep in investigation_steps:
		var step_errors: Array[String] = step.validate()
		for e: String in step_errors:
			errors.append("step '%s': %s" % [step.step_id, e])

	# 3. 全 outcome_rules の outcome_key が outcomes に存在する
	var outcome_keys: Array[String] = []
	for o: OutcomeData in outcomes:
		outcome_keys.append(o.outcome_key)
	for rule: OutcomeRule in outcome_rules:
		if rule.outcome_key not in outcome_keys:
			errors.append("outcome_rule references missing outcome_key: %s" % rule.outcome_key)

	# 4. "insufficient" アウトカムが存在する
	if "insufficient" not in outcome_keys:
		errors.append("missing outcome for key: insufficient")

	return errors
