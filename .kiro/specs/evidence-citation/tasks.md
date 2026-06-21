# タスクリスト — evidence-citation（証拠引用モデル）

## 実装タスク

- [x] 1. (P) InvestigationStep と case_001.tres のデータ拡張
  - [x] 1.1 `InvestigationStep` リソースに `correct_evidence_id: String = ""` フィールドを追加する
    - `scripts/data/investigation_step.gd` に `@export var correct_evidence_id: String = ""` を追記する
    - 既存フィールドの順序・型アノテーションは変更しない
    - 要件カバレッジ: 1.1, 1.3
  - [x] 1.2 `resources/cases/case_001.tres` の全 12 ステップに `correct_evidence_id` 値を設定する
    - Edit ツールで **1件ずつ** 設定する（バッチ編集不可）
    - 設定値は design.md の対応表に従う（s01: "", s02a: "e001_code", s02b: "e001_log", s02c: "e001_network", s02d: "", s03a: "e001_email", s03b: "e001_code", s03g: "", s04: "e001_network", s05: "e001_log", s06: "e001_code", s07: ""）
    - 要件カバレッジ: 1.2

- [x] 2. (P) EventBus に引用シグナルを追加する
  - `autoloads/event_bus.gd` の `# --- 連鎖推理チェーン ---` セクションに以下を追加する
  - `signal evidence_cited_correctly(step_id: String, evidence_id: String)`
  - `signal evidence_cited_wrongly(step_id: String, evidence_id: String)`
  - 既存シグナルは一切変更しない
  - 要件カバレッジ: 7.1, 7.2, 7.3

- [x] 3. (P) translations.csv に引用フェーズ UI 向けキーを追加する
  - `assets/i18n/translations.csv` に以下の3行を追加する
  - `CITE_EVIDENCE_PROMPT`: EN = `CITE EVIDENCE — select the evidence that answers this question` / JA = `証拠を引用してください — この問いに答える証拠を選択してください`
  - `CITE_EVIDENCE_BTN`: EN = `[ CITE THIS EVIDENCE ]` / JA = `[ この証拠を引用する ]`
  - `CHAIN_REVIEW_CITATION`: EN = `CITED: %s` / JA = `引用: %s`
  - 要件カバレッジ: 2.3, 3.2, 8.1

- [x] 4. CaseManager に引用状態管理を実装する
  - [x] 4.1 引用状態フラグ・カウンタ・履歴の変数追加と初期化処理を実装する
    - `_awaiting_citation: bool`・`_wrong_citation_count: int`・`citation_history: Dictionary` を追加する
    - `set_current_case()` と `start_investigation()` で `citation_history.clear()` と `_wrong_citation_count = 0` を追加する
    - `start_investigation()` でエントリーステップの `correct_evidence_id` を評価して `_awaiting_citation` の初期値を設定する
    - 要件カバレッジ: 6.1, 6.2, 6.6
  - [x] 4.2 `is_awaiting_citation()` getter と `cite_evidence()` メソッドを実装する
    - `is_awaiting_citation() -> bool` を追加する（`_awaiting_citation` の public 境界）
    - `cite_evidence(evidence_id: String) -> void` を実装する: AWAITING_CITATION 状態のみ有効
    - 正解時: `citation_history[step_id] = evidence_id` を記録し、`_awaiting_citation = false` に設定してから `EventBus.evidence_cited_correctly` を発信する
    - 誤り時: `_wrong_citation_count < 2` のとき `apply_wrong_citation_penalty()` を呼び出し、`_wrong_citation_count` をインクリメントしてから `EventBus.evidence_cited_wrongly` を発信する（ペナルティ先行・シグナル後発の順序を守る）
    - 要件カバレッジ: 3.4, 3.5, 3.6, 5.4, 6.3
  - [x] 4.3 `apply_wrong_citation_penalty()` メソッドを実装する
    - タイムリミットから 15 秒を差し引く（`apply_wrong_answer_penalty()` と同一パターン）
    - `EventBus.countdown_updated` を発信してタイマー表示を即時更新する
    - 要件カバレッジ: 5.2, 6.4
  - [x] 4.4 `answer_step()` に引用待ちガードを追加し、`get_chain_summary()` を拡張する
    - `answer_step()` の先頭ガードに `or _awaiting_citation` を追加する
    - `answer_step()` 内で次ステップに遷移する前に、次ステップの `correct_evidence_id` で `_awaiting_citation` と `_wrong_citation_count` をリセットする
    - `get_chain_summary()` の各エントリーに `"cited_evidence_id": citation_history.get(step_id, "")` を追加する
    - 要件カバレッジ: 5.5, 6.5, 6.7
  - [x] 4.5 `test_case_manager.gd` に引用機能のユニットテストを追加する
    - 正常系: 正しい `evidence_id` で `cite_evidence()` を呼ぶと `citation_history` に記録され `is_awaiting_citation()` が `false` を返すことを確認する
    - 正常系: `answer_step()` が AWAITING_CITATION 状態で無視されることを確認する
    - 異常系: `_wrong_citation_count` が 2 以上のとき `apply_wrong_citation_penalty()` が呼ばれないことを確認する
    - 境界値: `correct_evidence_id = ""` のステップでは `cite_evidence()` が呼ばれても何もしないことを確認する（スキップ状態）
    - 要件カバレッジ: 9.3

- [x] 5. InvestigationScreen に引用フェーズ UI を実装する
  - [x] 5.1 `_cite_button` と `_citation_prompt_label` を構築してレイアウトに配置する
    - `_cite_button: Button`・`_citation_prompt_label: Label`・`_citation_animating: bool = false` をメンバー変数に追加する
    - `_build_layout()` の `right_vbox` 末尾（ScrollContainer の後）にプロンプトラベルと CITE ボタンを追加する（`visible = false` で初期化）
    - `_cite_button.pressed.connect(_on_cite_evidence_pressed)` でシグナルを接続する
    - 要件カバレッジ: 3.2
  - [x] 5.2 `_update_citation_ui()` を実装してフェーズに応じた UI 状態を制御する
    - `CaseManager.is_awaiting_citation()` で現在のフェーズを判定する（ローカル変数に保持しない）
    - AWAITING_CITATION のとき: `_citation_prompt_label.visible = true`、`_input_locked = true`、`_cite_button.visible = (_selected_index >= 0)`
    - AWAITING_ANSWER のとき: `_citation_prompt_label.visible = false`、`_cite_button.visible = false`、`_input_locked = false`
    - 要件カバレッジ: 2.1, 2.2, 2.3, 2.4, 3.2
  - [x] 5.3 `_on_step_arrived()` に引用状態リセットと UI 更新を組み込む
    - ステップ到達時に `_selected_index = -1` にリセットして前ステップの選択状態をクリアする
    - `_update_citation_ui()` を呼び出して引用フェーズに入る（AWAITING_CITATION なら即座にプロンプトが表示される）
    - `_on_evidence_selected()` に「引用待ち状態のとき `_cite_button.visible = true` に設定する」を追加する
    - 要件カバレッジ: 2.1, 2.3, 3.1
  - [x] 5.4 `_on_cite_evidence_pressed()` と EventBus シグナルハンドラを実装する
    - `_on_cite_evidence_pressed()`: `_selected_index` が有効かつ `_citation_animating == false` のとき `CaseManager.cite_evidence()` を呼び出す
    - `_on_evidence_cited_correctly()`: 引用された証拠カードを緑ハイライトし、`_update_citation_ui()` で選択肢をアンロックして `grab_focus()` する
    - `_on_evidence_cited_wrongly()`: `_evidence_buttons` を走査して evidence_id が一致するカードを特定し、Tween で赤フラッシュする（_citation_animating = true → Tween 完了後に false）
    - `_ready()` で `EventBus.evidence_cited_correctly.connect()` と `EventBus.evidence_cited_wrongly.connect()` を接続し、`_exit_tree()` で切断する
    - 要件カバレッジ: 3.3, 4.1, 4.2, 5.1, 5.3

- [x] 6. ChainReviewScreen に引用履歴表示を追加する
  - `scenes/ui/chain_review_screen.gd` の summary ループ内で `entry.get("cited_evidence_id", "")` を取得する
  - `cited_evidence_id` が空文字の場合は「—」（dim カラー）、非空の場合はエビデンスタイトルを `tr("CHAIN_REVIEW_CITATION") % title` 形式で緑（RESOLVED カラー）で表示する
  - エビデンスタイトルは `CaseManager.current_case.evidence` から `evidence_id` で検索して取得する
  - 要件カバレッジ: 8.1, 8.2, 8.3, 8.4

- [x] 7. 後方互換確認と全ファイルの Lint 検証を実施する
  - [x] 7.1 `correct_evidence_id = ""` を使用する既存テストが変更なしでパスすることを確認する
    - `gut -d tests/` を実行して全テスト PASS を確認する
    - `cite_evidence()` を呼ばずに `answer_step()` だけ呼んだ場合の既存フロー（スキップ状態）が正常動作することを確認する
    - 要件カバレッジ: 9.1, 9.2
  - [x] 7.2 全修正ファイルに gdlint / gdformat を実行してエラーがないことを確認する
    - `gdlint scripts/ autoloads/ scenes/` → エラー 0 件
    - `gdformat --check scripts/ autoloads/ scenes/` → 差分 0
    - 問題があれば修正してから再実行する
    - 要件カバレッジ: （DoD 検証）
