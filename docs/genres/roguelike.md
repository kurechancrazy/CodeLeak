# ローグライク / ローグライト — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 9

---

## コアループ

ランダム生成されたフロアを進み → アイテム・強化を選択 →
ボスを倒すかデス（ローグライクは完全リセット、ローグライトは一部引き継ぎ）。

---

## シーン階層

```
Dungeon (Node2D)
├── FloorGenerator (Node)   — 部屋配置・廊下生成
├── TileMapLayer            — FloorGenerator が書き込む
├── RoomGroup (Node2D)      — 部屋ノード（入室時に敵・宝をスポーン）
│   └── Room (Node2D) × n
│       ├── EnemyGroup
│       └── Chest / Reward
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D
│   ├── StatsComponent (Node)  — 現ランのステータス（死亡でリセット）
│   └── InventoryComponent (Node) — ランごとのインベントリ
├── Minimap (CanvasLayer)
└── HUD (CanvasLayer)
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| RunManager | `autoloads/run_manager.gd` | ランの進行状態（フロア番号・ランスコア・引き継ぎ解放） |
| ProgressManager | `autoloads/progress_manager.gd` | アンロック・メタ進行 |

---

## 主要実装パターン

### ランスコープ vs 永続スコープの分離

```
ランスコープ（RunManager）: HP、ランアイテム、フロア番号、今回の強化
永続スコープ（SaveManager）: アンロック済みキャラ・アビリティ、総プレイ回数
```

プレイヤー死亡時は `RunManager.end_run()` でランスコープをリセットし、
永続スコープは `SaveManager` で継続する。

### ダンジョン生成（BSP 分割法）

```gdscript
# FloorGenerator.gd（抜粋）
func generate(floor_num: int, seed_val: int) -> void:
    seed(seed_val)
    var rooms: Array[Rect2i] = _bsp_split(Rect2i(0, 0, MAP_W, MAP_H), 4)
    for room: Rect2i in rooms:
        _carve_room(room)
    _connect_rooms(rooms)
    _place_enemies(rooms, floor_num)
```

BSP 法で分割した矩形を部屋とし、重心間を廊下でつなぐ。

### ドロップテーブル（RngUtils 使用）

```gdscript
# ItemDropTable.gd
@export var item_ids: Array[String] = []
@export var weights: Array[float] = []

func roll() -> String:
    var idx: int = RngUtils.weighted_random(weights)
    return item_ids[idx] if idx >= 0 else ""
```

---

## よくある地雷

- ランスコープのデータを SaveManager に直接書くとデス後もアイテムが残る → RunManager で管理
- 乱数シードをフロア生成時に固定しないと再現デバッグができない
- 部屋を全部一度にインスタンス化するとメモリが膨らむ → 入室時のみスポーン

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/roguelike.md` | このファイル |
| Autoload | `autoloads/run_manager.gd`（作成した場合） | — |
| ユーティリティ | `scripts/utils/rng_utils.gd` | 他ジャンルでも使用 |

```ini
; project.godot [autoload] から削除
RunManager="*res://autoloads/run_manager.gd"
```
