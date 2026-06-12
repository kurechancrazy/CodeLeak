# 3D アクション / アドベンチャー — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 17

---

## コアループ

リアルタイムの移動・攻撃・回避を組み合わせて敵を撃破し、
強化とともに次のエリアへ進む。**ロックオンカメラとコンボ**が体験の核心。

---

## シーン階層

```
Level (Node3D)
├── NavigationRegion3D         — 敵の経路探索用
├── EnemyGroup (Node3D)
│   └── Enemy (CharacterBody3D)
│       ├── NavigationAgent3D
│       ├── StateMachine (Node) — idle/patrol/chase/attack
│       └── HurtBox (Area3D)
├── Player (CharacterBody3D)
│   ├── MeshInstance3D
│   ├── CollisionShape3D
│   ├── SwordHitbox (Area3D)
│   ├── LockOnTarget (Marker3D)  — ロックオン中に敵にフォロー
│   ├── CameraArm (SpringArm3D)
│   │   └── Camera3D
│   └── AnimationTree (AnimationTree + AnimationPlayer)
└── HUD (CanvasLayer)
    ├── HPBar
    └── LockOnIndicator (TextureRect)
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| InputBuffer | `autoloads/input_buffer.gd` | コンボ入力判定 |

---

## 主要実装パターン

### ロックオンカメラ

```gdscript
# Player.gd
var _lock_target: Node3D = null

func _process(delta: float) -> void:
    if _lock_target != null and is_instance_valid(_lock_target):
        var look_dir: Vector3 = (_lock_target.global_position - _camera_arm.global_position)
        _camera_arm.look_at(_lock_target.global_position)
    else:
        _handle_free_camera(delta)

func _toggle_lock_on() -> void:
    if _lock_target != null:
        _lock_target = null
        return
    _lock_target = _find_nearest_enemy(8.0)  # 8m 以内
```

### AnimationTree によるブレンド

```
AnimationTree:
  BlendTree → StateMachine
    ├── idle
    ├── walk
    ├── run
    ├── attack_a  (attack 速度 2.0)
    └── dodge
```

`AnimationTree["parameters/StateMachine/conditions/attack"]` でトリガー。

### 敵 AI ステートマシン（NavigationAgent3D）

```gdscript
# Enemy.gd
enum AIState { IDLE, PATROL, CHASE, ATTACK }

func _physics_process(delta: float) -> void:
    match _ai_state:
        AIState.CHASE:
            _nav_agent.target_position = _player.global_position
            velocity = (_nav_agent.get_next_path_position() - global_position).normalized() * speed
            velocity.y -= GRAVITY * delta
            move_and_slide()
```

---

## よくある地雷

- ロックオン中に敵が死んだ後も `_lock_target` を保持すると null 参照エラー → `is_instance_valid()` で毎フレームチェック
- NavigationAgent3D のパス更新頻度を毎フレームにすると CPU 負荷が高い → `_nav_agent.target_desired_distance` と更新間隔を調整

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/3d-action.md` | このファイル |
| Autoload | `autoloads/input_buffer.gd` | 格闘ゲームでも使用 |

```ini
; 格闘ゲームも使わない場合のみ project.godot から削除
InputBuffer="*res://autoloads/input_buffer.gd"
```
