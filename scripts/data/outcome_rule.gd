class_name OutcomeRule
extends Resource

@export var min_resolved_count: int = 0
@export var min_points: int = 0
@export var required_issue_ids: Array[String] = []
@export var outcome_key: String = ""


func matches(resolved_ids: Array[String], total_points: int) -> bool:
	if total_points < min_points:
		return false
	if resolved_ids.size() < min_resolved_count:
		return false
	for required_id: String in required_issue_ids:
		if not resolved_ids.has(required_id):
			return false
	return true
