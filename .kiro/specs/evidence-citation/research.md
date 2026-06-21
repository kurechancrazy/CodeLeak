# リサーチログ — evidence-citation

## 調査サマリー

**調査タイプ:** Extension（既存システムへの機能追加）  
**調査範囲:** 既存コードパターンの分析（軽量Discovery）

---

## 調査トピック

### 1. InvestigationScreen の証拠表示パターン

**対象ファイル:** `scenes/ui/investigation_screen.gd`

**発見:**
- 証拠パネルはボタン一覧（`_evidence_container: VBoxContainer`）＋インライン表示（`_content_label: Label`）の2層構成
- クリック → `_on_evidence_selected(idx)` → `_display_evidence()` でコンテンツを `_content_label` に表示
- "詳細ビューを別ダイアログで開く" 仕組みは存在しない。表示はすべてインライン。
- `_selected_index: int = -1` で「現在選択中の証拠インデックス」を管理している

**設計への示唆:**  
CITE ボタンは右パネル下部に配置し、`_selected_index` が指す証拠を引用対象とする。  
要件3「詳細ビュー内に CITE ボタン」は既存UIパターンに合わせ  
「証拠コンテンツ表示エリアの下に CITE ボタン」と再解釈する。

---

### 2. CaseManager の状態管理パターン

**対象ファイル:** `autoloads/case_manager.gd`

**発見:**
- `choice_history: Dictionary`（key: step_id, value: choice_key）でステップ別選択を記録 → `citation_history` も同一パターン
- `apply_wrong_answer_penalty()` が既存のペナルティ適用メソッド → `apply_wrong_citation_penalty()` も同一パターンで追加
- `answer_step()` は `chain_complete` フラグでガード済み → 引用待ち状態ガードも同じフラグ変数で管理
- `get_chain_summary()` は `Array[Dictionary]` を返しており、各Dictionaryに新キーを追加するだけで拡張できる

**設計への示唆:**  
状態管理は enum ではなく `bool _awaiting_citation: bool` で十分（2状態のみ）。  
既存の `chain_complete` との合成で AWAITING/COMPLETE 判定が完結する。

---

### 3. EventBus シグナル命名規則

**対象ファイル:** `autoloads/event_bus.gd`

**発見:**
- 既存シグナル: `evidence_unlocked(evidence_id: String)`, `step_answered(step_id: String, choice_key: String)`
- 命名パターン: `<対象>_<過去形動詞>(引数: 型)`
- 引数は必要最小限（step_id + evidence_id）

**設計への示唆:**  
`evidence_cited_correctly(step_id, evidence_id)` と `evidence_cited_wrongly(step_id, evidence_id)` はパターン準拠。

---

### 4. ChainReviewScreen の summary 読み取りパターン

**対象ファイル:** `scenes/ui/chain_review_screen.gd`

**発見:**
- `CaseManager.get_chain_summary()` の返却 `Array[Dictionary]` を for ループで走査
- 各 entry で `entry.get("key", default)` でアクセス（キー不在でもクラッシュしない）
- 引用情報は `entry.get("cited_evidence_id", "")` で追加可能

**設計への示唆:**  
ChainReviewScreen は `entry.get("cited_evidence_id", "")` を読み追記するだけで拡張できる。  
既存ループ内に引用表示行を追加するパターンが最小変更。

---

## 設計決定事項

| 決定事項 | 採用 | 理由 |
|---------|------|------|
| CITE ボタンの配置 | 右パネル下部（`_content_label` 下）| 既存UIに詳細ダイアログ機構がないため |
| 引用状態管理 | `bool _awaiting_citation` | 2状態で十分、enumは過剰 |
| 誤引用カウント | `int _wrong_citation_count` (step到達時リセット) | ペナルティ上限2回を実装する最小構成 |
| S02d の扱い | `correct_evidence_id = ""` | off-trackステップで特定の証拠を強制するのはUX上不自然 |
