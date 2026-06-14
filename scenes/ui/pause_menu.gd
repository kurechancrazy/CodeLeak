## PauseMenu — ポーズ中に表示されるオーバーレイメニュー
extends CanvasLayer

const _COLOR_BG: Color = Color(0.05, 0.05, 0.05, 0.92)
const _COLOR_OVERLAY: Color = Color(0.0, 0.0, 0.0, 0.6)
var _COLOR_TEXT: Color = Color.html("#00ff41")

var _title_label: Label
var _resume_btn: Button
var _restart_btn: Button
var _main_menu_btn: Button


func _ready() -> void:
	_build_menu()
	visible = false
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.settings_changed.connect(_on_settings_changed)


func _build_menu() -> void:
	var overlay := ColorRect.new()
	overlay.color = _COLOR_OVERLAY
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = _COLOR_BG
	panel_style.set_corner_radius_all(4)
	panel_style.content_margin_left = 40.0
	panel_style.content_margin_right = 40.0
	panel_style.content_margin_top = 30.0
	panel_style.content_margin_bottom = 30.0

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_color_override("font_color", _COLOR_TEXT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_resume_btn = _add_menu_button(vbox, _on_resume_pressed)
	_restart_btn = _add_menu_button(vbox, _on_restart_pressed)
	_main_menu_btn = _add_menu_button(vbox, _on_main_menu_pressed)

	_refresh_labels()


func _add_menu_button(parent: VBoxContainer, callback: Callable) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(240, 44)
	btn.add_theme_color_override("font_color", _COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _refresh_labels() -> void:
	_title_label.text = tr("PAUSE_TITLE")
	_resume_btn.text = tr("BTN_RESUME")
	_restart_btn.text = tr("BTN_RESTART_LEVEL")
	_main_menu_btn.text = tr("BTN_MAIN_MENU")


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language":
		_refresh_labels()


func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused


func _on_resume_pressed() -> void:
	EventBus.game_paused.emit(false)


func _on_restart_pressed() -> void:
	EventBus.level_restarted.emit()
	EventBus.game_paused.emit(false)


func _on_main_menu_pressed() -> void:
	EventBus.game_paused.emit(false)
	EventBus.scene_change_requested.emit("res://scenes/ui/main_menu.tscn", "fade")


func _exit_tree() -> void:
	EventBus.game_paused.disconnect(_on_game_paused)
	if EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.disconnect(_on_settings_changed)
