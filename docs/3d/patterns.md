# 3D Patterns — 3D ゲーム固有の実装パターン

**対象:** Godot 4.4+ / GDScript 2.0 / 3Dゲーム（Node3D ベース）

---

## Claude Code 実装停止チェックリスト

```
□ RigidBody3D の position を _physics_process 外で直接変更しようとしている
□ DirectionalLight3D を複数配置しようとしている（通常1つで十分）
□ Node3D の rotation を Euler 角で直接操作しようとしている（ジンバルロックに注意）
□ Camera3D を World シーンの子ではなく Player ノードの子に置こうとしている
```

---

## シーン階層の設計ルール

```
World（Node3D）
├── Environment
│   ├── DirectionalLight3D   ← 太陽光（1つのみ）
│   ├── WorldEnvironment     ← 空・フォグ・SSAO設定
│   └── Level（Node3D）      ← ステージメッシュ・コリジョン
├── Entities（Node3D）
│   ├── Player
│   └── Enemies（Node3D）
└── HUD（CanvasLayer）       ← layer=1。2D UIは必ずここ
```

Camera3D の配置：
- **三人称視点:** `SpringArm3D` の子として `Camera3D` を配置。SpringArm3D を Player の子に。
- **一人称視点:** `Head`（Node3D）の子として `Camera3D` を配置。Head を Player の子に。
- **固定視点:** World の子として独立した `Camera3D`。

---

## CharacterBody3D の移動パターン

```gdscript
extends CharacterBody3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
    # 重力
    if not is_on_floor():
        velocity.y -= gravity * delta

    # ジャンプ
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # 水平移動（カメラ方向を基準）
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction: Vector3 = (camera_pivot.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction != Vector3.ZERO:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()
```

---

## 回転操作（ジンバルロック回避）

```gdscript
# ❌ 禁止: Euler 角の直接操作（ジンバルロックが起きる）
node.rotation.x += delta * sensitivity

# ✅ 正しい: X/Y は別々のノードで回転させる
# カメラのピッチ（上下）は Camera3D または Head ノードのローカルX軸
# キャラクターのヨー（左右）は CharacterBody3D のローカルY軸
func _rotate_camera(event: InputEventMouseMotion) -> void:
    rotate_y(-event.relative.x * sensitivity)              # キャラクター左右回転
    head.rotate_x(-event.relative.y * sensitivity)         # 頭（カメラ）上下回転
    head.rotation.x = clampf(head.rotation.x, -PI / 2.0, PI / 2.0)  # 上下角度制限
```

---

## Camera3D の設定

| プロパティ | 推奨値 | 説明 |
|-----------|--------|------|
| `fov` | 75.0 | 視野角。一人称: 90、三人称: 60–75 |
| `near` | 0.05〜0.1 | 近クリップ。小さすぎるとZファイティング |
| `far` | 100〜4000 | 遠クリップ。ステージサイズに合わせる |

### SpringArm3D（三人称カメラのめり込み防止）

```gdscript
# SpringArm3D を使うとカメラが壁にめり込まない
# Inspector で spring_length（最大距離）と collision_mask を設定する
# スクリプトでの変更は不要（物理的に自動で押し出される）
```

---

## ライティング設定

| ライト種 | 用途 | 数量の目安 |
|---------|------|-----------|
| `DirectionalLight3D` | 太陽・月（平行光） | 1つのみ |
| `OmniLight3D` | 街灯・炎・小さな光源 | シーンあたり 8 以下 |
| `SpotLight3D` | スポットライト・懐中電灯 | シーンあたり 8 以下 |

**パフォーマンス注意:**
- Shadow を有効にするライトは最小限に（DirectionalLight3D のみ shadow を使うのが基本）
- モバイルターゲットでは OmniLight3D の shadow を全て無効にする
- `WorldEnvironment` の `ambient_light` を使って間接光を安価に表現する

---

## NavigationAgent3D（経路探索）

```gdscript
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
    nav_agent.path_desired_distance = 0.5
    nav_agent.target_desired_distance = 0.5
    nav_agent.velocity_computed.connect(_on_velocity_computed)

func set_target(pos: Vector3) -> void:
    nav_agent.target_position = pos

func _physics_process(_delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var direction: Vector3 = (next_pos - global_position).normalized()
    nav_agent.velocity = direction * speed  # 速度を渡してアボイダンス計算

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    velocity = safe_velocity
    move_and_slide()
```

**NavigationRegion3D** に NavigationMesh をベイクしてからでないと動作しない。
NavigationMesh のベイクは Godot エディタの「NavigationRegion3D > Bake NavigationMesh」で実行。

---

## 3D モデルインポート設定

| 設定 | 推奨値 | 理由 |
|------|--------|------|
| Mesh LOD | 有効 | 遠距離ポリゴン削減 |
| Shadow Mesh | 有効（主要キャラのみ） | 影用低ポリゴンメッシュ |
| Compress | S3TC/BPTC | PC / コンソール向け圧縮 |
| Generate Mipmaps | 有効 | 遠距離テクスチャのノイズ低減 |

**禁止:** Blender からエクスポートした `.gltf` をそのまま使う → `.import` ファイルで設定を上書きし、変換後の `.scn` を使う
