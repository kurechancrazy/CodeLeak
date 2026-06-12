# Platform Input — タッチ/マウス/キーボード/ゲームパッド入力

## 入力の抽象化

Godot の `InputMap` を使って入力を抽象化する。ハードコードしない。

```
Project Settings → Input Map に以下を定義:
- ui_accept     (Enter / Space / A button)
- ui_cancel     (Escape / B button)
- ui_up/down/left/right
- game_jump     (Space / A button)
- game_attack   (Z / X button)
- game_pause    (Escape / Start button)
```

```gdscript
# ✅ InputMap の抽象アクションを使う
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("game_jump"):
        _jump()
    if event.is_action_pressed("game_pause"):
        EventBus.game_paused.emit(not GameManager.state == GameManager.GameState.PAUSED)

# ❌ 特定のキーをハードコード（禁止）
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode == KEY_SPACE:
        _jump()
```

---

## タッチ入力

```gdscript
# ✅ タッチとマウスを統合して処理
func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _handle_touch(event.position)
    elif event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _handle_touch(event.position)

# ✅ タッチジェスチャー（スワイプ）
var _touch_start: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_start = event.position
        else:
            var delta: Vector2 = event.position - _touch_start
            if delta.length() > 50.0:
                _handle_swipe(delta.normalized())
```

---

## ゲームパッド対応

```gdscript
# ✅ ゲームパッドの接続・切断を検出
func _ready() -> void:
    Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
    Logger.info("Gamepad connection", {"device": device, "connected": connected})
    if connected:
        EventBus.notification_requested.emit("コントローラーが接続されました", "info")

# ✅ アナログスティックの入力
func _physics_process(_delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if input_dir.length() > 0.2:  # デッドゾーン
        _move(input_dir)
```

---

## プラットフォーム別の注意事項

| プラットフォーム | 注意点 |
|-------------|------|
| iOS | `back` アクションは存在しない。UI でのみ戻るボタンを提供 |
| Android | `back` アクション（物理バックボタン）を必ずハンドル |
| Web | キーボードイベントはブラウザが横取りする場合がある（F5等） |
| コンソール | マウス入力は存在しない。UIのフォーカスを必ず実装 |

```gdscript
# ✅ Android のバックボタン対応
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if OS.get_name() == "Android":
            _handle_back_press()

func _handle_back_press() -> void:
    if SceneManager._history.is_empty():
        # 最初の画面→終了確認ダイアログを表示
        _show_quit_confirm()
    else:
        SceneManager.go_back()
```
