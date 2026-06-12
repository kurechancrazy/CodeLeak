# リズムゲーム — ジャンルガイド

**次元:** 2D / UI 専用  
**genre-starters.md:** バンドル 4

---

## コアループ

音楽に合わせてスクロールするノートをタイミングよくタップ / キーで叩き、
PERFECT / GOOD / MISS 判定で得点を稼ぐ。
**音楽時刻との同期・ノートスポーン・タイミング判定**が品質の核心。

---

## シーン階層

```
RhythmGame (Node2D)
├── MusicPlayer (AudioStreamPlayer)  — 楽曲再生（AudioManager は使わない）
├── Lanes (Node2D)                   — レーン数分の Node2D
│   ├── Lane_0 (Node2D)
│   │   └── NotePool (Node2D)        — ObjectPool でノート Sprite2D を再利用
│   ├── Lane_1 (Node2D)
│   ├── Lane_2 (Node2D)
│   └── Lane_3 (Node2D)
├── JudgeLine (Line2D)               — 判定ライン（固定位置）
└── HUD (CanvasLayer)
    ├── ScoreLabel
    ├── ComboLabel
    ├── JudgmentLabel                — PERFECT / GOOD / MISS を一瞬表示
    └── AccuracyBar (ProgressBar)
```

---

## 必須 Autoload

コアのみ使用。AudioManager は使わず `AudioStreamPlayer` を直接使う（再生位置の精度確保のため）。

---

## 主要実装パターン

### 音楽時刻との同期 + ノートスポーン

```gdscript
# RhythmGame.gd
extends Node2D

@onready var _music: AudioStreamPlayer = $MusicPlayer
@onready var _lanes: Node2D = $Lanes

# ビートマップデータ（Resource として外部定義）
@export var beat_map: Array[Dictionary] = []
# 各エントリ: {"time": float, "lane": int}

var _next_note_index: int = 0
const NOTE_LEAD_TIME: float = 1.5  # 判定ラインに到達するまでの秒数

func _ready() -> void:
    _music.play()

func _get_music_time() -> float:
    # AudioServer のレイテンシ補正を加算して精度を上げる
    return (_music.get_playback_position()
        + AudioServer.get_time_since_last_mix()
        - AudioServer.get_output_latency())

func _process(_delta: float) -> void:
    var music_time: float = _get_music_time()
    while _next_note_index < beat_map.size():
        var entry: Dictionary = beat_map[_next_note_index]
        var note_time: float = entry.get("time", 0.0)
        if note_time - music_time > NOTE_LEAD_TIME:
            break
        _spawn_note(entry.get("lane", 0), note_time)
        _next_note_index += 1

func _spawn_note(lane: int, note_time: float) -> void:
    var note: Node2D = _note_pool.get_instance()
    note.set_meta("note_time", note_time)
    note.set_meta("lane", lane)
    _lanes.get_child(lane).get_node("NotePool").add_child(note)
    Logger.info("Note spawned", {"lane": lane, "note_time": note_time})
```

### 判定ウィンドウ + コンボ管理

```gdscript
# RhythmGame.gd（続き）

const PERFECT_WINDOW: float = 0.045  # ±45 ms
const GOOD_WINDOW: float = 0.090     # ±90 ms

var _score: int = 0
var _combo: int = 0

enum Judgment { PERFECT, GOOD, MISS }

func on_lane_pressed(lane: int) -> void:
    var music_time: float = _get_music_time()
    var best_note: Node2D = _find_closest_active_note(lane, music_time)
    if best_note == null:
        return
    var note_time: float = best_note.get_meta("note_time")
    var diff: float = absf(music_time - note_time)
    var judgment: Judgment
    if diff <= PERFECT_WINDOW:
        judgment = Judgment.PERFECT
    elif diff <= GOOD_WINDOW:
        judgment = Judgment.GOOD
    else:
        return  # まだ早すぎる
    _apply_judgment(judgment, best_note)

func _find_closest_active_note(lane: int, music_time: float) -> Node2D:
    var pool: Node2D = _lanes.get_child(lane).get_node("NotePool")
    var best: Node2D = null
    var best_diff: float = GOOD_WINDOW + 0.001
    for child: Node in pool.get_children():
        if not child is Node2D:
            continue
        var note: Node2D = child as Node2D
        var diff: float = absf(music_time - float(note.get_meta("note_time")))
        if diff < best_diff:
            best_diff = diff
            best = note
    return best

func _apply_judgment(j: Judgment, note: Node2D) -> void:
    match j:
        Judgment.PERFECT:
            _score += 300 + _combo * 10
            _combo += 1
        Judgment.GOOD:
            _score += 100
            _combo += 1
        Judgment.MISS:
            _combo = 0
    note.queue_free()
    EventBus.judgment_made.emit(j, _combo)
    Logger.info("Judgment applied", {"judgment": j, "combo": _combo, "score": _score})
```

### MISS 判定（ノートが判定ラインを通過した場合）

```gdscript
# Note.gd — 各ノートの移動と通過 MISS 検出
extends Node2D

const SCROLL_SPEED: float = 400.0      # px / 秒
const MISS_THRESHOLD_Y: float = 100.0  # 判定ラインより下にこれだけ超えたら MISS

func _process(delta: float) -> void:
    position.y += SCROLL_SPEED * delta
    if position.y > MISS_THRESHOLD_Y:
        EventBus.note_missed.emit()
        Logger.info("Note missed", {"position_y": position.y})
        queue_free()
```

---

## よくある地雷

- `AudioStreamPlayer.get_playback_position()` はバッファリングで若干遅れる → `AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()` を加算して補正する（パターン 1 参照）
- ノートを `instantiate()` で毎回生成するとフレームスパイクが起きる → `scripts/utils/object_pool.gd` の ObjectPool を使って再利用する
- 楽曲再生開始と同時に `_process` が走ると最初のノートがスポーンされないことがある → `_music.play()` を `_ready()` の最後に呼び、`await get_tree().process_frame` を挟まない（シグナルベースで対応）
- 判定ウィンドウを `_process` の `delta` 精度で計算するとフレームレートに依存する → 常に `get_playback_position()` ベースの絶対時刻で比較する
- レーンインデックスが beat_map の範囲外になるとクラッシュする → `_spawn_note` でレーン数チェックを行う

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/rhythm.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
