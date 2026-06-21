## OutcomeScreen — 結末ナラティブ・コレクショントラッカー・シェア
extends MarginContainer

const _TYPEWRITER_SPEED: float = 0.025

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_BG: Color = Color.html("#0d0d0d")
var _COLOR_DIM: Color = Color.html("#555555")

var _narrative_label: Label
var _share_label: Label
var _full_narrative: String = ""
var _displayed_chars: int = 0
var _typewriter_active: bool = false
var _typewriter_timer: float = 0.0
var _content_built: bool = false


func _ready() -> void:
	var case_data: CaseData = CaseManager.current_case
	var key: String = CaseManager.selected_verdict
	if case_data == null or key.is_empty():
		EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")
		return
	GameManager.transition_to(GameManager.GameState.OUTCOME)
	EventBus.settings_changed.connect(_on_settings_changed)

	# MUST resolve (save) before reading X/3
	CaseManager.resolve_case()

	_build_layout(case_data, key)


func _build_layout(case_data: CaseData, verdict_key: String) -> void:
	for child: Node in get_children():
		child.queue_free()
	_content_built = false

	var bg: ColorRect = ColorRect.new()
	bg.color = _COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var outer_vbox: VBoxContainer = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(outer_vbox)

	var title: Label = Label.new()
	title.text = tr("OUTCOME_TITLE")
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 32)
	outer_vbox.add_child(title)

	# ISSUES RESOLVED / スコア表示
	var resolved_count: int = CaseManager.resolved_issue_ids.size()
	var total_issues: int = case_data.resolvable_issues.size()
	var verdict_label_text: String = "%d / %d" % [resolved_count, total_issues]

	var verdict_row: Label = Label.new()
	verdict_row.text = "ISSUES RESOLVED: %s" % verdict_label_text
	verdict_row.add_theme_color_override("font_color", _COLOR_DIM)
	verdict_row.add_theme_font_size_override("font_size", 18)
	outer_vbox.add_child(verdict_row)

	var score_row: Label = Label.new()
	score_row.text = tr("OUTCOME_SCORE") % CaseManager.total_points
	score_row.add_theme_color_override("font_color", _COLOR_TEXT)
	score_row.add_theme_font_size_override("font_size", 18)
	outer_vbox.add_child(score_row)

	var sep: HSeparator = HSeparator.new()
	outer_vbox.add_child(sep)

	# Narrative — scrollable, typewriter
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	_narrative_label = Label.new()
	_narrative_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_narrative_label.add_theme_font_size_override("font_size", 16)
	_narrative_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narrative_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_narrative_label)

	# Unread evidence
	var unread: Array[EvidenceItem] = CaseManager.get_unread_evidence()
	if unread.is_empty():
		var all_read_label: Label = Label.new()
		all_read_label.text = tr("OUTCOME_ALL_READ")
		all_read_label.add_theme_color_override("font_color", _COLOR_DIM)
		all_read_label.add_theme_font_size_override("font_size", 14)
		outer_vbox.add_child(all_read_label)
	else:
		var unread_label: Label = Label.new()
		var titles: Array[String] = []
		for ev: EvidenceItem in unread:
			titles.append(ev.get_title())
		unread_label.text = "%s %s" % [tr("OUTCOME_UNREAD_PREFIX"), ", ".join(titles)]
		unread_label.add_theme_color_override("font_color", _COLOR_DIM)
		unread_label.add_theme_font_size_override("font_size", 14)
		unread_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer_vbox.add_child(unread_label)

	# Alternate hint
	var hint: String = CaseManager.get_alternate_hint(verdict_key)
	if not hint.is_empty():
		var hint_label: Label = Label.new()
		hint_label.text = "%s %s" % [tr("OUTCOME_ALTERNATE_HINT_PREFIX"), hint]
		hint_label.add_theme_color_override("font_color", _COLOR_DIM)
		hint_label.add_theme_font_size_override("font_size", 14)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer_vbox.add_child(hint_label)

	# X/3 tracker (read AFTER resolve_case)
	var reached: int = CaseManager.get_reached_outcome_count(case_data.case_id)
	var tracker_label: Label = Label.new()
	tracker_label.text = tr("OUTCOME_TRACKER") % reached
	tracker_label.add_theme_color_override("font_color", _COLOR_TEXT)
	tracker_label.add_theme_font_size_override("font_size", 18)
	outer_vbox.add_child(tracker_label)

	# Share button
	var share_btn: Button = Button.new()
	share_btn.text = tr("BTN_SHARE_VERDICT")
	share_btn.flat = true
	share_btn.add_theme_color_override("font_color", _COLOR_DIM)
	share_btn.add_theme_font_size_override("font_size", 16)
	share_btn.pressed.connect(_on_share_pressed.bind(case_data, verdict_label_text))
	outer_vbox.add_child(share_btn)

	# Web fallback: always-visible selectable Label
	_share_label = Label.new()
	var share_text: String = _build_share_text(case_data, verdict_label_text)
	_share_label.text = share_text
	_share_label.add_theme_color_override("font_color", _COLOR_DIM)
	_share_label.add_theme_font_size_override("font_size", 13)
	_share_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Always show on Web, hide on native
	_share_label.visible = OS.has_feature("web")
	outer_vbox.add_child(_share_label)

	# Navigation buttons
	var btn_hbox: HBoxContainer = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 24)
	outer_vbox.add_child(btn_hbox)

	var retry_btn: Button = Button.new()
	retry_btn.text = tr("BTN_INVESTIGATE_AGAIN")
	retry_btn.flat = true
	retry_btn.custom_minimum_size = Vector2(260, 48)
	retry_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	retry_btn.add_theme_font_size_override("font_size", 18)
	retry_btn.pressed.connect(_on_retry_pressed)
	btn_hbox.add_child(retry_btn)
	retry_btn.grab_focus()

	var select_btn: Button = Button.new()
	select_btn.text = tr("BTN_CASE_SELECT")
	select_btn.flat = true
	select_btn.custom_minimum_size = Vector2(200, 48)
	select_btn.add_theme_color_override("font_color", _COLOR_DIM)
	select_btn.add_theme_font_size_override("font_size", 18)
	select_btn.pressed.connect(_on_case_select_pressed)
	btn_hbox.add_child(select_btn)

	# Start typewriter for narrative
	var outcome: OutcomeData = case_data.get_outcome(verdict_key)
	_full_narrative = outcome.get_narrative() if outcome != null else tr("OUTCOME_FALLBACK")
	_displayed_chars = 0
	_typewriter_active = true
	_typewriter_timer = 0.0
	_narrative_label.text = ""
	_content_built = true


func _build_share_text(case_data: CaseData, verdict_label: String) -> String:
	return tr("SHARE_TEXT") % [case_data.get_ai_name(), verdict_label, GameManager.STORE_URL]


func _process(delta: float) -> void:
	if not _typewriter_active or not _content_built:
		return
	_typewriter_timer += delta
	while _typewriter_timer >= _TYPEWRITER_SPEED and _displayed_chars < _full_narrative.length():
		_typewriter_timer -= _TYPEWRITER_SPEED
		_displayed_chars += 1
		_narrative_label.text = _full_narrative.substr(0, _displayed_chars)
	if _displayed_chars >= _full_narrative.length():
		_typewriter_active = false
		_narrative_label.text = _full_narrative


func _input(event: InputEvent) -> void:
	if not _typewriter_active:
		return
	var is_skip: bool = (
		event is InputEventMouseButton and (event as InputEventMouseButton).pressed
		or (
			event is InputEventKey
			and (event as InputEventKey).pressed
			and not (event as InputEventKey).echo
		)
	)
	if is_skip:
		_typewriter_active = false
		_narrative_label.text = _full_narrative
		get_viewport().set_input_as_handled()


func _on_share_pressed(case_data: CaseData, verdict_label: String) -> void:
	var text: String = _build_share_text(case_data, verdict_label)
	if not OS.has_feature("web"):
		DisplayServer.clipboard_set(text)
		EventBus.notification_requested.emit(tr("SHARE_COPIED"), "info")
	# Web: label is always visible, user can copy manually


func _on_retry_pressed() -> void:
	EventBus.scene_change_requested.emit("res://scenes/ui/briefing_screen.tscn", "fade")


func _on_case_select_pressed() -> void:
	EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language":
		var case_data: CaseData = CaseManager.current_case
		var verdict_key: String = CaseManager.selected_verdict
		if case_data != null and not verdict_key.is_empty():
			_build_layout(case_data, verdict_key)


func _exit_tree() -> void:
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
