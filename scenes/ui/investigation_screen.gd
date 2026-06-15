## InvestigationScreen — 証拠調査・カウントダウン画面（ポーズ内蔵）
extends MarginContainer

const _COLOR_TEXT: Color = Color.html("#00ff41")
const _COLOR_BG: Color = Color.html("#0d0d0d")
const _COLOR_DIM: Color = Color.html("#555555")
const _COLOR_READ: Color = Color.html("#336633")
const _COLOR_WARN: Color = Color.html("#ffff00")
const _COLOR_DANGER: Color = Color.html("#ff4444")
const _MONO_FONT_SIZE: int = 14
const _BODY_FONT_SIZE: int = 16

var _countdown_label: Label
var _evidence_buttons: Array[Button] = []
var _content_label: Label
var _verdict_btn: Button
var _selected_index: int = -1
var _time_expired_overlay: CanvasLayer
var _pause_overlay: CanvasLayer
var _is_paused: bool = false


func _ready() -> void:
	if CaseManager.current_case == null:
		EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")
		return
	GameManager.transition_to(GameManager.GameState.INVESTIGATING)
	EventBus.countdown_updated.connect(_on_countdown_updated)
	EventBus.verdict_submitted.connect(_on_verdict_submitted)
	EventBus.settings_changed.connect(_on_settings_changed)
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
	outer_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(outer_vbox)

	# Countdown row
	var timer_hbox: HBoxContainer = HBoxContainer.new()
	outer_vbox.add_child(timer_hbox)

	_countdown_label = Label.new()
	_countdown_label.text = "04:00"
	_countdown_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_countdown_label.add_theme_font_size_override("font_size", 28)
	_countdown_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_hbox.add_child(_countdown_label)

	# Main content HBox
	var content_hbox: HBoxContainer = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 20)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(content_hbox)

	# Left: evidence list
	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_stretch_ratio = 1.0
	content_hbox.add_child(left_vbox)

	var evidence_title: Label = Label.new()
	evidence_title.text = "EVIDENCE"
	evidence_title.add_theme_color_override("font_color", _COLOR_DIM)
	evidence_title.add_theme_font_size_override("font_size", 14)
	left_vbox.add_child(evidence_title)

	_evidence_buttons.clear()
	if CaseManager.current_case != null:
		var idx: int = 0
		for evidence: EvidenceItem in CaseManager.current_case.evidence:
			var btn: Button = Button.new()
			btn.flat = true
			btn.text = evidence.get_title()
			btn.add_theme_color_override("font_color", _COLOR_TEXT)
			btn.add_theme_font_size_override("font_size", 16)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(_on_evidence_selected.bind(idx))
			left_vbox.add_child(btn)
			_evidence_buttons.append(btn)
			idx += 1

	# Right: content panel
	var right_scroll: ScrollContainer = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_stretch_ratio = 2.0
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(right_scroll)

	_content_label = Label.new()
	_content_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_content_label.add_theme_font_size_override("font_size", _BODY_FONT_SIZE)
	_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_scroll.add_child(_content_label)

	# Verdict button
	_verdict_btn = Button.new()
	_verdict_btn.flat = true
	_verdict_btn.custom_minimum_size = Vector2(300, 52)
	_verdict_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	_verdict_btn.add_theme_font_size_override("font_size", 20)
	_verdict_btn.pressed.connect(_on_deliver_verdict)
	outer_vbox.add_child(_verdict_btn)
	_refresh_verdict_btn()

	# Focus first evidence button
	if not _evidence_buttons.is_empty():
		_evidence_buttons[0].grab_focus()


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


func _on_evidence_selected(index: int) -> void:
	if CaseManager.current_case == null:
		return
	_selected_index = index
	var evidence: EvidenceItem = CaseManager.current_case.evidence[index]
	CaseManager.mark_evidence_read(evidence.evidence_id)
	_refresh_evidence_list()
	_display_evidence(evidence)


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


func _refresh_verdict_btn() -> void:
	var unread_count: int = CaseManager.get_unread_evidence().size()
	if unread_count > 0:
		_verdict_btn.text = "%s  [%d %s]" % [tr("BTN_DELIVER_VERDICT"), unread_count, tr("UNREAD_COUNT_SUFFIX")]
	else:
		_verdict_btn.text = tr("BTN_DELIVER_VERDICT")


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
	_refresh_verdict_btn()


func _on_verdict_submitted(outcome_key: String) -> void:
	if outcome_key == "insufficient":
		# Time expired path — show overlay
		_time_expired_overlay.visible = true
	# Manual verdict is handled by _on_deliver_verdict routing to VerdictScreen


func _on_deliver_verdict() -> void:
	CaseManager.stop_timer()
	EventBus.scene_change_requested.emit("res://scenes/ui/verdict_screen.tscn", "fade")


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

	# Evidence keyboard nav
	if not _evidence_buttons.is_empty():
		if event.is_action_pressed("move_up"):
			var new_idx: int = max(0, _selected_index - 1)
			_evidence_buttons[new_idx].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			var new_idx: int = min(_evidence_buttons.size() - 1, _selected_index + 1)
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
	_refresh_verdict_btn()
	if CaseManager.current_case != null and _selected_index >= 0:
		var evidence: EvidenceItem = CaseManager.current_case.evidence[_selected_index]
		_display_evidence(evidence)


func _exit_tree() -> void:
	if EventBus.countdown_updated.is_connected(_on_countdown_updated):
		EventBus.countdown_updated.disconnect(_on_countdown_updated)
	if EventBus.verdict_submitted.is_connected(_on_verdict_submitted):
		EventBus.verdict_submitted.disconnect(_on_verdict_submitted)
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
	# Ensure unpause if we navigate away while paused
	if _is_paused:
		EventBus.game_paused.emit(false)
