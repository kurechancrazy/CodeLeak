# Tasks — ゲームプレイ画面

> **Feature:** gameplay-screen  
> **Phase:** tasks-generated  
> **Requirements coverage:** 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 9.1, 9.2, 9.3, 9.4

---

## Task 1: パズルデータモデルを定義する

> 要件: 8.1, 8.2  
> 依存: なし

- [x] 1.1 `scripts/data/puzzle_question.gd` を作成し、`prompt`・`choices`・`correct_index`・`explanation` の4フィールドを持つ `PuzzleQuestion extends Resource` クラスを定義する
- [x] 1.2 `scripts/data/puzzle_data.gd` を作成し、`level_id`・`title`・`flavor_text`・`bug_type`・`code_lines`・`questions: Array[PuzzleQuestion]`・`hint_lines: Array[int]` を持つ `PuzzleData extends Resource` クラスを定義する

---

## Task 2: スコア計算ユーティリティを実装してテストする

> 要件: 5.2, 5.4  
> 依存: なし

- [x] 2.1 `scripts/utils/score_calc.gd` を作成し、以下の純粋関数を実装する
  - `calculate_base_score(miss_count: int, elapsed_secs: float) -> int` — 式 `max(100, 1000 - miss_count * 100 - int(elapsed_secs * 2))`
  - `apply_hint_penalty(base_score: int, hints_used: int) -> int` — `base_score * pow(0.8, hints_used)` の整数部
  - `calculate_final_score(miss_count: int, elapsed_secs: float, hints_used: int) -> int` — 上記2関数の合成
  - `calculate_rank(score: int) -> String` — S(≥900)/A(≥700)/B(≥500)/C(≥300)/D(<300)
- [x] 2.2 `tests/unit/test_score_calc.gd` を作成し、全4関数の正常系・境界値（miss=0/elapsed=0/hints=0・最低スコア100の下限・各ランク境界値）をテストする

---

## Task 3: インフラ層を拡張する

> 要件: （設計インフラ）  
> 依存: Task 1

- [x] 3.1 `autoloads/event_bus.gd` にパズル用シグナル8本を追加する（`puzzle_loaded`・`line_selected`・`answer_submitted`・`hint_requested`・`hint_applied`・`puzzle_completed`・`level_cleared`・`level_restarted`）。シグナルの引数型は design.md の EventBus 変更表に従う
- [x] 3.2 `autoloads/game_manager.gd` の `GameState` enum に `LEVEL_SELECT`・`ANIMATING`・`LEVEL_CLEAR`・`GAME_CLEAR` を追加する
- [x] 3.3 `project.godot` の `[autoload]` セクションに `PuzzleManager="*res://autoloads/puzzle_manager.gd"` を `GameManager` の直後（4番目）に追加する

---

## Task 4: PuzzleManager Autoload を実装してテストする

> 要件: 3.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.3  
> 依存: Task 1, Task 2, Task 3

- [x] 4.1 `autoloads/puzzle_manager.gd` を新規作成し、内部状態変数（`current_puzzle`・`current_question_index`・`miss_count`・`hints_remaining`・`hints_used`・`selected_line`・`elapsed_time`・`_timer_active`）と `load_puzzle(puzzle: PuzzleData) -> void` を実装する。ロード時に内部状態を初期化し `EventBus.puzzle_loaded.emit(puzzle)` を発行する
- [x] 4.2 `PuzzleManager.submit_answer(choice_index: int) -> void` を実装する。正解時は `question_index` を進め `EventBus.answer_submitted.emit(true, explanation)` を発行し、全問正解なら `EventBus.level_cleared.emit()` を発行する。不正解時は `miss_count` を増やし `EventBus.answer_submitted.emit(false, "")` を発行する。いずれも EventBus 経由で ANIMATING 遷移を依頼する
- [x] 4.3 `PuzzleManager.use_hint() -> void` を実装する。`hints_remaining > 0` のとき `hints_remaining--`・`hints_used++` し `hint_lines` から対象行番号を選んで `EventBus.hint_applied.emit(line_index)` を発行する
- [x] 4.4 `PuzzleManager._process(delta)` でタイマーを実装する。`_timer_active` が `true` かつ `GameManager.state == PLAYING` のときのみ `elapsed_time += delta` する。`_start_timer()`・`_stop_timer()` ヘルパーを実装し `load_puzzle()` 時に start、`level_cleared` 時に stop する
- [x] 4.5 `PuzzleManager.restart_level() -> void` を実装する。`EventBus.level_restarted` を購読し、`load_puzzle(current_puzzle)` を再呼び出しして全状態をリセットする
- [x] 4.6 `tests/unit/test_puzzle_manager.gd` を作成し、以下をテストする
  - `load_puzzle()` 後に内部状態が初期化されること
  - 正解時に `question_index` が進み、全問正解で `level_cleared` シグナルが発行されること
  - 不正解時に `miss_count` が増えること
  - `use_hint()` が `hints_remaining = 0` のとき何もしないこと（境界値）
  - `restart_level()` 後に `miss_count` と `elapsed_time` がリセットされること

---

## Task 5: セーブデータの進捗保存を拡張してテストする

> 要件: 5.3, 5.4  
> 依存: Task 3, Task 4

- [x] 5.1 `autoloads/save_manager.gd` に `_on_puzzle_completed(score: int, miss_count: int, elapsed_time: float) -> void` を追加する。`EventBus.puzzle_completed` を購読し、`progress/scores` JSON辞書に `level_id → score` を保存する（既存スコアより高い場合のみ更新）。`progress/level_reached` も必要に応じて更新し `save_game()` を呼ぶ
- [x] 5.2 `save_manager.gd` の `save_game()` と `load_game()` を拡張し、`progress/level_reached`・`progress/levels_cleared`・`progress/scores` の3フィールドを `_save_config` に読み書きする
- [x] 5.3 `tests/unit/test_save_manager.gd` を更新し、`_on_puzzle_completed()` で同スコアより高い場合のみ保存されること・低い場合は上書きされないことを検証する

---

## Task 6: ゲームHUDを実装する

> 要件: 1.2.2, 1.2.3, 4.1, 5.1  
> 依存: Task 3

- [x] 6.1 `scenes/ui/game_hud.tscn` を作成する。画面上部に固定された `CanvasLayer` + `HBoxContainer` 構成で、`_level_label`（`LEVEL 1 / 5`）・`_bug_type_label`（`[BACKDOOR]`）・`_hints_label`（`HINTS: |||`）・`_timer_label`（`00:00`）・`_score_label`（`SCORE: 0`）・`_pause_button`（`[||]`）を配置する
- [x] 6.2 `scenes/ui/game_hud.gd` を作成し、`EventBus.puzzle_loaded` でラベルを初期化、`EventBus.hint_applied` でヒント残数表示を更新、`EventBus.answer_submitted(false, _)` でスコアを更新する。`_process(delta)` で `PuzzleManager.elapsed_time` を `MM:SS` 形式にフォーマットして `_timer_label` に表示する。`_pause_button.pressed` でポーズトグルを発行する

---

## Task 7: ポーズメニューを実装する

> 要件: 7.1, 7.2, 7.3, 7.4, 7.5  
> 依存: Task 3

- [x] 7.1 `scenes/ui/pause_menu.tscn` を作成する。`CanvasLayer`（`PROCESS_MODE_WHEN_PAUSED`）+ 中央配置 `PanelContainer` 構成で、`// PAUSED` タイトルラベルと `[RESUME]`・`[RESTART LEVEL]`・`[MAIN MENU]` ボタンを配置する。初期状態は非表示（`visible = false`）
- [x] 7.2 `scenes/ui/pause_menu.gd` を作成し、`EventBus.game_paused` を購読して `visible` を切り替える。`[RESUME]` → `EventBus.game_paused.emit(false)`、`[RESTART LEVEL]` → `EventBus.level_restarted.emit()`、`[MAIN MENU]` → `EventBus.scene_change_requested.emit("res://scenes/ui/main_menu.tscn", "fade")` を発行する

---

## Task 8: コードパネルを実装する

> 要件: 1.1.1, 1.1.2, 1.1.3, 1.1.4, 2.1.1, 2.1.2, 2.1.3, 2.2.1, 2.2.2, 6.1.1, 4.2（ヒントマーカー）, 9.2, 9.4  
> 依存: Task 1, Task 3

- [x] 8.1 `scenes/game/code_panel.tscn` を作成する。`PanelContainer`（背景色 `#0d0d0d`）→ `ScrollContainer` → `VBoxContainer`（`_code_lines_container`）の階層構造とする。各コード行は `HBoxContainer` + 行番号 `Label`（幅40px固定・色 `#555555`）+ `Button`（flat style・色 `#00ff41`）で構成し、4状態 StyleBox（normal/hover/selected/patched）をプログラムで生成する
- [x] 8.2 `scenes/game/code_panel.gd` を作成する。`EventBus.puzzle_loaded` を受信して `code_lines` から行ボタンを動的生成する。行 `Button.pressed` で `EventBus.line_selected.emit(line_index)` を発行する。`mouse_entered` でホバー色 `#1a1a2e` を適用し `mouse_exited` で元に戻す（要件 9.2）
- [x] 8.3 `code_panel.gd` に `_input(event)` を実装し、`move_up`/`move_down` でハイライト行を移動し、`confirm` で `EventBus.line_selected.emit(selected_line_index)` を発行する。`GameManager.state == ANIMATING` 中は全入力を無効化する（要件 2.1.3）
- [x] 8.4 `code_panel.gd` に `EventBus.hint_applied(line_index)` の購読を追加し、該当行ボタンのテキスト前に `~~` マーカーを追加する。`EventBus.answer_submitted(true, _)` を受信したとき現在選択行のテキスト末尾に `  >> PATCHED` を追記し緑フラッシュ Tween（0.3秒）を再生する

---

## Task 9: 調査パネルを実装する

> 要件: 1.2.1, 3.1.1, 3.1.2, 3.1.3, 3.2.1, 3.2.2, 3.2.3, 4.1, 4.2, 4.3, 4.4, 6.1.2, 6.2.1, 6.2.2, 9.1, 9.3  
> 依存: Task 1, Task 3, Task 4

- [x] 9.1 `scenes/game/investigation_panel.tscn` を作成する。`PanelContainer`（背景色 `#0a0a1a`）→ `VBoxContainer` 構成で、フレーバーテキスト用 `RichTextLabel`（`_flavor_label`）・区切り線・質問プロンプト `Label`（`_prompt_label`、初期非表示）・選択肢 `VBoxContainer`（`_choices_container`、初期非表示）・ヒント `Button`（`_hint_button`）を配置する。選択肢ボタンは最小高さ 40px とする（要件 9.3）
- [x] 9.2 `scenes/game/investigation_panel.gd` を作成する。`EventBus.puzzle_loaded` でフレーバーテキストを表示。`EventBus.line_selected` を受信して `PuzzleManager.get_current_question()` から質問と選択肢を取得し `[A]〜[D]` ラベル付きで `_choices_container` を動的生成する（要件 3.1.1, 3.1.2）
- [x] 9.3 `investigation_panel.gd` に選択肢クリック処理を実装する。ボタン押下で `PuzzleManager.submit_answer(choice_index)` を呼ぶ。`EventBus.answer_submitted(correct, explanation)` を購読し、正解時はパネルを緑フラッシュ（0.3秒）して解説テキストを表示し次質問/完了に遷移、不正解時はパネルを赤フラッシュ（0.2秒）して `>> ACCESS DENIED` を表示し Tween 完了後に選択肢を再表示する（要件 3.2.3）
- [x] 9.4 `investigation_panel.gd` に A/B/C/D キー入力を実装する（`_input(event)` で `KEY_A〜KEY_D` を検知）。`_hint_button.pressed` で `EventBus.hint_requested.emit()` を発行し、`EventBus.hint_applied` を受信してボタンテキストのヒント残数表示を更新する（要件 4.1, 4.3）

---

## Task 10: メインゲーム画面を統合する

> 要件: 1.1.1, 6.3.1, 6.3.2, 7.1, 7.2, 7.3, 9.4  
> 依存: Task 4, Task 5, Task 6, Task 7, Task 8, Task 9

- [x] 10.1 `scenes/game/game_screen.tscn` を作成する。`MarginContainer`（`PROCESS_MODE_PAUSABLE`）→ `HSplitContainer`（CodePanel 60% : InvestigationPanel 40%）+ `GameHUD`（CanvasLayer）+ `PauseMenu`（CanvasLayer）のシーン参照構成とする
- [x] 10.2 `scenes/game/game_screen.gd` を作成する。`_ready()` で `PuzzleManager.load_puzzle(puzzle_data)` を呼ぶ（パズルデータはシーン引数またはハードコードの `level_001` で渡す）。`EventBus.level_cleared` を購読し、タイプライター Tween で `[SYSTEM SECURED]` テキストを表示、完了後に `EventBus.puzzle_completed.emit(score, miss, time)` と `EventBus.scene_change_requested.emit(...)` を発行する（要件 6.3.1, 6.3.2）
- [x] 10.3 `game_screen.gd` の `_input(event)` でポーズトグルを実装する。`pause` アクションを受信したとき `GameManager.state != ANIMATING` であれば `EventBus.game_paused.emit(true/false)` を発行する（要件 7.1, 7.2, 7.3）

---

## Task 11: サンプルパズルデータを作成する

> 要件: 8.1, 8.2  
> 依存: Task 1

- [x] 11.1 `resources/puzzles/level_001.tres` を作成する。`PuzzleData` リソースに以下を設定する
  - `level_id = "level_001"`
  - `title = "The Obedient Liar"`
  - `flavor_text = "This AI was deployed to monitor network integrity. Analysts flagged unusual outbound traffic every Thursday at 3:17 AM. Find out what it's hiding."`
  - `bug_type = "BACKDOOR"`
  - `code_lines`（10行程度の疑似 Python コード、BACKDOOR を隠す実装）
  - `questions`（2〜3問、PuzzleQuestion リソース）
  - `hint_lines`（ヒント対象行2本）

---

## Task 12: ゴールデンパスを手動確認する

> 要件: 全要件の統合確認  
> 依存: Task 10, Task 11

- [ ] 12.1 Godot エディタで `game_screen.tscn` を実行し、以下のシナリオを確認する
  - [ ] レベル起動 → コードが行番号付きターミナル色で表示される（1.1.1〜1.1.4）
  - [ ] マウスでコード行をホバー → ホバー色が変わる（9.2）
  - [ ] コード行をクリック → 黄色ハイライト + 選択肢が右パネルに表示される（2.1.1, 3.1.1）
  - [ ] キーボード `↑/↓` でハイライト移動 → `Enter` で選択確定（2.2.1, 2.2.2）
  - [ ] 正解選択 → 緑フラッシュ + `>> PATCHED` 表示（6.1.1）
  - [ ] 不正解選択 → 赤フラッシュ + `>> ACCESS DENIED` + 即リトライ（6.2.1, 3.2.3）
  - [ ] `[HINT]` ボタン押下 → 対象行にマーカー表示 + ヒント残数減少（4.2）
  - [ ] ヒント残数 0 → ヒントボタンが無効化される（4.3）
  - [ ] 全問正解 → `[SYSTEM SECURED]` タイプライター演出 → リザルト遷移（6.3.1, 6.3.2）
  - [ ] `Esc` でポーズ → タイマー停止 + ポーズメニュー表示（7.1〜7.3）
  - [ ] `[RESTART LEVEL]` → 状態リセット（7.5）
  - [ ] セーブファイルにスコアが記録されていること（5.3）
