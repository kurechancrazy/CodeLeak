# サンドボックス / クラフト — ジャンルガイド

**次元:** 2D（Minecraft 風サイドビュー。3D 拡張の注意点も末尾に記載）  
**genre-starters.md:** バンドル 1

---

## コアループ

ブロック地形を掘って素材を採取し、クラフトで新しいアイテム・構造物を作る。
**TileMapLayer によるブロック管理・掘削 / 配置操作・クラフトレシピシステム**が品質の核心。

---

## シーン階層

```
World (Node2D)
├── TileMapLayer (terrain)      — ブロックの配置・物理コリジョン
├── TileMapLayer (background)   — 背景装飾（コリジョンなし）
├── Drops (Node2D)              — ドロップアイテム（Area2D）
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D
│   ├── CollisionShape2D
│   ├── MiningRay (RayCast2D)   — 採掘対象ブロックを検出
│   └── PlacePreview (Sprite2D) — 設置予定地のゴースト表示
└── HUD (CanvasLayer)
    ├── HotBar (HBoxContainer)  — 手持ちアイテムスロット
    └── CraftingPanel (VBoxContainer)
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| SaveManager | ワールドデータ（使用セル辞書）の保存・読み込み |

---

## 主要実装パターン

### ブロック採掘 + インベントリ追加

```gdscript
# Player.gd
extends CharacterBody2D

@onready var _mining_ray: RayCast2D = $MiningRay
@onready var _tilemap: TileMapLayer = get_parent().get_node("TileMapLayer")

# インベントリ: {source_id: int -> count: int}
var _inventory: Dictionary = {}

func try_mine() -> void:
    if not _mining_ray.is_colliding():
        return
    # コリジョン法線を少し内側にずらして確実にブロック内を指す
    var hit_pos: Vector2 = (_mining_ray.get_collision_point()
        - _mining_ray.get_collision_normal() * 2.0)
    var cell: Vector2i = _tilemap.local_to_map(_tilemap.to_local(hit_pos))
    var source_id: int = _tilemap.get_cell_source_id(cell)
    if source_id == -1:
        return  # 空セル
    _tilemap.erase_cell(cell)
    _add_to_inventory(source_id, 1)
    Logger.info("Mined block", {"source_id": source_id, "cell": cell})

func _add_to_inventory(item_id: int, count: int) -> void:
    _inventory[item_id] = _inventory.get(item_id, 0) + count
    EventBus.inventory_changed.emit(_inventory.duplicate())
```

### ブロック設置

```gdscript
# Player.gd（続き）

var _selected_item_id: int = -1

func try_place(world_pos: Vector2) -> void:
    if _selected_item_id == -1:
        return
    if _inventory.get(_selected_item_id, 0) <= 0:
        return
    var cell: Vector2i = _tilemap.local_to_map(_tilemap.to_local(world_pos))
    # プレイヤーが占有しているセルには設置不可
    var player_cell: Vector2i = _tilemap.local_to_map(
        _tilemap.to_local(global_position))
    if cell == player_cell:
        return
    if _tilemap.get_cell_source_id(cell) != -1:
        return  # 既にブロックがある
    _tilemap.set_cell(cell, _selected_item_id, Vector2i(0, 0))
    _inventory[_selected_item_id] -= 1
    EventBus.inventory_changed.emit(_inventory.duplicate())
    Logger.info("Placed block", {"item_id": _selected_item_id, "cell": cell})
```

### クラフトレシピ

```gdscript
# CraftRecipe.gd
class_name CraftRecipe
extends Resource

# 材料: {source_id: int -> count: int}
@export var ingredients: Dictionary = {}
@export var result_id: int = 0
@export var result_count: int = 1

func can_craft(inventory: Dictionary) -> bool:
    for item_id: int in ingredients:
        if inventory.get(item_id, 0) < ingredients[item_id]:
            return false
    return true

func craft(inventory: Dictionary) -> Dictionary:
    if not can_craft(inventory):
        Logger.error("Cannot craft: missing ingredients", {"result_id": result_id})
        return inventory
    var result: Dictionary = inventory.duplicate()
    for item_id: int in ingredients:
        result[item_id] -= ingredients[item_id]
    result[result_id] = result.get(result_id, 0) + result_count
    Logger.info("Crafted item", {"result_id": result_id, "result_count": result_count})
    return result
```

### ワールドデータの保存（使用セルのみ保存）

```gdscript
# WorldSaveHelper.gd（静的ユーティリティ）
class_name WorldSaveHelper
extends RefCounted

static func save_world(tilemap: TileMapLayer, save_key: String) -> void:
    var cells: Array[Vector2i] = tilemap.get_used_cells()
    var data: Array[Dictionary] = []
    for cell: Vector2i in cells:
        var source_id: int = tilemap.get_cell_source_id(cell)
        var atlas_coords: Vector2i = tilemap.get_cell_atlas_coords(cell)
        data.append({
            "x": cell.x,
            "y": cell.y,
            "source_id": source_id,
            "atlas_x": atlas_coords.x,
            "atlas_y": atlas_coords.y,
        })
    SaveManager.set_value(save_key, data)
    SaveManager.save()
    Logger.info("World saved", {"cell_count": data.size()})

static func load_world(tilemap: TileMapLayer, save_key: String) -> void:
    var data: Array = SaveManager.get_value(save_key, [])
    tilemap.clear()
    for entry: Dictionary in data:
        var cell: Vector2i = Vector2i(entry.get("x", 0), entry.get("y", 0))
        var source_id: int = entry.get("source_id", 0)
        var atlas_coords: Vector2i = Vector2i(
            entry.get("atlas_x", 0), entry.get("atlas_y", 0))
        tilemap.set_cell(cell, source_id, atlas_coords)
    Logger.info("World loaded", {"cell_count": data.size()})
```

---

## よくある地雷

- `TileMapLayer.get_cell_source_id()` は空セルに `-1` を返す → 採掘・設置の両方で必ず `-1` チェックをする
- ブロック設置後にナビゲーションメッシュが更新されないと NPC が壁を通り抜ける → `NavigationServer2D.bake_from_source_geometry_data()` で再ベイクする
- ワールドデータを全セル（空セル含む）保存しようとするとファイルが巨大になる → `TileMapLayer.get_used_cells()` で使用セルのみを保存する（パターン 4 参照）
- `RayCast2D` のコリジョンマスクをブロックレイヤーのみに設定しないとプレイヤー自身に当たる → `collision_mask` をブロックレイヤーに限定する
- `PlacePreview` を毎フレーム `set_cell` で更新すると TileMapLayer の内部再描画が重い → プレビューは専用の `Sprite2D` でセルスナップした位置に移動するだけにする

---

## 3D 版への応用（注意点）

- 3D ではブロックを `Dictionary` でスパース保存し（キー: `Vector3i`、値: `int`）、周辺チャンクのみ `MeshInstance3D` をベイクして表示する
- チャンク単位（例: 16 × 16 × 16）でロード / アンロードすることでパフォーマンスを確保する
- 詳細は `docs/genres/3d-rpg.md` のエリア非同期ロードパターンを参照

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/sandbox-craft.md` | このファイル |
| Autoload | なし（SaveManager はコア） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
