# Game Loop — _process / _physics_process の使い分け

**対象:** Godot 4.4+ / GDScript 2.0

---

## Claude Code 実装停止チェックリスト

以下のいずれかに該当する場合、**実装を停止してユーザーに確認する**。

```
□ _physics_process 内で UI ノードを更新しようとしている
□ _process 内で RigidBody / CharacterBody の velocity を直接セットしようとしている
□ delta を掛けずに座標を毎フレーム加算しようとしている
□ 重い処理（パスファインド・複雑なループ）を _process 内に書こうとしている
```

---

## 使い分けの判断基準

| 処理の種類 | 使うメソッド | 理由 |
|-----------|------------|------|
| キャラクター移動・物理演算 | `_physics_process(delta)` | 物理エンジンと同期した固定ステップで実行 |
| UI アニメーション・カメラ追従 | `_process(delta)` | 描画フレームに合わせた滑らかな更新 |
| 入力検出（ボタン押し続け） | `_process(delta)` | 毎フレーム Input.is_action_pressed() を確認 |
| 入力検出（1回のみ） | `_input(event)` | イベント発火時のみ呼ばれる。_process より効率的 |
| 重い計算・ファイルI/O | スレッド or シグナルチェーン | _process/_physics_process のどちらにも書かない |

```
迷ったら: 物理ノード（CharacterBody・RigidBody・Area）を動かす → _physics_process
            それ以外の視覚的な更新 → _process
```

---

## デルタタイム補正（必須）

**フレームレートに依存しない移動には必ず delta を掛ける。**

```gdscript
# ✅ 正しい: フレームレートに依存しない
func _process(delta: float) -> void:
    position.x += speed * delta

# ❌ 禁止: フレームレートで速度が変わる
func _process(_delta: float) -> void:
    position.x += 5.0
```

---

## CharacterBody2D の移動パターン（_physics_process）

```gdscript
extends CharacterBody2D

const SPEED: float = 200.0
const GRAVITY: float = 980.0
const JUMP_VELOCITY: float = -400.0

func _physics_process(delta: float) -> void:
    # 重力を加算
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 水平移動
    var direction: float = Input.get_axis("move_left", "move_right")
    velocity.x = direction * SPEED

    # ジャンプ
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    move_and_slide()
```

**禁止:** `_process` 内での `move_and_slide()` 呼び出し → 物理演算が不安定になる

---

## カメラ追従パターン（_process）

```gdscript
extends Camera2D

@export var target: Node2D = null
@export var smoothing_speed: float = 5.0

func _process(delta: float) -> void:
    if target == null:
        return
    # lerp でスムーズ追従
    global_position = global_position.lerp(target.global_position, smoothing_speed * delta)
```

**補足:** Godot 4 の Camera2D には `position_smoothing_enabled` が内蔵されている。
カスタム追従が不要なら Inspector で `position_smoothing_enabled = true` に設定するだけでよい。

---

## AnimationPlayer / Tween との共存

| 処理 | 推奨 |
|------|------|
| ループアニメーション（歩く・待機） | AnimationPlayer |
| 一時的な演出（出現・消滅・スコア表示） | Tween |
| 物理と連動するアニメーション | `_physics_process` 内で手動更新 |

```gdscript
# ✅ Tween と _process の共存（競合しない）
func show_damage(amount: int) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(label, "modulate:a", 0.0, 0.5)
    tween.tween_callback(label.queue_free)
    # tween 中でも _process は通常通り動く

# ❌ 禁止: Tween と _process で同じプロパティを競合させる
func _process(delta: float) -> void:
    label.modulate.a = 1.0  # Tween と競合
```

---

## set_physics_process / set_process による ON/OFF

不要な間は処理を止めてパフォーマンスを確保する。

```gdscript
func _ready() -> void:
    set_physics_process(false)  # 初期は無効

func start_movement() -> void:
    set_physics_process(true)

func stop_movement() -> void:
    set_physics_process(false)
    velocity = Vector2.ZERO
```

---

## 禁止パターン

```gdscript
# ❌ 禁止: _physics_process 内での UI 更新
func _physics_process(delta: float) -> void:
    move_and_slide()
    score_label.text = str(score)  # ← UI 更新は _process か EventBus シグナルで

# ❌ 禁止: await get_tree().process_frame をループで使う
func _process(_delta: float) -> void:
    await get_tree().process_frame  # ← シグナルベースに書き直す

# ❌ 禁止: _process 内でのファイルI/O
func _process(_delta: float) -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data.json"))
```
