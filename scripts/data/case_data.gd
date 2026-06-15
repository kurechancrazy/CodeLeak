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
@export var verdict_choices: Array[VerdictChoice] = []
@export var outcomes: Array[OutcomeData] = []
@export var time_limit_seconds: float = 240.0

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

func validate() -> Array[String]:
	var errors: Array[String] = []

	if evidence.size() != 4:
		errors.append("evidence count must be 4, got %d" % evidence.size())

	var required_types: Array[String] = ["CODE", "LOG", "EMAIL", "NETWORK"]
	var found_types: Array[String] = []
	for e: EvidenceItem in evidence:
		if e.type not in found_types:
			found_types.append(e.type)
	for t: String in required_types:
		if t not in found_types:
			errors.append("missing evidence type: %s" % t)

	if verdict_choices.is_empty():
		errors.append("verdict_choices must not be empty")

	var expected_keys: Array[String] = ["insufficient"]
	for vc: VerdictChoice in verdict_choices:
		if vc.outcome_key not in expected_keys:
			expected_keys.append(vc.outcome_key)

	var found_keys: Array[String] = []
	for o: OutcomeData in outcomes:
		if o.outcome_key in found_keys:
			errors.append("duplicate outcome_key: %s" % o.outcome_key)
		else:
			found_keys.append(o.outcome_key)

	for k: String in expected_keys:
		if k not in found_keys:
			errors.append("missing outcome for key: %s" % k)

	return errors
