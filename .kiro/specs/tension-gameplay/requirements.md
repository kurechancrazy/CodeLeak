# 要件定義書 — コアゲームループ再設計（ナラティブ決断型・1ケース完全版）

## 概要

**ゲームコンセプト:**
プレイヤーは AI セキュリティ調査官として、報告されたAIインシデントを調査する。コード・実行ログ・内部メール・ネットワークトレースの証拠を限られた時間で読み解き、「このAIは意図的に兵器化されたのか、それとも制御不能に暴走したのか」を判断して判決を下す。被疑者・被害者という人間の存在を背景に、正解のない道徳的判決を体験する。

**なぜこれが面白いか:**
- 正解が一意でない道徳的ジレンマ → プレイヤーが自分の判断を語りたくなる（SNSシェア）
- AI安全性・AI倫理という2026年のリアルな関心事がテーマ
- 全証拠を読む時間が足りない設計 → 「何を優先するか」が戦略になる
- 疑わしい人間・被害者が登場する → AIではなく「人間のドラマ」として感情投資できる
- 判決によって結末が変わり、選ばなかった判決の根拠がほのめかされる → 周回動機

**競合との差別化:**
- Hacknet / Orwell：AIを「直す」ではなく「裁く」。道徳的責任がテーマ。
- Her Story：証拠の読み方に時間制限がある。全部見られないことがゲームメカニクス。
- Papers, Please：不可逆な判断と人間ドラマ。本作はそのAI倫理版。

## リリース戦略（スコープの根拠）

**ファーストリリース = 1ケース完全版（Vertical Slice）**

- 1ケース（case_001）を最高品質で磨き込む
- itch.io で無料先行リリースし、ウィッシュリスト（WL）収集マシンとして機能させる
- ケース2・3は WL を積み上げた後、Steam 有料版（v2）として追加
- この方針は実装40h以内・面白さ（密度集中）・営業（WL収集）の3観点すべてを満たす

**1ケースでのリプレイ設計:**
- 3判決（意図的 / 暴走 / 証拠不十分）× それぞれ固有の結末
- 結末画面で「選ばなかった判決の根拠証拠」をほのめかす
- 「見た結末 X/3」コレクショントラッカー
- 240秒で全証拠を読めない設計 → 2周目で未読証拠を読む動機

---

## 要件

### 要件 1: 証拠調査システム

**目的：** プレイヤーとして、受動的に問題を解くのではなく、複数の証拠を能動的に選んで読み、自分で仮説を立てたい。また「被疑者・被害者という人間」の存在を感じながら調査したい。

#### 受入基準
1. When プレイヤーがケースを開始したとき、ゲームは左ペインに証拠リスト（4件固定）を表示し、右ペインに選択中の証拠の内容を表示する。
2. 証拠リストの各アイテムは以下のタイプのいずれかを持つ：`CODE`（コード断片）・`LOG`（実行ログ）・`EMAIL`（内部メール）・`NETWORK`（ネットワークトレース）。ケースは4タイプを1件ずつ含む。
3. When プレイヤーが証拠アイテムを選択したとき、右ペインにそのテキスト内容が表示され、既読フラグ（`[READ]` マーカー）が立つ。
4. プレイヤーは任意の順序・任意の回数で証拠を閲覧できる。
5. `EvidenceItem` リソース（`class_name EvidenceItem extends Resource`）は次のフィールドを持つ：`evidence_id: String`・`type: String`・`title: String`・`title_ja: String`・`content: String`・`content_ja: String`・`supports_verdict: String`（この証拠が示唆する判決の `outcome_key`。中立証拠は空文字）。各 `content` は日本語250文字・英語400文字以内とする。各フィールドにロケール対応 getter を実装する（既存 `puzzle_data.gd` の `get_title()` パターン踏襲）。
6. `CaseData` リソース（`class_name CaseData extends Resource`）は次のフィールドを持つ：`case_id: String`・`ai_name: String`・`ai_name_ja: String`・`threat_level: String`・`briefing: String`・`briefing_ja: String`・`suspects: Array[String]`・`suspects_ja: Array[String]`・`victims: Array[String]`・`victims_ja: Array[String]`・`evidence: Array[EvidenceItem]`・`verdict_choices: Array[VerdictChoice]`・`outcomes: Array[OutcomeData]`（型安全性・Inspector編集性のため Dictionary ではなく配列とし、各 `OutcomeData` が `outcome_key` を持つ）・`time_limit_seconds: float`。
7. ブリーフィング画面は `suspects` と `victims` を「関係者：〇〇（役職）」「被害対象：〇〇」として表示し、プレイヤーが「AIではなく人間のドラマ」として事件を認識できるようにする。
8. `CaseData` は `validate() -> Array[String]`（エラーメッセージ配列・空なら正常）を実装する。検証項目：証拠4件・4タイプ網羅・`verdict_choices` 非空・`outcomes` に全 `verdict_choices.outcome_key` ＋ `"insufficient"` が存在・各 `outcome_key` の重複なし。ケース選択画面はロード時に `validate()` を実行し、不正なケースはロックエントリ扱いとしてクラッシュを防ぐ。

### 要件 2: カウントダウンと証拠優先度

**目的：** プレイヤーとして、全ての証拠を読む時間的余裕がない状況で「どれを先に読むか」という戦略的判断を迫られたい。時間切れは「ゲームオーバー」ではなく「不十分な状態で判決を強いられる」結末につながる。

#### 受入基準
1. ケースは `time_limit_seconds`（デフォルト: 240秒）のカウントダウンを持ち、調査開始と同時に進行する。証拠4件 × 平均60〜70秒の読了時間を想定し、全件読了には時間が足りない設計とする。
2. While ゲームが進行しているとき、調査画面の常時表示エリアに残り時間を「MM:SS」形式で表示する。
3. 残り時間に応じて段階的な警告を行う：残120秒で黄色、残60秒で赤の点滅、残10秒で数字拡大。色のみに依存せず、記号（例：`! ` プレフィックス）を併用して色覚多様性に配慮する。
4. When カウントダウンが 0 になったとき、ゲームはプレイヤーの操作を停止し、「TIME EXPIRED — 証拠不十分のまま判決が確定した」というフルスクリーン告知をワンクッション挟んでから（クリック/任意キーで進む）、判決を `"insufficient"` に確定して結末画面へ遷移する。判決選択画面は経由しない。
5. The ゲームはポーズ中にカウントダウンを停止し、ポーズ解除で再開する。タイマーは `GameState` に依存せず、`EventBus.game_paused` 購読による専用フラグで制御する（`process_mode = ALWAYS` とし、ポーズで `_process` が止まらないようにする）。
6. When プレイヤーが「判決を下す」操作をしたとき、ゲームはカウントダウンを即座に停止し、以降の時間切れ判定が判決を上書きしないようにする。`submit_verdict` は冪等とし、既に判決が記録済みの場合は二重実行を無視する。

### 要件 3: 判決メカニズム

**目的：** プレイヤーとして、集めた証拠をもとに自分の解釈を「判決」として下したい。一度下した判決は覆せない重さを感じたい。

#### 受入基準
1. When プレイヤーが「判決を下す」ボタンを押したとき、ゲームは判決選択画面を表示する。
2. 判決選択画面は `CaseData.verdict_choices` に定義された判決選択肢を表示する。各 `VerdictChoice`（`class_name VerdictChoice extends Resource`）は `label: String`・`label_ja: String`・`outcome_key: String` のみを持つ。case_001 は「意図的兵器化」「暴走」の2つの `VerdictChoice` を持ち、ゲームはこれに加えて全ケース共通の「証拠不十分」（`outcome_key: "insufficient"`）を計3択として表示する。
3. When プレイヤーが判決を選択したとき、ゲームは選択ボタンを光らせる短い確定エフェクト（Tweenによるフラッシュ 0.5秒）を表示し、即座に結末画面へ遷移する。**判決の取り消し・キャンセルは不可。** これが判決の「重さ」を生む。
4. When プレイヤーが判決を選択したとき、ゲームは選択した `outcome_key` を `CaseManager.selected_verdict` に記録する。
5. 「証拠不十分」の結末（`outcome_key: "insufficient"` の `OutcomeData`）は「判断を先送りにした結果、最悪の事態が起きた」という後味の悪い内容とし、安易な逃げ道として機能しないようにする。

### 要件 4: 結末ナラティブ・シェア・リプレイ誘導

**目的：** プレイヤーとして、自分の判決が引き起こした「世界の変化」をナラティブで受け取り、選ばなかった判決への興味を持ち、SNSで他者と比較したい。

#### 受入基準
1. When プレイヤーが判決を確定したとき、ゲームは `selected_verdict` に対応する `OutcomeData.narrative` をタイプライター演出で表示する。
2. `CaseData.outcomes` は `Array[OutcomeData]` とする。`OutcomeData`（`class_name OutcomeData extends Resource`）は次を持つ：`outcome_key: String`・`narrative: String`・`narrative_ja: String`・`hint_for_replay: String`・`hint_for_replay_ja: String`。case_001 は `"intentional"`・`"runaway"`・`"insufficient"` の3つの `OutcomeData` を必須とする。`CaseData.get_outcome(key)` は配列を検索し、該当なしの場合は null を返す。OutcomeScreen は null 時にフォールバック文言を表示してクラッシュを防ぐ。
3. 結末画面は以下を表示する：
   - 結末ナラティブテキスト（タイプライター演出）
   - 「今回の判決」ラベル（選択した `VerdictChoice.label`）
   - **未読証拠の一覧**：既読フラグが立っていない `EvidenceItem` のタイトルを「未確認の証拠：[タイトル]」として列挙する
   - **選ばなかった判決の根拠**：プレイヤーが選択しなかった判決の `outcome_key` を持ち、その `OutcomeData.hint_for_replay` を「別の見方：…」として表示する（複数ある場合はランダムに1件）
4. 結末画面はスコアを表示しない。判決の「正しさ」ではなくナラティブの「面白さ」に集中させる。
5. 結末画面は **[ 見た結末：X/3 ]** のコレクショントラッカーを表示する。X は到達済みの `outcome_key` の種類数とする。**今回の判決を先に保存（要件4-8）してから** SaveManager を読み直して算出し、今回到達分が必ずカウントに含まれるようにする。
6. 結末画面は **[ 判決をシェアする ]** ボタンを提供する。押下すると次のテキストをクリップボードにコピーし、「コピーしました」トースト通知を表示する：`「[AI Code Leak] 私はAI-{ai_name}を「{verdict_label}」と判定した。あなたはどう裁く？ {STORE_URL} #AICodeLeak」`。`{STORE_URL}` は `GameManager` の定数（DEMO時=itch.io URL、製品版=Steam URL）から取得する。
7. `DisplayServer.clipboard_set` は戻り値で成否を判定できないため、Web版（`OS.has_feature("web")`）では常にシェアテキストを選択可能な Label として併置表示し、プレイヤーが確実に手動コピーできるようにする。ネイティブ版はクリップボードコピー＋トーストのみとする。
8. When プレイヤーが結末画面に到達したとき、ゲームは SaveManager にケースID・到達した `outcome_key`・既読証拠数を保存する（複数 `outcome_key` は配列として蓄積し、コレクショントラッカーに使用する）。
9. 結末画面は **[ もう一度調査する ]**・**[ ケース選択へ ]** ボタンを提供する。

### 要件 5: ケース選択画面とウィッシュリスト導線

**目的：** プレイヤーとして、ケースの状態を確認して調査を始めたい。また itch.io 無料版では「続きが気になる」状態から Steam ウィッシュリストへ誘導されたい（収益動線）。

#### 受入基準
1. When プレイヤーがメインメニューの [ PLAY ] を押したとき、ゲームはケース選択画面を表示する。
2. ケース選択画面は `resources/cases/` 内の `CaseData` リソースを動的に読み込み、`case_id` の昇順で表示する（ハードコードリスト禁止）。
3. ケース選択画面は各ケースについて以下を表示する：ケース番号・AI名・脅威レベル・クリア済みフラグ・到達済み結末数（`X/3`）。
4. ケース選択画面は、リリース時点で未実装のケース2・3を「[ STEAM版で続きを調査する ]」という非インタラクティブなロックエントリとして表示し、ケース2・3で扱う脅威の予告タイトルを示す。
5. ロックエントリまたは専用ボタンを押すと、`OS.shell_open(GameManager.WISHLIST_URL)` で Steam ウィッシュリストページを開く（itch.io 無料版が WL 収集面として機能する）。
6. クリア済みケースは何度でも再挑戦でき、前回と異なる判決を選択することで別の結末を見られる（周回プレイ支援）。

### 要件 6: UI/UX 品質基準（全画面共通）

**目的：** プレイヤーとして、マウス・キーボードどちらでも快適に操作でき、周回プレイでストレスを感じず、言語を切り替えても破綻しない体験を得たい。

#### 受入基準
1. 全画面（CaseSelect・Briefing・Investigation・Verdict・Outcome）はマウスとキーボードの両方をサポートする。各画面はフォーカス順（`focus_neighbor` / `grab_focus`）・Enter（決定）・Escape（戻る、ただし Verdict は不可）を定義する。Investigation の証拠リストは ↑↓ で選択・Enter で開けること。
2. タイプライター演出を行う画面（Briefing・Outcome）は、クリック/Enter/任意キーでの2段階スキップを実装する（1回目＝全文即時表示、2回目＝次へ）。
3. Investigation の証拠内容ペインは証拠タイプに応じて表示を切り替える：`CODE`・`LOG`・`NETWORK` は等幅フォント・オートラップ無効（横スクロール可）、`EMAIL` は可変幅・ワードラップ。
4. 証拠リストは3状態を視覚的に区別する：未読（明色）・既読（`[READ]` + 暗色）・選択中（`> ` プレフィックスまたは背景反転）。
5. 可変長テキストを表示する画面（Briefing・Outcome・CaseSelect）は `CenterContainer` ではなく `MarginContainer + ScrollContainer + VBoxContainer` を使い、コンテンツが縦に溢れてもボタンが画面外に出ないようにする。
6. 全画面は `EventBus.settings_changed` を購読し、言語切替時に `_refresh_labels()` 相当でロケール対応テキストを再評価・再描画する（既存 `main_menu.gd` パターン踏襲）。Investigation での再描画は既読・選択状態・残り時間を保持する。
7. 判決選択画面は、画面遷移直後 0.3〜0.5秒は入力を受け付けず、判決ボタンを十分に離して配置することで、不可逆な判決の誤爆を防ぐ。
8. 脅威レベル・残り時間など色で強調する情報は、テキスト・記号・形状を併用し、色のみに依存しない（product.md「形状で情報伝達」方針）。

### 要件 7: 既存コードの処遇とアーキテクチャ統合

**目的：** エンジニアとして、旧クイズ形式のコードと新ナラティブ調査システムの境界を明確にし、後戻りなく実装したい。

#### 受入基準
1. 旧クイズ形式の以下のファイルは本機能では使用せず、**破棄する**（ファイル削除）。破棄はシグナル・GameState・リソースクラスの削除と**同一コミットで原子的に**行い、参照漏れによる起動時パースエラーを防ぐ：
   - シーン：`scenes/game/game_screen.*`・`investigation_panel.*`・`code_panel.*`、`scenes/ui/game_hud.*`・`pause_menu.*`・`result_screen.*`
   - スクリプト：`scripts/data/puzzle_data.*`・`puzzle_question.*`、`autoloads/puzzle_manager.*`
   - リソース：`resources/puzzles/level_001.tres`
   - テスト：`tests/unit/test_puzzle_manager.gd`、`test_save_manager.gd` の旧パズル保存テスト、`test_game_manager.gd` の旧 GameState（RESULT 等）依存テスト、`test_score_calc*.gd`（スコア非表示のため不要な場合）
2. 上記破棄に伴い、`main_menu` の遷移先・`save_manager` のパズル保存経路・`game_manager` の `_on_game_started`/`_on_game_paused`・`EventBus` のパズル系シグナルを新システム向けに置換する。ポーズ機能（旧 pause_menu）は Investigation 画面内に再実装する。
3. 新規 Autoload `CaseManager`（`autoloads/case_manager.gd`）を追加し、`.kiro/steering/architecture.md` の Autoload 計画と `project.godot` の `[autoload]` に登録する。初期化順は PuzzleManager の位置を置き換える。
4. `GameManager.GameState` を本機能用（`CASE_SELECT`・`BRIEFING`・`INVESTIGATING`・`VERDICT`・`OUTCOME`・`PAUSED`）へ再定義し、旧ステートを削除する。`PAUSED` は維持し、`_on_game_paused` はポーズ前のステートを保存して解除時に復元する方式とする。`architecture.md` の GameState 定義も更新する。
5. `EventBus` に本機能用シグナルを追加する：`case_started`・`evidence_selected`・`evidence_read`・`countdown_updated`・`verdict_submitted`・`case_resolved`。旧パズル系シグナルは削除する。`game_paused` は維持する。
6. SaveManager のセーブスキーマに本機能用キーを追加する：`progress` セクションに `cases_resolved`（クリア済みケースIDのJSON配列）・`case_verdicts`（`case_id → 到達 outcome_key 配列` のJSON dict）。各ハンドラは JSON パース失敗時に空配列・空Dictへフォールバックし、重複を防いで append する。`architecture.md` のセーブスキーマも更新する。
7. `GameManager` に `const IS_DEMO: bool`・`const STORE_URL: String`・`const WISHLIST_URL: String` を追加する。itch.io エクスポート時は `IS_DEMO = true`・`STORE_URL = WISHLIST_URL`（Steamストアページ）とする。
8. ケース一覧は `DirAccess` による `.tres` 直接走査ではなく、`resources/cases/case_manifest.tres`（`Array[CaseData]` を持つインデックスリソース）経由でロードする。これによりエクスポート（.pck）・Web 環境でも確実に動作する。要件5-2「ハードコードリスト禁止」はデータ駆動の manifest により満たす。
9. ビジネスロジック（証拠未読抽出・選ばなかった判決のhint抽出・到達結末数算出・3択生成・タイマー減算）は Screen に置かず、`CaseManager` または `scripts/utils/` の純粋関数に切り出してユニットテスト可能にする。タイマー減算は `CaseManager._tick(delta)` に分離し、`_process` から呼ぶことでテストで delta を注入できるようにする。

---

## 実装コスト内訳（合計 約32時間・40h以内）

| 実装内容 | 時間 |
|---------|------|
| 既存パズルコード破棄・main_menu/save_manager/EventBus 整理 | 2h |
| リソース定義4種（CaseData/EvidenceItem/VerdictChoice/OutcomeData）+ getter + テスト | 3h |
| CaseManager Autoload（タイマー・既読・判決・時間切れ・保存）+ テスト | 5h |
| GameState/EventBus/architecture/project.godot 更新 | 1.5h |
| BriefingScreen（suspects/victims表示） | 3h |
| InvestigationScreen（左右ペイン・既読・カウントダウン・60秒赤点滅） | 6h |
| VerdictScreen（3択・即時確定エフェクト） | 2h |
| OutcomeScreen（タイプライター・未読証拠・選ばなかった根拠・トラッカー・シェア・フォールバック） | 4h |
| CaseSelectScreen（動的読込・ロックエントリ・WL導線） | 3.5h |
| IS_DEMO/STORE_URL/WISHLIST_URL 定数・バナー | 1h |
| ケースコンテンツ制作（case_001：証拠4件 + ブリーフィング + 判決2択 + 結末3種、EN/JA） | 4h |
| 統合テスト・lint・gdformat | 3h |
| **合計** | **約38h**（バッファ込みで40h以内） |

---

## v2 以降の拡張ポイント（MVP 外）

- ケース2・3の追加（Steam 有料版の中核）：`CaseData` リソース追加 + ロックエントリ解除
- グランドエンディング（複数ケース判決の組み合わせ分岐）：ケース2・3実装後に追加
- プレイヤー判決統計の集計表示（全プレイヤーの判決分布）：バックエンド必要
- シェア画像生成（現在はクリップボードテキストのみ・SubViewport方式）：優先度・高
- 証拠タイプ追加（`AUDIO`・`IMAGE`）：`EvidenceItem.type` の拡張で対応可
- メディアキット（30秒トレーラー・GIF・スクショ5枚・1行ピッチ）：**別タスク/別specで起票**（ゲームコード外・ローンチ必須）
