# Tasks — リザルト画面

## 概要

| # | タスク | 依存 |
|---|--------|------|
| 1 | GameManager に RESULT ステートと last_result を追加する | なし |
| 2 | game_screen.gd のクリア後処理をリザルト画面遷移に変更する | Task 1 |
| 3 | リザルト画面シーンとスクリプトを実装する | Task 1 |
| 4 | test_game_manager.gd にユニットテストを追加する | Task 1 |

カバー要件: 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 4.1, 4.2, 5.1（全17サブ要件）

---

## Task 1: GameManager に RESULT ステートと last_result を追加する

> 要件: 1.1.3, 5.1.1, 5.1.2

`autoloads/game_manager.gd` を修正し、`GameState` enum に `RESULT` を追加する。また、ゲームプレイ結果を格納するための `last_result: Dictionary` フィールドを追加する。フィールドの初期値は `{"score": 0, "miss_count": 0, "elapsed_time": 0.0, "hints_used": 0, "is_new_high_score": false}` とする。

- [x] 1.1 `GameState` enum の `LEVEL_CLEAR` の直後に `RESULT` を追加し、`var last_result: Dictionary` を初期値付きで宣言する

---

## Task 2: game_screen.gd のクリア後処理をリザルト画面遷移に変更する

> 要件: 1.1.1, 1.1.2, 3.1.1, 3.1.2, 3.1.3, 5.1.1, 5.1.2
> 依存: Task 1

`scenes/game/game_screen.gd` の `_on_secured_sequence_done()` を修正する。`puzzle_completed` を emit する前に、`SaveManager.get_value("progress", "scores", "{}")` から現在の保存スコアを取得して `is_new_high_score` を判定し、`GameManager.last_result` に全結果データを格納する。遷移先を `main_menu.tscn` から `result_screen.tscn` に変更する。

- [x] 2.1 `_on_secured_sequence_done()` でハイスコア判定・`last_result` 格納・遷移先変更を実装する

---

## Task 3: リザルト画面シーンとスクリプトを実装する

> 要件: 1.1.3, 1.2.1, 1.2.2, 1.2.3, 1.2.4, 2.1.1, 2.1.2, 2.1.3, 2.1.4, 2.1.5, 2.1.6, 2.1.7, 2.2.1, 2.2.2, 2.2.3, 3.2.1, 3.2.2, 4.1.1, 4.1.2, 4.1.3, 4.1.4, 4.1.5, 4.2.1, 4.2.2, 4.2.3
> 依存: Task 1

- [x] 3.1 `scenes/ui/result_screen.tscn` を作成する。`MarginContainer`（フルスクリーン anchor）→ `VBoxContainer` → 各ラベル（`_title_label`, `_level_label`, `_bug_type_label`, `HSeparator`, `_rank_label`, `_score_label`, `_time_label`, `_miss_label`, `_hints_label`, `_new_high_label`, `HSeparator`, `HBoxContainer` → `_retry_btn` + `_main_menu_btn`）の構成でシーンファイルを作成し、スクリプト `result_screen.gd` をアタッチする

- [x] 3.2 `result_screen.gd` に `_load_result_data()`・`_build_layout()`・`_apply_styles()` を実装する。`_ready()` で GameManager.last_result と PuzzleManager.current_puzzle から結果データを読み込み、各ラベルにテキストを設定する（ランクは `ScoreCalc.calculate_rank()` で導出、タイムは `MM:SS` フォーマット）。背景色 `#0d0d0d`・テキスト色 `#00ff41`・ランクラベル 72px・モノスペースフォントを適用する。`_ready()` 末尾で `EventBus.game_state_change_requested.emit(GameManager.GameState.RESULT)` を発行する

- [x] 3.3 `_play_intro_sequence()` で各ラベルを 100ms 間隔で `visible = true` にする Tween を実装する。演出完了後に `_buttons` を表示し `_animation_done = true` にする。ハイスコア時は `_new_high_label` の点滅 Tween（`modulate.a` 0→1 を 0.25s ループ）と `_score_label` のゴールド色（`#ffd700`）を適用する。`_input(event)` で `confirm` → retry・`cancel` → main_menu を `_animation_done` のガード付きで実装する

---

## Task 4: test_game_manager.gd にユニットテストを追加する

> 要件: 1.1.3, 5.1.1
> 依存: Task 1

`tests/unit/test_game_manager.gd` に以下のテストを追加する。

- [x] 4.1 `test_result_state_exists()`：`GameManager.GameState.RESULT` が enum に存在することを確認する。`test_last_result_initial_values()`：`last_result` の初期値が `score=0, miss_count=0, elapsed_time=0.0, hints_used=0, is_new_high_score=false` であることを確認する。`test_last_result_can_be_written()`：Dictionary への書き込み後に読み取れることを確認する
