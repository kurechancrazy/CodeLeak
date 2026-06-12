# Platform UX — プラットフォーム別UX設計ガイド

**対象:** Godot 4.4+ / GDScript 2.0

ゲームの対象プラットフォームが決まったら、このドキュメントを読んで対応方針を決める。
実装は `docs/styling/platform-input.md` と合わせて参照すること。

---

## セーフエリア対応（iOS / Android 必須）

### 問題

iPhone のノッチ・Dynamic Island・Android のホームインジケータが UI に被る。

### 対応コード

```gdscript
# scenes/ui/hud.gd または CanvasLayer のスクリプト
func _ready() -> void:
    _apply_safe_area()
    get_viewport().size_changed.connect(_apply_safe_area)

func _apply_safe_area() -> void:
    var safe_area: Rect2i = DisplayServer.get_display_safe_area()
    var viewport_size: Vector2i = DisplayServer.window_get_size()
    # セーフエリア外のマージンを計算
    var margin_left: int = safe_area.position.x
    var margin_top: int = safe_area.position.y
    var margin_right: int = viewport_size.x - safe_area.end.x
    var margin_bottom: int = viewport_size.y - safe_area.end.y
    # HUD にマージンを適用
    var container: MarginContainer = $MarginContainer
    container.add_theme_constant_override("margin_left", margin_left)
    container.add_theme_constant_override("margin_top", margin_top)
    container.add_theme_constant_override("margin_right", margin_right)
    container.add_theme_constant_override("margin_bottom", margin_bottom)
```

### セーフエリア対応チェック

```
□ iPhone 14 Pro / 15 Pro（Dynamic Island）で確認
□ Android のホームインジケータ（下部）に UI が被っていないか
□ 横持ち時の左右ノッチに UI が被っていないか
```

---

## 解像度スケーリング戦略

### 基準解像度

| ターゲット | 推奨基準解像度 | Stretch モード |
|-----------|-------------|---------------|
| PC横画面 | 1920×1080 | `canvas_items` + `expand` |
| モバイル縦 | 1080×1920 | `canvas_items` + `expand` |
| モバイル横 | 1920×1080 | `canvas_items` + `expand` |
| Web（PC） | 1280×720 | `canvas_items` + `expand` |

### フォント DPI スケーリング

```gdscript
# UI の基準フォントサイズを viewport サイズで動的に計算
func get_scaled_font_size(base_size: int) -> int:
    var viewport_height: float = get_viewport_rect().size.y
    var base_height: float = 1080.0  # 基準解像度
    var scale: float = viewport_height / base_height
    # 最小・最大クランプ
    scale = clampf(scale, 0.5, 2.0)
    return max(int(base_size * scale), 16)  # 最低 16px

# 使用例
func _ready() -> void:
    score_label.add_theme_font_size_override("font_size", get_scaled_font_size(32))
```

### 解像度別確認リスト

```
□ 1280×720 （低解像度PC / 旧型モバイル）でUI要素が画面内に収まる
□ 1920×1080 （フルHD PC）で基準通りに表示される
□ 2560×1440 （2K PC）でフォントが拡大されて読みやすい
□ 375×667 （iPhone SE / 小型モバイル）でタッチターゲットが 44px 以上
□ 430×932 （iPhone Pro Max）で余白が広がりすぎていない
```

---

## 画面向き対応（モバイル）

### project.godot の設定

```ini
[display]
; 横向き固定の場合
window/handheld/orientation=2  ; LANDSCAPE

; 縦向き固定の場合
window/handheld/orientation=1  ; PORTRAIT

; 両方対応する場合
window/handheld/orientation=0  ; SENSOR（OS に委ねる）
```

### 回転対応が必要な場合のレイアウト切り替え

```gdscript
func _ready() -> void:
    get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
    var size: Vector2 = get_viewport_rect().size
    if size.x > size.y:
        _apply_landscape_layout()
    else:
        _apply_portrait_layout()

func _apply_landscape_layout() -> void:
    # 横向きレイアウトの適用
    hud_container.set_anchors_preset(Control.PRESET_TOP_WIDE)

func _apply_portrait_layout() -> void:
    # 縦向きレイアウトの適用
    hud_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
```

**推奨:** ゲームジャンルが決まったら向きを固定する。両方対応は開発コストが2倍になる。

---

## Web プラットフォーム固有制約

### ブラウザタブ切り替え時の自動ポーズ

```gdscript
# autoloads/game_manager.gd
func _ready() -> void:
    # Web ではタブ切り替えで ApplicationFocusOut が発火する
    get_tree().root.focus_exited.connect(_on_focus_lost)
    get_tree().root.focus_entered.connect(_on_focus_regained)

func _on_focus_lost() -> void:
    if state == GameState.PLAYING:
        EventBus.game_paused.emit(true)

func _on_focus_regained() -> void:
    pass  # 自動再開はしない（ユーザー操作で再開させる）
```

### Web 音声の自動再生制限

ブラウザでは `AudioContext` がユーザー操作なしに起動できない。
最初のクリック/タップまで BGM を再生しない。

```gdscript
# scenes/ui/main_menu.gd
func _ready() -> void:
    # Web の場合はスタートボタン押下まで BGM を遅延
    if OS.get_name() == "Web":
        start_button.pressed.connect(func() -> void: AudioManager.play_bgm("title"))
    else:
        AudioManager.play_bgm("title")
```

### ブラウザの戻るボタン対応

```gdscript
# Web ではブラウザの戻るボタンを押されても処理しない（ゲームの状態管理は SceneManager が行う）
# HTML の history.pushState で対処が必要な場合は JavaScriptBridge を使う
func _input(event: InputEvent) -> void:
    if OS.get_name() == "Web":
        pass  # ブラウザ固有の入力は JavaScriptBridge で別途対応
```

---

## マウス / ゲームパッド / タッチの切り替え検知

```gdscript
# autoloads/game_manager.gd
enum InputDevice { KEYBOARD_MOUSE, GAMEPAD, TOUCH }
var current_input_device: InputDevice = InputDevice.KEYBOARD_MOUSE

func _input(event: InputEvent) -> void:
    var previous: InputDevice = current_input_device
    if event is InputEventKey or event is InputEventMouseButton:
        current_input_device = InputDevice.KEYBOARD_MOUSE
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        current_input_device = InputDevice.GAMEPAD
    elif event is InputEventScreenTouch or event is InputEventScreenDrag:
        current_input_device = InputDevice.TOUCH
    # 入力デバイス変更時に UI のフォーカス表示を切り替える
    if current_input_device != previous:
        EventBus.input_device_changed.emit(current_input_device)
```

**EventBus に `signal input_device_changed(device: int)` を追加すること。**
UI シーンがこのシグナルを購読してボタンのラベル（「Aボタン」vs「Enterキー」）を切り替える。
