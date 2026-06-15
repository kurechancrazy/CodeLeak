class_name EvidenceItem
extends Resource

@export var evidence_id: String = ""
@export var type: String = ""  # CODE / LOG / EMAIL / NETWORK
@export var title: String = ""
@export var title_ja: String = ""
@export_multiline var content: String = ""
@export_multiline var content_ja: String = ""
@export var supports_verdict: String = ""  # outcome_key this evidence hints at, empty = neutral

func get_title() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not title_ja.is_empty():
		return title_ja
	return title

func get_content() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not content_ja.is_empty():
		return content_ja
	return content
