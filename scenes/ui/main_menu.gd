## MainMenu — タイトル画面（MVP プレースホルダー）
extends Control

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_BG: Color = Color.html("#0d0d0d")


func _ready() -> void:
	_build_layout()


func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = _COLOR_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
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

	var subtitle := Label.new()
	subtitle.text = "[ debug the machine before it debugs you ]"
	subtitle.add_theme_color_override("font_color", Color.html("#555555"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var play_btn := Button.new()
	play_btn.text = "[ PLAY ]"
	play_btn.flat = true
	play_btn.custom_minimum_size = Vector2(200, 50)
	play_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	play_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	play_btn.add_theme_font_size_override("font_size", 24)
	play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(play_btn)

	var quit_btn := Button.new()
	quit_btn.text = "[ QUIT ]"
	quit_btn.flat = true
	quit_btn.custom_minimum_size = Vector2(200, 50)
	quit_btn.add_theme_color_override("font_color", Color.html("#555555"))
	quit_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	quit_btn.add_theme_font_size_override("font_size", 24)
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)


func _on_play_pressed() -> void:
	EventBus.scene_change_requested.emit("res://scenes/game/game_screen.tscn", "fade")


func _on_quit_pressed() -> void:
	get_tree().quit()
