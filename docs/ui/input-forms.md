# Input Forms — フォーム・入力バリデーション設計

## 入力フォームの基本構造

```gdscript
# scenes/ui/name_input_form.gd
extends Control

signal submitted(player_name: String)
signal cancelled()

@onready var name_input: LineEdit = $NameInput
@onready var submit_button: Button = $SubmitButton
@onready var error_label: Label = $ErrorLabel
@onready var char_count_label: Label = $CharCountLabel

const NAME_MIN_LENGTH: int = 1
const NAME_MAX_LENGTH: int = 20

func _ready() -> void:
    name_input.text_changed.connect(_on_text_changed)
    submit_button.pressed.connect(_on_submit_pressed)
    error_label.visible = false
    _update_char_count("")

func _on_text_changed(new_text: String) -> void:
    _update_char_count(new_text)
    _clear_error()

func _on_submit_pressed() -> void:
    var validation: Dictionary = _validate(name_input.text)
    if not validation.valid:
        _show_error(validation.message)
        return
    submitted.emit(name_input.text.strip_edges())

func _validate(text: String) -> Dictionary:
    var trimmed: String = text.strip_edges()
    if trimmed.length() < NAME_MIN_LENGTH:
        return {"valid": false, "message": "名前を入力してください"}
    if trimmed.length() > NAME_MAX_LENGTH:
        return {"valid": false, "message": "名前は%d文字以内にしてください" % NAME_MAX_LENGTH}
    return {"valid": true, "message": ""}

func _show_error(message: String) -> void:
    error_label.text = message
    error_label.visible = true
    EventBus.sfx_play_requested.emit("error")

func _clear_error() -> void:
    error_label.visible = false

func _update_char_count(text: String) -> void:
    char_count_label.text = "%d / %d" % [text.length(), NAME_MAX_LENGTH]
    submit_button.disabled = text.strip_edges().length() < NAME_MIN_LENGTH
```

---

## バリデーションの場所

**バリデーションはフォームシーンスクリプト内のみで行う。**
Autoload には検証済みの値のみを渡す。

```gdscript
# ✅ フォームスクリプトでバリデーション
func _on_submit_pressed() -> void:
    if not _is_valid():
        return
    GameManager.update_setting("player_name", name_input.text.strip_edges())

# ❌ Autoload 内でUIバリデーション（禁止）
func update_player_name(name: String) -> void:
    if name.length() == 0:  # UIバリデーションをAutoloadで行うのは禁止
        return
```

---

## 数値入力パターン

```gdscript
# SpinBox または LineEdit + 数値制限
@onready var volume_slider: HSlider = $VolumeSlider

func _ready() -> void:
    volume_slider.min_value = 0.0
    volume_slider.max_value = 1.0
    volume_slider.step = 0.05
    volume_slider.value = GameManager.settings.get("master_volume", 1.0)
    volume_slider.value_changed.connect(_on_volume_changed)

func _on_volume_changed(value: float) -> void:
    GameManager.update_setting("master_volume", value)
```

---

## フォーカス管理（キーボード・ゲームパッド対応）

```gdscript
func _ready() -> void:
    name_input.grab_focus()  # フォームを開いたら最初の入力欄にフォーカス

# ✅ Focus neighbor を設定してTab/ゲームパッド移動を可能に
# インスペクターで Focus Neighbor を設定するか：
func _setup_focus_chain() -> void:
    name_input.focus_next = submit_button.get_path()
    submit_button.focus_previous = name_input.get_path()
```
