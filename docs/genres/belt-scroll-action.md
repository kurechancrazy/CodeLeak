# ベルトスクロールアクション — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 1

---

## コアループ

ステージを右（または左）へ進みながら複数の敵をまとめて倒す。
スクリーンスクロール制御・複数敵への範囲攻撃・ノックバック／スタンが核心。
全敵撃破でスクロール制限が解放され、次エリアへ進行できる。

---

## シーン階層

```
Level (Node2D)
├── TileMapLayer              — 地面・壁（Physics Layer: world）
├── ScrollBoundary (Node2D)   — カメラ進行限界マーカー（複数配置）
├── EnemyGroup (Node2D)       — 敵インスタンスを動的 add_child
├── ItemGroup (Node2D)        — ドロップアイテム・回復アイテム
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D
│   ├── CollisionShape2D (CapsuleShape2D)
│   ├── AttackArea (Area2D)   — 扇形/円形。攻撃中のみ monitoring=true
│   └── HurtBox (Area2D)
├── Camera2D                  — Player を follow。limit_right でスクロール制限
└── HUD (CanvasLayer)
    ├── HPBar
    └── ScoreLabel
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| AudioManager | BGM・攻撃 SFX・ヒット SFX の再生 |
| ProgressManager | スコア集計・ステージクリア実績 |

---

## 主要実装パターン

### スクリーンスクロール制御

敵を全滅させると Camera2D の `limit_right` をスムーズに解放する。
Tween を使ってカメラが瞬間移動しないようにする。

```gdscript
# LevelController.gd
extends Node

@onready var _camera: Camera2D = $Camera2D
@onready var _enemy_group: Node2D = $EnemyGroup

var _scroll_limit_x: float = 400.0
var _zone_boundaries: Array[float] = [400.0, 900.0, 1400.0, -1.0]  # -1 = 制限なし
var _current_zone: int = 0

func _process(_delta: float) -> void:
    if _enemy_group.get_child_count() == 0:
        _advance_zone()

func _advance_zone() -> void:
    _current_zone += 1
    if _current_zone >= _zone_boundaries.size():
        return
    var next_limit: float = _zone_boundaries[_current_zone]
    if next_limit < 0.0:
        next_limit = 99999.0
    var tween: Tween = create_tween()
    tween.tween_method(_set_scroll_limit, _scroll_limit_x, next_limit, 0.5)

func _set_scroll_limit(value: float) -> void:
    _scroll_limit_x = value
    _camera.limit_right = int(value)
```

### 範囲攻撃（複数敵への同時ヒット）

AttackArea（Area2D）は通常 `monitoring = false` にしておき、
攻撃モーション中の一定時間だけ `true` にして複数敵に同時ヒットさせる。

```gdscript
# Player.gd
extends CharacterBody2D

enum State { IDLE, WALK, ATTACK, HURT, DEAD }

@onready var _attack_area: Area2D = $AttackArea
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

var _state: State = State.IDLE
var _attack_power: int = 10

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack") and _state == State.IDLE:
        _do_attack()

func _do_attack() -> void:
    _state = State.ATTACK
    _anim.play("attack")
    _attack_area.monitoring = true
    await get_tree().create_timer(0.15).timeout
    _attack_area.monitoring = false
    await _anim.animation_finished
    _state = State.IDLE

func _on_attack_area_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        var dir: Vector2 = (body.global_position - global_position).normalized()
        body.take_damage(_attack_power, dir)
```

### ノックバック / スタン

ダメージを受けた敵はノックバック速度を設定し、`STUN` 状態に遷移する。
スタン中は移動・攻撃を停止し、タイマー終了後に通常 AI へ戻る。

```gdscript
# Enemy.gd
extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, STUN, DEAD }

const STUN_DURATION: float = 0.4
const KNOCKBACK_FORCE: float = 300.0
const KNOCKBACK_FRICTION: float = 1200.0

var _state: State = State.IDLE
var _stun_timer: float = 0.0
var _hp: int = 30

func take_damage(amount: int, knockback_dir: Vector2) -> void:
    _hp -= amount
    if _hp <= 0:
        _die()
        return
    velocity = knockback_dir * KNOCKBACK_FORCE
    _state = State.STUN
    _stun_timer = STUN_DURATION
    AudioManager.play_sfx("enemy_hit")

func _physics_process(delta: float) -> void:
    match _state:
        State.STUN:
            _stun_timer -= delta
            if _stun_timer <= 0.0:
                _state = State.CHASE
            velocity = velocity.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
            move_and_slide()
        State.CHASE:
            _chase_player(delta)
        State.PATROL:
            _patrol(delta)

func _die() -> void:
    _state = State.DEAD
    EventBus.enemy_defeated.emit(global_position)
    queue_free()
```

### グラブ（掴み）攻撃

ベルトスクロールの醍醐味となる掴み投げ。
GrabArea で敵を捕捉し、`throw_enemy()` でノックバックを与える。

```gdscript
# Player.gd（掴み拡張）
@onready var _grab_area: Area2D = $GrabArea

var _grabbed_enemy: Node2D = null

func _try_grab() -> void:
    var bodies: Array[Node2D] = _grab_area.get_overlapping_bodies()
    for body: Node2D in bodies:
        if body.has_method("get_grabbed"):
            body.get_grabbed(self)
            _grabbed_enemy = body
            return

func throw_enemy(throw_dir: Vector2) -> void:
    if _grabbed_enemy == null:
        return
    _grabbed_enemy.take_damage(15, throw_dir * 2.0)
    _grabbed_enemy = null
```

---

## よくある地雷

- AttackArea の `collision_mask` を player の HurtBox レイヤーに向けると自分自身がヒットする → enemy レイヤーのみに設定する
- Camera2D の `limit_right` を毎フレーム更新すると敵が全滅した瞬間にカメラが飛ぶ → Tween でスムーズに移動させる
- 複数の敵が同フレームに `body_entered` を発火するとスタックが深くなる → `monitoring = false` は必ず `await` 後に実行する
- `EnemyGroup.get_child_count() == 0` の判定を `queue_free()` と同フレームに行うとカウントがずれる → `queue_free()` は次フレームに反映されるため、フレームをまたいでチェックする
- ノックバック中に別の攻撃が当たると `_stun_timer` がリセットされ無限スタンになる → ヒット無敵時間（`invincible_timer`）を別途設ける

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/belt-scroll-action.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
