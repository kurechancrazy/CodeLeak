# リサーチログ — chain-deduction

## 調査サマリー

**調査区分:** Extension（既存システムへの統合設計）  
**調査対象:** 現行ゲームループ全体（CaseManager・InvestigationScreen・VerdictScreen・OutcomeScreen・データリソース）

### 主な知見

1. **VerdictScreen は完全置換が必要** — 現在の `VerdictScreen` は「7択から手動で1つを選ぶ」構造であり、新フローでは手動選択が廃止される。`verdict_screen.tscn` / `.gd` は新規 `chain_review_screen.tscn` / `.gd` に置換する。

2. **OutcomeScreen は `verdict_choices` 参照あり** — `outcome_screen.gd` の L62–68 で `case_data.verdict_choices` を直接ループしている。新データ構造への対応が必要。

3. **CaseManager の状態変数が増える** — 現行 `selected_verdict: String` 1変数でアウトカムを管理しているが、新設計では `step_id_history`・`choice_history`・`resolved_issue_ids` が追加される。既存の `submit_verdict()` / `get_verdict_options()` は削除・置換対象。

4. **GameState.VERDICT → CHAIN_REVIEW へのリネームが必要** — `architecture.md` の GameState 列挙型に `CHAIN_REVIEW` を追加（または `VERDICT` をリネーム）する。既存コード中 `VERDICT` への参照はすべて `CHAIN_REVIEW` に変更。

5. **EventBus に新シグナルが必要** — 既存シグナル（`verdict_submitted`）は削除・非推奨化し、`step_answered`・`issue_resolved`・`investigation_chain_complete` を追加する。

6. **InvestigationScreen の右パネル構造変更** — 現行は右側が「証拠コンテンツ表示エリア」だが、ステップ問題が常に表示される必要がある。「上：ステップ質問+選択肢 / 下：証拠コンテンツ（クリック時）」のスプリット構造に変更。

---

## リサーチ記録

### 1. 分岐ツリーのデータ設計パターン

**調査内容:** GDScript Resource で有向グラフ（分岐ツリー）を表現する方法

**知見:**
- GDScript の `@export` は `Dictionary` を直接エクスポートできない（Godot 4.4 時点では `Dictionary[String, Resource]` の export は不安定）
- 代替: `Array[InvestigationStep]` をフラットリストで持ち、`step_id: String` による線形探索でルックアップする
- パフォーマンス: 1ケース最大12ステップなので O(n) 線形探索で問題なし
- ブランチ終端は `next_step_id = ""` で表現するのが最もシンプル

**決定:** `CaseData.investigation_steps: Array[InvestigationStep]` + `entry_step_id: String` の組み合わせを採用。

---

### 2. 後戻り不可のUX設計

**調査内容:** 既存の「キャンセル不可」実装パターン

**知見:**
- `VerdictScreen._input()` で Escape と pause を `set_input_as_handled()` で握りつぶす実装が既に存在（L133–137）
- 同様のパターンを `InvestigationScreen` のステップ回答フェーズに適用できる
- 確定ボタンに0.4秒のinput lock（`_input_locked`）が `VerdictScreen` で実装済み → 同パターン流用

**決定:** ステップ確定後の `answer_step()` 呼び出しは即座に `current_step_id` を書き換え、UIレベルでは前ステップへのナビゲーション手段を提供しない。

---

### 3. 課題解決とアウトカムルール評価

**調査内容:** 複数条件マッチのアウトカム決定ロジック

**知見:**
- 現行の `CaseManager.get_alternate_hint()` は `outcomes` 配列を線形探索するパターン
- `OutcomeRule` も同様に配列を先頭から評価し最初にマッチしたものを採用する「ルールエンジン」パターンが適切
- Godot Resource の `@export var required_issue_ids: Array[String]` は配列の全要素チェックが必要 → `resolved_issue_ids.has()` でループ検査

**決定:** `CaseManager.determine_outcome()` が `outcome_rules` を線形評価し、最初にマッチした `outcome_key` を返す。マッチなしは `"insufficient"` を返す。

---

### 4. InvestigationScreen のレイアウト変更

**調査内容:** 現行の右パネルと、ステップ質問パネルの共存方法

**知見:**
- 現行レイアウト: `[タイマー行] / [証拠ボタン列|証拠コンテンツ] / [DELIVER VERDICT ボタン]`
- ステップ質問は「現在解くべきアクション」なので常時表示が必要
- 証拠コンテンツはクリックで参照するもの（情報参照）→ 下部に折りたためる設計が自然

**決定:** 右パネルを `VSplitContainer` または固定分割に変更。上部 (~60%) = ステップ質問+選択肢、下部 (~40%) = 選択した証拠コンテンツ。DELIVER VERDICT ボタンは削除（フローが自動化されるため不要）。

---

### 5. ASTRA-7事件の分岐ツリー設計（コンテンツ）

**調査内容:** 既存の case_001 証拠4件からどう分岐ツリーを設計するか

**知見（既存証拠）:**
- CODE: `pharmaceutical_router.py` の病院除外リスト（deployment: 2026-02-14以前）
- LOG: 迂回開始ログ（2026-02-14〜）＋ MCRP株価相関
- EMAIL: V.Chen の内部メール（2026-02-10）
- NETWORK: bloomberg-api への未承認接続（2026-02-01〜2026-02-13）

**課題候補（7件）:**
1. `code_tampered` — コードに意図的な除外リストが組み込まれた
2. `email_authorized` — 人間（V.Chen）がASTRA-7に指示した
3. `timeline_human_first` — コード変更は ASTRA-7 稼働前
4. `api_self_initiated` — ASTRA-7 が自律的に外部APIを発見した
5. `financial_correlation` — 株価上昇と迂回タイミングの相関
6. `api_before_code` — ネットワーク接続はコード変更より前（ASTRA-7の先行探索）
7. `chen_redacted` — メールの [REDACTED] 受信者が問題の核心

**分岐ツリー設計（10ステップ）:**
```
S01 [DEDUCTION] 最初に何を疑う？
  → A: コードの改ざん             → S02a
  → B: 株価連動の不正             → S02b
  → C: 未承認ネットワーク接続     → S02c
  → D〜G: (デコイ)               → S02d

S02a [CODE] 除外リストはいつ作られたか？
  → A: ASTRA-7稼働前 (2026-02-10) → resolves: timeline_human_first → S03a
  → B〜G: デコイ                   → S03b

S02b [LOG] 株価上昇の直前に何が起きたか？
  → A: 迂回開始ログ                → resolves: financial_correlation → S03c
  → B〜G: デコイ                   → S03d

S02c [NETWORK] APIへの最初の接続日は？
  → A: 2026-02-01 (コード前)      → resolves: api_before_code → S03e
  → B〜G: デコイ                   → S03f

S02d [DEDUCTION] デコイ選択後の簡略パス
  → どれでも → S03g (shallow)

S03a [EMAIL] Chenのメールで誰が指示したか？
  → A: [REDACTED] が存在する      → resolves: chen_redacted → S04a
  → B〜G: デコイ                   → S04b

S03b [LOG] ログのどこに矛盾があるか？
  → A: 0件配送失敗は改ざんの証拠  → resolves: code_tampered → S04c
  → B〜G: デコイ                   → S04d

S03c [CODE] コードのどこが問題か？
  → A: _should_exclude_hospital   → resolves: code_tampered → S04e
  → B〜G: デコイ                   → S04f

S03d [NETWORK] 接続は誰が承認したか？
  → A: 承認記録なし=自律           → resolves: api_self_initiated → S04g
  → B〜G: デコイ                   → S04h

S03e [EMAIL] Chenの指示時期とAPI接続の関係は？
  → A: API接続が指示より先        → resolves: api_self_initiated → S04i
  → B〜G: デコイ                   → S04j

S03f [CODE] 除外されたのはどのタイプの病院か？
  → A: Tier-3(低利益)のみ         → resolves: email_authorized → S04k
  → B〜G: デコイ                   → S04l

S03g [DEDUCTION] 簡略パス最終問
  → どれでも → END (0課題)

S04a [DEDUCTION] 最終判断: この事件の本質は？
  → END (各選択後終了)

※ S04* は全て最終ステップ（next_step_id = ""）
```

**設計の含意:** 序盤で「コード → メール → 人間犯罪」路線を選ぶと `timeline_human_first + chen_redacted + code_tampered` が解決（3課題）。「ネットワーク → AI自律」路線を選ぶと `api_before_code + api_self_initiated` が解決（2課題）。両路線を1ランで取ることは不可能 → 周回プレイ動機が生まれる。
