# 3D プラットフォーマー — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 16

---

## コアループ

ステージを走り・ジャンプし・アクション操作でゴールへ到達する。
**空中制御感・スプリングアームカメラ・コヨーテタイム**がプレイ感を左右する。

---

## シーン階層

```
Level (Node3D)
├── World (StaticBody3D) — CSGBox / MeshInstance3D + CollisionShape3D
├── CollectibleGroup (Node3D)
├── EnemyGroup (Node3D)
├── Player (CharacterBody3D)
│   ├── MeshInstance3D
│   ├── CollisionShape3D (CapsuleShape3D)
│   ├── CameraArm (SpringArm3D)       — カメラ引き
│   │   └── Camera3D
│   └── AnimationPlayer
├── DirectionalLight3D
├── WorldEnvironment
└── HUD (CanvasLayer)
    ├── CoinCounter
    └── HealthDisplay
```

---

## 主要実装パターン

### CharacterBody3D の移動 + カメラ相対移動

```gdscript
# Player.gd
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    # カメラの向きを基準に移動方向を計算
    var camera_basis: Basis = _camera.global_transform.basis
    var move_dir: Vector3 = (camera_basis.x * input_dir.x + camera_basis.z * input_dir.y).normalized()
    move_dir.y = 0.0
    velocity.x = move_dir.x * SPEED
    velocity.z = move_dir.z * SPEED
    if is_on_floor() and Input.is_action_just_pressed("jump"):
        velocity.y = JUMP_VELOCITY
    move_and_slide()
```

### SpringArm3D の設定（カメラめり込み防止）

```gdscript
# SpringArm3D: spring_length = 5.0, margin = 0.2
# collision_mask を world レイヤーのみに設定
# Player の CollisionShape3D は SpringArm3D の mask から外す
```

### コヨーテタイム

2D と同じ実装パターンが使える。`is_on_floor()` で `_coyote_timer` をリセットする。

---

## よくある地雷

- カメラが壁にめり込む → SpringArm3D の `collision_mask` を地形レイヤーのみに設定
- `velocity.y` を毎フレーム `-= GRAVITY` すると着地時にもマイナスが蓄積する → `if is_on_floor(): velocity.y = -0.1` でリセット
- カメラ相対移動を実装しないと操作が直感的でなくなる（特に 3D）

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/3d-platformer.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |
