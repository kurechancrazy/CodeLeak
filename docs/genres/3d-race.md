# 3D レース — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 21

---

## コアループ

コースを走り、全ラップを最速で完走する。
**VehicleBody3D の調整・チェックポイントシステム・ラップタイム管理**が実装の柱。

---

## シーン階層

```
Race (Node3D)
├── Track (StaticBody3D + MeshInstance3D)
├── CheckpointGroup (Node3D)
│   └── Checkpoint_01 (Area3D) × n   — 通過順序を管理
│       └── CollisionShape3D
├── CarGroup (Node3D)
│   └── PlayerCar (VehicleBody3D)
│       ├── MeshInstance3D
│       ├── CollisionShape3D
│       ├── VehicleWheel3D × 4
│       │   ├── WheelMesh (MeshInstance3D)
│       │   └── CollisionShape3D
│       └── Camera3D (後方固定)
├── RaceManager (Node)          — 順位・ラップ・ゴール管理
├── DirectionalLight3D
├── WorldEnvironment
└── HUD (CanvasLayer)
    ├── SpeedLabel
    ├── LapLabel
    └── PositionLabel
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| RaceManager | `autoloads/race_manager.gd` | ラップ・タイム・順位・ベストタイム管理 |

---

## 主要実装パターン

### VehicleBody3D の基本設定

```gdscript
# PlayerCar.gd
@onready var _wheels: Array[VehicleWheel3D] = [
    $WheelFL, $WheelFR, $WheelRL, $WheelRR
]

func _physics_process(_delta: float) -> void:
    var throttle: float = Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
    var steer: float = Input.get_axis("steer_right", "steer_left") * MAX_STEER_ANGLE

    # VehicleBody3D の組み込みプロパティを使用
    engine_force = throttle * MAX_ENGINE_FORCE
    steering = steer
```

VehicleWheel3D のパラメータ（`use_as_traction`・`suspension_stiffness`・`wheel_friction_slip`）で挙動を調整する。

### チェックポイントシステム

```gdscript
# Checkpoint.gd
@export var checkpoint_index: int = 0

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player_car"):
        RaceManager.pass_checkpoint(checkpoint_index)

# RaceManager.gd
func pass_checkpoint(index: int) -> void:
    if index != _next_checkpoint:
        return   # 順序違反は無視
    _next_checkpoint = (index + 1) % total_checkpoints
    if _next_checkpoint == 0:
        _complete_lap()
```

### ベストタイムの保存

`ProgressManager.set_stat("best_lap_ms", time_ms)` でベストタイムを永続化する。

---

## よくある地雷

- VehicleBody3D の `mass` が小さすぎると吹き飛ぶ → 最低でも 800 〜 1500 kg を推奨
- チェックポイントを `Area3D` でなく `RayCast3D` にすると通過判定が不安定
- ラップ数をカウントする前にチェックポイントの通過順序バリデーションを省略すると「壁抜けでゴール」ができる

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/3d-race.md` | このファイル |
| Autoload | `autoloads/race_manager.gd`（作成した場合） | — |

```ini
; project.godot [autoload] から削除
RaceManager="*res://autoloads/race_manager.gd"
```
