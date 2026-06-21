## CaseSelectScreen — ケース選択画面
extends MarginContainer

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_BG: Color = Color.html("#0d0d0d")
var _COLOR_DIM: Color = Color.html("#555555")
var _COLOR_LOCK: Color = Color.html("#333333")

var _scroll: ScrollContainer
var _vbox: VBoxContainer
var _entry_buttons: Array[Button] = []
var _focused_index: int = 0


func _ready() -> void:
	GameManager.transition_to(GameManager.GameState.CASE_SELECT)
	custom_minimum_size = get_viewport().get_visible_rect().size
	_build_layout()
	EventBus.settings_changed.connect(_on_settings_changed)


func _build_layout() -> void:
	# Clear existing children
	for child: Node in get_children():
		child.queue_free()
	_entry_buttons.clear()
	_focused_index = 0

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var outer_vbox: VBoxContainer = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 24)
	margin.add_child(outer_vbox)

	var title: Label = Label.new()
	title.text = tr("BTN_CASE_SELECT_TITLE")
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 36)
	outer_vbox.add_child(title)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 16)
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_vbox)

	_populate_cases()

	var back_btn: Button = Button.new()
	back_btn.text = tr("BTN_MAIN_MENU")
	back_btn.flat = true
	back_btn.add_theme_color_override("font_color", _COLOR_DIM)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_on_back_pressed)
	outer_vbox.add_child(back_btn)


func _populate_cases() -> void:
	# Load manifest - handle missing gracefully
	var manifest_path: String = "res://resources/cases/case_manifest.tres"
	if not ResourceLoader.exists(manifest_path):
		_add_coming_soon_entry()
		return

	var manifest: Resource = load(manifest_path)
	if not manifest is CaseManifest:
		_add_coming_soon_entry()
		return

	var case_manifest: CaseManifest = manifest as CaseManifest
	for case_data: CaseData in case_manifest.cases:
		var errors: Array[String] = case_data.validate()
		if errors.is_empty():
			_add_playable_entry(case_data)
		else:
			Logger.error("Invalid case data", {"id": case_data.case_id, "errors": errors})
			_add_error_locked_entry(case_data)

	# Locked steam entries for cases 2 and 3
	_add_locked_steam_entry()
	_add_locked_steam_entry()

	# Focus first playable entry
	if not _entry_buttons.is_empty():
		_entry_buttons[0].grab_focus()


func _add_playable_entry(case_data: CaseData) -> void:
	var reached: int = CaseManager.get_reached_outcome_count(case_data.case_id)

	var panel: PanelContainer = PanelContainer.new()
	_vbox.add_child(panel)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label: Label = Label.new()
	name_label.text = "CASE: AI-%s" % case_data.get_ai_name()
	name_label.add_theme_color_override("font_color", _COLOR_TEXT)
	name_label.add_theme_font_size_override("font_size", 22)
	info_vbox.add_child(name_label)

	var threat_label: Label = Label.new()
	threat_label.text = "%s %s" % [tr("CASE_THREAT_PREFIX"), case_data.threat_level]
	threat_label.add_theme_color_override("font_color", _COLOR_DIM)
	threat_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(threat_label)

	var tracker_label: Label = Label.new()
	tracker_label.text = tr("CASE_OUTCOMES_TRACKER") % reached
	tracker_label.add_theme_color_override("font_color", _COLOR_TEXT if reached > 0 else _COLOR_DIM)
	tracker_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(tracker_label)

	var play_btn: Button = Button.new()
	play_btn.text = tr("BTN_PLAY")
	play_btn.flat = false
	play_btn.custom_minimum_size = Vector2(160, 48)
	play_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	play_btn.add_theme_font_size_override("font_size", 20)
	play_btn.pressed.connect(_on_case_selected.bind(case_data))
	hbox.add_child(play_btn)

	_entry_buttons.append(play_btn)


func _add_locked_steam_entry() -> void:
	var panel: PanelContainer = PanelContainer.new()
	_vbox.add_child(panel)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	var lock_label: Label = Label.new()
	lock_label.text = tr("CASE_LOCKED")
	lock_label.add_theme_color_override("font_color", _COLOR_LOCK)
	lock_label.add_theme_font_size_override("font_size", 18)
	lock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lock_label)

	var wl_btn: Button = Button.new()
	wl_btn.text = tr("BTN_WISHLIST")
	wl_btn.flat = true
	wl_btn.custom_minimum_size = Vector2(200, 48)
	wl_btn.add_theme_color_override("font_color", _COLOR_DIM)
	wl_btn.add_theme_font_size_override("font_size", 16)
	wl_btn.pressed.connect(_on_wishlist_pressed)
	hbox.add_child(wl_btn)
	_entry_buttons.append(wl_btn)


func _add_error_locked_entry(case_data: CaseData) -> void:
	var label: Label = Label.new()
	label.text = "[ERROR] Case %s failed validation" % case_data.case_id
	label.add_theme_color_override("font_color", _COLOR_LOCK)
	_vbox.add_child(label)


func _add_coming_soon_entry() -> void:
	var label: Label = Label.new()
	label.text = tr("CASE_LOCKED")
	label.add_theme_color_override("font_color", _COLOR_LOCK)
	label.add_theme_font_size_override("font_size", 18)
	_vbox.add_child(label)


func _on_case_selected(case_data: CaseData) -> void:
	CaseManager.set_current_case(case_data)
	EventBus.scene_change_requested.emit("res://scenes/ui/briefing_screen.tscn", "fade")


func _on_wishlist_pressed() -> void:
	OS.shell_open(GameManager.WISHLIST_URL)


func _on_back_pressed() -> void:
	EventBus.scene_change_requested.emit("res://scenes/ui/main_menu.tscn", "fade")


func _input(event: InputEvent) -> void:
	if _entry_buttons.is_empty():
		return
	if event.is_action_pressed("move_up"):
		_focused_index = max(0, _focused_index - 1)
		_entry_buttons[_focused_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_focused_index = min(_entry_buttons.size() - 1, _focused_index + 1)
		_entry_buttons[_focused_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language":
		_build_layout()


func _exit_tree() -> void:
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
