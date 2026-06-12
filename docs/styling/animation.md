# Animation — Tween・AnimationPlayer 設計

## Tween vs AnimationPlayer の選択基準

| 状況 | 使うもの |
|------|---------|
| コードから動的に生成するアニメーション | Tween |
| デザイナーが調整するキャラクターアニメーション | AnimationPlayer |
| ステートマシンが必要な複雑なアニメーション | AnimationTree |
| UIのフェードイン・スライド等 | Tween |

---

## Tween パターン

```gdscript
# ✅ create_tween() で毎回新しい Tween を作る（再利用しない）
func _fade_in() -> void:
    modulate.a = 0.0
    var tween: Tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)

# ✅ 複数プロパティを並行アニメーション
func _pop_in() -> void:
    scale = Vector2.ZERO
    modulate.a = 0.0
    var tween: Tween = create_tween()
    tween.set_parallel(true)  # 並行実行
    tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "modulate:a", 1.0, 0.2)

# ✅ チェーン（直列）
func _shake_then_fade() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(self, "position:x", position.x + 10.0, 0.05)
    tween.tween_property(self, "position:x", position.x - 10.0, 0.05)
    tween.tween_property(self, "position:x", position.x, 0.05)
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    tween.tween_callback(queue_free)  # 完了後に自分を削除

# ✅ await で完了を待つ
func _transition() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.5)
    await tween.finished
    _next_step()
```

---

## AnimationPlayer パターン

```gdscript
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ✅ アニメーション名は定数で管理
const ANIM_IDLE: String = "idle"
const ANIM_RUN: String = "run"
const ANIM_JUMP: String = "jump"
const ANIM_DEATH: String = "death"

func _update_animation(velocity: Vector2) -> void:
    if not is_on_floor():
        animation_player.play(ANIM_JUMP)
    elif velocity.length() > 0.1:
        animation_player.play(ANIM_RUN)
    else:
        animation_player.play(ANIM_IDLE)

# ✅ アニメーション完了を待つ
func _play_death() -> void:
    animation_player.play(ANIM_DEATH)
    await animation_player.animation_finished
    queue_free()
```

---

## 禁止パターン

```gdscript
# ❌ _process() 内で毎フレーム Tween を作成（禁止）
func _process(delta: float) -> void:
    var tween: Tween = create_tween()  # 毎フレーム新規作成 → 大量のゴミが発生
    tween.tween_property(...)

# ✅ フラグで制御
var _is_animating: bool = false

func _start_animation() -> void:
    if _is_animating:
        return
    _is_animating = true
    var tween: Tween = create_tween()
    tween.tween_property(self, "position", target, 0.5)
    tween.tween_callback(func() -> void: _is_animating = false)
```

---

## パフォーマンス基準

- Tween は同時に 10個まで（それ以上はプールまたは見直し）
- AnimationPlayer のアニメーションは 60fps 以下で設計
- シェーダーアニメーションはプロファイラーで確認してから本番投入
