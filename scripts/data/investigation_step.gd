class_name InvestigationStep
extends Resource

const VALID_QUESTION_TYPES: Array[String] = ["CODE", "LOG", "NETWORK", "DEDUCTION"]

@export var step_id: String = ""
@export var question: String = ""
@export var question_ja: String = ""
@export var question_type: String = "DEDUCTION"
@export var display_as_code: bool = false
@export var choices: Array[StepChoice] = []
@export var reveals_evidence_id: String = ""
@export var correct_evidence_id: String = ""


func get_question() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not question_ja.is_empty():
		return question_ja
	return question


func get_choice_by_key(key: String) -> StepChoice:
	for choice: StepChoice in choices:
		if choice.choice_key == key:
			return choice
	return null


func validate() -> Array[String]:
	var errors: Array[String] = []
	if step_id.is_empty():
		errors.append("step_id must not be empty")
	if choices.size() != 7:
		errors.append("choices count must be 7, got %d" % choices.size())
	if question.is_empty():
		errors.append("question must not be empty")
	if not VALID_QUESTION_TYPES.has(question_type):
		errors.append("invalid question_type: %s" % question_type)
	return errors
