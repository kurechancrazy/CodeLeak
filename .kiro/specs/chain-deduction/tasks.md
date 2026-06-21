# 実装タスク — chain-deduction（分岐型連鎖推理）

> 各タスク完了の定義（DoD）：実装 + テスト PASS + gdlint 0 + gdformat 差分0。  
> 旧 `verdict_submitted` シグナルは Task 5 で参照除去後、Task 10 で削除する。  
> タスク8（コンテンツ）はリソースクラスが揃う Task 2 完了後に着手可能。

---

## 1. 新規データリソース4件の作成

> `StepChoice`・`InvestigationStep`・`CaseIssue`・`OutcomeRule` の4リソースクラスと単体テストを作成する。

- [x] 1.1 `scripts/data/step_choice.gd` を作成する。`choice_key`・`label`・`label_ja`・`next_step_id`・`resolves_issue_id` を typed export として定義し、`get_label() -> String`（ロケール対応）と `is_terminal() -> bool`（`next_step_id.is_empty()`）を実装する。
  - _Requirements: 1_

- [x] 1.2 `scripts/data/investigation_step.gd` を作成する。`step_id`・`question`・`question_ja`・`question_type`（`CODE`/`LOG`/`NETWORK`/`DEDUCTION`）・`display_as_code`・`choices: Array[StepChoice]`（7件）・`reveals_evidence_id` を typed export として定義し、`get_question() -> String`（ロケール対応）・`get_choice_by_key(key: String) -> StepChoice`・`validate() -> Array[String]`（choices.size() != 7 等のチェック）を実装する。
  - _Requirements: 1_

- [x] 1.3 `scripts/data/case_issue.gd` を作成する。`issue_id`・`description`・`description_ja` を typed export として定義し、`get_description() -> String`（ロケール対応）を実装する。
  - _Requirements: 1_

- [x] 1.4 `scripts/data/outcome_rule.gd` を作成する。`min_resolved_count: int`・`required_issue_ids: Array[String]`・`outcome_key: String` を typed export として定義し、`matches(resolved_ids: Array[String]) -> bool`（min_resolved_count 以上かつ required_issue_ids の全要素が resolved_ids に含まれる）を実装する。
  - _Requirements: 1, 5_

- [x] 1.5 新リソース4件の単体テストを作成する（`tests/unit/test_step_choice.gd`・`test_investigation_step.gd`・`test_outcome_rule.gd`）。`get_label()` のロケール切り替え、`is_terminal()` の true/false、`validate()` の7件チェック・0件エラー、`matches()` の境界値（min=0・required=[]・全条件一致・不一致）を検証する。
  - _Requirements: 1, 5_

---

## 2. CaseData の更新

> `verdict_choices` を廃止し、分岐ツリー用フィールドと新バリデーションルールを追加する。

- [x] 2.1 `scripts/data/case_data.gd` の `verdict_choices: Array[VerdictChoice]` フィールドを削除し、`entry_step_id: String`・`investigation_steps: Array[InvestigationStep]`・`resolvable_issues: Array[CaseIssue]`・`outcome_rules: Array[OutcomeRule]` を追加する。`get_step_by_id(step_id: String) -> InvestigationStep` と `get_issue_by_id(issue_id: String) -> CaseIssue` を追加する。
  - _Requirements: 1_

- [x] 2.2 `CaseData.validate()` を新ルールで実装する。① `entry_step_id` が `investigation_steps` 内に存在する、② 全 `investigation_steps` の choices が7件、③ 全 `outcome_rules` の `outcome_key` が `outcomes` に存在する、④ `"insufficient"` アウトカムが `outcomes` に存在する、の4条件を検証する。旧来の証拠4件固定チェックと `verdict_choices` チェックは削除する。
  - _Requirements: 1_

- [x] 2.3 `tests/unit/test_case_data.gd` を新データ構造に対応させる。旧 verdict_choices テストを削除し、`get_step_by_id()` の正常（存在するID）・境界（存在しないID → null）、`validate()` の新4条件（正常・各欠損・entry_step_id 不整合）を追加する。
  - _Requirements: 1_

---

## 3. EventBus・GameManager の更新

> 新シグナルを追加し、GameState に CHAIN_REVIEW を追加する。（Task 5 で旧シグナルの接続を除去後、Task 10 で削除する）

- [x] 3.1 `autoloads/event_bus.gd` に新シグナルを追加する：`step_arrived(step_id: String)`・`step_answered(step_id: String, choice_key: String)`・`issue_resolved(issue_id: String)`・`evidence_unlocked(evidence_id: String)`・`investigation_chain_complete(resolved_issue_ids: Array)`。
  - _Requirements: 2, 3_

- [x] 3.2 `autoloads/game_manager.gd` の `GameState` 列挙型に `CHAIN_REVIEW` を追加する（`VERDICT` の後・`OUTCOME` の前）。`architecture.md` の GameState 定義も更新する。
  - _Requirements: 4_

---

## 4. CaseManager の拡張

> チェーン走査状態・`answer_step()`・`determine_outcome()`・`get_chain_summary()` を追加する。

- [x] 4.1 `autoloads/case_manager.gd` に新状態変数を追加し、`set_current_case()` と `start_case()` のリセット処理を更新する。新変数：`current_step_id: String`・`step_id_history: Array[String]`・`choice_history: Dictionary`・`resolved_issue_ids: Array[String]`・`chain_complete: bool`。`start_investigation()` を追加し、`entry_step_id` をセットして `EventBus.step_arrived.emit()` を呼ぶ。
  - _Requirements: 2_

- [x] 4.2 `CaseManager.answer_step(choice_key: String) -> void` を実装する。① 現在ステップの `get_choice_by_key()` で選択肢を取得、② `step_id_history` に記録、③ `choice_history[current_step_id] = choice_key`、④ `resolves_issue_id` があれば `resolved_issue_ids` に追加して `EventBus.issue_resolved.emit()`、⑤ `reveals_evidence_id` があれば `EventBus.evidence_unlocked.emit()`、⑥ `is_terminal()` なら `chain_complete = true`・タイマー停止・`EventBus.investigation_chain_complete.emit(resolved_issue_ids)`、⑦ そうでなければ `current_step_id = choice.next_step_id`・`EventBus.step_arrived.emit(current_step_id)` の順で実装する。
  - _Requirements: 2_

- [x] 4.3 `CaseManager.determine_outcome() -> String` を実装する。`current_case.outcome_rules` を先頭から評価し、`rule.matches(resolved_issue_ids)` が最初に true になった `rule.outcome_key` を返す。マッチなしは `"insufficient"` を返す。`get_chain_summary() -> Array[Dictionary]` も実装する（`step_id_history` を辿り `{step_id, choice_key, resolved_issue_id, timed_out}` を返す）。
  - _Requirements: 4, 5_

- [x] 4.4 タイムアウト時の処理を `_tick()` に追加する。`time_remaining <= 0` かつ `not chain_complete` のとき `chain_complete = true`・`EventBus.investigation_chain_complete.emit(resolved_issue_ids)` を呼ぶ。旧 `submit_verdict("insufficient")` 呼び出しは削除する。
  - _Requirements: 2_

- [x] 4.5 `tests/unit/test_case_manager.gd` を新仕様に対応させる。`answer_step()` の分岐進行・課題解決記録・ブランチ終端で chain_complete=true・`step_id_history` の順序、`determine_outcome()` のルール評価順・insufficientフォールバック、タイムアウトで chain_complete=true を検証する。旧 `submit_verdict`・`get_verdict_options` 関連テストを削除する。
  - _Requirements: 2, 4, 5_

---

## 5. InvestigationScreen の改修

> 旧「DELIVER VERDICT」ボタンを廃止し、ステップ質問パネルを組み込む。証拠開示シグナルに対応する。

- [x] 5.1 `scenes/ui/investigation_screen.gd` から旧 `verdict_submitted` 接続（L29・L301・L370–371）・`_verdict_btn`・`_on_deliver_verdict()`・`_refresh_verdict_btn()` を削除する。代わりに `EventBus.investigation_chain_complete.connect(_on_chain_complete)` と `EventBus.step_arrived.connect(_on_step_arrived)` と `EventBus.evidence_unlocked.connect(_on_evidence_unlocked)` を `_ready()` で接続する。`_exit_tree()` の disconnect も更新する。
  - _Requirements: 2, 7_

- [x] 5.2 右パネルを上下分割し、上部（約60%）にステップ質問パネルを実装する。`_build_step_panel()` で質問タイプラベル・質問文（`display_as_code` に応じてモノスペースフォント切替）・選択肢ボタン7件を生成する。`_refresh_step_ui(step: InvestigationStep)` で現在ステップを表示し、タイマー行に「STEP N」インジケーターを追加する。下部（約40%）は既存の証拠コンテンツエリアを維持する。
  - _Requirements: 2, 7_

- [x] 5.3 `_on_step_choice_selected(choice_key: String)` を実装する。0.2秒 input lock（誤爆防止）・`CaseManager.answer_step(choice_key)` 呼び出し・`_on_step_arrived()` でパネル更新・`_on_chain_complete()` で `scene_change_requested.emit("res://scenes/ui/chain_review_screen.tscn", "fade")` を実装する。`_on_evidence_unlocked()` で証拠ボタン追加も実装する。`_input()` の Escape はポーズ専用を維持（前ステップ移動には使用不可）。
  - _Requirements: 2, 3, 7_

---

## 6. ChainReviewScreen の新規作成

> 旧 `VerdictScreen` の位置に入る新画面。ステップ履歴・課題解決数・VERDICTボタンを実装する。

- [x] 6.1 `scenes/ui/chain_review_screen.gd`・`chain_review_screen.tscn` を作成する。`_ready()` で `GameManager.transition_to(GameManager.GameState.CHAIN_REVIEW)` を呼ぶ。`CaseManager.current_case == null` ガードを追加する。input lock（0.4秒）で誤爆防止を実装する（`VerdictScreen` の既存パターンを踏襲）。`_input()` で Escape と pause を握りつぶす（判定確定後は戻れない）。
  - _Requirements: 4_

- [x] 6.2 `_build_layout()` でステップ履歴リストを構築する。`CaseManager.get_chain_summary()` を用いて各ステップ行に「質問概要・選択したラベル・解決した課題説明（あれば）」を表示する。課題を解決したステップは緑色（`#00ff41`）、解決しなかったステップは暗色（`#555555`）、タイムアウトは赤色（`#ff4444`）で色分けする。
  - _Requirements: 4_

- [x] 6.3 ヘッダーに「ISSUES IDENTIFIED: X / Y」（X = `resolved_issue_ids.size()`、Y = `resolvable_issues.size()`）を目立つサイズで表示する。`[ VERDICT ]` ボタンを実装し、押下時に `CaseManager.selected_verdict = CaseManager.determine_outcome()` をセットしてから `scene_change_requested.emit("res://scenes/ui/outcome_screen.tscn", "fade")` を呼ぶ。キーボード（Enter/Space）とマウスクリックの両方をサポートする。
  - _Requirements: 4, 5, 7_

---

## 7. OutcomeScreen の改修

> `verdict_choices` 参照を除去し、「ISSUES RESOLVED: X / Y」表示に変更する。

- [x] 7.1 `scenes/ui/outcome_screen.gd` の L62–68（`verdict_choices` をループして `verdict_choice` を取得しているブロック）を削除する。代わりに `ISSUES RESOLVED: X / Y`（`CaseManager.resolved_issue_ids.size()` / `current_case.resolvable_issues.size()`）を表示する Label に変更する。`verdict_key` は `CaseManager.selected_verdict` から取得（ChainReviewScreen が事前にセット済み）。
  - _Requirements: 5_

---

## 8. ASTRA-7 分岐ツリーコンテンツの作成

> `case_001.tres` を分岐型10ステップ・7課題・3アウトカムルールで再設計する。

- [x] 8.1 `resources/cases/case_001.tres` を再設計する。`research.md` のツリー設計を基に `InvestigationStep` × 10（CODE×3・LOG×2・NETWORK×2・DEDUCTION×3）・`StepChoice` × 70（各ステップ7件）・`CaseIssue` × 7・`OutcomeRule` × 3（高正答率→`intentional`・中→`runaway`・低→`insufficient`）を定義する。`verdict_choices` フィールドを削除し、`entry_step_id` を設定する。既存の `evidence`・`outcomes`・`time_limit_seconds` は維持する。
  - _Requirements: 6_

- [x] 8.2 Godot エディタで `case_001.tres` をロードし `CaseData.validate()` がエラー0件であることを確認する。全 `next_step_id` が有効なステップIDまたは空文字であることを手動または GUT テストで検証する。
  - _Requirements: 6_

---

## 9. 翻訳キーの追加

> `ChainReviewScreen` の新UIテキストを `translations.csv` に追加する。

- [x] 9.1 `assets/i18n/translations.csv` に以下のキーを英日で追加する：`CHAIN_REVIEW_TITLE`（"INVESTIGATION COMPLETE" / "調査完了"）・`CHAIN_REVIEW_ISSUES_IDENTIFIED`（"ISSUES IDENTIFIED: %d / %d" / "課題特定: %d / %d"）・`CHAIN_REVIEW_VERDICT_BTN`（"[ VERDICT ]" / "[ 判決 ]"）・`CHAIN_REVIEW_STEP_TIMEOUT`（"TIMEOUT" / "タイムアウト"）・`CHAIN_REVIEW_ISSUE_RESOLVED`（"Resolved: %s" / "解決: %s"）。`ChainReviewScreen` 内の全テキストが `tr()` を使用していることを確認する。
  - _Requirements: 4_

---

## 10. 旧コードの削除とクリーンアップ

> Task 5〜7 で参照除去済みの旧ファイル・シグナル・メソッドを削除する。

- [x] 10.1 `scenes/ui/verdict_screen.gd` と `scenes/ui/verdict_screen.tscn` を削除する。`main.tscn` 等でシーンパスをハードコードしている箇所がないことを grep で確認してから削除する。
  - _Requirements: 4_

- [x] 10.2 `autoloads/event_bus.gd` から `signal verdict_submitted(outcome_key: String)` を削除する。`autoloads/case_manager.gd` から `submit_verdict()`・`get_verdict_options()` を削除する。codebase 全体で `verdict_submitted`・`get_verdict_options`・`submit_verdict` への参照がゼロになることを grep で確認する。
  - _Requirements: 2_

- [x] 10.3 gdlint と gdformat を `scripts/`・`autoloads/`・`scenes/` 全体に対して実行し、エラー0件・差分0 を確認する。GUT で全テスト PASS を確認する。
  - _Requirements: 1, 2, 3, 4, 5, 6, 7_
