class_name StepChoice
extends Resource

@export var choice_key: String = ""
@export var label: String = ""
@export var label_ja: String = ""
@export var next_step_id: String = ""
@export var resolves_issue_id: String = ""
@export var points: int = 0


func get_label() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not label_ja.is_empty():
		return label_ja
	return label


func is_terminal() -> bool:
	return next_step_id.is_empty()
