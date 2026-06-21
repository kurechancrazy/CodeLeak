class_name CaseIssue
extends Resource

@export var issue_id: String = ""
@export var description: String = ""
@export var description_ja: String = ""


func get_description() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not description_ja.is_empty():
		return description_ja
	return description
