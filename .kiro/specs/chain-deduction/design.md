# 技術設計書 — chain-deduction（分岐型連鎖推理）

---

## アーキテクチャパターン

**分岐調査ツリー（Branching Investigation Tree）**

```
[CaseData] ─── entry_step_id ──→ [InvestigationStep S01]
                                          │
                                   choices[0..6]
                                    ↙   ↓   ↘
                               [S02a] [S02b] [S02c]   ← 選択肢で分岐
                                 │                │
                              [S03a]           [S03e]
                                 │                │
                               (END)           (END)  ← next_step_id=""
```

- **Resource-driven**: ツリー構造はすべて `CaseData` リソースで定義（コードではなくデータが分岐を制御）
- **CaseManager が状態機械**: 現在ステップIDと訪問履歴を保持し、`answer_step()` でツリーを走査
- **後戻り不可**: `answer_step()` 呼び出し後は前ステップへのナビゲーション手段を UI・ロジック両面で排除

---

## ゲームフロー（変更部分）

```
[現行]
InvestigationScreen ─→ VerdictScreen ─→ OutcomeScreen

[新規]
InvestigationScreen ─→ ChainReviewScreen ─→ OutcomeScreen
  (ステップ質問を内包)    (一括正誤開示)      (ナラティブ・変更最小)
```

**GameState 変更:**

| 旧 | 新 | 変更内容 |
|----|----|---------|
| `VERDICT` | `CHAIN_REVIEW` | リネーム |
| — | （`INVESTIGATING` を拡張） | ステップ進行は `INVESTIGATING` 状態内で完結 |

---

## コンポーネント一覧・インターフェース

### 1. `StepChoice` — 新規リソース

**ファイル:** `scripts/data/step_choice.gd`

```gdscript
class_name StepChoice
extends Resource

@export var choice_key: String = ""
@export var label: String = ""
@export var label_ja: String = ""
@export var next_step_id: String = ""      # "" = ブランチ終端
@export var resolves_issue_id: String = "" # "" = 課題解決なし

func get_label() -> String
func is_terminal() -> bool  # next_step_id.is_empty()
```

---

### 2. `InvestigationStep` — 新規リソース

**ファイル:** `scripts/data/investigation_step.gd`

```gdscript
class_name InvestigationStep
extends Resource

@export var step_id: String = ""
@export var question: String = ""
@export var question_ja: String = ""
@export var question_type: String = "DEDUCTION"  # CODE / LOG / NETWORK / DEDUCTION
@export var display_as_code: bool = false
@export var choices: Array[StepChoice] = []      # 常に 7 件
@export var reveals_evidence_id: String = ""     # 到達時に開示する証拠 ID

func get_question() -> String                    # ロケール対応
func get_choice_by_key(key: String) -> StepChoice
func validate() -> Array[String]                 # choices.size() != 7 などチェック
```

---

### 3. `CaseIssue` — 新規リソース

**ファイル:** `scripts/data/case_issue.gd`

```gdscript
class_name CaseIssue
extends Resource

@export var issue_id: String = ""
@export var description: String = ""
@export var description_ja: String = ""

func get_description() -> String  # ロケール対応
```

---

### 4. `OutcomeRule` — 新規リソース

**ファイル:** `scripts/data/outcome_rule.gd`

```gdscript
class_name OutcomeRule
extends Resource

@export var min_resolved_count: int = 0
@export var required_issue_ids: Array[String] = []
@export var outcome_key: String = ""

func matches(resolved_ids: Array[String]) -> bool
# resolved_ids.size() >= min_resolved_count
# かつ required_issue_ids の全要素が resolved_ids に含まれる
```

---

### 5. `CaseData` — 変更

**ファイル:** `scripts/data/case_data.gd`

**削除フィールド:**
- `verdict_choices: Array[VerdictChoice]`（`VerdictChoice` リソースも非推奨化）

**追加フィールド:**
```gdscript
@export var entry_step_id: String = ""
@export var investigation_steps: Array[InvestigationStep] = []
@export var resolvable_issues: Array[CaseIssue] = []
@export var outcome_rules: Array[OutcomeRule] = []
```

**変更メソッド:**
```gdscript
func get_step_by_id(step_id: String) -> InvestigationStep   # 追加
func get_issue_by_id(issue_id: String) -> CaseIssue          # 追加
func validate() -> Array[String]                              # 旧バリデーション撤廃・新ルールに変更
```

**`validate()` 新ルール:**
- `entry_step_id` が `investigation_steps` 内に存在すること
- 全 `investigation_steps` の `choices.size() == 7`
- 全 `outcome_rules` の `outcome_key` が `outcomes` に存在すること
- `"insufficient"` アウトカムが `outcomes` に存在すること

---

### 6. `CaseManager` — 拡張

**ファイル:** `autoloads/case_manager.gd`

**削除メソッド:**
- `submit_verdict(outcome_key: String)`
- `get_verdict_options() -> Array[VerdictChoice]`

**追加フィールド:**
```gdscript
var current_step_id: String = ""
var step_id_history: Array[String] = []   # 訪問順ステップIDリスト
var choice_history: Dictionary = {}       # {step_id: choice_key}
var resolved_issue_ids: Array[String] = []
var chain_complete: bool = false
```

**追加メソッド:**
```gdscript
func start_investigation() -> void
# entry_step_id をセット、チェーン状態をリセット
# → EventBus.step_arrived.emit(entry_step_id)

func get_current_step() -> InvestigationStep

func answer_step(choice_key: String) -> void
# 1. current_case.get_step_by_id(current_step_id) から choice を取得
# 2. step_id_history.append(current_step_id)
# 3. choice_history[current_step_id] = choice_key
# 4. if choice.resolves_issue_id: resolved_issue_ids.append(...)
#    → EventBus.issue_resolved.emit(issue_id)
# 5. if choice.reveals_evidence_id: EventBus.evidence_unlocked.emit(evidence_id)
# 6. if choice.is_terminal():
#    chain_complete = true; _timer_active = false
#    → EventBus.investigation_chain_complete.emit(resolved_issue_ids)
# 7. else: current_step_id = choice.next_step_id
#    → EventBus.step_arrived.emit(current_step_id)

func determine_outcome() -> String
# current_case.outcome_rules を順番に評価
# rule.matches(resolved_issue_ids) なら rule.outcome_key を返す
# マッチなし → "insufficient"

func get_revealed_evidence_ids() -> Array[String]
# step_id_history の各ステップの reveals_evidence_id + CaseData.evidence の初期証拠

func get_chain_summary() -> Array[Dictionary]
# step_id_history を辿り、各ステップの {step_id, choice_key, resolved_issue_id} を返す
```

**既存メソッドの変更:**
- `start_case()`: `start_investigation()` 呼び出しを追加
- `set_current_case()`: 新フィールドの初期化を追加

---

### 7. `EventBus` — シグナル追加・削除

**ファイル:** `autoloads/event_bus.gd`

**削除シグナル:**
- `verdict_submitted(outcome_key: String)` — 廃止

**追加シグナル:**
```gdscript
signal step_arrived(step_id: String)
signal step_answered(step_id: String, choice_key: String)
signal issue_resolved(issue_id: String)
signal evidence_unlocked(evidence_id: String)
signal investigation_chain_complete(resolved_issue_ids: Array)
```

---

### 8. `GameManager` — GameState 変更

**ファイル:** `autoloads/game_manager.gd`

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    CASE_SELECT,
    BRIEFING,
    INVESTIGATING,
    CHAIN_REVIEW,   # 旧 VERDICT をリネーム
    OUTCOME,
    PAUSED,
}
```

---

### 9. `InvestigationScreen` — 変更

**ファイル:** `scenes/ui/investigation_screen.gd`

**レイアウト変更:**

```
[旧]
┌─────────────────────────────────┐
│ タイマー                         │
├──────────────┬──────────────────┤
│ 証拠ボタン列  │ 証拠コンテンツ     │
├─────────────────────────────────┤
│ [ DELIVER VERDICT ]             │
└─────────────────────────────────┘

[新]
┌─────────────────────────────────┐
│ タイマー          │ STEP N       │
├──────────────┬──────────────────┤
│ 証拠ボタン列  │ ステップ質問文    │
│              │ ─────────────── │
│              │ [選択肢 1]       │
│              │ [選択肢 2]       │
│              │ ...             │
│              │ [選択肢 7]       │
│              ├──────────────────┤
│              │ 証拠コンテンツ    │
│              │ (クリックで表示)  │
└──────────────┴──────────────────┘
```

**削除:** `_verdict_btn`、`_on_deliver_verdict()`、`_refresh_verdict_btn()`

**追加:**
```gdscript
var _step_choice_buttons: Array[Button] = []
var _step_question_label: Label
var _step_type_label: Label
var _step_indicator_label: Label  # "STEP N"
var _content_panel: Control       # 証拠コンテンツエリア（下部）

func _build_step_panel() -> void
func _refresh_step_ui(step: InvestigationStep) -> void
func _on_step_choice_selected(choice_key: String) -> void
  # CaseManager.answer_step(choice_key) を呼ぶ
  # EventBus.investigation_chain_complete に接続して ChainReviewScreen へ

func _on_step_arrived(step_id: String) -> void   # EventBus接続
func _on_investigation_complete(resolved_ids: Array) -> void
  # → scene_change_requested.emit("chain_review_screen.tscn")
```

**`_input()` 変更:**
- ステップ確定後はすべての入力を 0.2 秒 lock（誤爆防止）
- Escape = ポーズのみ（前ステップ移動には使用不可）

---

### 10. `ChainReviewScreen` — 新規シーン

**ファイル:** `scenes/ui/chain_review_screen.gd` / `.tscn`

**レイアウト:**
```
┌──────────────────────────────────────────┐
│ INVESTIGATION COMPLETE                   │
│ ISSUES IDENTIFIED: 3 / 7                │
├──────────────────────────────────────────┤
│ [STEP 1] 最初に何を疑う？                │
│   → 選択: コードの改ざん ✓ (code_tampered 解決) │
│ [STEP 2] 除外リストの作成時期は？         │
│   → 選択: ASTRA-7稼働前 ✓              │
│ [STEP 3] ...                            │
│ [STEP 4] タイムアウト ×                 │
├──────────────────────────────────────────┤
│             [ VERDICT ]                 │
└──────────────────────────────────────────┘
```

**インターフェース:**
```gdscript
func _ready() -> void
  # CaseManager.determine_outcome() で outcome_key を取得
  # CaseManager.get_chain_summary() でリスト構築

func _build_layout() -> void
  # 各ステップ行: step_id_history を順番に表示
  # 課題解決あり = 緑色、解決なし = 暗色、タイムアウト = 赤色

func _on_verdict_pressed() -> void
  # CaseManager.selected_verdict = determine_outcome() セット済みであること
  # → scene_change_requested.emit("outcome_screen.tscn")
```

---

### 11. `OutcomeScreen` — 変更（最小）

**ファイル:** `scenes/ui/outcome_screen.gd`

**削除:** `verdict_choices` を参照している L62–68 のブロック  

**変更:**
- "YOUR VERDICT: ..." → "ISSUES RESOLVED: X / Y" を表示
- `verdict_key` は `CaseManager.selected_verdict` から取得（`determine_outcome()` の結果を `start_case_resolve` 前に設定）

---

## シーン遷移マップ（変更後）

```
BriefingScreen
    ↓
InvestigationScreen
    ↓ (全ステップ終了 or タイムアウト)
ChainReviewScreen  ← NEW（旧 VerdictScreen の位置）
    ↓ ([ VERDICT ] ボタン)
OutcomeScreen
    ↓ (RETRY / CASE SELECT)
BriefingScreen / CaseSelectScreen
```

---

## データフロー図

```
CaseData.tres
  └── entry_step_id ─→ CaseManager.start_investigation()
                              │
                    current_step_id = "S01"
                              │
                    InvestigationScreen._refresh_step_ui()
                              │
                   プレイヤーが選択肢を選ぶ
                              │
                    CaseManager.answer_step("choice_A")
                    ├── choice_history["S01"] = "choice_A"
                    ├── resolved_issue_ids += ["code_tampered"]
                    ├── EventBus.issue_resolved("code_tampered")
                    ├── current_step_id = "S02a"
                    └── EventBus.step_arrived("S02a")
                              │
                    InvestigationScreen._refresh_step_ui()
                              │
                    ... (繰り返し) ...
                              │
                    choice.is_terminal() == true
                    └── EventBus.investigation_chain_complete([...])
                              │
                    ChainReviewScreen
                    ├── CaseManager.get_chain_summary() → リスト表示
                    ├── CaseManager.determine_outcome() → outcome_key
                    └── [ VERDICT ] → OutcomeScreen
```

---

## 要件トレーサビリティ

| 要件 | 対応コンポーネント |
|------|-----------------|
| 1.1 StepChoice | `StepChoice` リソース |
| 1.2 InvestigationStep | `InvestigationStep` リソース |
| 1.3 CaseIssue | `CaseIssue` リソース |
| 1.4 OutcomeRule | `OutcomeRule` リソース |
| 1.5 CaseData 変更 | `CaseData` フィールド追加・削除 |
| 1.6 validate() | `CaseData.validate()` 新ルール |
| 2.1 後戻り不可 | `CaseManager.answer_step()` / `InvestigationScreen._input()` |
| 2.2 課題解決記録 | `CaseManager.answer_step()` → `resolved_issue_ids` |
| 2.3 ブランチ終端 | `StepChoice.is_terminal()` → `chain_complete = true` |
| 2.4 Escape = ポーズのみ | `InvestigationScreen._input()` |
| 2.5 タイムアウト | `CaseManager._tick()` → `chain_complete = true` |
| 3.1 初期証拠 | `CaseData.evidence` (変更なし) |
| 3.2 ステップ到達時証拠 | `EventBus.evidence_unlocked` → `InvestigationScreen` |
| 3.3 証拠常時参照可 | 証拠パネル常時表示（下部エリア） |
| 4.1 ステップ一覧 | `ChainReviewScreen._build_layout()` |
| 4.2 課題数表示 | `ChainReviewScreen` ヘッダー |
| 4.3 アウトカム決定 | `CaseManager.determine_outcome()` |
| 4.4 insufficientフォールバック | `determine_outcome()` のデフォルト戻り値 |
| 4.5 VERDICT ボタン | `ChainReviewScreen._on_verdict_pressed()` |
| 4.6 美術方針 | `ChainReviewScreen` カラー定数（既存パターン踏襲） |
| 5.1–5.4 アウトカムルール | `OutcomeRule.matches()` / `CaseManager.determine_outcome()` |
| 5.5 アウトカム画面 | `OutcomeScreen` 変更 |
| 6.1–6.6 シナリオ構成 | `case_001.tres` 再設計 |
| 7.1–7.3 操作 | `InvestigationScreen._input()` / `ChainReviewScreen._input()` |

---

## 削除・非推奨化するコンポーネント

| ファイル | 対応 |
|---------|------|
| `scripts/data/verdict_choice.gd` | 非推奨化（`StepChoice` に置換）。`OutcomeData` 参照は維持 |
| `scenes/ui/verdict_screen.gd` | 削除 → `chain_review_screen.gd` に置換 |
| `scenes/ui/verdict_screen.tscn` | 削除 → `chain_review_screen.tscn` に置換 |
| `EventBus.verdict_submitted` シグナル | 削除 |
| `CaseManager.get_verdict_options()` | 削除 |
| `CaseManager.submit_verdict()` | 削除 |

---

## テスト設計方針

| テスト対象 | テストファイル | 主要テストケース |
|-----------|-------------|----------------|
| `StepChoice` | `tests/unit/test_step_choice.gd` | `is_terminal()`, `get_label()` ロケール |
| `InvestigationStep` | `tests/unit/test_investigation_step.gd` | `validate()` 7件チェック, `get_choice_by_key()` |
| `OutcomeRule` | `tests/unit/test_outcome_rule.gd` | `matches()` 境界値（min_count=0, required=[]等） |
| `CaseData` | `tests/unit/test_case_data.gd` | 新 `validate()` ルール, `get_step_by_id()` |
| `CaseManager` | `tests/unit/test_case_manager.gd` | `answer_step()` 分岐, `determine_outcome()` ルール評価, タイムアウト記録 |
