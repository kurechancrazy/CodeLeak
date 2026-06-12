# 3D ホラー / サバイバル — ジャンルガイド

**次元:** 3D（一人称 または 三人称固定）  
**genre-starters.md:** バンドル 22

---

## コアループ

暗いマップを探索し → アイテムを集め → 敵を回避・撃退し → 脱出する。
**照明演出・敵 AI（NavigationAgent）・インベントリ圧迫感**が恐怖を生む。

---

## シーン階層（三人称固定視点版）

```
Level (Node3D)
├── NavigationRegion3D
├── EnemyGroup (Node3D)
│   └── Enemy (CharacterBody3D)
│       ├── MeshInstance3D
│       ├── NavigationAgent3D
│       ├── HearingArea (Area3D)   — 音響トリガー
│       └── SightRayCast (RayCast3D) — 視線チェック
├── InteractableGroup (Node3D)    — 扉・アイテム・セーブポイント
├── Player (CharacterBody3D)
│   ├── Head (Node3D)
│   │   ├── Camera3D
│   │   └── Flashlight (SpotLight3D)
│   ├── CollisionShape3D
│   └── InteractRay (RayCast3D)
├── WorldEnvironment              — 暗い ambient + 霧
└── HUD (CanvasLayer)
    ├── StaminaBar
    ├── ItemSlots
    └── InteractLabel
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| TimeManager | `autoloads/time_manager.gd` | イベントトリガーの時刻管理（任意） |

---

## 主要実装パターン

### 敵の視線チェック（RayCast3D）

```gdscript
# Enemy.gd
@onready var _sight_ray: RayCast3D = $SightRayCast

func _can_see_player() -> bool:
    _sight_ray.target_position = to_local(_player.global_position)
    _sight_ray.force_raycast_update()
    if not _sight_ray.is_colliding():
        return false
    return _sight_ray.get_collider() == _player
```

### フラッシュライトのバッテリー管理

```gdscript
# Player.gd
var _battery: float = 100.0

func _process(delta: float) -> void:
    if _flashlight.visible:
        _battery -= delta * DRAIN_RATE
        if _battery <= 0.0:
            _battery = 0.0
            _flashlight.visible = false
```

### インタラクト（RayCast3D + インターフェース）

```gdscript
# Player.gd
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        if _interact_ray.is_colliding():
            var obj: Object = _interact_ray.get_collider()
            if obj.has_method("interact"):
                obj.interact()
```

---

## よくある地雷

- NavigationAgent3D のパス計算タイミングが遅れると敵が壁に突っ込む → `NavigationAgent3D.velocity_computed` シグナルを使う avoidance を有効化
- SpotLight3D の `shadow_enabled = true` を多数使うとフレームレートが落ちる → 敵に近い場合のみ有効化
- 恐怖イベントをタイマーで起動すると「規則性」に気づかれる → プレイヤーの行動（扉を開けた・アイテムを取った）をトリガーにする

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/3d-horror.md` | このファイル |
| Autoload | `autoloads/time_manager.gd` | 農業シム・3D RPG でも使用 |

```ini
; 農業シム・3D RPG も使わない場合のみ削除
TimeManager="*res://autoloads/time_manager.gd"
```
