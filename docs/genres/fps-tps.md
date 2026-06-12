# FPS / TPS — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 18

---

## コアループ

射撃・リロード・移動を組み合わせて敵を倒し、ミッションを達成する。
**照準（FPS 視点または肩越し）・武器システム・弾薬管理**が核心。

---

## シーン階層（FPS 版）

```
Level (Node3D)
├── NavigationRegion3D
├── EnemyGroup (Node3D)
├── Player (CharacterBody3D)
│   ├── Head (Node3D)                  — カメラ・武器の親。左右回転はここ
│   │   ├── Camera3D
│   │   └── WeaponHolder (Node3D)      — 武器モデルをここにアタッチ
│   │       └── CurrentWeapon (Node3D)
│   │           ├── AnimationPlayer
│   │           ├── MuzzleFlash (GPUParticles3D)
│   │           └── RayCast3D          — ヒットスキャン（Hitscan）用
│   └── CollisionShape3D (CapsuleShape3D)
├── WorldEnvironment
└── HUD (CanvasLayer)
    ├── Crosshair (TextureRect)
    ├── AmmoLabel
    └── HPBar
```

---

## 主要実装パターン

### FPS カメラの回転（マウス入力）

```gdscript
# Player.gd
func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        _head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        _head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
```

### Hitscan（即着弾）射撃

```gdscript
# Weapon.gd
@onready var _ray: RayCast3D = $RayCast3D

func fire() -> void:
    if _ammo <= 0:
        return
    _ammo -= 1
    _anim.play("fire")
    if _ray.is_colliding():
        var hit: Object = _ray.get_collider()
        if hit.has_method("take_damage"):
            hit.take_damage(_damage)
        _spawn_impact_fx(_ray.get_collision_point(), _ray.get_collision_normal())
    EventBus.sfx_play_requested.emit("gunshot")
```

### TPS（肩越し）カメラ

SpringArm3D を Head に追加し、平時は右肩オフセット、ADS（エイム）時は中央寄りに Tween する。

```gdscript
func _aim(is_aiming: bool) -> void:
    var target_offset: Vector3 = Vector3(0.4, 0.0, 0.0) if not is_aiming else Vector3(0.1, 0.0, 0.0)
    create_tween().tween_property(_arm, "position", target_offset, 0.1)
```

---

## よくある地雷

- `Input.mouse_mode` を `MOUSE_MODE_CAPTURED` にしないとマウスがウィンドウ外に出る
- RayCast3D の長さが短すぎると近距離の敵に当たらない → `target_position = Vector3(0, 0, -100)` など十分な長さにする
- 武器切り替え時に `WeaponHolder` の子ノードを `queue_free()` + `instantiate()` すると落下アニメーションが消える → 武器ノードを非表示で持ち続け `visible` を切り替える

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/fps-tps.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |
