# マッチ3パズル — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 4

---

## コアループ

グリッド上の宝石を隣接するマスと入れ替え、同色を3個以上一直線に並べて消去して得点を得る。
マッチ検出・重力落下・カスケード（連鎖）制御の3要素が核心。
消去後の空白を上から新規宝石で補充し、連鎖が途切れるまで繰り返す。

---

## シーン階層

```
Game (Node2D)
├── Board (Node2D)
│   └── GemGrid (Node2D)          — Gem インスタンスを cols×rows 並べる
│       └── Gem (Sprite2D × N)    — 各マスの宝石スプライト
├── SelectionHighlight (Sprite2D) — 選択中マスの強調表示
└── HUD (CanvasLayer)
    ├── ScoreLabel
    ├── MovesLabel
    └── TargetLabel
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| AudioManager | マッチ音・連鎖 SE・BGM 再生 |
| ProgressManager | 最高スコア・クリア済みステージの永続化 |

---

## 主要実装パターン

### グリッドデータ + マッチ検出

グリッドは `Array` の `Array[int]` で管理する。値 `0` が空マス、1〜N が宝石の種類 ID。
横方向・縦方向を独立してスキャンし、重複セルを `has()` でフィルタする。

```gdscript
# board.gd
class_name Board
extends Node2D

const COLS: int = 8
const ROWS: int = 8
const GEM_TYPES: int = 5

var _grid: Array = []  # Array[Array[int]]

func _ready() -> void:
    _init_grid()
    _ensure_no_initial_matches()

func _init_grid() -> void:
    _grid.clear()
    for _y: int in ROWS:
        var row: Array[int] = []
        row.resize(COLS)
        for x: int in COLS:
            row[x] = randi_range(1, GEM_TYPES)
        _grid.append(row)

func find_matches() -> Array[Vector2i]:
    var matched: Array[Vector2i] = []
    # 横方向スキャン
    for y: int in ROWS:
        for x: int in range(COLS - 2):
            var t: int = _grid[y][x]
            if t != 0 and t == _grid[y][x + 1] and t == _grid[y][x + 2]:
                for dx: int in range(3):
                    var cell: Vector2i = Vector2i(x + dx, y)
                    if not matched.has(cell):
                        matched.append(cell)
    # 縦方向スキャン
    for x: int in COLS:
        for y: int in range(ROWS - 2):
            var t: int = _grid[y][x]
            if t != 0 and t == _grid[y + 1][x] and t == _grid[y + 2][x]:
                for dy: int in range(3):
                    var cell: Vector2i = Vector2i(x, y + dy)
                    if not matched.has(cell):
                        matched.append(cell)
    return matched

func _ensure_no_initial_matches() -> void:
    # 初期配置でマッチが出た場合、マッチしないランダム値を再割り当てする
    while not find_matches().is_empty():
        for cell: Vector2i in find_matches():
            _grid[cell.y][cell.x] = randi_range(1, GEM_TYPES)
```

### スワップ + カスケードループ

入れ替えてもマッチが生じない場合は即座に元に戻す。
カスケード中は入力をブロックし、グリッドが安定するまで繰り返す。

```gdscript
# board.gd（続き）
var _is_animating: bool = false

func try_swap(a: Vector2i, b: Vector2i) -> void:
    if _is_animating:
        return
    # 隣接チェック（チェビシェフ距離ではなくマンハッタン距離 = 1 のみ許可）
    if abs(a.x - b.x) + abs(a.y - b.y) != 1:
        return
    _swap_cells(a, b)
    if find_matches().is_empty():
        _swap_cells(a, b)  # マッチなし → 元に戻す
        return
    _is_animating = true
    await _process_cascade()
    _is_animating = false

func _process_cascade() -> void:
    while true:
        var matches: Array[Vector2i] = find_matches()
        if matches.is_empty():
            break
        var count: int = matches.size()
        _remove_cells(matches)
        EventBus.gems_matched.emit(count)
        await get_tree().create_timer(0.15).timeout  # 消去アニメーション待ち
        _apply_gravity()
        await get_tree().create_timer(0.12).timeout  # 落下アニメーション待ち
        _fill_empty_cells()
        await get_tree().create_timer(0.1).timeout   # 補充アニメーション待ち

func _remove_cells(cells: Array[Vector2i]) -> void:
    for cell: Vector2i in cells:
        _grid[cell.y][cell.x] = 0

func _swap_cells(a: Vector2i, b: Vector2i) -> void:
    var tmp: int = _grid[a.y][a.x]
    _grid[a.y][a.x] = _grid[b.y][b.x]
    _grid[b.y][b.x] = tmp
    Logger.info("Board: swapped (%d,%d) <-> (%d,%d)" % [a.x, a.y, b.x, b.y])
```

### 重力落下と上部補充

列ごとに下から詰め、上部に空きができたら新規宝石でランダムに埋める。

```gdscript
# board.gd（続き）
func _apply_gravity() -> void:
    for x: int in COLS:
        var write_y: int = ROWS - 1
        for read_y: int in range(ROWS - 1, -1, -1):
            if _grid[read_y][x] != 0:
                _grid[write_y][x] = _grid[read_y][x]
                if write_y != read_y:
                    _grid[read_y][x] = 0
                write_y -= 1

func _fill_empty_cells() -> void:
    for x: int in COLS:
        for y: int in ROWS:
            if _grid[y][x] == 0:
                _grid[y][x] = randi_range(1, GEM_TYPES)
```

### スコア計算（連鎖ボーナス）

連鎖数をカウントし、連鎖が深いほど倍率を高くする。

```gdscript
# game.gd
var _score: int = 0
var _combo: int = 0

func _on_gems_matched(count: int) -> void:
    _combo += 1
    var multiplier: float = 1.0 + (_combo - 1) * 0.5
    var gained: int = int(count * 10 * multiplier)
    _score += gained
    Logger.info("Game: +%d pts (combo=%d, matched=%d)" % [gained, _combo, count])
    EventBus.score_updated.emit(_score)

func _on_cascade_finished() -> void:
    _combo = 0
```

---

## よくある地雷

- カスケード中にプレイヤーが操作できるとグリッドが壊れる → `_is_animating` フラグでスワップ受付を制御する
- `find_matches()` の結果に重複が含まれると消去カウントが狂う → `has()` チェックで必ず重複排除する
- `_apply_gravity()` と `_fill_empty_cells()` の順序を逆にすると新規宝石が即座にマッチし連鎖が無限ループする → 重力を先に適用し、補充後に再スキャンする
- `await` 中にシーンが `queue_free()` されると to_local エラーが発生する → コールバック内で `if not is_instance_valid(self): return` を確認する
- 初期配置でマッチが生じていると開幕カスケードが起きてプレイヤーが意図しない消去を体験する → `_ensure_no_initial_matches()` で生成時に排除する

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/match3.md` | このファイル |
| Autoload | なし（コアのみ使用） | ProgressManager はオプション stub のまま残してよい |

project.godot から追加で削除するエントリなし（このジャンルはコア Autoload のみ使用する）。
