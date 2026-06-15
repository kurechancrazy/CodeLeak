# 実装タスク — tension-gameplay（ナラティブ調査型・1ケース完全版）

> 設計 §7「実装順序」に従う。タスク2（原子的破棄）は起動不能を防ぐため一括実行・起動確認必須。
> 各タスク完了の定義（DoD）：実装 + テスト PASS + gdlint 0 + gdformat 差分0。

---

## 1. リソースクラスとバリデーション基盤

- [x] 1.1 4リソースクラスを作成する（`scripts/data/evidence_item.gd`・`verdict_choice.gd`・`outcome_data.gd`・`case_data.gd`）。各フィールドと型を設計 §3.1 通り定義し、ロケール対応 getter（`get_title`/`get_content`/`get_label`/`get_narrative`/`get_hint_for_replay`/`get_ai_name`/`get_briefing`/`get_suspects`/`get_victims`）を実装する。`outcomes` は `Array[OutcomeData]` とする。
  - _Requirements: 1.5, 1.6, 3.2, 4.2_
- [x] 1.2 `CaseData.get_outcome(key)` を配列検索 + null フォールバックで実装し、`CaseData.validate() -> Array[String]`（証拠4件・4タイプ網羅・verdict_choices非空・全 outcome_key + insufficient 存在・重複なし）を実装する。
  - _Requirements: 1.8, 4.2_
- [x] 1.3 `scripts/data/case_manifest.gd`（`class_name CaseManifest extends Resource` / `@export var cases: Array[CaseData]`）を作成する。
  - _Requirements: 7.8_
- [x] 1.4 リソースのユニットテストを作成する（`tests/unit/test_case_data.gd` 他）。getter の正常（ja/en）・異常（空 *_ja）・境界（空配列）、`validate()` の正常（エラー0）・欠損検出（outcome欠落・キー不一致・タイプ不足）、`get_outcome` の該当なし null を検証する。
  - _Requirements: 1.5, 1.6, 1.8, 4.2_

## 2. 旧コードの原子的破棄とアーキテクチャ基盤

- [x] 2.1 旧クイズ系ファイルを一括削除する：`scenes/game/game_screen.*`・`investigation_panel.*`・`code_panel.*`、`scenes/ui/game_hud.*`・`pause_menu.*`・`result_screen.*`、`scripts/data/puzzle_data.*`・`puzzle_question.*`、`autoloads/puzzle_manager.*`、`resources/puzzles/level_001.tres`。対応する旧テスト（`test_puzzle_manager.gd`、`test_save_manager.gd` の旧パズル部分、`test_game_manager.gd` の RESULT 依存、`test_score_calc*.gd`）も同時に削除する。
  - _Requirements: 7.1_
- [x] 2.2 `EventBus` の旧パズル系シグナルを削除し、新シグナル（`case_started`・`evidence_selected`・`evidence_read`・`countdown_updated`・`verdict_submitted`・`case_resolved`）を追加する。`game_paused` は維持する。
  - _Requirements: 7.5_
- [x] 2.3 `GameManager` の `GameState` を再定義する（`BOOT`・`MAIN_MENU`・`CASE_SELECT`・`BRIEFING`・`INVESTIGATING`・`VERDICT`・`OUTCOME`・`PAUSED`）。`_on_game_started`/`_on_game_over` を撤去し、`_on_game_paused` を state 退避・復元方式に変更する。`IS_DEMO`・`STORE_URL`・`WISHLIST_URL` 定数を追加する。
  - _Requirements: 7.4, 7.7_
- [x] 2.4 `main_menu.gd` の `_on_play_pressed` 遷移先を `case_select_screen.tscn` に変更する。プロジェクトをエディタで開き、パースエラーなく起動することを確認する（破棄漏れ検出）。
  - _Requirements: 7.2, 5.1_

## 3. CaseManager Autoload

- [x] 3.1 `autoloads/case_manager.gd` を作成し `project.godot` の `[autoload]`（PuzzleManager の位置）と `architecture.md` に登録する。`PROCESS_MODE_ALWAYS`・`game_paused` 購読・`set_current_case`/`start_case`/`mark_evidence_read`/`resolve_case` を設計 §3.2 通り実装する。
  - _Requirements: 7.3, 2.1, 2.5_
- [x] 3.2 タイマーを `_tick(delta)` に分離し `_process` から呼ぶ。`_paused` フラグ制御、`time_remaining<=0` で `submit_verdict("insufficient")`、`submit_verdict` の冪等ガード（判決記録済みなら無視）、「判決を下す」時のタイマー停止を実装する。
  - _Requirements: 2.4, 2.5, 2.6, 3.4_
- [x] 3.3 ビジネスロジックのヘルパーを実装する：`get_unread_evidence`・`get_verdict_options`（2択 + 共通 insufficient）・`get_alternate_hint`・`get_reached_outcome_count`。
  - _Requirements: 3.2, 4.3, 4.5, 7.9_
- [x] 3.4 `tests/unit/test_case_manager.gd` を作成する。`_tick(241)` の時間切れ→insufficient、`submit_verdict` 冪等（submit 後 `_tick(999)` でも結末維持）、`_paused` でタイマー停止・解除で再開、ヘルパー各種の正常・境界（全既読・未到達）を検証する（get_tree 副作用なし）。
  - _Requirements: 2.4, 2.5, 2.6, 3.4, 4.3, 4.5, 7.9_

## 4. SaveManager スキーマ拡張

- [x] 4.1 `save_manager.gd` の `puzzle_completed` 購読と `_on_puzzle_completed` を撤去し、`case_resolved` 購読と `_on_case_resolved` を実装する。`cases_resolved`（JSON配列）・`case_verdicts`（JSON dict）を JSON 型ガード + 重複防止 append で保存する。`architecture.md` のセーブスキーマを更新する。
  - _Requirements: 4.8, 5.3, 7.6_
- [x] 4.2 `tests/unit/test_save_manager.gd` を新スキーマで置換する。重複なし append、破損 JSON 文字列でクラッシュしない異常系、同一ケース3判決で種類数が 3 になることを検証する。
  - _Requirements: 4.8, 5.3, 7.6_

## 5. ケース選択画面

- [x] 5.1 `scenes/ui/case_select_screen.*` を作成する（`MarginContainer + ScrollContainer + VBoxContainer`）。`case_manifest.tres` 経由でケースをロードし、`validate()` でエラーのあるケースはロックエントリ扱いにする。各ケースに番号・AI名・脅威Lv・到達結末 X/3 を表示する。
  - _Requirements: 5.2, 5.3, 7.8, 6.5_
- [x] 5.2 未実装ケース2・3のロックエントリ（「STEAM版で続きを調査する」）と WL 誘導（`OS.shell_open(WISHLIST_URL)`）、プレイ可能ケース選択（`set_current_case` → Briefing 遷移）、キーボードナビ（↑↓/Enter/Esc）を実装する。
  - _Requirements: 5.1, 5.4, 5.5, 5.6, 6.1_

## 6. ブリーフィング画面

- [x] 6.1 `scenes/ui/briefing_screen.*` を作成する（Scroll コンテナ・null ガード・自身で `BRIEFING` 設定）。AI名・脅威レベル（記号併用）・関係者・被害対象・briefing 本文を表示する。
  - _Requirements: 1.7, 6.5, 6.8_
- [x] 6.2 タイプライター演出と2段階スキップ（クリック/Enter/任意キー：1回目=全文即時、2回目=Investigation へ）、Esc で CaseSelect 戻り、言語切替の動的再描画を実装する。
  - _Requirements: 6.1, 6.2, 6.6_

## 7. 調査画面（中核）

- [x] 7.1 `scenes/ui/investigation_screen.*` のレイアウトを構築する（CountdownBar + 左右ペイン HBox + 判決ボタン、ポーズメニュー CanvasLayer）。null ガード、自身で `INVESTIGATING` 設定後 `start_case` 呼び出し、`_exit_tree` での全 disconnect を実装する。
  - _Requirements: 1.1, 3.1_
- [x] 7.2 証拠リストの表示と選択を実装する：証拠タイプ別表示（CODE/LOG/NETWORK=等幅・autowrap無効、EMAIL=ワードラップ）、3状態（未読/既読[READ]/選択中）、選択で `mark_evidence_read`、マウスと ↑↓/Enter 操作。
  - _Requirements: 1.2, 1.3, 1.4, 6.3, 6.4, 6.1_
- [x] 7.3 CountdownBar の段階警告（残120秒=黄・残60秒=赤点滅+記号・残10秒=拡大）を `countdown_updated` 購読で実装し、色のみに依存しない記号併用とする。判決ボタンに未読件数バッジを表示する。
  - _Requirements: 2.2, 2.3, 6.8_
- [x] 7.4 「判決を下す」操作（タイマー停止 → VerdictScreen 遷移）、時間切れ捕捉（`verdict_submitted` の insufficient → TIME EXPIRED フルスクリーン告知 → クリック/キーで Outcome へ）、ポーズメニュー開閉、言語再描画（既読・選択・残時間を保持）を実装する。
  - _Requirements: 2.4, 2.6, 3.1, 6.6_

## 8. 判決画面

- [x] 8.1 `scenes/ui/verdict_screen.*` を作成する。null ガード、自身で `VERDICT` 設定、`get_verdict_options()` で3択ボタンを十分離して生成、遷移直後 0.3〜0.5秒の入力ガード、cancel/pause 無視を実装する。
  - _Requirements: 3.1, 3.2, 6.7_
- [x] 8.2 判決選択時の 0.5秒フラッシュ Tween → `submit_verdict(key)` → OutcomeScreen 遷移（取消不可）を実装する。
  - _Requirements: 3.3, 3.4_

## 9. 結末画面

- [x] 9.1 `scenes/ui/outcome_screen.*` を作成する（Scroll コンテナ・null/空verdict ガード）。`resolve_case()` で先に保存 → `get_outcome`（null 時フォールバック文言）の narrative をタイプライター表示（スキップ対応）する。
  - _Requirements: 4.1, 4.2_
- [x] 9.2 今回の判決ラベル、未読証拠一覧（空なら「全て確認済み」）、別の見方（`get_alternate_hint`）、見た結末 X/3（保存後に `get_reached_outcome_count`）、スコア非表示を実装する。
  - _Requirements: 4.3, 4.4, 4.5_
- [x] 9.3 判決シェア（ネイティブ=クリップボード+トースト、Web=`OS.has_feature("web")` で選択可能Label常時併置）、`[もう一度調査する]`・`[ケース選択へ]` ボタン、言語再描画を実装する。
  - _Requirements: 4.6, 4.7, 4.9, 6.6_

## 10. コンテンツと i18n

- [x] 10.1 翻訳CSV の旧クイズ前提キー（HTP 等）を削除し、新ゲームルール（証拠調査・判決）と各画面の新規キー（TIME EXPIRED・OUTCOME_FALLBACK・ボタン文言等）を追加する。
  - _Requirements: 7.2_
- [x] 10.2 `resources/cases/case_001.tres`（証拠4件 CODE/LOG/EMAIL/NETWORK・ブリーフィング・被疑者/被害者・判決2択・結末3種 intentional/runaway/insufficient、EN/JA）と `case_manifest.tres` を作成する。`validate()` がエラー0であることを確認する。
  - _Requirements: 1.2, 1.5, 1.6, 1.7, 3.2, 3.5, 4.2_

## 11. 統合・品質保証

- [x] 11.1 全ケース整合性テストを作成する：`case_manifest` 経由で全 `CaseData` に `validate()` を実行しエラー0を CI で保証する（outcome_key タイプミスのサイレント不具合検出）。
  - _Requirements: 1.8, 4.2_
- [x] 11.2 全画面遷移マトリクスを手動検証する（MainMenu→CaseSelect→Briefing→Investigation→Verdict→Outcome→各分岐・再挑戦・Esc・時間切れ・ポーズ再開）。GUT 全 PASS・gdlint 0・gdformat 差分0 を確認する。
  - _Requirements: 2.5, 3.3, 4.9, 5.6_
- [x] 11.3 Web版（itch.io エクスポート）で実機検証する：シェアの選択可能Label表示、WLボタンの新規タブ遷移、`case_manifest` ロード、IS_DEMO/STORE_URL/WISHLIST_URL の実URL置換確認。
  - _Requirements: 4.7, 5.5, 7.7, 7.8_
