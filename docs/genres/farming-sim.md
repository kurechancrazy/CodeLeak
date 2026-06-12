# 農業 / 生活シム — ジャンルガイド

**次元:** 2D（見下ろし型）  
**genre-starters.md:** バンドル 12

---

## コアループ

朝起きる → 農作業（耕す・種植え・水やり・収穫） → NPC と交流 →
夜に寝て翌日へ。**ゲーム内時計と作物成長ステート機械**が中心。

---

## シーン階層

```
Farm (Node2D)
├── TileMapLayer (地形・農地)
├── CropGrid (Node2D)     — 作物ノードを GridUtils のセル座標で管理
│   └── Crop_01 (Node2D)
│       ├── AnimatedSprite2D   — 成長段階ごとのアニメーション
│       └── CropData (Resource) — 種類・成長ステップ・水やり状態
├── NPCGroup (Node2D)
├── Building_House (Node2D)
├── Building_Shop (Node2D)
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D（4方向）
│   └── ToolHitbox (Area2D)   — 農具の作用範囲
└── HUD (CanvasLayer)
    ├── ClockDisplay       — TimeManager.get_formatted_time()
    ├── StaminaBar
    └── HotbarUI
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| TimeManager | `autoloads/time_manager.gd` | ゲーム内時計・日付・季節 |

---

## 主要実装パターン

### 作物成長（ステート機械 + 日付シグナル）

```gdscript
# Crop.gd
enum GrowthStage { SEED, SPROUT, GROWING, READY }

var _stage: GrowthStage = GrowthStage.SEED
var _watered_today: bool = false

func _ready() -> void:
    TimeManager.day_changed.connect(_on_day_changed)

func _on_day_changed(_day: int, _season: int) -> void:
    if _watered_today:
        _advance_growth()
    _watered_today = false   # 翌日はリセット

func water() -> void:
    _watered_today = true
    _sprite.play("watered")
```

### 農地セルの管理（GridUtils 使用）

```gdscript
# CropGrid.gd
var _grid: Dictionary = {}   # {Vector2i: Crop}

func plant(world_pos: Vector2, crop_scene: PackedScene) -> bool:
    var cell: Vector2i = GridUtils.world_to_grid(world_pos, TILE_SIZE)
    if _grid.has(cell):
        return false
    var crop: Node2D = crop_scene.instantiate()
    crop.position = GridUtils.grid_to_world_center(cell, TILE_SIZE)
    add_child(crop)
    _grid[cell] = crop
    return true
```

### 日変わり処理（TimeManager シグナル）

`TimeManager.day_changed` で作物の成長判定、NPC スケジュール更新、
スタミナ回復、セーブポイント自動セーブを行う。

---

## よくある地雷

- 作物データをノードに持つと収穫後に消える → CropData（Resource）をセーブデータに永続化
- 時計を止め忘れてイベント中も日が変わる → `TimeManager.pause_time()` で一時停止
- NPC の移動経路が季節・天候で変わる場合は FlagManager または別の条件管理が必要

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/farming-sim.md` | このファイル |
| Autoload | `autoloads/time_manager.gd` | 3D RPG・3D ホラーでも使用 |
| テスト | `tests/unit/test_time_manager.gd` | 上記と同様 |
| ユーティリティ | `scripts/utils/grid_utils.gd` | SRPG・タワーディフェンスでも使用 |

```ini
; 3D RPG・3D ホラーも使わない場合のみ project.godot から削除
TimeManager="*res://autoloads/time_manager.gd"
```
