# 3D パズル / 脱出ゲーム — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 23

---

## コアループ

環境の謎を解き、オブジェクトを操作してゴールに到達する。
**物理演算パズル・インタラクト設計・ヒントシステム**が体験の核心。

---

## シーン階層

```
Room (Node3D)
├── StaticBody3D (壁・床・天井)
├── Props (Node3D)               — 触れられる物体群
│   ├── Box (RigidBody3D)        — 押せる箱
│   │   ├── MeshInstance3D
│   │   └── CollisionShape3D
│   ├── Lever (StaticBody3D)     — 状態を切り替えるギミック
│   └── Platform (AnimatableBody3D) — 動く床・エレベーター
├── GoalTrigger (Area3D)
├── Player (CharacterBody3D)
│   ├── Head (Node3D)
│   │   └── Camera3D
│   ├── GrabRay (RayCast3D)      — オブジェクトをつかむ
│   └── HeldObjectSlot (Node3D) — 持っているオブジェクトの親
└── HUD (CanvasLayer)
    ├── InteractLabel
    └── HintButton
```

---

## 主要実装パターン

### RigidBody3D のオブジェクト把持

```gdscript
# Player.gd
var _held_object: RigidBody3D = null

func _try_grab() -> void:
    if not _grab_ray.is_colliding():
        return
    var obj: Object = _grab_ray.get_collider()
    if not obj is RigidBody3D:
        return
    _held_object = obj
    _held_object.freeze = true   # 物理を一時停止
    _held_object.reparent(_held_slot)
    _held_object.position = Vector3.ZERO

func _release() -> void:
    if _held_object == null:
        return
    _held_object.reparent(get_tree().current_scene)
    _held_object.freeze = false
    _held_object.linear_velocity = _camera.global_basis.z * -THROW_FORCE
    _held_object = null
```

### ギミック連動（シグナルチェーン）

```gdscript
# Lever.gd
signal activated(state: bool)

var _state: bool = false

func interact() -> void:
    _state = !_state
    activated.emit(_state)
    _anim.play("on" if _state else "off")
```

```gdscript
# Door.gd
@export var trigger: Node = null

func _ready() -> void:
    if trigger != null and trigger.has_signal("activated"):
        trigger.activated.connect(_on_trigger_activated)
```

### ヒントシステム

```gdscript
# HintManager.gd (Level の子ノード)
@export var hints: Array[String] = []
var _hint_index: int = 0

func request_hint() -> String:
    if _hint_index >= hints.size():
        return "これ以上ヒントはありません。"
    var hint: String = hints[_hint_index]
    _hint_index += 1
    return hint
```

ヒント要求回数を `ProgressManager.increment_stat("hints_used")` で記録しておく。

---

## よくある地雷

- RigidBody3D を `reparent()` する際に `global_transform` を保存しないと座標がズレる → reparent 前後で `global_position` を保存・復元する
- 複数のギミックが同じ Door に連動する場合は「全レバーが ON になったら開く」ロジックを Door 側が持つ
- フレームレートが変わると物理挙動が変わる → `ProjectSettings > physics/common/physics_ticks_per_second = 60` に固定

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/3d-puzzle.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |
