## PauseMenu — ポーズ中に表示されるオーバーレイメニュー
extends CanvasLayer

const _COLOR_TEXT: Color = Color.html("#00ff41")
const _COLOR_BG: Color = Color(0.05, 0.05, 0.05, 0.92)
const _COLOR_OVERLAY: Color = Color(0.0, 0.0, 0.0, 0.6)


func _ready() -> void:
	_build_menu()
	visible = false
	EventBus.game_paused.connect(_on_game_paused)


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

	var title := Label.new()
	title.text = "// PAUSED"
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_add_menu_button(vbox, "[RESUME]", _on_resume_pressed)
	_add_menu_button(vbox, "[RESTART LEVEL]", _on_restart_pressed)
	_add_menu_button(vbox, "[MAIN MENU]", _on_main_menu_pressed)


func _add_menu_button(parent: VBoxContainer, label_text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.flat = true
	btn.custom_minimum_size = Vector2(240, 44)
	btn.add_theme_color_override("font_color", _COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.pressed.connect(callback)
	parent.add_child(btn)


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
