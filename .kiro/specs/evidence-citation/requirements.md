# 要件定義書 — evidence-citation（証拠引用モデル）

## 概要

**コンセプト:**  
調査ステップで選択肢を選ぶ前に、プレイヤーが「どのエビデンスを根拠にするか」を明示的に選択する必要がある。正しいエビデンスを引用すると選択肢がアンロックされ、誤ったエビデンスを引用すると時間ペナルティが発生する。

**現行フローとの主な差分:**

| 項目 | 現行 | 新規 |
|------|------|------|
| 回答フロー | ステップ到達 → 選択肢を選ぶ | ステップ到達 → 証拠を引用 → 選択肢を選ぶ |
| 選択肢の状態 | 常にアクティブ | 引用前はロック・引用後にアンロック |
| 誤引用の結果 | なし | タイムペナルティ＋再選択可能 |
| 体験の質 | 「読んで選ぶ」 | 「証拠を使って推論する」 |

---

## 要件

### 要件 1: InvestigationStep の証拠引用フィールド

**目的:** どのエビデンスがそのステップの回答根拠として正しいかをデータで定義できるようにする。

#### 受入基準

1. `InvestigationStep` リソースは `correct_evidence_id: String` フィールドを持つ。値が空文字の場合は証拠引用フェーズをスキップすることを表す。
2. `case_001.tres` の全 `InvestigationStep` に対して `correct_evidence_id` が設定される。各ステップの問いの種類（CODE / LOG / NETWORK / EMAIL / DEDUCTION）に対応した値が設定される。以下のステップは引用フェーズをスキップするため `correct_evidence_id = ""` とする：S01（到達時点で開示されている証拠が `e001_code` 1件のみのため、引用は推理体験にならない）、S03g（複数証拠を総合して判断する収束ステップ）、S07（複数証拠を総合した最終帰責ステップ）。これら以外の DEDUCTION タイプのステップも単一の証拠に根拠を特定できない場合は空文字を設定する。
3. `InvestigationStep` の既存フィールド（`step_id`・`question`・`question_type`・`choices`・`reveals_evidence_id`）は変更しない。

---

### 要件 2: ステップ到達時の「引用待ち」状態

**目的:** ステップに到達したとき、プレイヤーが先に証拠を選ぶことを強制する UI フローを実現する。

#### 受入基準

1. When プレイヤーが `correct_evidence_id` が非空のステップに到達したとき、証拠引用システムは選択肢パネルを「引用待ち（AWAITING_CITATION）」状態でロックし、クリック・キーボード操作を受け付けない状態にする。
2. While 「引用待ち」状態のとき、証拠引用システムはエビデンスパネルの各エビデンスカードを「引用可能」状態として強調表示する。
3. While 「引用待ち」状態のとき、証拠引用システムは選択肢パネル上に引用を促すプロンプトメッセージを表示する（例: 「CITE EVIDENCE — select the evidence that answers this question」）。
4. When プレイヤーが `correct_evidence_id` が空文字のステップに到達したとき、証拠引用システムは引用フェーズをスキップし、選択肢パネルを即座にアクティブ状態にする。

---

### 要件 3: 証拠引用アクション

**目的:** プレイヤーが「引用」操作を実行する手段を提供する。「エビデンスカードを開いて読む」動作と「引用する」動作を明確に分離する。

#### 受入基準

1. While 「引用待ち」状態のとき、エビデンスカードをクリックすると詳細ビューが開く（現行の「証拠を読む」動作を維持する）。
2. While 「引用待ち」状態のとき、詳細ビュー内に「CITE THIS EVIDENCE」ボタンが表示される。引用フェーズ中（「引用待ち」状態）以外では、このボタンは表示されない。
3. When プレイヤーが詳細ビュー内の「CITE THIS EVIDENCE」ボタンを押したとき、引用アクションが実行される。
4. When 引用アクションが実行されたとき、`CaseManager` は引用されたエビデンスIDと現在ステップの `correct_evidence_id` を照合し、正誤を判定する。
5. `CaseManager` は正誤判定の結果を `EventBus` 経由でシグナルとして発信する。正解の場合は `evidence_cited_correctly(step_id: String, evidence_id: String)` を、誤りの場合は `evidence_cited_wrongly(step_id: String, evidence_id: String)` を発信する。
6. `CaseManager` は現在ステップで正しく引用されたエビデンスIDを `cited_evidence_id` として記録する。

---

### 要件 4: 正解引用のフィードバックと選択肢アンロック

**目的:** 正しい証拠を引用したとき、プレイヤーに達成感を与えつつ選択肢への移行をスムーズにする。

#### 受入基準

1. When `evidence_cited_correctly` シグナルを受信したとき、証拠引用システムは引用されたエビデンスカードを正解状態（緑色ハイライト）で表示する。
2. When `evidence_cited_correctly` シグナルを受信したとき、証拠引用システムは選択肢パネルをアンロックし、プレイヤーが回答できる状態にする。
3. 正解引用によるポイント加算・時間ボーナスは行わない（選択肢回答のポイントで完結する）。

---

### 要件 5: 誤引用のペナルティとリトライ

**目的:** 誤ったエビデンスを引用したとき、意思決定のコストを可視化し、正しい根拠の選択を促す。

#### 受入基準

1. When `evidence_cited_wrongly` シグナルを受信したとき、証拠引用システムは引用されたエビデンスカードを誤り状態（赤色フラッシュ）で表示する。
2. When `evidence_cited_wrongly` シグナルを受信したとき、`CaseManager` はタイムリミットから 15 秒を差し引く（`apply_wrong_citation_penalty()` メソッドを呼び出す）。
3. When `evidence_cited_wrongly` シグナルを受信したとき、証拠引用システムは「引用待ち」状態を維持し、プレイヤーが別のエビデンスを選び直せる状態を保つ。
4. 同一ステップにおける誤引用ペナルティは最大2回までとする。3回目以降の誤引用は「引用待ち」状態を維持するが、タイムペナルティは発生しない。
5. If タイムリミットが 0 以下になったとき、誤引用中であっても `CaseManager` は調査チェーンを終了する（既存のタイムアウト処理と同様）。

---

### 要件 6: CaseManager の状態管理拡張

**目的:** 証拠引用フェーズ（引用待ち / 回答待ち）をゲーム進行状態として管理する。

#### 受入基準

1. `CaseManager` は現在ステップが「引用待ち（AWAITING_CITATION）」か「回答待ち（AWAITING_ANSWER）」かを識別できる状態フラグを持つ。
2. `CaseManager.start_investigation()` はエントリーステップの `correct_evidence_id` が非空の場合に状態を「引用待ち」に設定し、空の場合は「回答待ち」に設定する。
3. `CaseManager.cite_evidence(evidence_id: String)` メソッドを追加する。このメソッドは「引用待ち」状態のときのみ有効とし、「回答待ち」状態で呼ばれた場合は何もしない。
4. `CaseManager.apply_wrong_citation_penalty()` メソッドを追加する。このメソッドはタイムリミットから 15 秒を差し引き、`EventBus.countdown_updated` を発信する。
5. `CaseManager.answer_step()` は「回答待ち」状態のときのみ有効とし、「引用待ち」状態で呼ばれた場合は何もしない。
6. `CaseManager` は `citation_history: Dictionary` 変数を持つ（key: `step_id: String`、value: `evidence_id: String`）。正しい引用が完了したとき `citation_history[current_step_id] = evidence_id` として記録する。`start_investigation()` および `set_current_case()` が呼ばれたとき、`citation_history` をクリアする。
7. `CaseManager.get_chain_summary()` の返却値に `cited_evidence_id: String`（正しく引用されたエビデンスID、引用不要ステップでは空文字）を追加する。この値は `citation_history` から取得する。

---

### 要件 7: EventBus への新規シグナル追加

**目的:** 証拠引用の正誤をシステム全体に通知し、UI とロジックを分離する。

#### 受入基準

1. `EventBus` に `evidence_cited_correctly(step_id: String, evidence_id: String)` シグナルを追加する。
2. `EventBus` に `evidence_cited_wrongly(step_id: String, evidence_id: String)` シグナルを追加する。
3. 既存シグナル（`evidence_unlocked`・`step_arrived`・`step_answered`・`issue_resolved`・`countdown_updated` 等）は変更しない。

---

### 要件 8: チェーンレビュー画面での引用履歴表示

**目的:** 各ステップで何の証拠を根拠にしたかをプレイヤーが振り返れるようにする。

#### 受入基準

1. チェーンレビュー画面は各ステップ行に「引用したエビデンス名（または「引用不要」）」を追加表示する。
2. 正しい証拠を引用したステップの引用欄は緑色で表示する。
3. 引用フェーズをスキップしたステップ（`correct_evidence_id = ""`）の引用欄は「—」を表示する。
4. 誤引用の試行履歴は表示しない（正しく引用したエビデンス名のみを表示し、UI をシンプルに保つ）。

---

### 要件 9: 既存テストの後方互換

**目的:** 証拠引用機能の追加が既存テストを壊さないことを保証する。

#### 受入基準

1. `correct_evidence_id` が空文字の `InvestigationStep` を使用した既存の `test_case_manager.gd` テストは変更なしでパスし続ける。
2. `cite_evidence()` を呼ばずに `answer_step()` を呼んだとき、`correct_evidence_id` が空文字のステップでは現行と同一の動作をする。
3. 新機能（`cite_evidence`・`apply_wrong_citation_penalty`・新規シグナル）のユニットテストを `test_case_manager.gd` に追加する。
