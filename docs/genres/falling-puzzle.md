# 落ち物パズル（テトリス型） — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 4

---

## コアループ

上から落ちてくるピースをプレイヤーが回転・左右移動させてボードに積み上げ、
横一列がすべて埋まったら消去して得点を得る。
重力ループ・ライン消去・ピーススポーンキューの3要素が核心。
レベルが上がるほど落下速度が増し、難易度が自然にエスカレートする。

---

## シーン階層

```
Game (Node2D)
├── Board (Node2D)              — 10×20 グリッドの描画・データ管理
│   └── GridRenderer (Node2D)  — ブロック Sprite2D を動的生成
├── ActivePiece (Node2D)        — 現在操作中のピース
├── NextPiecePreview (Node2D)   — 次のピースプレビュー表示
├── GhostPiece (Node2D)         — 落下先のゴースト（半透明）を表示
└── HUD (CanvasLayer)
    ├── ScoreLabel
    ├── LevelLabel
    └── LinesLabel
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| AudioManager | ライン消去 SFX・レベルアップ BGM 切り替え |
| ProgressManager | ハイスコア・最大消去ライン数の永続化 |

---

## 主要実装パターン

### ボードデータ構造 + 重力ループ

グリッドは `Array` の `Array` で管理する。値 `0` が空マス、1 以上がブロックの色 ID。
重力タイマーには `Timer` ノードを使い、フレームレート非依存にする。

```gdscript
# board.gd
class_name Board
extends Node2D

const COLS: int = 10
const ROWS: int = 20

var _grid: Array = []  # Array[Array[int]]

func _ready() -> void:
    _init_grid()

func _init_grid() -> void:
    _grid.clear()
    for _y: int in ROWS:
        var row: Array[int] = []
        row.resize(COLS)
        row.fill(0)
        _grid.append(row)

func is_valid_position(cells: Array[Vector2i]) -> bool:
    for cell: Vector2i in cells:
        if cell.x < 0 or cell.x >= COLS or cell.y >= ROWS:
            return false
        if cell.y >= 0 and _grid[cell.y][cell.x] != 0:
            return false
    return true

func lock_piece(cells: Array[Vector2i], color_id: int) -> void:
    for cell: Vector2i in cells:
        if cell.y >= 0:
            _grid[cell.y][cell.x] = color_id
    Logger.info("Board: piece locked, color_id=%d" % color_id)
```

### ライン消去

消去後は上の行をすべて1行分下にシフトする。
`while` ループで `y` インデックスをその場で再チェックすることで、
複数行が連続した場合のインデックスずれを防ぐ。

```gdscript
# board.gd（続き）
func clear_lines() -> int:
    var cleared: int = 0
    var y: int = ROWS - 1
    while y >= 0:
        if _is_full_row(y):
            _grid.remove_at(y)
            var new_row: Array[int] = []
            new_row.resize(COLS)
            new_row.fill(0)
            _grid.insert(0, new_row)
            cleared += 1
            # y を減らさず同じ行を再チェック
        else:
            y -= 1
    if cleared > 0:
        Logger.info("Board: cleared %d line(s)" % cleared)
    return cleared

func _is_full_row(y: int) -> bool:
    for x: int in COLS:
        if _grid[y][x] == 0:
            return false
    return true
```

### ピース回転（ウォールキック付き）

回転後に壁や積みブロックと重なる場合、左右へのオフセットを順番に試して
収まる位置を探す（スーパーローテーションシステムの簡易版）。

```gdscript
# active_piece.gd
class_name ActivePiece
extends Node2D

var _cells: Array[Vector2i] = []
var _origin: Vector2i = Vector2i.ZERO

func try_rotate(board: Board) -> bool:
    var rotated: Array[Vector2i] = _rotate_cells(_cells, _origin)
    # ウォールキック: 0, -1, +1, -2, +2 のオフセットを順に試す
    for offset_x: int in [0, -1, 1, -2, 2]:
        var shifted: Array[Vector2i] = []
        for c: Vector2i in rotated:
            shifted.append(Vector2i(c.x + offset_x, c.y))
        if board.is_valid_position(shifted):
            _cells = shifted
            return true
    return false

func _rotate_cells(cells: Array[Vector2i], origin: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for cell: Vector2i in cells:
        var local: Vector2i = cell - origin
        # 90° 時計回り: (x, y) → (y, -x)  ※ 反時計回りは (-y, x)
        result.append(Vector2i(local.y, -local.x) + origin)
    return result
```

### スコア計算とレベル更新

消去ライン数に応じてスコアを累積し、一定ライン数ごとにレベルアップして
重力タイマー間隔を短縮する。

```gdscript
# game.gd
const LINES_PER_LEVEL: int = 10
const BASE_GRAVITY_SEC: float = 1.0
const GRAVITY_DECREMENT: float = 0.07

@onready var _gravity_timer: Timer = $GravityTimer
@onready var _board: Board = $Board

var _score: int = 0
var _level: int = 1
var _total_lines: int = 0

func _on_lines_cleared(count: int) -> void:
    var points: Array[int] = [0, 100, 300, 500, 800]
    _score += points[mini(count, 4)] * _level
    _total_lines += count
    var new_level: int = (_total_lines / LINES_PER_LEVEL) + 1
    if new_level > _level:
        _level = new_level
        var interval: float = maxf(0.1, BASE_GRAVITY_SEC - (_level - 1) * GRAVITY_DECREMENT)
        _gravity_timer.wait_time = interval
        Logger.info("Game: level up to %d, gravity=%.2f" % [_level, interval])
    EventBus.score_updated.emit(_score, _level, _total_lines)
```

---

## よくある地雷

- 重力ループを `_process()` の `delta` 累積で実装するとポーズ中にも進む → `Timer` ノードを `process_callback = TIMER_PROCESS_IDLE` で使い、ポーズ時は `paused = true` にする
- ライン消去後に `for y in ROWS` でインデックスをインクリメントすると、行がシフトした直後の行を飛ばすバグが発生する → `while` ループで同じ `y` を再チェックする
- ゴーストピース計算を毎フレーム全行スキャンすると重い → ピース移動・回転のタイミングのみ更新し、結果をキャッシュする
- `Array[int]` にした内部配列を `duplicate()` せずに使い回すと、消去処理後に参照がずれる → `_init_grid()` で必ず新規配列を生成する
- テトロミノの定義を `const` 配列で持つ場合、GDScript の `const` は深い複製をしない → 回転時は毎回新しい `Array[Vector2i]` を生成して元データを汚さない

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/falling-puzzle.md` | このファイル |
| Autoload | なし（コアのみ使用） | ProgressManager はオプション stub のまま残してよい |

project.godot から追加で削除するエントリなし（このジャンルはコア Autoload のみ使用する）。
