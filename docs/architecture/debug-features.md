# Debug Features — デバッグ機能の実装指針

**対象:** Godot 4.4+ / GDScript 2.0

デバッグ機能はリリースビルドに混入しないよう、`OS.is_debug_build()` で必ずガードする。

---

## 標準デバッグ機能リスト

以下は開発効率を高めるために推奨される標準デバッグ機能。
必要なものだけ実装する（全部実装する必要はない）。

| 機能 | 優先度 | 実装場所 |
|------|-------|---------|
| FPS / メモリ表示オーバーレイ | **必須** | デバッグHUD（CanvasLayer） |
| シーン直接起動（main_menu スキップ） | **必須** | 起動シーン切り替え設定 |
| コリジョン形状の可視化 | 推奨 | Project Settings（エディタのみ） |
| 無敵モード | 推奨 | GameManager の debug フラグ |
| ステージスキップ | 推奨 | デバッグコマンド |
| スローモーション | オプション | Engine.time_scale 操作 |
| ランダムシード固定 | オプション | 再現性テスト用 |

---

## デバッグコードの分離ルール

### 原則

```
OS.is_debug_build() == true  → エディタ実行 / デバッグエクスポート
OS.is_debug_build() == false → リリースエクスポート
```

デバッグ機能は必ずこのガードで囲む。本番コードに `if debug_mode:` のようなフラグを散在させない。

### DebugManager パターン（推奨）

```gdscript
# autoloads/debug_manager.gd（デバッグビルド時のみ追加する Autoload）
extends Node

@onready var fps_label: Label = null
var _invincible: bool = false
var _time_scale: float = 1.0

func _ready() -> void:
    if not OS.is_debug_build():
        queue_free()  # リリースビルドでは自己削除
        return
    _setup_debug_hud()

func _setup_debug_hud() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    canvas.layer = 100  # 最前面
    fps_label = Label.new()
    fps_label.position = Vector2(8, 8)
    canvas.add_child(fps_label)
    add_child(canvas)

func _process(_delta: float) -> void:
    if not OS.is_debug_build():
        return
    fps_label.text = "FPS: %d | MEM: %d MB" % [
        Engine.get_frames_per_second(),
        OS.get_static_memory_usage() / 1_000_000
    ]
    # デバッグショートカット
    if Input.is_action_just_pressed("debug_invincible"):
        toggle_invincible()
    if Input.is_action_just_pressed("debug_skip_stage"):
        skip_stage()

func toggle_invincible() -> void:
    _invincible = not _invincible
    Logger.debug("Debug: invincible = %s" % _invincible)

func skip_stage() -> void:
    EventBus.scene_change_requested.emit("res://scenes/game/next_stage.tscn", "fade")

func set_time_scale(scale: float) -> void:
    _time_scale = scale
    Engine.time_scale = scale
    Logger.debug("Debug: time_scale = %s" % scale)
```

### デバッグ用 Input アクション（project.godot に追加）

```ini
[input]
debug_invincible={...}  ; F1 など
debug_skip_stage={...}  ; F2 など
debug_slow_motion={...} ; F3 など
```

**これらのアクションはデバッグビルドでのみ機能するよう `DebugManager` 内でのみ参照する。**

---

## シーン直接起動（main_menu スキップ）

毎回タイトル画面から始めると開発効率が下がる。
以下の方法でゲームプレイシーンに直接入れるようにする。

```gdscript
# autoloads/game_manager.gd の _ready() に追加
func _ready() -> void:
    # デバッグビルドでは環境変数でシーンを上書きできる
    if OS.is_debug_build():
        var debug_scene: String = OS.get_environment("DEBUG_SCENE")
        if debug_scene != "":
            SceneManager.go_to(debug_scene, SceneManager.TRANSITION_NONE)
            return
    # 通常起動
    SceneManager.go_to("res://scenes/ui/main_menu.tscn", SceneManager.TRANSITION_NONE)
```

**使い方:** Godot エディタの実行設定または `.env` ファイルで `DEBUG_SCENE=res://scenes/game/game_world.tscn` を指定する。

---

## ランダムシード固定（再現性テスト）

バグ再現や自動テストで、乱数の挙動を固定する。

```gdscript
# autoloads/game_manager.gd
func _ready() -> void:
    if OS.is_debug_build():
        var seed_override: int = OS.get_environment("DEBUG_SEED").to_int()
        if seed_override != 0:
            seed(seed_override)
            Logger.debug("Debug: random seed fixed to %d" % seed_override)
        else:
            randomize()
    else:
        randomize()
```

**テストでの使い方:**
```gdscript
# GUT テスト内
func before_each() -> void:
    seed(12345)  # 再現性のある乱数シードを固定
```

---

## コリジョン形状の可視化

スクリプト不要。`Project Settings > Debug > Visible Collision Shapes` を `true` にする。
**リリースビルドでは自動的に無効になる。**

---

## デバッグ機能チェックリスト（開発開始前に決める）

```
□ FPS/メモリ表示が必要か → DebugManager に実装
□ シーン直接起動が必要か → DEBUG_SCENE 環境変数に対応
□ 無敵モードが必要か → DebugManager に debug_invincible フラグ
□ ステージスキップが必要か → DebugManager に debug_skip_stage 実装
□ スローモーションが必要か → Engine.time_scale 操作
□ ランダムシード固定が必要か → DEBUG_SEED 環境変数に対応
```
