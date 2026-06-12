# パーティーゲーム — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 4

---

## コアループ

複数プレイヤーが順番にミニゲームをプレイして得点を競う。
ミニゲームシーケンサー・プレイヤー登録（1〜4 人）・ラウンドスコア集計が核心。

> **注意:** `autoloads/party_manager.gd` は JRPG のパーティーキャラクター編成用であり、
> このジャンルのプレイヤースコア管理とは無関係。混同しないこと。

---

## シーン階層

```
PartyGameRoot (Node2D)
├── PartyGameManager (Node)         — ミニゲームのシーケンス制御
├── PlayerRegistry (Node)           — プレイヤー 1〜4 の情報・スコア管理
└── UI (CanvasLayer)
    ├── ScoreBoard (PanelContainer) — 全プレイヤーの得点一覧
    ├── MiniGameTitle (Label)       — 次のミニゲーム名を表示
    └── CountdownLabel (Label)      — 3・2・1・GO!

# ミニゲーム単体シーン（SceneManager でロード）
MiniGame_Dodge (Node2D)
├── Arena (TileMapLayer)
├── Players (Node2D)
│   └── PlayerCharacter × n
└── ResultOverlay (CanvasLayer)
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| SceneManager | ミニゲームシーンの切り替え |
| AudioManager | BGM・SE 再生 |

---

## 主要実装パターン

### ミニゲームシーケンサー

```gdscript
# party_game_manager.gd
class_name PartyGameManager
extends Node

@export var mini_games: Array[PackedScene] = []
@export var rounds: int = 3

var _current_round: int = 0
var _current_game_index: int = 0

signal round_finished(scores: Dictionary)
signal game_over(final_scores: Dictionary)

func start() -> void:
    _current_round = 0
    _current_game_index = 0
    _play_next_mini_game()

func _play_next_mini_game() -> void:
    if _current_game_index >= mini_games.size():
        _current_game_index = 0
        _current_round += 1
        if _current_round >= rounds:
            game_over.emit(PlayerRegistry.get_all_scores())
            return
    var scene: PackedScene = mini_games[_current_game_index]
    _current_game_index += 1
    SceneManager.go_to(scene)

func on_mini_game_finished(scores: Dictionary) -> void:
    PlayerRegistry.add_scores(scores)
    round_finished.emit(scores)
    await get_tree().create_timer(3.0).timeout
    _play_next_mini_game()
```

### プレイヤー登録 + スコア管理

```gdscript
# player_registry.gd（Autoload またはシングルトンとして使用）
extends Node

const MAX_PLAYERS: int = 4

var _player_count: int = 2
var _scores: Dictionary = {}
var _colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]

func setup(player_count: int) -> void:
    _player_count = clampi(player_count, 1, MAX_PLAYERS)
    _scores.clear()
    for i: int in _player_count:
        _scores[i] = 0

func add_scores(delta: Dictionary) -> void:
    for pid: int in delta:
        _scores[pid] = _scores.get(pid, 0) + delta.get(pid, 0)

func get_all_scores() -> Dictionary:
    return _scores.duplicate()

func get_player_color(player_id: int) -> Color:
    return _colors[player_id % _colors.size()]

func get_winner_id() -> int:
    var best_id: int = 0
    var best_score: int = -1
    for pid: int in _scores:
        if _scores[pid] > best_score:
            best_score = _scores[pid]
            best_id = pid
    return best_id
```

### ミニゲーム内カウントダウン + 結果送信

```gdscript
# mini_game_base.gd — 各ミニゲームが extends するベース
extends Node2D

var _time_limit: float = 30.0
var _elapsed: float = 0.0
var _is_active: bool = false
var _results: Dictionary = {}   # {player_id: int -> score: int}

func start_game() -> void:
    await _show_countdown()
    _is_active = true

func _show_countdown() -> void:
    for i: int in [3, 2, 1]:
        EventBus.countdown_tick.emit(i)
        await get_tree().create_timer(1.0).timeout
    EventBus.countdown_tick.emit(0)   # GO!

func _process(delta: float) -> void:
    if not _is_active:
        return
    _elapsed += delta
    if _elapsed >= _time_limit:
        _finish_game()

func _finish_game() -> void:
    _is_active = false
    EventBus.mini_game_finished.emit(_results)
```

### スコアボード表示

```gdscript
# score_board.gd
extends PanelContainer

@onready var _rows: Array[HBoxContainer] = []

func refresh(scores: Dictionary) -> void:
    for pid: int in scores:
        if pid >= _rows.size():
            continue
        var row: HBoxContainer = _rows[pid]
        var label: Label = row.get_node("ScoreLabel") as Label
        label.text = str(scores[pid])
        row.modulate = PlayerRegistry.get_player_color(pid)
```

---

## よくある地雷

- `autoloads/party_manager.gd` は JRPG のパーティーキャラクター管理用であり、このジャンルのプレイヤースコア管理とは無関係。混同しないこと
- ミニゲームシーン切り替え時に `PlayerRegistry` のスコアがリセットされると思いがちだが、Autoload はシーン切り替えで破棄されないのでデータは保持される
- カウントダウン中も `_process` が走る → `_is_active` フラグで制御しないとタイマーが先走る
- `Dictionary` のキーに `int` と `String` が混在すると `get()` が意図通りに動かない → キー型を統一する
- `get_tree().create_timer()` の `await` 中にシーンが破棄されると孤立シグナルになる → ミニゲームシーン遷移前にタイマーを確実に完了させるか、`is_inside_tree()` で保護する

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/party-game.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
