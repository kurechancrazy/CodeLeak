extends GutTest


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_get_label_returns_english_by_default() -> void:
	var sc: StepChoice = StepChoice.new()
	sc.label = "Option A"
	sc.label_ja = "選択肢A"
	TranslationServer.set_locale("en")
	assert_eq(sc.get_label(), "Option A", "should return English label by default")


func test_get_label_returns_japanese_when_locale_ja() -> void:
	var sc: StepChoice = StepChoice.new()
	sc.label = "Option A"
	sc.label_ja = "選択肢A"
	TranslationServer.set_locale("ja")
	assert_eq(sc.get_label(), "選択肢A", "should return Japanese label when locale is ja")


func test_get_label_falls_back_to_english_when_label_ja_empty() -> void:
	var sc: StepChoice = StepChoice.new()
	sc.label = "Option A"
	sc.label_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(sc.get_label(), "Option A", "should fall back to English when label_ja is empty")


func test_is_terminal_returns_true_when_next_step_id_empty() -> void:
	var sc: StepChoice = StepChoice.new()
	sc.next_step_id = ""
	assert_true(sc.is_terminal(), "should return true when next_step_id is empty")


func test_is_terminal_returns_false_when_next_step_id_not_empty() -> void:
	var sc: StepChoice = StepChoice.new()
	sc.next_step_id = "step_02"
	assert_false(sc.is_terminal(), "should return false when next_step_id is non-empty")
