# パズルゲーム — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 2

---

## コアループ

ルールに従ってオブジェクトを操作し、ゴール条件を満たす。
**Undo（取り消し）・レベルリセット・アニメーション中の入力無効** が使いやすさの核心。

---

## シーン階層

```
Level (Node2D)
├── TileMapLayer (固定壁・床)
├── BlockGroup (Node2D)        — 動かせるブロック群
│   └── Block (StaticBody2D または CharacterBody2D)
├── GoalGroup (Node2D)         — ゴールゾーン
│   └── Goal (Area2D)
├── Player (CharacterBody2D または GridMover)
└── HUD (CanvasLayer)
    ├── MoveCounter
    └── UndoButton
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| LevelManager | （作成する場合）`autoloads/level_manager.gd` | レベル進行・クリア状態管理 |
| ProgressManager | `autoloads/progress_manager.gd` | 星評価・クリア率 |

---

## 主要実装パターン

### グリッド移動（物理を使わない方式）

```gdscript
# Player.gd — ゲームステートが PLAYING の間のみ入力受付
func _unhandled_input(event: InputEvent) -> void:
    if GameManager.state != GameManager.GameState.PLAYING:
        return
    if event.is_action_pressed("move_left"):
        _try_move(Vector2i(-1, 0))

func _try_move(dir: Vector2i) -> void:
    var next_cell: Vector2i = _cell + dir
    if _is_blocked(next_cell):
        return
    if _push_block(next_cell, dir):
        _save_undo_state()
        _cell = next_cell
        position = GridUtils.grid_to_world_center(_cell, TILE_SIZE)
```

### Undo の実装

```gdscript
# UndoSystem.gd（Level の子 Node）
var _history: Array[Dictionary] = []

func save_state() -> void:
    _history.append(_capture_state())

func undo() -> void:
    if _history.is_empty():
        return
    _apply_state(_history.pop_back())

func _capture_state() -> Dictionary:
    return {
        "player_cell": _player_cell,
        "block_cells": _block_cells.duplicate()
    }
```

### アニメーション中の入力無効

```gdscript
# GameState を ANIMATING にして入力をブロックする
GameManager.change_state(GameManager.GameState.ANIMATING)
var tween: Tween = create_tween()
tween.tween_property(player, "position", target_pos, 0.1)
await tween.finished
GameManager.change_state(GameManager.GameState.PLAYING)
```

---

## よくある地雷

- 移動が物理ベースだと壁めり込みが起きる → グリッド移動（セル座標で管理）を推奨
- Undo の履歴サイズ上限を設けないとメモリが増え続ける
- ゴール判定を `_process` でやると複数フレームでシグナルが連発する → `body_entered` の 1 回判定で行う

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/puzzle.md` | このファイル |
| ユーティリティ | `scripts/utils/grid_utils.gd` | SRPG・農業シムでも使用 |
