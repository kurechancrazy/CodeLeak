# 技術設計書 — evidence-citation（証拠引用モデル）

## 概要と設計方針

調査ステップを「引用待ち（AWAITING_CITATION）」→「回答待ち（AWAITING_ANSWER）」の2フェーズに分割する。  
既存のシグナル・メソッドパターンを最大限継承し、変更差分を最小化する。

---

## アーキテクチャパターンと境界マップ

```
┌─────────────────────────────────────────────────────────────┐
│ Data Layer                                                  │
│  InvestigationStep (+correct_evidence_id)                   │
│  case_001.tres (各ステップに correct_evidence_id 値を設定)   │
└──────────────────────┬──────────────────────────────────────┘
                       │ リソース参照
┌──────────────────────▼──────────────────────────────────────┐
│ Logic Layer                                                 │
│  CaseManager                                                │
│  ├─ _awaiting_citation: bool                                │
│  ├─ _wrong_citation_count: int                              │
│  ├─ citation_history: Dictionary                            │
│  ├─ cite_evidence(evidence_id) → 正誤判定 + signal          │
│  ├─ apply_wrong_citation_penalty() → タイマー操作            │
│  └─ is_awaiting_citation() → bool (public getter)          │
└──────────────────────┬──────────────────────────────────────┘
                       │ EventBus (シグナルのみ)
┌──────────────────────▼──────────────────────────────────────┐
│ Event Layer (EventBus)                                      │
│  + evidence_cited_correctly(step_id, evidence_id)           │
│  + evidence_cited_wrongly(step_id, evidence_id)             │
│  ※ 既存シグナルは変更なし                                    │
└──────────┬───────────────────────────┬──────────────────────┘
           │ connect                   │ connect
┌──────────▼──────────┐  ┌────────────▼─────────────────────┐
│ UI Layer            │  │ Review Layer                      │
│ InvestigationScreen │  │ ChainReviewScreen                 │
│ ├─ _cite_button     │  │ └─ get_chain_summary() の         │
│ ├─ _citation_prompt │  │    cited_evidence_id を追加表示   │
│ └─ _on_cite_pressed │  └───────────────────────────────────┘
│  ※ 引用状態は       │
│  is_awaiting_       │
│  citation() getter  │
│  で CaseManager を  │
│  参照（ローカル複製なし）│
└─────────────────────┘
```

**依存方向:** Data → Logic → Event → UI/Review（上位層は下位層を参照しない）

---

## 技術スタックとの整合

| 項目 | 方針 |
|------|------|
| 言語 | GDScript 2.0 typed（全変数・引数・戻り値に型アノテーション） |
| UIパターン | 既存のコード生成UI（`Button.new()` / `Label.new()`）に準拠 |
| 状態管理 | CaseManager の既存 `bool` フラグパターンを踏襲 |
| シグナル | EventBus 経由、UI がロジックを直接操作しない原則を維持 |
| 外部依存 | 新規追加なし |

---

## コンポーネント定義と API 契約

### 1. InvestigationStep（データ層）

**ファイル:** `scripts/data/investigation_step.gd`

**変更内容:** フィールド1件追加

```
@export var correct_evidence_id: String = ""
# 空文字 = 引用フェーズをスキップ
```

`validate()` の変更: なし（空文字は有効値）

---

**ファイル:** `resources/cases/case_001.tres`

> **実装注意:** `tres` ファイルのバッチ編集はコンテキスト照合の失敗リスクがある。  
> 各ステップの `correct_evidence_id` 追加は **Edit ツールで1件ずつ** 行うこと。

各 `InvestigationStep` への `correct_evidence_id` 設定値:

| ステップID | correct_evidence_id | 理由 |
|-----------|---------------------|------|
| s01 | `""` | 到達時証拠が1件のみ（CODE）。引用に選択の余地がない |
| s02a | `"e001_code"` | CODEコミット日付との照合が根拠 |
| s02b | `"e001_log"` | ログの時系列が根拠 |
| s02c | `"e001_network"` | ネットワーク接続の承認記録が根拠 |
| s02d | `""` | off-track収束ステップ。特定証拠を強制するとUX上不自然 |
| s03a | `"e001_email"` | V.チェンのメールが直接根拠 |
| s03b | `"e001_code"` | 除外リストのコードが根拠 |
| s03g | `""` | 複数証拠総合の収束ステップ |
| s04 | `"e001_network"` | 承認記録なしの証明が根拠 |
| s05 | `"e001_log"` | 統計的相関のログが根拠 |
| s06 | `"e001_code"` | gitコミット日付が根拠 |
| s07 | `""` | 全証拠総合の最終帰責ステップ |

---

### 2. CaseManager（ロジック層）

**ファイル:** `autoloads/case_manager.gd`

**新規追加変数:**

```
var citation_history: Dictionary = {}
# key: step_id: String, value: evidence_id: String
# 正しく引用されたステップのみ記録

var _awaiting_citation: bool = false
# true = AWAITING_CITATION、false = AWAITING_ANSWER

var _wrong_citation_count: int = 0
# 現在ステップでの誤引用回数（ステップ移動時にリセット）
```

**変更: `set_current_case()`**  
`citation_history.clear()` を追加

**変更: `start_investigation()`**  
`citation_history.clear()` を追加  
エントリーステップの `correct_evidence_id` に基づいて初期状態を設定:

```
# エントリーステップの correct_evidence_id 判定
_awaiting_citation = not entry_step.correct_evidence_id.is_empty()
_wrong_citation_count = 0
```

**変更: `answer_step(choice_key: String)`**  
先頭ガードに `_awaiting_citation` を追加:

```
if current_case == null or chain_complete or _awaiting_citation:
    return
```

次のステップに進む前に次ステップの引用状態を設定:

```
# 次ステップに進む前
if next_step != null:
    _awaiting_citation = not next_step.correct_evidence_id.is_empty()
    _wrong_citation_count = 0
```

**新規: `cite_evidence(evidence_id: String) -> void`**

```
# AWAITING_CITATION 状態のときのみ有効
# 正誤判定を行い EventBus でシグナル発信
# 正解の場合: citation_history[current_step_id] = evidence_id、_awaiting_citation = false
# 誤りの場合: _wrong_citation_count が 2 未満なら apply_wrong_citation_penalty() 呼び出し
#             _wrong_citation_count インクリメント
```

**新規: `apply_wrong_citation_penalty() -> void`**

```
# タイムリミットから 15 秒を差し引く
# EventBus.countdown_updated を発信
# apply_wrong_answer_penalty() と同パターン
```

**新規: `is_awaiting_citation() -> bool`**

```
# _awaiting_citation の public getter
# InvestigationScreen が直接 _awaiting_citation にアクセスすることを禁止し、
# このメソッド経由で読む。UI 側がローカルコピーを持たないための設計上の強制境界。
return _awaiting_citation
```

**`cite_evidence()` 内の呼び出し順序（誤引用時）:**

誤引用が確定した場合、以下の順序で処理する:
1. `_wrong_citation_count < 2` のとき `apply_wrong_citation_penalty()` を呼ぶ（タイマーを先に更新）
2. `_wrong_citation_count` をインクリメント
3. `EventBus.evidence_cited_wrongly.emit(step_id, evidence_id)` を発信

タイマーが正しい値に更新された後でシグナルが飛ぶため、UI が `countdown_updated` と `evidence_cited_wrongly` を受信したとき残り時間が確定している。

**変更: `get_chain_summary() -> Array[Dictionary]`**  
各エントリーに `cited_evidence_id: String` を追加:

```
{
    "step_id": step_id,
    "choice_key": chosen_key,
    "resolved_issue_id": resolved_id,
    "points_earned": points_earned,
    "timed_out": chosen_key.is_empty(),
    "cited_evidence_id": citation_history.get(step_id, ""),  # 新規追加
}
```

---

### 3. EventBus（イベント層）

**ファイル:** `autoloads/event_bus.gd`

**追加シグナル（`# --- 連鎖推理チェーン ---` セクションに追記）:**

```
signal evidence_cited_correctly(step_id: String, evidence_id: String)
signal evidence_cited_wrongly(step_id: String, evidence_id: String)
```

---

### 4. InvestigationScreen（UI層）

**ファイル:** `scenes/ui/investigation_screen.gd`

**新規追加メンバー変数:**

```
var _cite_button: Button
var _citation_prompt_label: Label
var _citation_animating: bool = false
# ※ _awaiting_citation はローカルに持たない。
#    CaseManager.is_awaiting_citation() を都度呼び出す。
#    ローカルコピーはシグナル受信タイミングとのズレを生む。
# _citation_animating: 赤フラッシュ Tween 実行中は true。
#    Tween 完了前に別の証拠をクリックしてもCITEアクションを受け付けない。
```

**`_build_layout()` への追加（右パネル `right_vbox` の末尾に追加）:**

```
# 証拠引用プロンプト（引用待ち状態でのみ表示）
_citation_prompt_label = Label.new()
_citation_prompt_label.visible = false
_citation_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
right_vbox.add_child(_citation_prompt_label)  # ScrollContainer の後

# CITE THIS EVIDENCE ボタン（引用待ち + 証拠選択済みのときのみ有効）
_cite_button = Button.new()
_cite_button.visible = false
_cite_button.pressed.connect(_on_cite_evidence_pressed)
right_vbox.add_child(_cite_button)
```

**`_build_step_panel()` への追加:**  
引用待ち状態のとき、既存の `_input_locked` フラグを `true` に設定して選択肢ボタンをロックする。  
`modulate.a = 0.4` での視覚的ロックのみでは `ui_accept` キーによるキーボードナビゲーションを防げない。  
`_input_locked` がすでに存在するパターンを再利用し、引用フェーズ終了時に `_input_locked = false` に戻す。

**新規ハンドラ `_on_step_arrived()` 内に引用状態の同期追加:**

```
# _selected_index を -1 にリセット（前ステップの選択状態をクリア）
_selected_index = -1
_update_citation_ui()
```

**新規: `_update_citation_ui() -> void`**  
`CaseManager.is_awaiting_citation()` の値に基づいて以下を更新:

| 条件 | `_citation_prompt_label.visible` | `_cite_button.visible` | `_input_locked` |
|------|----------------------------------|------------------------|-----------------|
| AWAITING_CITATION | `true`（ステップ到達と同時に表示） | `_selected_index >= 0` のとき `true` | `true` |
| AWAITING_ANSWER | `false` | `false` | `false` |

**D2 設計方針:** プロンプト（「この問いに答える証拠を選んでください」）はステップ到達と同時に表示し、  
何をすべきか即座にプレイヤーに伝える。CITE ボタンは証拠カードをクリックして初めて現れる。  
2つの UI 要素の表示タイミングを分離することで、操作手順が自明になる。

**新規: `_on_evidence_selected(index: int)` への追加:**  
引用待ち状態（`CaseManager.is_awaiting_citation()` が `true`）のとき `_cite_button.visible = true` に設定。

**新規: `_on_cite_evidence_pressed() -> void`**  
`_selected_index` が有効かつ `_citation_animating == false` の場合に `CaseManager.cite_evidence(evidence.evidence_id)` を呼び出す。  
`_citation_animating == true`（赤フラッシュ中）は呼び出しを無視する。

**新規シグナルハンドラ:**

```
func _on_evidence_cited_correctly(_step_id: String, evidence_id: String) -> void:
    # 証拠カードを緑ハイライト
    # _cite_button.visible = false
    # _citation_prompt_label.visible = false
    # ※ _awaiting_citation はローカル変数を持たないため、ここでは変更しない
    #    CaseManager.is_awaiting_citation() が次回から false を返すことで状態が反映される
    # _update_citation_ui() 呼び出し → _input_locked = false、選択肢が有効化される
    # 選択肢ボタンに grab_focus()

func _on_evidence_cited_wrongly(_step_id: String, evidence_id: String) -> void:
    # 誤引用されたエビデンスカードを特定:
    #   _evidence_buttons 配列を走査し、evidence_id が一致するインデックスを探す
    #   CaseManager.current_case.evidence[i].evidence_id == evidence_id で照合
    # 該当カードを Tween で赤フラッシュ（赤→元色）
    # Tween 実行中は _citation_animating フラグを true にして二重引用を防ぐ
    # 引用待ち状態を維持（_cite_button は引き続き表示）
```

**`_ready()` / `_exit_tree()` での新規シグナル接続・切断:**

```
EventBus.evidence_cited_correctly.connect(_on_evidence_cited_correctly)
EventBus.evidence_cited_wrongly.connect(_on_evidence_cited_wrongly)
```

---

### 5. ChainReviewScreen（レビュー層）

**ファイル:** `scenes/ui/chain_review_screen.gd`

**変更: `_build_layout()` 内の summary ループ**

各 `entry` から `cited_evidence_id: String = entry.get("cited_evidence_id", "")` を取得し、  
選択肢表示行の下に引用表示行を追加:

```
# 引用エビデンス表示行
var cited_text: String
var cited_color: Color
if correct_evidence_id is empty (""):
    cited_text = "—"
    cited_color = _COLOR_DIM
elif cited_evidence_id is not empty:
    # EvidenceItem のタイトルを取得して表示
    cited_text = tr("CHAIN_REVIEW_CITATION") % evidence_title
    cited_color = _COLOR_RESOLVED
else:
    cited_text = "—"
    cited_color = _COLOR_DIM
```

ただし ChainReviewScreen は `correct_evidence_id` を直接参照しない。  
`cited_evidence_id` が空文字かどうかのみで判定（引用不要ステップは `citation_history` に記録されないため自然に空文字になる）。

---

### 6. translations.csv（i18n層）

**ファイル:** `assets/i18n/translations.csv`

追加するキー:

| キー | EN | JA |
|-----|----|----|
| `CITE_EVIDENCE_PROMPT` | `CITE EVIDENCE — select the evidence that answers this question` | `証拠を引用してください — この問いに答える証拠を選択してください` |
| `CITE_EVIDENCE_BTN` | `[ CITE THIS EVIDENCE ]` | `[ この証拠を引用する ]` |
| `CHAIN_REVIEW_CITATION` | `CITED: %s` | `引用: %s` |

---

## データフロー図

### 引用フェーズの状態遷移

```
step_arrived(step_id)
        │
        ▼
 correct_evidence_id == ""?
        │
    YES │                          NO
        ▼                          ▼
 AWAITING_ANSWER            AWAITING_CITATION
 (選択肢アクティブ)           (選択肢グレーアウト)
        │                     証拠カード クリック可能
        │                     CITEボタン (証拠選択後)
        │                          │
        │               cite_evidence(evidence_id)
        │                          │
        │                 ┌────────┴────────┐
        │                 │                 │
        │              CORRECT          WRONG (count < 2)
        │                 │                 │
        │   emit cited_correctly   emit cited_wrongly
        │   citation_history 記録  -15秒ペナルティ
        │   AWAITING_ANSWER ↓      AWAITING_CITATION 維持
        │                 │
        └─────────────────┘
                  │
            answer_step()
                  │
             次ステップへ
```

---

## 要件トレーサビリティ

| 要件 | 実装コンポーネント |
|------|-----------------|
| 1.1 correct_evidence_id フィールド追加 | InvestigationStep |
| 1.2 case_001.tres への値設定 | case_001.tres |
| 1.3 既存フィールド変更なし | InvestigationStep（確認済み） |
| 2.1 AWAITING_CITATION 状態でロック | InvestigationScreen._update_citation_ui() |
| 2.2 証拠カード強調表示 | InvestigationScreen._update_citation_ui() |
| 2.3 プロンプトメッセージ表示 | InvestigationScreen._citation_prompt_label |
| 2.4 空文字ステップはスキップ | CaseManager.cite_evidence() / start_investigation() |
| 3.1 カードクリック = 詳細表示（現行維持） | InvestigationScreen._on_evidence_selected() |
| 3.2 詳細エリア下に CITE ボタン表示 | InvestigationScreen._cite_button |
| 3.3 CITE ボタン押下で引用アクション | InvestigationScreen._on_cite_evidence_pressed() |
| 3.4 正誤判定 | CaseManager.cite_evidence() |
| 3.5 シグナル発信 | CaseManager → EventBus |
| 3.6 citation_history 記録 | CaseManager.cite_evidence() |
| 4.1 正解 → 緑ハイライト | InvestigationScreen._on_evidence_cited_correctly() |
| 4.2 正解 → 選択肢アンロック | InvestigationScreen._on_evidence_cited_correctly() |
| 4.3 ポイント変更なし | （変更対象なし） |
| 5.1 誤り → 赤フラッシュ | InvestigationScreen._on_evidence_cited_wrongly() |
| 5.2 誤り → 15秒ペナルティ | CaseManager.apply_wrong_citation_penalty() |
| 5.3 誤り → AWAITING_CITATION 維持 | CaseManager.cite_evidence() |
| 5.4 1ステップ最大2回ペナルティ | CaseManager._wrong_citation_count |
| 5.5 タイムアウト時は終了 | CaseManager._tick()（既存ロジック） |
| 6.1 状態フラグ | CaseManager._awaiting_citation |
| 6.2 start_investigation() 初期化 | CaseManager.start_investigation() |
| 6.3 cite_evidence() メソッド | CaseManager.cite_evidence() |
| 6.4 apply_wrong_citation_penalty() | CaseManager.apply_wrong_citation_penalty() |
| 6.5 answer_step() ガード | CaseManager.answer_step() |
| 6.6 citation_history 変数 | CaseManager.citation_history |
| 6.7 get_chain_summary() 拡張 | CaseManager.get_chain_summary() |
| 7.1 evidence_cited_correctly シグナル | EventBus |
| 7.2 evidence_cited_wrongly シグナル | EventBus |
| 7.3 既存シグナル変更なし | EventBus（確認済み） |
| 8.1 引用エビデンス名を表示 | ChainReviewScreen._build_layout() |
| 8.2 正解引用を緑表示 | ChainReviewScreen._build_layout() |
| 8.3 スキップステップは「—」 | ChainReviewScreen._build_layout() |
| 8.4 誤引用履歴は非表示 | （citation_history に正解のみ記録のため自然に満たす） |
| 9.1 既存テスト変更なし | correct_evidence_id="" デフォルト値 |
| 9.2 cite_evidence() 不要ステップの後方互換 | CaseManager._awaiting_citation = false |
| 9.3 新規ユニットテスト追加 | test_case_manager.gd |
