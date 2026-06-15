class_name OutcomeData
extends Resource

@export var outcome_key: String = ""
@export_multiline var narrative: String = ""
@export_multiline var narrative_ja: String = ""
@export_multiline var hint_for_replay: String = ""
@export_multiline var hint_for_replay_ja: String = ""

func get_narrative() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not narrative_ja.is_empty():
		return narrative_ja
	return narrative

func get_hint_for_replay() -> String:
	if TranslationServer.get_locale().begins_with("ja") and not hint_for_replay_ja.is_empty():
		return hint_for_replay_ja
	return hint_for_replay
