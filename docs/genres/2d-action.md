# 2D アクション / プラットフォーマー — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 1

---

## コアループ

ステージ上を走り・ジャンプし・攻撃して敵を倒し、ゴールへ到達する。
即応性の高い入力感と「気持ちいい空中制御」が最重要。

---

## シーン階層

```
Level (Node2D)
├── TileMapLayer          — 地形（衝突あり）
├── BackgroundLayer       — 背景スプライト
├── EnemyGroup (Node2D)   — インスタンスで動的追加
├── ItemGroup (Node2D)    — コイン・アイテム
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D
│   ├── CollisionShape2D
│   ├── AttackHitbox (Area2D) — 攻撃中のみ監視する
│   └── HurtBox (Area2D)
└── HUD (CanvasLayer)
    ├── HPBar
    └── ScoreLabel
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| GameManager | PLAYING / PAUSED / GAME_OVER 遷移 |
| AudioManager | BGM・ジャンプ・着地 SFX |
| ProgressManager | コイン総数・ステージクリア実績 |

---

## 主要実装パターン

### コヨーテタイム + ジャンプバッファ

```gdscript
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.10

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

func _physics_process(delta: float) -> void:
    if is_on_floor():
        _coyote_timer = COYOTE_TIME
    else:
        _coyote_timer -= delta
    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = JUMP_BUFFER_TIME
    else:
        _jump_buffer_timer -= delta
    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        _do_jump()
```

### プレイヤー状態機械（シンプル版）

```gdscript
enum State { IDLE, RUN, JUMP, FALL, ATTACK }
var _state: State = State.IDLE
```

State は `_state` で管理し、AnimatedSprite2D は `play(state_name)` で切り替える。
アニメーション完了シグナル (`animation_finished`) で ATTACK → IDLE 遷移する。

### 攻撃判定タイミング

AttackHitbox（Area2D）は通常 `monitoring = false`。
AnimationPlayer の animation track で攻撃モーションの `[0.2 - 0.4]` フレームだけ有効化する。

---

## よくある地雷

- `velocity` は CharacterBody2D のプロパティ。`motion_velocity` は存在しない（Godot 4）
- `is_on_floor()` は `move_and_slide()` 後のみ正確。呼び順に注意
- TileMapLayer の物理レイヤーを設定しないと衝突が起きない（Layer 1 = world を必ず設定）
- 攻撃 Area2D を `body_entered` で受けると自分自身にも反応する場合がある → `collision_layer / mask` を適切に分離

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/2d-action.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
