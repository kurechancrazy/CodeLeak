extends GutTest


func after_each() -> void:
	TranslationServer.set_locale("en")


func _make_choice(key: String) -> StepChoice:
	var sc: StepChoice = StepChoice.new()
	sc.choice_key = key
	sc.label = "Choice " + key
	return sc


func _make_valid_step() -> InvestigationStep:
	var step: InvestigationStep = InvestigationStep.new()
	step.step_id = "step_01"
	step.question = "What happened?"
	step.question_ja = "何が起きた？"
	step.question_type = "DEDUCTION"
	for i: int in range(7):
		step.choices.append(_make_choice("c%d" % i))
	return step


# --- get_question() locale tests ---

func test_get_question_returns_english_by_default() -> void:
	var step: InvestigationStep = _make_valid_step()
	TranslationServer.set_locale("en")
	assert_eq(step.get_question(), "What happened?", "should return English question by default")


func test_get_question_returns_japanese_when_locale_ja() -> void:
	var step: InvestigationStep = _make_valid_step()
	TranslationServer.set_locale("ja")
	assert_eq(step.get_question(), "何が起きた？", "should return Japanese question when locale is ja")


func test_get_question_falls_back_to_english_when_question_ja_empty() -> void:
	var step: InvestigationStep = _make_valid_step()
	step.question_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(
		step.get_question(),
		"What happened?",
		"should fall back to English when question_ja is empty"
	)


# --- get_choice_by_key() tests ---

func test_get_choice_by_key_returns_correct_choice() -> void:
	var step: InvestigationStep = _make_valid_step()
	var result: StepChoice = step.get_choice_by_key("c3")
	assert_not_null(result, "should return a StepChoice for an existing key")
	assert_eq(result.choice_key, "c3", "returned choice should have the correct key")


func test_get_choice_by_key_returns_null_for_missing_key() -> void:
	var step: InvestigationStep = _make_valid_step()
	var result: StepChoice = step.get_choice_by_key("nonexistent")
	assert_null(result, "should return null for a key that does not exist")


# --- validate() tests ---

func test_validate_returns_empty_for_valid_step() -> void:
	var step: InvestigationStep = _make_valid_step()
	var errors: Array[String] = step.validate()
	assert_eq(errors.size(), 0, "valid step should produce no errors")


func test_validate_error_when_choices_count_not_7() -> void:
	var step: InvestigationStep = _make_valid_step()
	step.choices.clear()
	var errors: Array[String] = step.validate()
	assert_true(errors.size() > 0, "should report error when choices count is not 7")
	var found: bool = false
	for err: String in errors:
		if "choices count" in err:
			found = true
	assert_true(found, "error should mention choices count")


func test_validate_error_when_step_id_empty() -> void:
	var step: InvestigationStep = _make_valid_step()
	step.step_id = ""
	var errors: Array[String] = step.validate()
	assert_true(errors.size() > 0, "should report error when step_id is empty")
	var found: bool = false
	for err: String in errors:
		if "step_id" in err:
			found = true
	assert_true(found, "error should mention step_id")


func test_validate_error_when_question_empty() -> void:
	var step: InvestigationStep = _make_valid_step()
	step.question = ""
	var errors: Array[String] = step.validate()
	assert_true(errors.size() > 0, "should report error when question is empty")
	var found: bool = false
	for err: String in errors:
		if "question" in err:
			found = true
	assert_true(found, "error should mention question")


func test_validate_error_when_question_type_invalid() -> void:
	var step: InvestigationStep = _make_valid_step()
	step.question_type = "INVALID"
	var errors: Array[String] = step.validate()
	assert_true(errors.size() > 0, "should report error for invalid question_type")
	var found: bool = false
	for err: String in errors:
		if "question_type" in err:
			found = true
	assert_true(found, "error should mention question_type")


func test_validate_accepts_all_valid_question_types() -> void:
	for qtype: String in ["CODE", "LOG", "NETWORK", "DEDUCTION"]:
		var step: InvestigationStep = _make_valid_step()
		step.question_type = qtype
		var errors: Array[String] = step.validate()
		var type_error: bool = false
		for err: String in errors:
			if "question_type" in err:
				type_error = true
		assert_false(type_error, "question_type '%s' should be valid" % qtype)
