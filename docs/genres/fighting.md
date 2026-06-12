# 格闘ゲーム — ジャンルガイド

**次元:** 2D（横視点）  
**genre-starters.md:** バンドル 14

---

## コアループ

HP ゲージを削り合い、コンボ・立ち回りで相手のゲージをゼロにする。
**フレームデータ精度・コンボ入力・投げ/ガード判定**が品質の核心。

---

## シーン階層

```
FightArena (Node2D)
├── Background (Sprite2D / ParallaxBackground)
├── Fighter_1 (CharacterBody2D)
│   ├── AnimatedSprite2D (FrameData ベース)
│   ├── Hurtbox (Area2D)        — くらい判定
│   ├── HitboxGroup (Node2D)    — 攻撃判定（複数）
│   └── InputBuffer (Node)      — ローカルインスタンスで InputBuffer を使用
├── Fighter_2 (CharacterBody2D) — 同上（または AI）
├── RoundManager (Node)
└── HUD (CanvasLayer)
    ├── HP_Bar_P1
    ├── HP_Bar_P2
    ├── RoundIndicator          — ○●● など
    └── TimerLabel
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| InputBuffer | `autoloads/input_buffer.gd` | コンボ入力の時間窓判定 |

---

## 主要実装パターン

### コンボ入力判定（InputBuffer 使用）

格闘ゲームでは同じ InputBuffer を複数のファイターが使うのではなく、
**ファイターごとに InputBuffer のインスタンスを持つ**。

```gdscript
# Fighter.gd
var _buffer: Node = null

func _ready() -> void:
    _buffer = load("res://autoloads/input_buffer.gd").new()
    add_child(_buffer)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("p1_light"):
        _buffer.record("light")
    elif event.is_action_pressed("p1_heavy"):
        _buffer.record("heavy")
    elif event.is_action_pressed("p1_special"):
        _buffer.record("special")

func _check_combo() -> void:
    if _buffer.matches_sequence(["light", "light", "heavy"]):
        _execute_combo_abc()
```

Autoload の `InputBuffer` は **グローバルインスタンスとしてではなく**、  
このようにローカル `new()` で使う。

### フレームデータ（Physics フレーム単位で管理）

```gdscript
# Fighter.gd — 攻撃中のフレーム制御
var _attack_frame: int = 0

const STARTUP_FRAMES: int = 5
const ACTIVE_FRAMES: int = 3
const RECOVERY_FRAMES: int = 12

func _physics_process(_delta: float) -> void:
    if _is_attacking:
        _attack_frame += 1
        if _attack_frame < STARTUP_FRAMES:
            pass   # 発生前
        elif _attack_frame < STARTUP_FRAMES + ACTIVE_FRAMES:
            _hitbox.monitoring = true   # 攻撃判定有効
        else:
            _hitbox.monitoring = false
        if _attack_frame >= STARTUP_FRAMES + ACTIVE_FRAMES + RECOVERY_FRAMES:
            _is_attacking = false
            _attack_frame = 0
```

### 投げ / ガード

- 投げ：相手が GROUND かつ一定距離以内の場合のみ成立。ガード無効。
- ガード：`_is_blocking` フラグ中の被ダメージを削減（0 〜 90%）。投げには無効。
- めくり判定：攻撃の当たった方向と相手の向きが同じならガード失敗。

---

## よくある地雷

- `_physics_process` を固定 60Hz で動かさないとフレームデータがプラットフォームにより変化する → `ProjectSettings` の `physics/common/physics_ticks_per_second` を 60 に固定
- Hurtbox と Hitbox を同じレイヤーにすると自分に当たる → collision_layer / mask で分離
- ラウンド間リセット時に `_buffer.clear()` を忘れると前ラウンドの入力が残る

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/fighting.md` | このファイル |
| Autoload | `autoloads/input_buffer.gd` | 3D アクションでも使用 |
| テスト | `tests/unit/test_input_buffer.gd` | 上記と同様 |

```ini
; 3D アクションも使わない場合のみ project.godot から削除
InputBuffer="*res://autoloads/input_buffer.gd"
```
