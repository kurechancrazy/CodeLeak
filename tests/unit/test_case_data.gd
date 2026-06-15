extends GutTest


func after_each() -> void:
	TranslationServer.set_locale("en")


# --- EvidenceItem ---

func test_evidence_get_title_returns_english_by_default() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.title = "Leaked Token"
	ev.title_ja = "漏洩トークン"
	TranslationServer.set_locale("en")
	assert_eq(ev.get_title(), "Leaked Token", "should return English title by default")


func test_evidence_get_title_returns_japanese_when_locale_ja() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.title = "Leaked Token"
	ev.title_ja = "漏洩トークン"
	TranslationServer.set_locale("ja")
	assert_eq(ev.get_title(), "漏洩トークン", "should return Japanese title when locale is ja")


func test_evidence_get_title_returns_english_when_title_ja_empty() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.title = "Leaked Token"
	ev.title_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(ev.get_title(), "Leaked Token", "should fall back to English when title_ja is empty")


func test_evidence_get_content_returns_english_by_default() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.content = "API key exposed"
	ev.content_ja = "APIキーが露出"
	TranslationServer.set_locale("en")
	assert_eq(ev.get_content(), "API key exposed", "should return English content by default")


func test_evidence_get_content_returns_japanese_when_locale_ja() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.content = "API key exposed"
	ev.content_ja = "APIキーが露出"
	TranslationServer.set_locale("ja")
	assert_eq(ev.get_content(), "APIキーが露出", "should return Japanese content when locale is ja")


func test_evidence_get_content_returns_english_when_content_ja_empty() -> void:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.content = "API key exposed"
	ev.content_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(ev.get_content(), "API key exposed", "should fall back to English when content_ja is empty")


# --- VerdictChoice ---

func test_verdict_get_label_returns_english_by_default() -> void:
	var vc: VerdictChoice = VerdictChoice.new()
	vc.label = "Accuse insider"
	vc.label_ja = "内部犯を告発"
	TranslationServer.set_locale("en")
	assert_eq(vc.get_label(), "Accuse insider", "should return English label by default")


func test_verdict_get_label_returns_japanese_when_locale_ja() -> void:
	var vc: VerdictChoice = VerdictChoice.new()
	vc.label = "Accuse insider"
	vc.label_ja = "内部犯を告発"
	TranslationServer.set_locale("ja")
	assert_eq(vc.get_label(), "内部犯を告発", "should return Japanese label when locale is ja")


func test_verdict_get_label_returns_english_when_label_ja_empty() -> void:
	var vc: VerdictChoice = VerdictChoice.new()
	vc.label = "Accuse insider"
	vc.label_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(vc.get_label(), "Accuse insider", "should fall back to English when label_ja is empty")


# --- OutcomeData ---

func test_outcome_get_narrative_returns_english_by_default() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.narrative = "The insider was arrested."
	od.narrative_ja = "内部犯が逮捕された。"
	TranslationServer.set_locale("en")
	assert_eq(od.get_narrative(), "The insider was arrested.", "should return English narrative by default")


func test_outcome_get_narrative_returns_japanese_when_locale_ja() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.narrative = "The insider was arrested."
	od.narrative_ja = "内部犯が逮捕された。"
	TranslationServer.set_locale("ja")
	assert_eq(od.get_narrative(), "内部犯が逮捕された。", "should return Japanese narrative when locale is ja")


func test_outcome_get_narrative_returns_english_when_narrative_ja_empty() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.narrative = "The insider was arrested."
	od.narrative_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(od.get_narrative(), "The insider was arrested.", "should fall back to English when narrative_ja is empty")


func test_outcome_get_hint_returns_english_by_default() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.hint_for_replay = "Check the network logs."
	od.hint_for_replay_ja = "ネットワークログを確認して。"
	TranslationServer.set_locale("en")
	assert_eq(od.get_hint_for_replay(), "Check the network logs.", "should return English hint by default")


func test_outcome_get_hint_returns_japanese_when_locale_ja() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.hint_for_replay = "Check the network logs."
	od.hint_for_replay_ja = "ネットワークログを確認して。"
	TranslationServer.set_locale("ja")
	assert_eq(od.get_hint_for_replay(), "ネットワークログを確認して。", "should return Japanese hint when locale is ja")


func test_outcome_get_hint_returns_english_when_hint_ja_empty() -> void:
	var od: OutcomeData = OutcomeData.new()
	od.hint_for_replay = "Check the network logs."
	od.hint_for_replay_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(od.get_hint_for_replay(), "Check the network logs.", "should fall back to English when hint_for_replay_ja is empty")


# --- CaseData getters ---

func test_case_get_ai_name_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.ai_name = "ARIA"
	cd.ai_name_ja = "アリア"
	TranslationServer.set_locale("en")
	assert_eq(cd.get_ai_name(), "ARIA", "should return English ai_name by default")


func test_case_get_ai_name_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.ai_name = "ARIA"
	cd.ai_name_ja = "アリア"
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_ai_name(), "アリア", "should return Japanese ai_name when locale is ja")


func test_case_get_ai_name_returns_english_when_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.ai_name = "ARIA"
	cd.ai_name_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_ai_name(), "ARIA", "should fall back to English when ai_name_ja is empty")


func test_case_get_briefing_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.briefing = "Investigate the breach."
	cd.briefing_ja = "侵害を調査せよ。"
	TranslationServer.set_locale("en")
	assert_eq(cd.get_briefing(), "Investigate the breach.", "should return English briefing by default")


func test_case_get_briefing_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.briefing = "Investigate the breach."
	cd.briefing_ja = "侵害を調査せよ。"
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_briefing(), "侵害を調査せよ。", "should return Japanese briefing when locale is ja")


func test_case_get_briefing_returns_english_when_briefing_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.briefing = "Investigate the breach."
	cd.briefing_ja = ""
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_briefing(), "Investigate the breach.", "should fall back to English when briefing_ja is empty")


func test_case_get_suspects_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.suspects = ["Alice", "Bob"]
	cd.suspects_ja = ["アリス", "ボブ"]
	TranslationServer.set_locale("en")
	assert_eq(cd.get_suspects(), ["Alice", "Bob"], "should return English suspects by default")


func test_case_get_suspects_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.suspects = ["Alice", "Bob"]
	cd.suspects_ja = ["アリス", "ボブ"]
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_suspects(), ["アリス", "ボブ"], "should return Japanese suspects when locale is ja")


func test_case_get_suspects_returns_english_when_suspects_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.suspects = ["Alice", "Bob"]
	cd.suspects_ja = []
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_suspects(), ["Alice", "Bob"], "should fall back to English when suspects_ja is empty")


func test_case_get_victims_returns_english_by_default() -> void:
	var cd: CaseData = CaseData.new()
	cd.victims = ["Corp X"]
	cd.victims_ja = ["X社"]
	TranslationServer.set_locale("en")
	assert_eq(cd.get_victims(), ["Corp X"], "should return English victims by default")


func test_case_get_victims_returns_japanese_when_locale_ja() -> void:
	var cd: CaseData = CaseData.new()
	cd.victims = ["Corp X"]
	cd.victims_ja = ["X社"]
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_victims(), ["X社"], "should return Japanese victims when locale is ja")


func test_case_get_victims_returns_english_when_victims_ja_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.victims = ["Corp X"]
	cd.victims_ja = []
	TranslationServer.set_locale("ja")
	assert_eq(cd.get_victims(), ["Corp X"], "should fall back to English when victims_ja is empty")


# --- CaseData.get_outcome() ---

func _make_outcome(key: String) -> OutcomeData:
	var od: OutcomeData = OutcomeData.new()
	od.outcome_key = key
	return od


func test_get_outcome_returns_matching_outcome_data() -> void:
	var cd: CaseData = CaseData.new()
	cd.outcomes.append(_make_outcome("insider"))
	cd.outcomes.append(_make_outcome("insufficient"))
	var result: OutcomeData = cd.get_outcome("insider")
	assert_not_null(result, "should return the matching OutcomeData")
	assert_eq(result.outcome_key, "insider", "returned outcome should have the correct key")


func test_get_outcome_returns_null_when_key_not_found() -> void:
	var cd: CaseData = CaseData.new()
	cd.outcomes.append(_make_outcome("insider"))
	var result: OutcomeData = cd.get_outcome("external_hack")
	assert_null(result, "should return null when key does not match any outcome")


func test_get_outcome_returns_null_on_empty_outcomes() -> void:
	var cd: CaseData = CaseData.new()
	var result: OutcomeData = cd.get_outcome("anything")
	assert_null(result, "should return null when outcomes array is empty")


# --- CaseData.validate() helpers ---

func _make_evidence(type: String) -> EvidenceItem:
	var ev: EvidenceItem = EvidenceItem.new()
	ev.type = type
	return ev


func _make_verdict(key: String) -> VerdictChoice:
	var vc: VerdictChoice = VerdictChoice.new()
	vc.outcome_key = key
	return vc


func _make_valid_case() -> CaseData:
	var cd: CaseData = CaseData.new()
	cd.evidence.append(_make_evidence("CODE"))
	cd.evidence.append(_make_evidence("LOG"))
	cd.evidence.append(_make_evidence("EMAIL"))
	cd.evidence.append(_make_evidence("NETWORK"))
	cd.verdict_choices.append(_make_verdict("insider"))
	cd.outcomes.append(_make_outcome("insider"))
	cd.outcomes.append(_make_outcome("insufficient"))
	return cd


# --- CaseData.validate() tests ---

func test_validate_returns_empty_for_valid_case() -> void:
	var cd: CaseData = _make_valid_case()
	var errors: Array[String] = cd.validate()
	assert_eq(errors.size(), 0, "valid case should produce no errors")


func test_validate_error_when_evidence_count_not_4() -> void:
	var cd: CaseData = _make_valid_case()
	cd.evidence.remove_at(0)
	var errors: Array[String] = cd.validate()
	assert_true(errors.size() > 0, "should report error for wrong evidence count")
	var found: bool = false
	for err: String in errors:
		if "evidence count" in err:
			found = true
	assert_true(found, "error should mention evidence count")


func test_validate_error_when_evidence_type_missing() -> void:
	var cd: CaseData = CaseData.new()
	cd.evidence.append(_make_evidence("CODE"))
	cd.evidence.append(_make_evidence("LOG"))
	cd.evidence.append(_make_evidence("NETWORK"))
	cd.evidence.append(_make_evidence("NETWORK"))
	cd.verdict_choices.append(_make_verdict("insider"))
	cd.outcomes.append(_make_outcome("insider"))
	cd.outcomes.append(_make_outcome("insufficient"))
	var errors: Array[String] = cd.validate()
	var found: bool = false
	for err: String in errors:
		if "EMAIL" in err:
			found = true
	assert_true(found, "error should mention missing EMAIL type")


func test_validate_error_when_verdict_choices_empty() -> void:
	var cd: CaseData = CaseData.new()
	cd.evidence.append(_make_evidence("CODE"))
	cd.evidence.append(_make_evidence("LOG"))
	cd.evidence.append(_make_evidence("EMAIL"))
	cd.evidence.append(_make_evidence("NETWORK"))
	cd.outcomes.append(_make_outcome("insufficient"))
	var errors: Array[String] = cd.validate()
	var found: bool = false
	for err: String in errors:
		if "verdict_choices" in err:
			found = true
	assert_true(found, "error should mention empty verdict_choices")


func test_validate_error_when_outcome_key_missing_for_verdict_choice() -> void:
	var cd: CaseData = CaseData.new()
	cd.evidence.append(_make_evidence("CODE"))
	cd.evidence.append(_make_evidence("LOG"))
	cd.evidence.append(_make_evidence("EMAIL"))
	cd.evidence.append(_make_evidence("NETWORK"))
	cd.verdict_choices.append(_make_verdict("insider"))
	cd.outcomes.append(_make_outcome("insufficient"))
	# "insider" outcome is deliberately missing
	var errors: Array[String] = cd.validate()
	var found: bool = false
	for err: String in errors:
		if "insider" in err:
			found = true
	assert_true(found, "error should mention missing outcome for insider key")


func test_validate_error_when_insufficient_outcome_missing() -> void:
	var cd: CaseData = _make_valid_case()
	cd.outcomes.clear()
	cd.outcomes.append(_make_outcome("insider"))
	# "insufficient" is deliberately absent
	var errors: Array[String] = cd.validate()
	var found: bool = false
	for err: String in errors:
		if "insufficient" in err:
			found = true
	assert_true(found, "error should mention missing insufficient outcome")


func test_validate_error_when_outcome_key_duplicated() -> void:
	var cd: CaseData = _make_valid_case()
	cd.outcomes.append(_make_outcome("insider"))
	# "insider" now appears twice
	var errors: Array[String] = cd.validate()
	var found: bool = false
	for err: String in errors:
		if "duplicate" in err and "insider" in err:
			found = true
	assert_true(found, "error should mention duplicate outcome_key")
