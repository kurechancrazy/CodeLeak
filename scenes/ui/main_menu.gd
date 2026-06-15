## MainMenu — タイトル画面（EN/JA 言語切替・遊び方説明付き）
extends Control

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_BG: Color = Color.html("#0d0d0d")
var _COLOR_DIM: Color = Color.html("#555555")

var _subtitle_label: Label
var _play_btn: Button
var _htp_btn: Button
var _quit_btn: Button
var _lang_btn: Button

var _htp_overlay: Panel
var _htp_title_label: Label
var _htp_section_title_labels: Array[Label] = []
var _htp_section_body_labels: Array[Label] = []
var _htp_close_btn: Button

var _htp_title_keys: Array[String] = [
	"HTP_MISSION_TITLE",
	"HTP_EVIDENCE_TITLE",
	"HTP_VERDICT_TITLE",
	"HTP_REPLAY_TITLE",
]
var _htp_body_keys: Array[String] = [
	"HTP_MISSION",
	"HTP_EVIDENCE",
	"HTP_VERDICT",
	"HTP_REPLAY",
]


func _ready() -> void:
	_build_layout()
	_build_htp_overlay()
	EventBus.settings_changed.connect(_on_settings_changed)


func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = _COLOR_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "AI CODE LEAK"
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_subtitle_label = Label.new()
	_subtitle_label.add_theme_color_override("font_color", _COLOR_DIM)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_subtitle_label)

	_play_btn = Button.new()
	_play_btn.flat = true
	_play_btn.custom_minimum_size = Vector2(200, 50)
	_play_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	_play_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_play_btn.add_theme_font_size_override("font_size", 24)
	_play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(_play_btn)

	_htp_btn = Button.new()
	_htp_btn.flat = true
	_htp_btn.custom_minimum_size = Vector2(200, 50)
	_htp_btn.add_theme_color_override("font_color", _COLOR_DIM)
	_htp_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_htp_btn.add_theme_font_size_override("font_size", 24)
	_htp_btn.pressed.connect(func() -> void: _show_htp(true))
	vbox.add_child(_htp_btn)

	_quit_btn = Button.new()
	_quit_btn.flat = true
	_quit_btn.custom_minimum_size = Vector2(200, 50)
	_quit_btn.add_theme_color_override("font_color", _COLOR_DIM)
	_quit_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_quit_btn.add_theme_font_size_override("font_size", 24)
	_quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(_quit_btn)

	_lang_btn = Button.new()
	_lang_btn.flat = true
	_lang_btn.custom_minimum_size = Vector2(60, 32)
	_lang_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	_lang_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_lang_btn.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	_lang_btn.offset_left = -80.0
	_lang_btn.offset_top = 12.0
	_lang_btn.offset_right = -12.0
	_lang_btn.offset_bottom = 44.0
	_lang_btn.pressed.connect(_on_lang_pressed)
	add_child(_lang_btn)

	_refresh_labels()


func _build_htp_overlay() -> void:
	_htp_overlay = Panel.new()
	_htp_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_htp_overlay.visible = false
	add_child(_htp_overlay)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = _COLOR_BG
	_htp_overlay.add_theme_stylebox_override("panel", bg_style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 160)
	margin.add_theme_constant_override("margin_right", 160)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_htp_overlay.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	_htp_title_label = Label.new()
	_htp_title_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_htp_title_label.add_theme_font_size_override("font_size", 28)
	_htp_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_htp_title_label)

	vbox.add_child(HSeparator.new())

	_htp_section_title_labels.clear()
	_htp_section_body_labels.clear()

	for i: int in _htp_title_keys.size():
		var section_title := Label.new()
		section_title.add_theme_color_override("font_color", _COLOR_TEXT)
		section_title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(section_title)
		_htp_section_title_labels.append(section_title)

		var section_body := Label.new()
		section_body.add_theme_color_override("font_color", _COLOR_DIM)
		section_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(section_body)
		_htp_section_body_labels.append(section_body)

	vbox.add_child(HSeparator.new())

	_htp_close_btn = Button.new()
	_htp_close_btn.flat = true
	_htp_close_btn.custom_minimum_size = Vector2(160, 44)
	_htp_close_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	_htp_close_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_htp_close_btn.pressed.connect(func() -> void: _show_htp(false))
	vbox.add_child(_htp_close_btn)

	_refresh_htp_labels()


func _refresh_labels() -> void:
	var current_locale: String = TranslationServer.get_locale()
	var lang_target: String = "ja" if current_locale == "en" else "en"
	_lang_btn.text = "[%s]" % lang_target.to_upper()
	_subtitle_label.text = tr("MAIN_SUBTITLE")
	_play_btn.text = tr("BTN_PLAY")
	_htp_btn.text = tr("BTN_HOW_TO_PLAY")
	_quit_btn.text = tr("BTN_QUIT")
	if _htp_overlay != null:
		_refresh_htp_labels()


func _refresh_htp_labels() -> void:
	_htp_title_label.text = tr("HTP_TITLE")
	for i: int in _htp_section_title_labels.size():
		_htp_section_title_labels[i].text = tr(_htp_title_keys[i])
		_htp_section_body_labels[i].text = tr(_htp_body_keys[i])
	_htp_close_btn.text = tr("BTN_CLOSE")


func _show_htp(show: bool) -> void:
	_htp_overlay.visible = show


func _on_lang_pressed() -> void:
	var current: String = str(GameManager.settings.get("language", "en"))
	var next_locale: String = "ja" if current == "en" else "en"
	TranslationServer.set_locale(next_locale)
	GameManager.update_setting("language", next_locale)
	SaveManager.save_settings()
	_refresh_labels()


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language":
		_refresh_labels()


func _input(event: InputEvent) -> void:
	if _htp_overlay != null and _htp_overlay.visible:
		if event.is_action_pressed("cancel"):
			_show_htp(false)
			get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _exit_tree() -> void:
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
