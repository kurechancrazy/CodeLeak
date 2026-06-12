# SRPG（シミュレーション RPG） — ジャンルガイド

**次元:** 2D（グリッド見下ろし型）  
**genre-starters.md:** バンドル 11

---

## コアループ

グリッド上にユニットを配置し、ターン制で移動・攻撃する。
**選択 → 移動範囲表示 → 移動 → 攻撃対象選択 → 実行** の操作フローが核心。

---

## シーン階層

```
BattleMap (Node2D)
├── TileMapLayer (地形・障害物)
├── TileMapLayer (ハイライト用オーバーレイ)  — 移動範囲・攻撃範囲の着色
├── UnitGroup (Node2D)
│   ├── PlayerUnit × n (CharacterBody2D 相当のシンプルNode2D)
│   └── EnemyUnit × n
├── PhaseController (Node)   — プレイヤーターン/敵ターンの管理
├── CursorNode (Node2D)      — グリッドカーソル
└── HUD (CanvasLayer)
    ├── UnitInfoPanel         — 選択ユニットのHP・ステータス
    ├── ActionMenu            — 攻撃/アイテム/待機
    └── TurnLabel
```

---

## 必須 Autoload / ユーティリティ

| 種別 | ファイル | 役割 |
|------|---------|------|
| ユーティリティ | `scripts/utils/grid_utils.gd` | 移動範囲 BFS・マンハッタン距離 |

---

## 主要実装パターン

### 移動範囲の表示（GridUtils.get_cells_in_range）

```gdscript
# PhaseController.gd — ユニット選択時
func _show_move_range(unit: Node2D) -> void:
    var passable: Callable = func(p: Vector2i) -> bool:
        return not _is_occupied(p) and not _is_obstacle(p)
    var cells: Array[Vector2i] = GridUtils.get_cells_in_range(
        GridUtils.world_to_grid(unit.global_position, TILE_SIZE),
        unit.move_range,
        passable
    )
    _highlight_cells(cells, Color(0.2, 0.6, 1.0, 0.5))
```

### ターンフロー（状態機械）

```gdscript
enum Phase { PLAYER_SELECT, PLAYER_MOVE, PLAYER_ACTION, ENEMY_TURN, RESULT }
var _phase: Phase = Phase.PLAYER_SELECT
```

各フェーズ遷移は `_change_phase(new_phase)` で一元管理し、
フェーズ入口処理（カーソル有効化・AI 起動等）を集中させる。

### 敵 AI（最もシンプルな実装）

```gdscript
# EnemyUnit — 近くのプレイヤーユニットへ近づき、攻撃範囲に入ったら攻撃
func ai_turn() -> void:
    var target: Node2D = _find_nearest_player()
    if target == null:
        return
    var target_cell: Vector2i = GridUtils.world_to_grid(target.global_position, TILE_SIZE)
    var my_cell: Vector2i = GridUtils.world_to_grid(global_position, TILE_SIZE)
    if GridUtils.is_in_range(my_cell, target_cell, attack_range):
        _attack(target)
    else:
        _move_toward(target_cell)
```

---

## よくある地雷

- グリッド座標とワールド座標の変換を各スクリプトで計算すると不整合が出る → `GridUtils` で一元化
- TileMapLayer の「障害物」判定はレイヤーID で行う（`get_cell_source_id()` を使う）
- ユニットが同じセルに重なれるバグ → `PhaseController` が占有マスを Dictionary で管理

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/srpg.md` | このファイル |
| ユーティリティ | `scripts/utils/grid_utils.gd` | タワーディフェンス・農業シムでも使用 |
| テスト | `tests/unit/test_grid_utils.gd` | 上記と同様 |
