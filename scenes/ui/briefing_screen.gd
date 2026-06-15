## BriefingScreen — ミッションブリーフィング画面
extends MarginContainer

const _COLOR_TEXT: Color = Color.html("#00ff41")
const _COLOR_BG: Color = Color.html("#0d0d0d")
const _COLOR_DIM: Color = Color.html("#555555")
const _COLOR_WARN: Color = Color.html("#ffff00")
const _TYPEWRITER_SPEED: float = 0.03  # seconds per character

var _briefing_label: Label
var _begin_btn: Button
var _full_text: String = ""
var _displayed_chars: int = 0
var _typewriter_active: bool = false
var _typewriter_timer: float = 0.0
var _skip_stage: int = 0  # 0=typing, 1=full text shown, 2=proceed


func _ready() -> void:
	if CaseManager.current_case == null:
		EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")
		return
	GameManager.transition_to(GameManager.GameState.BRIEFING)
	EventBus.settings_changed.connect(_on_settings_changed)
	_build_layout()


func _build_layout() -> void:
	for child: Node in get_children():
		child.queue_free()

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

	# Title
	var title: Label = Label.new()
	title.text = tr("BRIEFING_TITLE")
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 32)
	outer_vbox.add_child(title)

	var case_data: CaseData = CaseManager.current_case

	# Target AI
	var target_label: Label = Label.new()
	target_label.text = "%s AI-%s" % [tr("BRIEFING_TARGET_PREFIX"), case_data.get_ai_name()]
	target_label.add_theme_color_override("font_color", _COLOR_TEXT)
	target_label.add_theme_font_size_override("font_size", 22)
	outer_vbox.add_child(target_label)

	# Threat level with symbol
	var threat_symbol: String = _threat_symbol(case_data.threat_level)
	var threat_label: Label = Label.new()
	threat_label.text = "%s %s %s" % [tr("BRIEFING_THREAT_PREFIX"), case_data.threat_level, threat_symbol]
	threat_label.add_theme_color_override("font_color", _threat_color(case_data.threat_level))
	threat_label.add_theme_font_size_override("font_size", 18)
	outer_vbox.add_child(threat_label)

	# Suspects
	var suspects: Array[String] = case_data.get_suspects()
	if not suspects.is_empty():
		var suspects_label: Label = Label.new()
		suspects_label.text = "%s %s" % [tr("BRIEFING_SUSPECTS_PREFIX"), ", ".join(suspects)]
		suspects_label.add_theme_color_override("font_color", _COLOR_DIM)
		suspects_label.add_theme_font_size_override("font_size", 16)
		suspects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer_vbox.add_child(suspects_label)

	# Victims
	var victims: Array[String] = case_data.get_victims()
	if not victims.is_empty():
		var victims_label: Label = Label.new()
		victims_label.text = "%s %s" % [tr("BRIEFING_VICTIMS_PREFIX"), ", ".join(victims)]
		victims_label.add_theme_color_override("font_color", _COLOR_DIM)
		victims_label.add_theme_font_size_override("font_size", 16)
		victims_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer_vbox.add_child(victims_label)

	var sep: HSeparator = HSeparator.new()
	outer_vbox.add_child(sep)

	# Briefing content - scrollable
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	_briefing_label = Label.new()
	_briefing_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_briefing_label.add_theme_font_size_override("font_size", 16)
	_briefing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_briefing_label)

	# Begin button (hidden until text complete)
	_begin_btn = Button.new()
	_begin_btn.text = tr("BTN_BEGIN_INVESTIGATION")
	_begin_btn.flat = true
	_begin_btn.custom_minimum_size = Vector2(300, 50)
	_begin_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	_begin_btn.add_theme_font_size_override("font_size", 20)
	_begin_btn.visible = false
	_begin_btn.pressed.connect(_proceed_to_investigation)
	outer_vbox.add_child(_begin_btn)

	# Start typewriter
	_full_text = case_data.get_briefing()
	_displayed_chars = 0
	_typewriter_active = true
	_typewriter_timer = 0.0
	_skip_stage = 0
	_briefing_label.text = ""


func _threat_symbol(level: String) -> String:
	match level:
		"CRITICAL":
			return "[!!!!]"
		"HIGH":
			return "[!!!]"
		"MED":
			return "[!!]"
		_:
			return "[!]"


func _threat_color(level: String) -> Color:
	match level:
		"CRITICAL":
			return Color.html("#ff0000")
		"HIGH":
			return Color.html("#ff4444")
		"MED":
			return _COLOR_WARN
		_:
			return _COLOR_DIM


func _process(delta: float) -> void:
	if not _typewriter_active:
		return
	_typewriter_timer += delta
	while _typewriter_timer >= _TYPEWRITER_SPEED and _displayed_chars < _full_text.length():
		_typewriter_timer -= _TYPEWRITER_SPEED
		_displayed_chars += 1
		_briefing_label.text = _full_text.substr(0, _displayed_chars)
	if _displayed_chars >= _full_text.length():
		_typewriter_active = false
		_briefing_label.text = _full_text
		_skip_stage = 1
		_begin_btn.visible = true
		_begin_btn.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")
		get_viewport().set_input_as_handled()
		return

	# Typewriter skip (any key / click when typing or when text complete)
	var is_skip_action: bool = (
		event is InputEventMouseButton and (event as InputEventMouseButton).pressed
		or event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo
		or event.is_action_pressed("confirm")
	)

	if is_skip_action:
		if _typewriter_active:
			# Stage 1: show full text immediately
			_typewriter_active = false
			_displayed_chars = _full_text.length()
			_briefing_label.text = _full_text
			_skip_stage = 1
			_begin_btn.visible = true
			_begin_btn.grab_focus()
			get_viewport().set_input_as_handled()
		elif _skip_stage == 1 and event.is_action_pressed("confirm"):
			# Stage 2: proceed (button press handles it, but also allow bare Enter)
			_proceed_to_investigation()
			get_viewport().set_input_as_handled()


func _proceed_to_investigation() -> void:
	EventBus.scene_change_requested.emit("res://scenes/ui/investigation_screen.tscn", "fade")


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language" and CaseManager.current_case != null:
		_build_layout()


func _exit_tree() -> void:
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
