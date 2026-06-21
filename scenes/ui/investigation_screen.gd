## InvestigationScreen — 証拠調査・分岐推理チェーン画面（ポーズ内蔵）
extends MarginContainer

const _MONO_FONT_SIZE: int = 14
const _BODY_FONT_SIZE: int = 16

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_BG: Color = Color.html("#0d0d0d")
var _COLOR_DIM: Color = Color.html("#555555")
var _COLOR_READ: Color = Color.html("#336633")
var _COLOR_WARN: Color = Color.html("#ffff00")
var _COLOR_DANGER: Color = Color.html("#ff4444")

var _countdown_label: Label
var _evidence_buttons: Array[Button] = []
var _content_label: Label
var _selected_index: int = -1
var _time_expired_overlay: CanvasLayer
var _pause_overlay: CanvasLayer
var _is_paused: bool = false

var _step_container: VBoxContainer
var _evidence_container: VBoxContainer
var _step_choice_buttons: Array[Button] = []
var _step_question_label: Label
var _step_type_label: Label
var _step_indicator_label: Label
var _input_locked: bool = false
var _step_count: int = 0
var _displayed_evidence_ids: Dictionary = {}
var _cite_button: Button
var _citation_prompt_label: Label
var _citation_animating: bool = false


func _ready() -> void:
	if CaseManager.current_case == null:
		EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")
		return
	GameManager.transition_to(GameManager.GameState.INVESTIGATING)
	EventBus.countdown_updated.connect(_on_countdown_updated)
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.step_arrived.connect(_on_step_arrived)
	EventBus.investigation_chain_complete.connect(_on_chain_complete)
	EventBus.evidence_unlocked.connect(_on_evidence_unlocked)
	EventBus.evidence_cited_correctly.connect(_on_evidence_cited_correctly)
	EventBus.evidence_cited_wrongly.connect(_on_evidence_cited_wrongly)
	_build_layout()
	_build_time_expired_overlay()
	_build_pause_overlay()
	CaseManager.start_case()


func _build_layout() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = _COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var outer_vbox: VBoxContainer = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(outer_vbox)

	# タイマー行
	var timer_hbox: HBoxContainer = HBoxContainer.new()
	outer_vbox.add_child(timer_hbox)

	_countdown_label = Label.new()
	_countdown_label.text = "04:00"
	_countdown_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_countdown_label.add_theme_font_size_override("font_size", 28)
	_countdown_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_hbox.add_child(_countdown_label)

	_step_indicator_label = Label.new()
	_step_indicator_label.text = "STEP 0"
	_step_indicator_label.add_theme_color_override("font_color", _COLOR_DIM)
	_step_indicator_label.add_theme_font_size_override("font_size", 20)
	_step_indicator_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	timer_hbox.add_child(_step_indicator_label)

	var top_sep: HSeparator = HSeparator.new()
	outer_vbox.add_child(top_sep)

	# メインコンテンツ（左：質問、右：証拠）
	var content_hbox: HBoxContainer = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 24)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(content_hbox)

	# --- 左: 質問パネル（主役・幅 2/3）---
	_step_container = VBoxContainer.new()
	_step_container.add_theme_constant_override("separation", 10)
	_step_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_step_container.size_flags_stretch_ratio = 2.0
	_step_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(_step_container)

	_step_type_label = Label.new()
	_step_type_label.add_theme_color_override("font_color", _COLOR_DIM)
	_step_type_label.add_theme_font_size_override("font_size", 13)
	_step_container.add_child(_step_type_label)

	_step_question_label = Label.new()
	_step_question_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_step_question_label.add_theme_font_size_override("font_size", 16)
	_step_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_step_question_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_step_container.add_child(_step_question_label)

	var sep_q: HSeparator = HSeparator.new()
	_step_container.add_child(sep_q)

	# --- 右: 証拠パネル（参照用・幅 1/3）---
	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_stretch_ratio = 1.0
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(right_vbox)

	var evidence_title: Label = Label.new()
	evidence_title.text = "── EVIDENCE ──"
	evidence_title.add_theme_color_override("font_color", _COLOR_DIM)
	evidence_title.add_theme_font_size_override("font_size", 13)
	right_vbox.add_child(evidence_title)

	_evidence_container = VBoxContainer.new()
	_evidence_container.add_theme_constant_override("separation", 6)
	right_vbox.add_child(_evidence_container)

	_evidence_buttons.clear()
	_displayed_evidence_ids.clear()

	var ev_sep: HSeparator = HSeparator.new()
	right_vbox.add_child(ev_sep)

	# 証拠コンテンツスクロール
	var evidence_scroll: ScrollContainer = ScrollContainer.new()
	evidence_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(evidence_scroll)

	_content_label = Label.new()
	_content_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_content_label.add_theme_font_size_override("font_size", _BODY_FONT_SIZE)
	_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evidence_scroll.add_child(_content_label)

	_citation_prompt_label = Label.new()
	_citation_prompt_label.add_theme_color_override("font_color", _COLOR_WARN)
	_citation_prompt_label.add_theme_font_size_override("font_size", 14)
	_citation_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_citation_prompt_label.visible = false
	right_vbox.add_child(_citation_prompt_label)

	_cite_button = Button.new()
	_cite_button.flat = true
	_cite_button.add_theme_color_override("font_color", _COLOR_TEXT)
	_cite_button.add_theme_font_size_override("font_size", 15)
	_cite_button.visible = false
	_cite_button.pressed.connect(_on_cite_evidence_pressed)
	right_vbox.add_child(_cite_button)

	# 初期ステップ表示（start_case() 呼び出し前に current_step_id が設定済みの場合）
	var initial_step: InvestigationStep = null
	if CaseManager.current_case != null:
		initial_step = CaseManager.current_case.get_step_by_id(CaseManager.current_step_id)
	if initial_step != null:
		_step_indicator_label.text = "STEP 1"
		_step_count = 1
		_build_step_panel(initial_step)


func _update_citation_ui() -> void:
	var awaiting: bool = CaseManager.is_awaiting_citation()
	_citation_prompt_label.text = tr("CITE_EVIDENCE_PROMPT")
	_citation_prompt_label.visible = awaiting
	_cite_button.text = tr("CITE_EVIDENCE_BTN")
	_cite_button.visible = awaiting and _selected_index >= 0
	_input_locked = awaiting
	for btn: Button in _step_choice_buttons:
		btn.modulate.a = 0.4 if awaiting else 1.0


func _build_step_panel(step: InvestigationStep) -> void:
	_step_choice_buttons.clear()
	for child: Node in _step_container.get_children():
		if child is Button:
			child.queue_free()

	_step_type_label.text = "[ %s ]" % step.question_type
	_step_question_label.text = step.get_question()
	if step.display_as_code:
		_step_question_label.add_theme_font_size_override("font_size", _MONO_FONT_SIZE)
	else:
		_step_question_label.add_theme_font_size_override("font_size", 16)

	var letter_labels: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]
	for i: int in range(step.choices.size()):
		var choice: StepChoice = step.choices[i]
		var prefix: String = letter_labels[i] if i < letter_labels.size() else str(i + 1)
		var btn: Button = Button.new()
		btn.text = "%s.  %s" % [prefix, choice.get_label()]
		btn.flat = true
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_color_override("font_color", _COLOR_TEXT)
		btn.add_theme_font_size_override("font_size", 15)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_step_choice_selected.bind(choice.choice_key))
		_step_container.add_child(btn)
		_step_choice_buttons.append(btn)

	if not _step_choice_buttons.is_empty():
		_step_choice_buttons[0].grab_focus()


func _build_time_expired_overlay() -> void:
	_time_expired_overlay = CanvasLayer.new()
	_time_expired_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_time_expired_overlay.visible = false
	add_child(_time_expired_overlay)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time_expired_overlay.add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time_expired_overlay.add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var title: Label = Label.new()
	title.text = tr("TIME_EXPIRED_TITLE")
	title.add_theme_color_override("font_color", _COLOR_DANGER)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var body: Label = Label.new()
	body.text = tr("TIME_EXPIRED_BODY")
	body.add_theme_color_override("font_color", Color.WHITE)
	body.add_theme_font_size_override("font_size", 20)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)

	var continue_btn: Button = Button.new()
	continue_btn.text = tr("BTN_CONTINUE")
	continue_btn.flat = true
	continue_btn.custom_minimum_size = Vector2(200, 48)
	continue_btn.add_theme_color_override("font_color", Color.WHITE)
	continue_btn.add_theme_font_size_override("font_size", 22)
	continue_btn.pressed.connect(_go_to_outcome)
	vbox.add_child(continue_btn)
	continue_btn.grab_focus()


func _build_pause_overlay() -> void:
	_pause_overlay = CanvasLayer.new()
	_pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_pause_overlay.visible = false
	add_child(_pause_overlay)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var title: Label = Label.new()
	title.text = tr("PAUSE_TITLE")
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn: Button = Button.new()
	resume_btn.text = tr("PAUSE_RESUME")
	resume_btn.flat = true
	resume_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	resume_btn.add_theme_font_size_override("font_size", 22)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)
	resume_btn.grab_focus()

	var abandon_btn: Button = Button.new()
	abandon_btn.text = tr("PAUSE_CASE_SELECT")
	abandon_btn.flat = true
	abandon_btn.add_theme_color_override("font_color", _COLOR_DIM)
	abandon_btn.add_theme_font_size_override("font_size", 18)
	abandon_btn.pressed.connect(_on_abandon_pressed)
	vbox.add_child(abandon_btn)


func _on_step_choice_selected(choice_key: String) -> void:
	if _input_locked:
		return
	_input_locked = true
	for btn: Button in _step_choice_buttons:
		btn.disabled = true
	CaseManager.answer_step(choice_key)
	# _input_locked は _on_step_arrived または _on_chain_complete で解除


func _on_step_arrived(step_id: String) -> void:
	_step_count += 1
	_step_indicator_label.text = "STEP %d" % _step_count
	var step: InvestigationStep = CaseManager.current_case.get_step_by_id(step_id)
	if step != null:
		_build_step_panel(step)
	_selected_index = -1
	_update_citation_ui()


func _on_chain_complete(_resolved_issue_ids: Array) -> void:
	# チェーン完了 → ChainReviewScreen へ遷移
	EventBus.scene_change_requested.emit("res://scenes/ui/chain_review_screen.tscn", "fade")


func _on_evidence_unlocked(evidence_id: String) -> void:
	if CaseManager.current_case == null:
		return
	if _displayed_evidence_ids.has(evidence_id):
		return
	_displayed_evidence_ids[evidence_id] = true
	for evidence: EvidenceItem in CaseManager.current_case.evidence:
		if evidence.evidence_id == evidence_id:
			_add_evidence_button(evidence, CaseManager.current_case.evidence.find(evidence))
			return


func _add_evidence_button(evidence: EvidenceItem, idx: int) -> void:
	var btn: Button = Button.new()
	btn.flat = true
	btn.text = evidence.get_title()
	btn.add_theme_color_override("font_color", _COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 16)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(_on_evidence_selected.bind(idx))
	_evidence_container.add_child(btn)
	_evidence_buttons.append(btn)


func _on_evidence_selected(index: int) -> void:
	if CaseManager.current_case == null:
		return
	_selected_index = index
	var evidence: EvidenceItem = CaseManager.current_case.evidence[index]
	CaseManager.mark_evidence_read(evidence.evidence_id)
	_refresh_evidence_list()
	_display_evidence(evidence)
	if CaseManager.is_awaiting_citation():
		_cite_button.visible = true


func _display_evidence(evidence: EvidenceItem) -> void:
	_content_label.text = evidence.get_content()
	# Type-based formatting
	match evidence.type:
		"CODE", "LOG", "NETWORK":
			_content_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			_content_label.add_theme_font_size_override("font_size", _MONO_FONT_SIZE)
		"EMAIL":
			_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_content_label.add_theme_font_size_override("font_size", _BODY_FONT_SIZE)


func _refresh_evidence_list() -> void:
	if CaseManager.current_case == null:
		return
	var evidence_list: Array[EvidenceItem] = CaseManager.current_case.evidence
	for i: int in range(evidence_list.size()):
		if i >= _evidence_buttons.size():
			break
		var btn: Button = _evidence_buttons[i]
		var ev: EvidenceItem = evidence_list[i]
		var is_read: bool = ev.evidence_id in CaseManager.read_evidence_ids
		var is_selected: bool = i == _selected_index
		var prefix: String = tr("EVIDENCE_SELECTED_PREFIX") if is_selected else ""
		var read_suffix: String = " " + tr("EVIDENCE_READ_MARKER") if is_read else ""
		btn.text = prefix + ev.get_title() + read_suffix
		if is_selected:
			btn.add_theme_color_override("font_color", Color.WHITE)
		elif is_read:
			btn.add_theme_color_override("font_color", _COLOR_READ)
		else:
			btn.add_theme_color_override("font_color", _COLOR_TEXT)


func _on_cite_evidence_pressed() -> void:
	if _selected_index < 0 or _citation_animating or CaseManager.current_case == null:
		return
	var evidence: EvidenceItem = CaseManager.current_case.evidence[_selected_index]
	CaseManager.cite_evidence(evidence.evidence_id)


func _on_evidence_cited_correctly(_step_id: String, evidence_id: String) -> void:
	if CaseManager.current_case == null:
		return
	for i: int in range(CaseManager.current_case.evidence.size()):
		if CaseManager.current_case.evidence[i].evidence_id == evidence_id:
			if i < _evidence_buttons.size():
				_evidence_buttons[i].add_theme_color_override("font_color", Color.html("#66ff66"))
	_cite_button.visible = false
	_citation_prompt_label.visible = false
	_update_citation_ui()
	if not _step_choice_buttons.is_empty():
		_step_choice_buttons[0].grab_focus()


func _on_evidence_cited_wrongly(_step_id: String, evidence_id: String) -> void:
	if CaseManager.current_case == null:
		return
	for i: int in range(CaseManager.current_case.evidence.size()):
		if CaseManager.current_case.evidence[i].evidence_id == evidence_id:
			if i < _evidence_buttons.size():
				var btn: Button = _evidence_buttons[i]
				_citation_animating = true
				btn.add_theme_color_override("font_color", _COLOR_DANGER)
				var tween: Tween = create_tween()
				tween.tween_interval(0.35)
				tween.tween_callback(
					func() -> void:
						btn.add_theme_color_override("font_color", _COLOR_TEXT)
						_citation_animating = false
				)
			return


func _on_countdown_updated(remaining: float) -> void:
	var mins: int = int(remaining) / 60
	var secs: int = int(remaining) % 60
	var prefix: String = ""

	if remaining <= 10.0:
		prefix = "!! "
		_countdown_label.visible = true
		_countdown_label.add_theme_font_size_override("font_size", 40)
		_countdown_label.add_theme_color_override("font_color", _COLOR_DANGER)
	elif remaining <= 60.0:
		prefix = "! "
		_countdown_label.add_theme_font_size_override("font_size", 28)
		_countdown_label.add_theme_color_override("font_color", _COLOR_DANGER)
		# Blink: toggle visibility based on time
		_countdown_label.visible = int(remaining * 2.0) % 2 == 0
	elif remaining <= 120.0:
		prefix = ""
		_countdown_label.visible = true
		_countdown_label.add_theme_font_size_override("font_size", 28)
		_countdown_label.add_theme_color_override("font_color", _COLOR_WARN)
	else:
		prefix = ""
		_countdown_label.visible = true
		_countdown_label.add_theme_font_size_override("font_size", 28)
		_countdown_label.add_theme_color_override("font_color", _COLOR_TEXT)

	_countdown_label.text = "%s%02d:%02d" % [prefix, mins, secs]


func _go_to_outcome() -> void:
	EventBus.scene_change_requested.emit("res://scenes/ui/outcome_screen.tscn", "fade")


func _input(event: InputEvent) -> void:
	if _time_expired_overlay != null and _time_expired_overlay.visible:
		if event is InputEventKey and (event as InputEventKey).pressed:
			_go_to_outcome()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return

	# Evidence keyboard nav — 証拠ボタンにフォーカスがある場合のみ動作
	if not _evidence_buttons.is_empty():
		var focused: Control = get_viewport().gui_get_focus_owner()
		var focused_idx: int = _evidence_buttons.find(focused as Button)
		if focused_idx >= 0:
			if event.is_action_pressed("move_up"):
				var new_idx: int = max(0, focused_idx - 1)
				_evidence_buttons[new_idx].grab_focus()
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("move_down"):
				var new_idx: int = min(_evidence_buttons.size() - 1, focused_idx + 1)
				_evidence_buttons[new_idx].grab_focus()
				get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	_is_paused = not _is_paused
	_pause_overlay.visible = _is_paused
	EventBus.game_paused.emit(_is_paused)


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_abandon_pressed() -> void:
	if _is_paused:
		_toggle_pause()  # unpause first
	EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key != "language":
		return
	# Refresh labels without rebuilding (preserve read/selected state)
	_refresh_evidence_list()
	if CaseManager.current_case != null and _selected_index >= 0:
		var evidence: EvidenceItem = CaseManager.current_case.evidence[_selected_index]
		_display_evidence(evidence)


func _exit_tree() -> void:
	if EventBus.countdown_updated.is_connected(_on_countdown_updated):
		EventBus.countdown_updated.disconnect(_on_countdown_updated)
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
	if EventBus.step_arrived.is_connected(_on_step_arrived):
		EventBus.step_arrived.disconnect(_on_step_arrived)
	if EventBus.investigation_chain_complete.is_connected(_on_chain_complete):
		EventBus.investigation_chain_complete.disconnect(_on_chain_complete)
	if EventBus.evidence_unlocked.is_connected(_on_evidence_unlocked):
		EventBus.evidence_unlocked.disconnect(_on_evidence_unlocked)
	if EventBus.evidence_cited_correctly.is_connected(_on_evidence_cited_correctly):
		EventBus.evidence_cited_correctly.disconnect(_on_evidence_cited_correctly)
	if EventBus.evidence_cited_wrongly.is_connected(_on_evidence_cited_wrongly):
		EventBus.evidence_cited_wrongly.disconnect(_on_evidence_cited_wrongly)
	# Ensure unpause if we navigate away while paused
	if _is_paused:
		EventBus.game_paused.emit(false)
