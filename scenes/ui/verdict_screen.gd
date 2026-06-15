## VerdictScreen — 判決選択画面（取消不可・誤爆防止）
extends MarginContainer

const _COLOR_TEXT: Color = Color.html("#00ff41")
const _COLOR_BG: Color = Color.html("#0d0d0d")
const _COLOR_DIM: Color = Color.html("#555555")
const _COLOR_FLASH: Color = Color.WHITE

var _input_locked: bool = true
var _verdict_buttons: Array[Button] = []

func _ready() -> void:
	if CaseManager.current_case == null:
		EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")
		return
	GameManager.transition_to(GameManager.GameState.VERDICT)
	_build_layout()
	# Input lock: prevent accidental double-click from InvestigationScreen
	_input_locked = true
	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		_input_locked = false
		if not _verdict_buttons.is_empty():
			_verdict_buttons[0].grab_focus()
	)

func _build_layout() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = _COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = tr("VERDICT_TITLE")
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = tr("VERDICT_SUBTITLE")
	subtitle.add_theme_color_override("font_color", _COLOR_DIM)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(subtitle)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Verdict buttons - well spaced to prevent mis-click
	var btn_vbox: VBoxContainer = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 32)
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_vbox)

	_verdict_buttons.clear()
	var options: Array[VerdictChoice] = CaseManager.get_verdict_options()
	for option: VerdictChoice in options:
		var btn: Button = Button.new()
		btn.text = option.get_label()
		btn.flat = true
		btn.custom_minimum_size = Vector2(400, 64)
		btn.add_theme_color_override("font_color", _COLOR_TEXT)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_verdict_selected.bind(option.outcome_key, btn))
		btn_vbox.add_child(btn)
		_verdict_buttons.append(btn)

func _on_verdict_selected(outcome_key: String, btn: Button) -> void:
	if _input_locked:
		return
	_input_locked = true  # prevent double-submit
	# Flash tween
	var tween: Tween = create_tween()
	tween.tween_property(btn, "modulate", _COLOR_FLASH, 0.15)
	tween.tween_property(btn, "modulate", _COLOR_TEXT, 0.15)
	tween.tween_property(btn, "modulate", _COLOR_FLASH, 0.1)
	tween.tween_property(btn, "modulate", _COLOR_TEXT, 0.1)
	tween.tween_callback(func() -> void:
		CaseManager.submit_verdict(outcome_key)
		EventBus.scene_change_requested.emit("res://scenes/ui/outcome_screen.tscn", "fade")
	)

func _input(event: InputEvent) -> void:
	# Verdict is irreversible — no cancel/escape
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
