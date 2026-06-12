# Design: ゲームプレイ画面

## 概要

ゲームプレイ画面は左ペイン（コードパネル）と右ペイン（調査パネル）の2カラム構成で、プレイヤーが疑似コードを読んで怪しい行を選択し、修正選択肢を回答するコアループを実現する。ビジネスロジックは `PuzzleManager` Autoload に集約し、シーンはシグナルの受信と表示更新のみを担う。

---

## ファイル配置計画

| ファイルパス | レイヤー | 行数上限 | 内容 |
|------------|--------|---------|------|
| `scripts/data/puzzle_question.gd` | Domain | 20 | PuzzleQuestion Resource（型安全な質問データ） |
| `scripts/data/puzzle_data.gd` | Domain | 40 | PuzzleData Resource（レベルデータコンテナ） |
| `scripts/utils/score_calc.gd` | Domain | 50 | スコア計算純粋関数・ランク判定 |
| `autoloads/puzzle_manager.gd` | Application | 150 | パズル進行・状態管理・タイマー |
| `autoloads/event_bus.gd` | Application | 150 | パズル用シグナル追加（既存ファイル拡張） |
| `autoloads/game_manager.gd` | Application | 150 | GameState 拡張（既存ファイル拡張） |
| `autoloads/save_manager.gd` | Application | 150 | 進捗保存拡張（既存ファイル拡張） |
| `scenes/game/game_screen.tscn` + `.gd` | Presentation | 80 | ゲームプレイメイン画面（2カラム統合） |
| `scenes/game/code_panel.tscn` + `.gd` | Presentation | 100 | コード表示・行選択UI |
| `scenes/game/investigation_panel.tscn` + `.gd` | Presentation | 100 | 質問・選択肢・ヒントUI |
| `scenes/ui/game_hud.tscn` + `.gd` | Presentation | 80 | HUD（タイマー・スコア・ヒント数） |
| `scenes/ui/pause_menu.tscn` + `.gd` | Presentation | 50 | ポーズオーバーレイ |
| `resources/puzzles/level_001.tres` | Data | — | サンプルパズルデータ（動作確認用） |
| `tests/unit/test_puzzle_manager.gd` | Test | 200 | PuzzleManager 正常系・異常系・境界値 |
| `tests/unit/test_score_calc.gd` | Test | 100 | スコア計算全関数テスト |

> `PuzzleManager` は `project.godot` の `[autoload]` に `GameManager` の直後（順序4番目）に追加する。

---

## アーキテクチャ制約チェック

```
✅ PuzzleManager は EventBus 経由でのみ他 Autoload と通信する
✅ scenes/ スクリプトはシグナルを受けて表示更新するだけ（ロジックなし）
✅ scripts/utils/score_calc.gd は副作用なし（純粋関数のみ）
✅ 全変数・パラメータ・戻り値に型アノテーション
✅ print() を使わない（Logger を使用）
✅ get_node("../../xxx") のハードコードパス使用禁止
✅ 新規ファイルの行数が上限以内
✅ PuzzleManager._exit_tree() でシグナル切断を実装する
```

---

## データモデル

### PuzzleQuestion（要件 8.2 の型安全版）

```
class_name PuzzleQuestion
extends Resource

@export var prompt: String         # 質問文（英語）
@export var choices: Array[String] # 選択肢リスト（2〜4要素、英語）
@export var correct_index: int     # 正解インデックス（0始まり）
@export var explanation: String    # 解説テキスト（英語、正解時に表示）
```

> **設計決定:** 要件 8.2 は `Array[Dictionary]` と定義しているが、型安全性確保のため `PuzzleQuestion extends Resource` クラスに昇格させる。GDScript の typed array `Array[PuzzleQuestion]` により、コンパイル時チェックが可能。

### PuzzleData（要件 8.1）

```
class_name PuzzleData
extends Resource

@export var level_id: String              # 例: "level_001"
@export var title: String                 # 例: "The Obedient Liar"
@export var flavor_text: String           # AIの正体・目的ナラティブ（英語）
@export var bug_type: String              # 例: "BACKDOOR"
@export var code_lines: Array[String]     # 疑似コード行（英語）
@export var questions: Array[PuzzleQuestion]
@export var hint_lines: Array[int]        # ヒント対象の行番号リスト
```

### PuzzleManager 内部状態

```
current_puzzle: PuzzleData       # 現在ロード中のパズル
current_question_index: int = 0  # 現在の質問インデックス
selected_line: int = -1          # 選択中のコード行（-1=未選択）
miss_count: int = 0              # ミス回数
hints_remaining: int = 3         # 残りヒント数
hints_used: int = 0              # 使用済みヒント数（スコア計算用）
elapsed_time: float = 0.0        # 経過時間（秒）
_timer_active: bool = false      # タイマー動作フラグ
```

---

## コンポーネント設計

### GameScreen（`scenes/game/game_screen.tscn`）

```
GameScreen (MarginContainer, PROCESS_MODE_PAUSABLE)
  ├── HSplitContainer
  │     ├── CodePanel (シーン参照, 60% 幅)
  │     └── InvestigationPanel (シーン参照, 40% 幅)
  ├── GameHUD (CanvasLayer, PROCESS_MODE_WHEN_PAUSED)
  └── PauseMenu (CanvasLayer, PROCESS_MODE_WHEN_PAUSED, 初期非表示)
```

`game_screen.gd` の責務：
- `PuzzleManager.load_puzzle(puzzle)` の呼び出し（シーン開始時）
- `EventBus.level_cleared` を受信してタイプライター演出の起動
- ポーズトグルの処理（`pause` アクション → `GameManager.transition_to(PAUSED)`）

### CodePanel（`scenes/game/code_panel.tscn`）

```
CodePanel (PanelContainer, 背景 #0d0d0d)
  └── ScrollContainer
        └── VBoxContainer  ← _code_lines_container
              └── [各行] HBoxContainer
                    ├── Label  (行番号, color #555555, 幅固定40px)
                    └── Button (コードテキスト, flat style, color #00ff41)
                               ← 4状態 StyleBox: normal/hover/focus/patched
```

`code_panel.gd` の責務：
- `EventBus.puzzle_loaded` を受信してコード行を動的生成
- 各行 Button の `pressed` → `EventBus.line_selected.emit(line_index)`
- `mouse_entered` → ホバー色 `#1a1a2e` 適用（要件 9.2）
- `EventBus.hint_applied` を受信して該当行に波線マーカーを表示
- `EventBus.answer_submitted(true, ...)` を受信して `>> PATCHED` をアペンド（要件 6.1.1）
- `move_up/move_down` 入力で選択カーソルを移動（要件 2.2.1）
- `confirm` 入力で選択確定（要件 2.2.2）
- WHILE `ANIMATING` 状態：行選択を無効化（要件 2.1.3）

### InvestigationPanel（`scenes/game/investigation_panel.tscn`）

```
InvestigationPanel (PanelContainer, 背景 #0a0a1a)
  └── VBoxContainer
        ├── RichTextLabel  _flavor_label   (フレーバーテキスト)
        ├── HSeparator
        ├── Label          _prompt_label   (質問プロンプト、初期非表示)
        ├── VBoxContainer  _choices_container (選択肢ボタン群、初期非表示)
        │     └── [各選択肢] Button ([A]〜[D] + テキスト, 最小高さ 40px)
        ├── HSeparator
        └── Button         _hint_button    ([HINT] ボタン)
```

`investigation_panel.gd` の責務：
- `EventBus.puzzle_loaded` を受信してフレーバーテキストを表示
- `EventBus.line_selected` を受信して質問・選択肢を表示
- A/B/C/D キー入力の受付（要件 3.1.3）
- 選択肢ボタン押下 → `PuzzleManager.submit_answer(choice_index)` を呼び出し
- `EventBus.answer_submitted` を受信してフィードバック演出を再生
  - 正解：パネルを `#00ff41` にフラッシュ 0.3秒、解説テキストを表示
  - 不正解：パネルを `#ff0000` にフラッシュ 0.2秒、`>> ACCESS DENIED` を表示
- `_hint_button.pressed` → `EventBus.hint_requested.emit()`
- `EventBus.hint_applied` を受信してヒント数表示を更新

### GameHUD（`scenes/ui/game_hud.tscn`）

```
GameHUD (CanvasLayer)
  └── HBoxContainer (画面上部バー)
        ├── Label  _level_label    ("LEVEL 1 / 5")
        ├── Label  _bug_type_label ("[BACKDOOR]")
        ├── Label  _hints_label    ("HINTS: |||" ← 残数をパイプ記号で表現)
        ├── Label  _timer_label    ("00:23")
        ├── Label  _score_label    ("SCORE: 850")
        └── Button _pause_button   ("[||]")
```

`game_hud.gd` の責務：
- `EventBus.puzzle_loaded` を受信して初期値表示
- `EventBus.hint_applied` を受信してヒント残数を更新
- `EventBus.answer_submitted(false, ...)` を受信してミス数反映スコアを更新
- `_process(delta)` でタイマーラベルを更新（PuzzleManager.elapsed_time を参照）
- `_pause_button.pressed` → ポーズトグル

### PauseMenu（`scenes/ui/pause_menu.tscn`）

```
PauseMenu (CanvasLayer, PROCESS_MODE_WHEN_PAUSED)
  └── PanelContainer (中央配置)
        └── VBoxContainer
              ├── Label   ("// PAUSED")
              ├── Button  _resume_button   ("[RESUME]")
              ├── Button  _restart_button  ("[RESTART LEVEL]")
              └── Button  _mainmenu_button ("[MAIN MENU]")
```

`pause_menu.gd` の責務：
- `_resume_button.pressed` → `EventBus.game_paused.emit(false)`
- `_restart_button.pressed` → `EventBus.level_restarted.emit()`
- `_mainmenu_button.pressed` → `EventBus.scene_change_requested.emit("res://scenes/ui/main_menu.tscn", "fade")`

### PuzzleManager（`autoloads/puzzle_manager.gd`）

公開 API：

| メソッド | 引数 | 戻り値 | 説明 |
|---------|------|--------|------|
| `load_puzzle(puzzle)` | `PuzzleData` | `void` | パズルをロードして初期化 |
| `submit_answer(choice_index)` | `int` | `void` | 選択肢回答を処理 |
| `use_hint()` | — | `void` | ヒント使用を処理 |
| `restart_level()` | — | `void` | 現在レベルを再初期化 |
| `get_current_question()` | — | `PuzzleQuestion` | 現在の質問を返す |
| `calculate_score()` | — | `int` | 現時点のスコアを返す |

### score_calc.gd（純粋関数）

| 関数 | 引数 | 戻り値 | 説明 |
|------|------|--------|------|
| `calculate_base_score(miss_count, elapsed_secs)` | `int, float` | `int` | ベーススコア計算（最低100） |
| `apply_hint_penalty(base_score, hints_used)` | `int, int` | `int` | ヒントペナルティ適用（×0.8^n） |
| `calculate_final_score(miss_count, elapsed_secs, hints_used)` | `int, float, int` | `int` | 最終スコア計算 |
| `calculate_rank(score)` | `int` | `String` | S/A/B/C/D ランク判定 |

ランク閾値：S(≥900) / A(≥700) / B(≥500) / C(≥300) / D(<300)

---

## 画面レイアウト（ASCII図）

```
┌──────────────────────────────────────────────────────────────────────────┐
│  [HUD] LEVEL 1/5  [BACKDOOR]  HINTS: |||  00:23  SCORE: 850  [||]       │
├────────────────────────────────────┬─────────────────────────────────────┤
│ CODE TERMINAL                      │ INVESTIGATION TERMINAL               │
│ ─────────────────────────────────  │ ──────────────────────────────────── │
│  01│ def initialize():             │  TARGET: DAEMON_INIT.py             │
│  02│   self.mode = "safe"          │                                      │
│  03│   if DEBUG:                   │  This AI was designed to optimize   │
│▶ 04│     log("booting...")         │  network traffic. But analysts      │
│  05│   self._start()               │  detected unusual connections at    │
│  06│   return True                 │  3:17 AM every Thursday...          │
│  07│                               │ ──────────────────────────────────── │
│  08│ def _start(self):             │  What does _start() do that         │
│  09│   self.payload = None         │  initialize() doesn't expect?       │
│  10│   if PROD:                    │                                      │
│  11│     self._connect()           │  [A] Returns True unconditionally   │
│                                    │  [B] Sets payload before mode check │
│                                    │  [C] Bypasses the DEBUG guard       │
│                                    │  [D] Calls _connect() in PROD only  │
│                                    │                                      │
│                                    │  [ HINT ] (2 remaining)             │
└────────────────────────────────────┴─────────────────────────────────────┘
```

---

## EventBus の変更

既存の `event_bus.gd` に以下のシグナルブロックを追加する。

| シグナル名 | パラメータ | 発行者 | 購読者 |
|-----------|----------|--------|--------|
| `puzzle_loaded` | `puzzle: PuzzleData` | PuzzleManager | CodePanel, InvestigationPanel, GameHUD |
| `line_selected` | `line_index: int` | CodePanel | PuzzleManager, InvestigationPanel |
| `answer_submitted` | `correct: bool, explanation: String` | PuzzleManager | CodePanel, InvestigationPanel, GameHUD |
| `hint_requested` | — | InvestigationPanel | PuzzleManager |
| `hint_applied` | `line_index: int` | PuzzleManager | CodePanel, GameHUD |
| `puzzle_completed` | `score: int, miss_count: int, elapsed_time: float` | PuzzleManager | SaveManager |
| `level_cleared` | — | PuzzleManager | GameScreen |
| `level_restarted` | — | PauseMenu | PuzzleManager, GameScreen |

---

## データフロー（ASCII図）

### A. コード行選択 → 選択肢表示

```
プレイヤーがコード行をクリック（or confirm キー）
  → scenes/game/code_panel.gd: line_button.pressed
    → EventBus.line_selected.emit(line_index)
      ├── autoloads/puzzle_manager.gd: selected_line = line_index
      └── scenes/game/investigation_panel.gd: _on_line_selected(line_index)
            → 質問プロンプト・選択肢ボタンを表示
```

### B. 選択肢回答 → 正誤判定 → フィードバック

```
プレイヤーが選択肢をクリック（or A/B/C/D キー）
  → scenes/game/investigation_panel.gd: choice_button.pressed
    → autoloads/puzzle_manager.gd: submit_answer(choice_index)
          → GameManager.transition_to(ANIMATING)
          → if correct:
              question_index++
              EventBus.answer_submitted.emit(true, explanation)
              if all questions done → EventBus.level_cleared.emit()
          → if not correct:
              miss_count++
              EventBus.answer_submitted.emit(false, "")
      ├── scenes/game/code_panel.gd: _on_answer_submitted(correct, _)
      │     → if correct: 行に ">> PATCHED" を表示（緑フラッシュ 0.3s）
      │     → if not correct: 何もしない
      └── scenes/game/investigation_panel.gd: _on_answer_submitted(correct, explanation)
            → if correct: 解説テキスト表示 → 次質問または完了
            → if not correct: ">> ACCESS DENIED" 表示（赤フラッシュ 0.2s）
                  → Tween 完了後: 選択肢を再表示（即リトライ）
                  → GameManager.transition_to(PLAYING)
```

### C. ヒント使用

```
プレイヤーが [HINT] ボタンをクリック
  → scenes/game/investigation_panel.gd: _hint_button.pressed
    → EventBus.hint_requested.emit()
      → autoloads/puzzle_manager.gd: _on_hint_requested()
            hints_remaining-- / hints_used++
            EventBus.hint_applied.emit(hint_line_index)
        ├── scenes/game/code_panel.gd: _on_hint_applied(line_index)
        │     → 当該行に波線マーカーを追加
        └── scenes/ui/game_hud.gd: _on_hint_applied(_)
              → ヒント残数表示を更新
```

### D. レベルクリア → スコア保存 → リザルト遷移

```
EventBus.level_cleared.emit()
  ├── scenes/game/game_screen.gd: _on_level_cleared()
  │     → GameManager.transition_to(LEVEL_CLEAR)
  │     → タイプライター演出 "[SYSTEM SECURED]" 再生
  │       → Tween 完了後:
  │           EventBus.puzzle_completed.emit(score, miss, time)
  │           EventBus.scene_change_requested.emit("res://scenes/game/result_screen.tscn", "fade")
  └── autoloads/puzzle_manager.gd: _stop_timer()
```

```
EventBus.puzzle_completed.emit(score, miss_count, elapsed_time)
  → autoloads/save_manager.gd: _on_puzzle_completed(score, miss_count, elapsed_time)
        → update progress/scores[level_id] if score > best
        → update progress/level_reached if needed
        → save_game()
```

### E. ポーズ

```
プレイヤーが Esc / pause アクション入力
  → scenes/game/game_screen.gd: _input(event)
    → EventBus.game_paused.emit(true)
      → autoloads/game_manager.gd: get_tree().paused = true
                                   transition_to(PAUSED)
      → autoloads/puzzle_manager.gd: _stop_timer()
      → scenes/ui/pause_menu.gd: visible = true
```

---

## セーブデータへの影響

| section | key | 型 | 変更内容 | SAVE_VERSION |
|---------|-----|---|---------|-------------|
| `progress` | `level_reached` | `int` | 新規追加（デフォルト: `1`） | 据え置き（新規追加のみ） |
| `progress` | `levels_cleared` | `String` | 新規追加（デフォルト: `"[]"`、JSON配列） | 据え置き |
| `progress` | `scores` | `String` | 新規追加（デフォルト: `"{}"` JSON辞書 `level_id → int`） | 据え置き |

`SaveManager.save_game()` は既存の high_score 保存に加え、上記フィールドを保存するよう拡張する。

---

## テスト要件

| ファイル | テスト必須 | テスト対象 |
|---------|----------|----------|
| `autoloads/puzzle_manager.gd` | **必須** | `load_puzzle()`・`submit_answer()`・`use_hint()`・`restart_level()` 各正常系・異常系・境界値 |
| `scripts/utils/score_calc.gd` | **必須** | `calculate_base_score()`・`apply_hint_penalty()`・`calculate_final_score()`・`calculate_rank()` 全パターン |
| `autoloads/save_manager.gd`（拡張部分） | **必須** | `_on_puzzle_completed()` でスコアが正しく更新されるか |
| `scenes/game/code_panel.gd` | 任意 | ロジックは PuzzleManager に集約済みのため skip |
| `scenes/game/investigation_panel.gd` | 任意 | 同上 |
| `scenes/ui/game_hud.gd` | 任意 | 同上 |

テスト不可領域（Tween フィードバック演出・タイマー `_process`）は手動確認とし、tasks.md に記録する。

---

## 実装順序（tasks.md のたたき台）

1. `scripts/data/puzzle_question.gd` — PuzzleQuestion Resource 定義（テスト: なし）
2. `scripts/data/puzzle_data.gd` — PuzzleData Resource 定義（テスト: なし）
3. `scripts/utils/score_calc.gd` — スコア計算・ランク判定純粋関数（テスト: **必須**）
4. `tests/unit/test_score_calc.gd` — score_calc テスト（タスク3と同時）
5. `autoloads/event_bus.gd` — パズル用シグナル8本追加（テスト: なし）
6. `autoloads/game_manager.gd` — GameState に LEVEL_SELECT・ANIMATING・LEVEL_CLEAR・GAME_CLEAR 追加（テスト: なし）
7. `autoloads/puzzle_manager.gd` — 進行管理ロジック実装（テスト: **必須**）
8. `tests/unit/test_puzzle_manager.gd` — PuzzleManager テスト（タスク7と同時）
9. `autoloads/save_manager.gd` — 進捗保存拡張 + テスト追加（テスト: **必須**）
10. `project.godot` — PuzzleManager を autoload セクションに追加
11. `scenes/ui/game_hud.tscn` + `.gd` — HUD実装（テスト: 任意）
12. `scenes/ui/pause_menu.tscn` + `.gd` — ポーズメニュー実装（テスト: 任意）
13. `scenes/game/code_panel.tscn` + `.gd` — コードパネル実装（テスト: 任意）
14. `scenes/game/investigation_panel.tscn` + `.gd` — 調査パネル実装（テスト: 任意）
15. `scenes/game/game_screen.tscn` + `.gd` — メイン画面統合（テスト: 任意）
16. `resources/puzzles/level_001.tres` — サンプルパズルデータ作成
17. 手動確認: レベル起動 → コード行選択 → 選択肢回答（正解/不正解） → ヒント使用 → クリア → スコア保存 → リザルト遷移
