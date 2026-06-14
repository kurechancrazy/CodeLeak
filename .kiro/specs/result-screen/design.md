# Design — リザルト画面

## Architecture Pattern & Boundary Map

リザルト画面は既存 Autoload 群（GameManager・PuzzleManager・SaveManager・SceneManager）を読み取り専用で利用する。書き込みは SceneManager への `scene_change_requested` のみ。

```
game_screen.gd
  │
  │ 1. SaveManager.get_value("progress","scores") で旧スコア取得
  │ 2. is_new_high_score を判定
  │ 3. GameManager.last_result に格納
  │ 4. EventBus.puzzle_completed.emit(...)
  │    └─ SaveManager._on_puzzle_completed() → 保存
  │ 5. EventBus.scene_change_requested.emit("result_screen", "fade")
  │
  ▼
result_screen.gd
  │  _ready() で読み取り
  │  ├── GameManager.last_result   (score, miss, time, hints, is_new_high_score)
  │  └── PuzzleManager.current_puzzle  (title, bug_type)
  │
  ├── [RETRY]      → EventBus.scene_change_requested("game_screen")
  └── [MAIN MENU]  → EventBus.scene_change_requested("main_menu")
```

---

## Technology Stack & Alignment

| 役割 | 採用技術 | 根拠 |
|------|---------|------|
| シーン型 | `Control`（MarginContainer） | game_hud・pause_menu と同じ CanvasLayer 不要の全画面 UI |
| アニメーション | `Tween`（create_tween） | `gameplay-screen` の既存パターンと統一 |
| データ読み取り | Autoload 直接参照（読み取りのみ） | EventBus 経由は不要（読み取りのみで副作用なし） |
| 状態遷移 | `EventBus.game_state_change_requested` | GameManager への書き込みは EventBus 経由ルール準拠 |

---

## Components & Interface Contracts

### 1. GameManager の拡張（`autoloads/game_manager.gd`）

**追加: GameState enum に `RESULT` を追加**

```
enum GameState {
    ...
    LEVEL_CLEAR,
    RESULT,      # ← 追加
    GAME_CLEAR,
}
```

**追加: last_result フィールド**

```
var last_result: Dictionary = {
    "score": 0,           # int  — 最終スコア
    "miss_count": 0,      # int  — ミス回数
    "elapsed_time": 0.0,  # float — クリアタイム（秒）
    "hints_used": 0,      # int  — ヒント使用数
    "is_new_high_score": false,  # bool
}
```

- `last_result` はゲームプレイ終了時に `game_screen.gd` が格納する
- リザルト画面は `_ready()` で読み取り専用アクセスする

---

### 2. game_screen.gd の修正（`scenes/game/game_screen.gd`）

**`_on_secured_sequence_done()` の処理順変更**:

```
旧:
  EventBus.puzzle_completed.emit(score, miss, time)
  EventBus.scene_change_requested.emit("main_menu", "fade")

新:
  1. final_score = ScoreCalc.calculate_final_score(...)
  2. scores_json = SaveManager.get_value("progress", "scores", "{}")
  3. old_score = int(JSON.parse_string(scores_json).get(level_id, 0))
  4. GameManager.last_result = {
       "score": final_score,
       "miss_count": PuzzleManager.miss_count,
       "elapsed_time": PuzzleManager.elapsed_time,
       "hints_used": PuzzleManager.hints_used,
       "is_new_high_score": final_score > old_score
     }
  5. EventBus.puzzle_completed.emit(final_score, miss_count, elapsed_time)
     └─ SaveManager が同フレームで書き込み（ここで保存が完了する）
  6. EventBus.scene_change_requested.emit("res://scenes/ui/result_screen.tscn", "fade")
```

---

### 3. ResultScreen（`scenes/ui/result_screen.tscn` + `result_screen.gd`）

**ノード構成**:

```
ResultScreen (MarginContainer, anchor full rect)
└── VBoxContainer (_layout)
    ├── Label (_title_label)          "// ANALYSIS COMPLETE"
    ├── Label (_level_label)          レベルタイトル
    ├── Label (_bug_type_label)       "[BACKDOOR]" など
    ├── HSeparator
    ├── Label (_rank_label)           "S" / "A" / "B" / "C" / "D"（72px）
    ├── Label (_score_label)          "SCORE: 1000"
    ├── Label (_time_label)           "TIME:  00:42"
    ├── Label (_miss_label)           "MISS:  2"
    ├── Label (_hints_label)          "HINTS USED: 1"
    ├── Label (_new_high_label)       ">> NEW HIGH SCORE!" （条件付き表示）
    ├── HSeparator
    └── HBoxContainer (_buttons)
        ├── Button (_retry_btn)       "[RETRY]"
        └── Button (_main_menu_btn)   "[MAIN MENU]"
```

**スクリプト公開インターフェース**:

```
# シグナル（なし）

# 内部フロー
func _ready() -> void
  → _load_result_data()    # GameManager.last_result + PuzzleManager から取得
  → _build_layout()        # ノード生成
  → _apply_styles()        # 色・フォント適用
  → _play_intro_sequence() # タイプライター Tween

func _play_intro_sequence() -> void
  → 各ラベルを 100ms 間隔で visible = true
  → 完了後: _buttons を表示、_animation_done = true

func _on_retry_pressed() -> void
  → EventBus.game_state_change_requested.emit(GameManager.GameState.PLAYING)
  → EventBus.scene_change_requested.emit("res://scenes/game/game_screen.tscn", "fade")

func _on_main_menu_pressed() -> void
  → EventBus.game_state_change_requested.emit(GameManager.GameState.MAIN_MENU)
  → EventBus.scene_change_requested.emit("res://scenes/ui/main_menu.tscn", "fade")

func _input(event: InputEvent) -> void
  → confirm アクション → _on_retry_pressed()     (animation_done のみ)
  → cancel アクション  → _on_main_menu_pressed()  (animation_done のみ)
```

**状態フィールド（内部）**:

```
var _animation_done: bool = false
var _result_score: int
var _result_miss: int
var _result_time: float
var _result_hints: int
var _result_is_new_high: bool
var _rank: String

# 色定数（var、Color.html() は非定数式）
var _COLOR_BG: Color     = Color.html("#0d0d0d")
var _COLOR_TEXT: Color   = Color.html("#00ff41")
var _COLOR_DIM: Color    = Color.html("#555555")
var _COLOR_GOLD: Color   = Color.html("#ffd700")
```

---

### 4. ハイスコア演出の詳細

| 条件 | `_new_high_label` | `_score_label` 色 |
|------|------------------|------------------|
| is_new_high_score = true | visible = true、点滅 Tween（0.5s周期） | `_COLOR_GOLD` |
| is_new_high_score = false | visible = false | `_COLOR_TEXT` |

点滅 Tween:
```
tween.set_loops()
tween.tween_property(_new_high_label, "modulate:a", 0.0, 0.25)
tween.tween_property(_new_high_label, "modulate:a", 1.0, 0.25)
```

---

### 5. タイプライター演出シーケンス

| 順序 | ノード | 遅延 |
|-----|-------|------|
| 1 | `_title_label` | 即時 |
| 2 | `_level_label` | +100ms |
| 3 | `_bug_type_label` | +100ms |
| 4 | `_rank_label` | +100ms |
| 5 | `_score_label` | +100ms |
| 6 | `_time_label` | +100ms |
| 7 | `_miss_label` | +100ms |
| 8 | `_hints_label` | +100ms |
| 9 | `_new_high_label`（条件付き） | +100ms |
| 10 | `_buttons`（HBoxContainer） | +200ms |

全8〜9項目 × 100ms = 最大 1.1s（要件 2.2.3 の 2s 以内を満たす）

---

## 要件トレーサビリティ

| 要件 ID | 対応コンポーネント |
|---------|----------------|
| 1.1.1 | game_screen.gd: scene_change_requested を result_screen に変更 |
| 1.1.2 | game_screen.gd: GameManager.last_result に格納 |
| 1.1.3 | result_screen.gd: _ready() で RESULT ステートに遷移 |
| 1.2.1 | result_screen.gd: _on_retry_pressed() |
| 1.2.2 | result_screen.gd: _on_main_menu_pressed() |
| 1.2.3, 1.2.4 | result_screen.gd: _input() |
| 2.1.1〜2.1.7 | result_screen.gd: _build_layout() + _load_result_data() |
| 2.2.1〜2.2.3 | result_screen.gd: _play_intro_sequence() |
| 3.1.1〜3.1.3 | game_screen.gd: is_new_high_score 判定ロジック |
| 3.2.1〜3.2.2 | result_screen.gd: ハイスコア点滅 Tween |
| 4.1.1〜4.1.5 | result_screen.gd: _apply_styles() |
| 4.2.1〜4.2.3 | result_screen.gd: _build_layout() ボタン設定 |
| 5.1.1 | SaveManager（既存）: puzzle_completed で自動保存 |
| 5.1.2 | 保存は puzzle_completed emit と同フレームで完了（Tween より前） |
