# タワーディフェンス — ジャンルガイド

**次元:** 2D（見下ろし型グリッド）  
**genre-starters.md:** バンドル 10

---

## コアループ

所定のパスを進む敵ウェーブに対し、グリッド上にタワーを配置して撃破する。
**グリッド管理 + ウェーブ管理 + タワー射撃 AI** が三本柱。

---

## シーン階層

```
Stage (Node2D)
├── GridManager (Node)      — タワー配置可能マス・占有状態
├── PathCurve (Path2D)      — 敵の移動経路
├── TileMapLayer            — 背景グリッド描画
├── TowerGroup (Node2D)     — プレイスメント時に add_child
│   └── Tower_01 (Node2D)
│       ├── Sprite2D
│       ├── RangeArea (Area2D)   — 射程内の敵を検出
│       └── ShootTimer (Timer)
├── EnemyGroup (Node2D)     — PathFollow2D で移動
├── BulletPool (Node2D)     — ObjectPool
├── PlacementUI (CanvasLayer)
└── HUD (CanvasLayer)
    ├── CurrencyLabel
    ├── LivesLabel
    └── WaveLabel
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| WaveManager | `autoloads/wave_manager.gd` | ウェーブ番号・残敵カウント |

---

## 主要実装パターン

### グリッドへのタワー配置（GridUtils 使用）

```gdscript
# GridManager.gd
func try_place_tower(world_pos: Vector2, tower_scene: PackedScene) -> bool:
    var cell: Vector2i = GridUtils.world_to_grid(world_pos, TILE_SIZE)
    if _occupied.has(cell):
        return false
    if not _is_placeable(cell):
        return false
    var tower: Node2D = tower_scene.instantiate()
    tower.global_position = GridUtils.grid_to_world_center(cell, TILE_SIZE)
    tower_group.add_child(tower)
    _occupied[cell] = tower
    return true
```

### 射程内の最前列の敵を選ぶ

```gdscript
# Tower.gd — ShootTimer.timeout ごとに実行
func _pick_target() -> Node:
    var targets: Array[Area2D] = range_area.get_overlapping_areas()
    var furthest: Node = null
    var max_progress: float = -1.0
    for area: Area2D in targets:
        var enemy: Node = area.get_parent()
        if enemy.has_method("get_path_progress"):
            var progress: float = enemy.get_path_progress()
            if progress > max_progress:
                max_progress = progress
                furthest = enemy
    return furthest
```

敵は `PathFollow2D.progress_ratio` を公開するか、専用 getter を持つ。

### 敵の移動（PathFollow2D）

```gdscript
# Enemy.gd
var _path_follow: PathFollow2D = null

func _physics_process(delta: float) -> void:
    _path_follow.progress += speed * delta
    global_position = _path_follow.global_position
    if _path_follow.progress_ratio >= 1.0:
        _reach_goal()
```

---

## よくある地雷

- タワー配置後にパス上の経路が塞がれないよう、パス（Path2D）のセルに配置禁止フラグを立てる
- RangeArea で `monitoring_started/stopped` を管理していないと、敵が死んだ後も射撃し続ける
- ウェーブ間隔のタイマーを複数並走させると次のウェーブが早まるバグが出る → `is_wave_active` フラグで排他制御

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/tower-defense.md` | このファイル |
| Autoload | `autoloads/wave_manager.gd` | シューティングでも使用 |
| データ | `scripts/data/wave_data.gd` | シューティングでも使用 |
| ユーティリティ | `scripts/utils/grid_utils.gd` | SRPG・農業シムでも使用 |

```ini
; シューティングも使わない場合のみ project.godot から削除
WaveManager="*res://autoloads/wave_manager.gd"
```
