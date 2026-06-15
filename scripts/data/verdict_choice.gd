class_name VerdictChoice
extends Resource

@export var label: String = ""
@export var label_ja: String = ""
@export var outcome_key: String = ""

func get_label() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not label_ja.is_empty():
		return label_ja
	return label
