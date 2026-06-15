# 技術設計書 — tension-gameplay（ナラティブ調査型・1ケース完全版）

> 本設計は実装者・UI/UX・テスターの3観点レビュー（致命的指摘14件）を反映済み。各修正は §で明示する。

## 1. Architecture Pattern & Boundary Map

### アーキテクチャパターン

旧クイズ系を**原子的に破棄**し、新 Autoload（CaseManager）+ 5画面へ全面置換する。既存基盤（EventBus・SceneManager・GameManager・SaveManager・AudioManager・Logger）は流用。全画面は GDScript で UI を動的構築する（既存シーンと統一）。

### シーン遷移フロー

```
MainMenu ─[PLAY]─► CaseSelectScreen ─[ロック/WL]─► OS.shell_open(WISHLIST_URL)
                        │ ケース選択
                        ▼
                   BriefingScreen ──[Esc]──► CaseSelect
                        │ [BEGIN INVESTIGATION]（Enter）
                        ▼
                   InvestigationScreen（ポーズUI内蔵）
                        │ [判決を下す] ──────► VerdictScreen ─► OutcomeScreen
                        │ 時間切れ ─► TIME EXPIRED 告知 ─────────────► OutcomeScreen
                        ▼
                   OutcomeScreen ─[もう一度]─► BriefingScreen
                                  └[ケース選択]─► CaseSelectScreen
```

### Boundary Map（所有権）

| 責務 | 所有者 | 備考 |
|------|--------|------|
| ケースデータ保持（シーン間バス） | CaseManager.current_case | データバス |
| カウントダウン・時間切れ判定 | CaseManager（`_tick`分離） | テスト可能化 |
| ポーズ制御 | CaseManager（`_paused`フラグ） | state非依存 §3.2 |
| 既読・判決・3択生成・未読抽出・hint抽出・到達数算出 | CaseManager / CaseUtils | Screen に置かない §3.2 |
| GameState 遷移 | 各画面 `_ready`（統一） | §3.4 |
| 永続化（結末・既読） | SaveManager | §3.10 |
| データ検証 | CaseData.validate() | §3.1 |

### 状態遷移の統一規則（レビュー G-1 反映）

**各画面は自分の `_ready()` で自分の GameState を設定する。** 遷移元はシーン変更のみを要求し、state は変えない。これによりレース・二重遷移を排除する。

---

## 2. Technology Stack & Alignment

| 技術 | 利用箇所 | 制約・備考 |
|------|---------|-----------|
| GDScript 2.0 (typed) | 全新規ファイル | 型アノテーション必須 |
| Godot Tween | タイプライター・点滅・フラッシュ | スキップ対応 §3.6/3.9 |
| EventBus シグナル | Autoload ↔ 画面 | 直接参照禁止・各画面 `_exit_tree` で disconnect |
| ConfigFile (SaveManager) | 結末・既読の永続化 | JSON型ガード必須 §3.10 |
| Resource (.tres) | CaseData 等4リソース | `outcomes: Array[OutcomeData]`（型安全）§3.1 |
| case_manifest.tres | ケース一覧 | DirAccess 走査を回避・export耐性 §3.5 |
| TranslationServer | EN/JA | 各画面で `settings_changed` 再描画 §3.12 |
| DisplayServer.clipboard_set | シェア | Web は常時フォールバックLabel併置 §3.9 |
| OS.shell_open | WL誘導 | Web実機検証 §6 |

---

## 3. Components & Interface Contracts

### 3.1 リソースクラス（4種）＋ バリデーション

**ファイル:** `scripts/data/case_data.gd`・`evidence_item.gd`・`verdict_choice.gd`・`outcome_data.gd`

```
# evidence_item.gd
class_name EvidenceItem extends Resource
@export var evidence_id: String = ""
@export var type: String = ""              # CODE / LOG / EMAIL / NETWORK
@export var title: String = ""
@export var title_ja: String = ""
@export_multiline var content: String = ""
@export_multiline var content_ja: String = ""
@export var supports_verdict: String = ""
func get_title() -> String
func get_content() -> String

# verdict_choice.gd
class_name VerdictChoice extends Resource
@export var label: String = ""
@export var label_ja: String = ""
@export var outcome_key: String = ""
func get_label() -> String

# outcome_data.gd  ← outcome_key を内包（Dictionary を廃し Array 化）
class_name OutcomeData extends Resource
@export var outcome_key: String = ""
@export_multiline var narrative: String = ""
@export_multiline var narrative_ja: String = ""
@export_multiline var hint_for_replay: String = ""
@export_multiline var hint_for_replay_ja: String = ""
func get_narrative() -> String
func get_hint_for_replay() -> String

# case_data.gd
class_name CaseData extends Resource
@export var case_id: String = ""
@export var ai_name: String = ""
@export var ai_name_ja: String = ""
@export var threat_level: String = "MED"
@export_multiline var briefing: String = ""
@export_multiline var briefing_ja: String = ""
@export var suspects: Array[String] = []
@export var suspects_ja: Array[String] = []
@export var victims: Array[String] = []
@export var victims_ja: Array[String] = []
@export var evidence: Array[EvidenceItem] = []
@export var verdict_choices: Array[VerdictChoice] = []
@export var outcomes: Array[OutcomeData] = []     # Dictionary を廃止（F-2）
@export var time_limit_seconds: float = 240.0
func get_ai_name() -> String
func get_briefing() -> String
func get_suspects() -> Array[String]
func get_victims() -> Array[String]
# 型安全な検索（強制キャスト禁止・null フォールバック）
func get_outcome(key: String) -> OutcomeData:
    # for o in outcomes: if o.outcome_key == key: return o
    # return null
# データ検証（テスト対象・CaseSelect ロード時に実行）
func validate() -> Array[String]:
    # 証拠4件・4タイプ網羅・verdict_choices非空・
    # 全 verdict_choices.outcome_key + "insufficient" が outcomes に存在・
    # outcome_key 重複なし。違反をメッセージ配列で返す（空なら正常）
```

**ロケール getter 規約:** `TranslationServer.get_locale().begins_with("ja") and not *_ja.is_empty()` で日本語。

**要件対応:** 1.5, 1.6, 1.8, 3.2, 4.2

---

### 3.2 CaseManager — 新規 Autoload（ポーズ・タイマー再設計）

**ファイル:** `autoloads/case_manager.gd`（PuzzleManager を置換）
**process_mode:** `PROCESS_MODE_ALWAYS`（ポーズで `_process` を止めない・レビュー A-2 反映）

```
extends Node

var current_case: CaseData = null
var read_evidence_ids: Array[String] = []
var selected_verdict: String = ""
var time_remaining: float = 0.0
var _timer_active: bool = false
var _paused: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    EventBus.game_paused.connect(_on_game_paused)

func _on_game_paused(is_paused: bool) -> void:
    _paused = is_paused

# CaseSelect が呼ぶ。状態を完全初期化（再挑戦・別ケースで安全・D-3反映）
func set_current_case(case_data: CaseData) -> void:
    current_case = case_data
    read_evidence_ids.clear()
    selected_verdict = ""
    time_remaining = 0.0
    _timer_active = false

# InvestigationScreen._ready が呼ぶ。タイマー開始。
func start_case() -> void:
    read_evidence_ids.clear()
    selected_verdict = ""
    time_remaining = current_case.time_limit_seconds
    _paused = false
    _timer_active = true
    EventBus.case_started.emit(current_case)

func mark_evidence_read(evidence_id: String) -> void:
    # 未登録なら append → EventBus.evidence_read.emit(evidence_id)

func get_unread_evidence() -> Array[EvidenceItem]
func get_verdict_options() -> Array[VerdictChoice]   # 2択 + 共通 insufficient（3択生成・A-1反映）
func get_alternate_hint(chosen_key: String) -> String # 選ばなかった outcome の hint ランダム1件
func get_reached_outcome_count(case_id: String) -> int # X/3 算出（SaveManager 読取）

# 冪等ガード（二重 submit 防止・C-2/B-2 反映）
func submit_verdict(outcome_key: String) -> void:
    if not selected_verdict.is_empty():
        return
    selected_verdict = outcome_key
    _timer_active = false
    EventBus.verdict_submitted.emit(outcome_key)

# タイマー減算を分離（テストで delta 注入・A-3 反映）
func _tick(delta: float) -> void:
    if not _timer_active or _paused:
        return
    time_remaining -= delta
    EventBus.countdown_updated.emit(time_remaining)
    if time_remaining <= 0.0:
        time_remaining = 0.0
        submit_verdict("insufficient")   # 冪等ガードで二重発火しない

func _process(delta: float) -> void:
    _tick(delta)

func resolve_case() -> void:
    EventBus.case_resolved.emit(
        current_case.case_id, selected_verdict, read_evidence_ids.size()
    )
```

**要件対応:** 2.1, 2.4, 2.5, 2.6, 3.4, 4.8, 7.3, 7.9

---

### 3.3 EventBus — シグナル置換

**削除:** `puzzle_loaded`・`line_selected`・`answer_submitted`・`hint_requested`・`hint_applied`・`puzzle_completed`・`level_cleared`・`level_restarted`
**維持:** `game_paused`・`scene_change_requested`・`scene_loaded`・`settings_changed`・`save_requested`・`load_requested`・`save_completed`・`game_state_change_requested`・`notification_requested`
**追加:**
```
signal case_started(case_data: CaseData)
signal evidence_selected(evidence_id: String)
signal evidence_read(evidence_id: String)
signal countdown_updated(remaining: float)
signal verdict_submitted(outcome_key: String)
signal case_resolved(case_id: String, outcome_key: String, read_count: int)
```

**重要（レビュー A-1）:** シグナル削除と、それを参照する `game_hud.gd`・`pause_menu.gd`・`result_screen.gd`・`game_screen.gd` 等の破棄、`PuzzleData` 型を使う `puzzle_loaded` の削除は**同一コミットで原子的に**行う。

**要件対応:** 7.5

---

### 3.4 GameManager — 状態・定数・ハンドラ修正

**GameState enum（全面再定義・レビュー B-1/B-2）:**
```
enum GameState { BOOT, MAIN_MENU, CASE_SELECT, BRIEFING, INVESTIGATING, VERDICT, OUTCOME, PAUSED }
```

**ポーズハンドラ修正（state 退避・復元）:**
```
var _state_before_pause: GameState = GameState.INVESTIGATING

func _on_game_paused(is_paused: bool) -> void:
    if is_paused:
        _state_before_pause = state
        transition_to(GameState.PAUSED)
        get_tree().paused = true
    else:
        transition_to(_state_before_pause)
        get_tree().paused = false
```

**撤去:** `_on_game_started`/`_on_game_over` とその connect（新フローはスコア概念なし）。`game_started`/`game_over` シグナルへの依存を断つ。`reset_score`/`add_score`/`high_score` は未使用となるが、save_game の `high_score` 保存は無害なゴミとして残置可（または除去）。

**定数追加:**
```
const IS_DEMO: bool = true
const STORE_URL: String = "https://store.steampowered.com/app/PLACEHOLDER"
const WISHLIST_URL: String = "https://store.steampowered.com/app/PLACEHOLDER"
```

**要件対応:** 7.4, 7.7

---

### 3.5 CaseSelectScreen — 新規シーン

**ファイル:** `scenes/ui/case_select_screen.tscn` / `.gd`
**ルートコンテナ:** `MarginContainer + ScrollContainer + VBoxContainer`（縦溢れ対応・UI B-3）

**責務:** `case_manifest.tres` 経由でケースを読み込み（DirAccess 走査を回避・F-1）、各ケースを検証して一覧表示。

```
func _ready():
    transition_to(CASE_SELECT)
    var manifest: CaseManifest = load("res://resources/cases/case_manifest.tres")
    for case in manifest.cases:
        var errors := case.validate()
        if errors.is_empty():
            _add_playable_entry(case)   # 番号・AI名・脅威Lv・到達結末 X/3
        else:
            Logger.error("Invalid case", {"id": case.case_id, "errors": errors})
            _add_locked_entry(case)      # クラッシュさせずロック扱い
    # 未実装ケース2・3は「STEAM版で続きを調査する」ロックエントリ
    # キーボード: ↑↓でエントリ移動・Enter で選択・Esc で MainMenu

# プレイ可能選択:
#   CaseManager.set_current_case(case)
#   scene_change_requested(briefing_screen)   # state は遷移先で設定

# ロック/WL: OS.shell_open(GameManager.WISHLIST_URL)
```

**新リソース:** `scripts/data/case_manifest.gd`（`class_name CaseManifest extends Resource` / `@export var cases: Array[CaseData]`）

**要件対応:** 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 7.8, 6.1, 6.5

---

### 3.6 BriefingScreen — 新規シーン

**ファイル:** `scenes/ui/briefing_screen.tscn` / `.gd`
**ルートコンテナ:** `MarginContainer + ScrollContainer + VBoxContainer`

```
func _ready():
    if CaseManager.current_case == null:
        scene_change_requested(case_select_screen); return     # null ガード
    transition_to(BRIEFING)
    EventBus.settings_changed.connect(_on_settings_changed)     # 言語再描画
    _build_and_typewrite()

# 表示: [MISSION BRIEFING] / TARGET:{ai_name} / THREAT:{threat_level}（記号併用 [!!!]）
#       関係者:{suspects} / 被害対象:{victims} / briefing本文（タイプライター）
#       [BEGIN INVESTIGATION]
# タイプライター・スキップ（UI A-2）: クリック/Enter/任意キーで
#   1回目=全文即時表示、2回目=確定して Investigation へ
# キーボード: Enter=BEGIN(or スキップ), Esc=CaseSelect へ戻る
func _exit_tree(): settings_changed.disconnect(...)
```

**要件対応:** 1.7, 6.1, 6.2, 6.6, 6.8

---

### 3.7 InvestigationScreen — 新規シーン（中核・ポーズ内蔵）

**ファイル:** `scenes/ui/investigation_screen.tscn` / `.gd`
**process_mode:** ルートは `PAUSABLE`、ポーズメニュー（CanvasLayer）は `WHEN_PAUSED`

**レイアウト:**
```
MarginContainer (PAUSABLE)
└ VBox
   ├ CountdownBar（常時・MM:SS・段階警告 §下記）   ← CenterContainer 不使用
   └ HBox
      ├ 左: 証拠リスト VBox（4ボタン・3状態表示）   stretch 1
      └ 右: ScrollContainer > 内容 Label           stretch 2
   └ [判決を下す]（未読件数バッジ付き・UI C-2）
CanvasLayer(WHEN_PAUSED): ポーズメニュー（再開/ケース選択）
```

**証拠タイプ別表示（UI B-1）:**
- `CODE`/`LOG`/`NETWORK`: 等幅フォント・`autowrap_mode = OFF`・横スクロール許可
- `EMAIL`: 可変幅・`autowrap_mode = WORD_SMART`

**証拠3状態（UI C-1）:** 未読=明色 / 既読=`[READ]`+暗色 / 選択中=`> `プレフィックス

**段階警告（UI C-3・色覚配慮 UI E-2）:**
- 残120秒: 黄 / 残60秒: 赤点滅 + `! ` / 残10秒: 数字拡大 + `!! `

```
func _ready():
    if CaseManager.current_case == null:
        scene_change_requested(case_select_screen); return
    transition_to(INVESTIGATING)         # ← 自分で state 設定（統一規則）
    EventBus.countdown_updated.connect(_on_countdown_updated)
    EventBus.verdict_submitted.connect(_on_verdict_submitted)
    EventBus.settings_changed.connect(_on_settings_changed)
    _build_evidence_list()
    CaseManager.start_case()             # state は既に INVESTIGATING（C-1反映）

# 証拠選択（マウス/↑↓+Enter）: 右ペイン更新 + mark_evidence_read + [READ] + 状態再描画
# [判決を下す]: CaseManager._timer_active=false（タイマー停止・B-2反映）
#               scene_change_requested(verdict_screen)
# _on_verdict_submitted（時間切れ insufficient を捕捉）:
#   _show_time_expired_overlay() → クリック/キーで OutcomeScreen へ（D-1反映）
# _input: pause（ポーズメニュー開閉）
# 言語再描画: 既読・選択・残時間を保持して再描画（UI E-1）
func _exit_tree(): 全 connect を disconnect（D-1メモリリーク対策）
```

**要件対応:** 1.1, 1.3, 1.4, 2.2, 2.3, 2.4, 2.6, 3.1, 6.1, 6.3, 6.4, 6.6, 6.8

---

### 3.8 VerdictScreen — 新規シーン（誤爆防止）

**ファイル:** `scenes/ui/verdict_screen.tscn` / `.gd`

```
func _ready():
    if CaseManager.current_case == null:
        scene_change_requested(case_select_screen); return   # null ガード（D-2）
    transition_to(VERDICT)
    _input_locked = true
    get_tree().create_timer(0.4).timeout.connect(
        func(): _input_locked = false)                        # 遷移直後入力ガード（UI D-2）
    # CaseManager.get_verdict_options()（2択+insufficient）でボタン生成
    # ボタンは十分離して配置（誤クリック物理防止）

# ボタン押下（_input_locked中は無視）:
#   0.5s フラッシュ Tween → CaseManager.submit_verdict(key)
#   scene_change_requested(outcome_screen)
# pause / cancel は無視（要件3-3 取消不可）
```

**要件対応:** 3.1, 3.2, 3.3, 3.4, 6.7

---

### 3.9 OutcomeScreen — 新規シーン

**ファイル:** `scenes/ui/outcome_screen.tscn` / `.gd`
**ルートコンテナ:** `MarginContainer + ScrollContainer + VBoxContainer`（縦長必至・UI B-3）

```
func _ready():
    var case := CaseManager.current_case
    var key := CaseManager.selected_verdict
    if case == null or key.is_empty():
        scene_change_requested(case_select_screen); return    # null/空 ガード（D-2）
    transition_to(OUTCOME)
    EventBus.settings_changed.connect(_on_settings_changed)

    CaseManager.resolve_case()           # ① 先に保存（順序修正・E-4）
    var outcome := case.get_outcome(key)
    var text := outcome.get_narrative() if outcome else tr("OUTCOME_FALLBACK")  # null防御（F-3）
    _typewrite(text)                     # スキップ対応（UI A-2）

    # 今回の判決ラベル / 未読証拠一覧（空なら「全て確認済み」UI B-1）
    # 別の見方: CaseManager.get_alternate_hint(key)
    # [見た結末 X/3]: CaseManager.get_reached_outcome_count(case.case_id)  ← 保存後に読む

# [判決をシェア]:
#   var t := "[AI Code Leak] 私はAI-%s を「%s」と判定した。あなたはどう裁く？ %s #AICodeLeak"
#   ネイティブ: DisplayServer.clipboard_set(t) + トースト
#   Web(OS.has_feature("web")): 選択可能 Label に t を常時併置（要件4-7）
# [もう一度調査する]: scene_change_requested(briefing_screen)  # current_case 維持
# [ケース選択へ]: scene_change_requested(case_select_screen)
func _exit_tree(): settings_changed.disconnect(...)
```

**要件対応:** 4.1〜4.9, 6.2, 6.6

---

### 3.10 SaveManager — スキーマ拡張（型ガード明示）

**削除:** `EventBus.puzzle_completed` 購読（:15）と `_on_puzzle_completed`（:83-105）
**追加:**
```
func _ready(): EventBus.case_resolved.connect(_on_case_resolved)

func _on_case_resolved(case_id: String, outcome_key: String, _read_count: int) -> void:
    # cases_resolved（JSON配列・型ガード）
    var resolved: Variant = JSON.parse_string(get_value("progress","cases_resolved","[]"))
    if not resolved is Array: resolved = []
    if case_id not in resolved: resolved.append(case_id)
    set_value("progress","cases_resolved", JSON.stringify(resolved))
    # case_verdicts（JSON dict・型ガード・キー未存在初期化）
    var verdicts: Variant = JSON.parse_string(get_value("progress","case_verdicts","{}"))
    if not verdicts is Dictionary: verdicts = {}
    var arr: Array = verdicts.get(case_id, [])
    if outcome_key not in arr: arr.append(outcome_key)
    verdicts[case_id] = arr
    set_value("progress","case_verdicts", JSON.stringify(verdicts))
    save_game()
```

**セーブスキーマ（progress）:**
| key | 型 | デフォルト | 説明 |
|-----|----|---------|------|
| `cases_resolved` | String(JSON配列) | `"[]"` | クリア済みケースID |
| `case_verdicts` | String(JSON dict) | `"{}"` | case_id → 到達 outcome_key 配列 |

**要件対応:** 4.8, 5.3, 7.6

---

### 3.11 MainMenu — 遷移先・翻訳キー更新

**ファイル:** `scenes/ui/main_menu.gd`
- `_on_play_pressed()`（:224）の遷移先を `case_select_screen.tscn` へ変更
- HTP（遊び方）の旧クイズ前提キー（`HTP_CODE` 等）を新ゲームルール（証拠調査・判決）へ差し替え。翻訳CSV の旧キー削除・新キー追加を**タスクとして独立**させ、`tr()` が生キーを表示するバグを防ぐ（レビュー G-3）

**要件対応:** 5.1, 7.2

---

### 3.12 言語切替の動的再描画（全画面共通方針・UI E-1）

各画面は `main_menu.gd` の確立パターンを踏襲する：
- `_ready` で `EventBus.settings_changed.connect(_on_settings_changed)`
- `_on_settings_changed(key, _v)`: `key == "language"` で `_refresh_labels()`
- `_refresh_labels()` は CaseData のロケール getter を**再評価**して再描画
- Investigation は再描画時に既読・選択・残り時間を保持
- `_exit_tree` で disconnect

---

## 4. Data Flow

### 通常フロー
```
CaseSelect.set_current_case → Briefing → Investigation.start_case
  → INVESTIGATING: _tick で countdown_updated → CountdownBar（段階警告）
  → 証拠選択 → mark_evidence_read → 3状態更新
  → [判決] → _timer_active=false → Verdict → submit_verdict(key)
  → Outcome.resolve_case（保存）→ get_reached_outcome_count（X/3）
```

### 時間切れフロー（ワンクッション）
```
_tick: time_remaining<=0 → submit_verdict("insufficient")（冪等）
  → verdict_submitted → Investigation._on_verdict_submitted
  → TIME EXPIRED オーバーレイ → クリック/キー → Outcome
```

### ポーズフロー（再設計）
```
pause入力 → game_paused(true) → GameManager: _state_before_pause退避, PAUSED, tree.paused=true
  CaseManager(_process_mode=ALWAYS): _paused=true → _tick は減算しない
解除 → game_paused(false) → state復元, tree.paused=false, _paused=false → タイマー再開
```

### 再挑戦フロー
```
Outcome[もう一度] → Briefing（current_case 維持）→ Investigation.start_case で全状態リセット
```

---

## 5. 要件 ↔ コンポーネント対応表

| 要件 | コンポーネント |
|------|-------------|
| 1.1,1.3,1.4 | InvestigationScreen（3.7） |
| 1.2,1.5,1.6,1.8 | リソース4種+validate（3.1） |
| 1.7 | BriefingScreen（3.6） |
| 2.1,2.4,2.5,2.6 | CaseManager（3.2） |
| 2.2,2.3 | InvestigationScreen CountdownBar 段階警告（3.7） |
| 3.1 | Investigation→Verdict（3.7,3.8） |
| 3.2,3.3,3.4 | VerdictScreen+CaseManager（3.8,3.2） |
| 3.5,4.1,4.2 | OutcomeData+OutcomeScreen（3.1,3.9） |
| 4.3 | OutcomeScreen 未読/別の見方（3.9） |
| 4.4 | OutcomeScreen（スコア非表示）（3.9） |
| 4.5 | get_reached_outcome_count（3.2,3.9） |
| 4.6,4.7 | OutcomeScreen シェア+Webフォールバック（3.9） |
| 4.8 | resolve_case+SaveManager（3.2,3.10） |
| 4.9 | OutcomeScreen ボタン（3.9） |
| 5.1 | MainMenu（3.11） |
| 5.2,5.3,5.6 | CaseSelectScreen+manifest（3.5） |
| 5.4,5.5 | CaseSelectScreen ロック/WL（3.5） |
| 6.1 | 各画面キーボードナビ（3.5-3.9） |
| 6.2 | タイプライタースキップ（3.6,3.9） |
| 6.3 | 証拠タイプ別表示（3.7） |
| 6.4 | 証拠3状態表示（3.7） |
| 6.5 | Scroll コンテナ方針（3.5,3.6,3.9） |
| 6.6 | 言語動的再描画（3.12） |
| 6.7 | Verdict 誤爆防止（3.8） |
| 6.8 | 色+記号併用（3.6,3.7） |
| 7.1,7.2 | 旧コード原子的破棄（3.3,3.11, research調査3） |
| 7.3 | CaseManager 登録（3.2） |
| 7.4 | GameState 再定義+ポーズ修正（3.4） |
| 7.5 | EventBus 置換（3.3） |
| 7.6 | SaveManager 型ガード（3.10） |
| 7.7 | GameManager 定数（3.4） |
| 7.8 | case_manifest（3.5） |
| 7.9 | ロジック切り出し+_tick（3.2） |

---

## 6. テスト戦略（網羅性強化）

### ユニットテスト（GUT）
| 対象 | テストファイル | 区分 |
|------|-------------|------|
| 4リソース getter | `test_case_data.gd` 他 | 正常(ja/en)・異常(空*_ja)・境界(空配列) |
| `CaseData.validate()` | `test_case_data.gd` | 正常tres=0件・欠損tres=該当検出（outcome欠落・キー不一致・タイプ不足） |
| `CaseManager._tick` | `test_case_manager.gd` | `_tick(241)`で時間切れ→insufficient・境界(time=0) |
| `submit_verdict` 冪等 | `test_case_manager.gd` | `submit("a")`後 `_tick(999)` でも結末a維持（二重submit防止） |
| ポーズ | `test_case_manager.gd` | `_paused=true`で`_tick`減算なし・解除で再開（フラグ直接操作・get_tree副作用なし） |
| 3択生成/未読抽出/hint抽出/到達数 | `test_case_manager.gd` | 正常・境界(全既読・未到達) |
| SaveManager 結末保存 | `test_save_manager.gd`（置換） | 重複なしappend・**破損JSON文字列でクラッシュしない**異常系 |

### 破棄するテスト（レビュー B-4/D-2）
`test_puzzle_manager.gd` 全体、`test_save_manager.gd` の旧パズル保存テスト（:95-149）、`test_game_manager.gd` の RESULT 依存テスト（:104-110）、`test_score_calc*.gd`（スコア廃止のため）。**破棄は旧コード破棄と同一コミット。**

### 全ケース整合性テスト
`resources/cases/*.tres`（manifest 経由）全件に `validate()` を走らせ、エラー0を CI で保証（outcome_key タイプミスのサイレント不具合を検出）。

### 手動検証（release-checklist 追加）
1. **全画面遷移マトリクス**：MainMenu→CaseSelect→Briefing→Investigation→Verdict→Outcome→各分岐・再挑戦・Esc戻り
2. **Web実機（itch.io）**：シェアの常時フォールバックLabel表示・WLボタンの新規タブ遷移・case_manifest ロード
3. **エクスポート前**：IS_DEMO/STORE_URL/WISHLIST_URL の実URL置換確認
4. **言語切替**：各画面プレイ中の EN/JA 切替で証拠・ナラティブが追従

**DoD:** GUT 全 PASS / gdlint 0 / gdformat 差分0 / 上記手動チェック完了 / UI チェックリスト（docs/styling/ux-standards.md）。

---

## 7. 実装順序（直列ブロッカー・破棄漏れ防止）

1. **リソース4種 + CaseManifest + validate()**（全ての前提・テスト同時）
2. **原子的破棄コミット**：旧シグナル削除 + game_hud/pause_menu/result_screen/game_screen/code_panel/investigation_panel/puzzle_manager/puzzle_data/puzzle_question + 対応テスト削除 + GameState 再定義 + game_manager ハンドラ修正 + EventBus 置換（**一度に行い起動確認**）
3. **CaseManager + テスト**（_tick/ポーズ/冪等/各ヘルパー）
4. **SaveManager スキーマ + テスト**（型ガード・破損耐性）
5. **GameManager 定数**
6. **画面**：CaseSelect → Briefing → Investigation（ポーズ内蔵）→ Verdict → Outcome（各 null ガード・disconnect・言語再描画）
7. **翻訳CSV 更新**（旧HTPキー削除・新キー）
8. **case_001.tres + case_manifest.tres** コンテンツ制作
9. **統合テスト・lint・gdformat・Web実機検証・全ケース validate CI**

---

## 8. MVP 外（v2）

ケース2・3 / グランドエンディング / 判決統計（バックエンド）/ シェア画像生成 / メディアキット（別spec）
