# Research Log — tension-gameplay（1ケース完全版）

## Summary

**Discovery Type:** Extension（既存 Autoload 基盤への統合・旧パズル系の置換を伴う）

旧クイズ形式（PuzzleManager / game_screen / investigation_panel / code_panel）を破棄し、ナラティブ調査型（CaseManager + 4画面 + 4リソース）へ置換する。EventBus・SceneManager・GameManager・SaveManager・AudioManager の基盤はそのまま流用する。3観点レビュー（実装・面白さ・営業）で指摘された全リスクを設計に織り込み済み。

主要な発見:
1. SceneManager はデータ受け渡し機能を持たない → CaseManager をシーン間データバスとして使用する。
2. 既存シーンは全て GDScript でUIを動的構築する方式（.tscn は空ルート）。新画面も同方式に統一する。
3. SaveManager は `get_value()` / `set_value()` の汎用アクセサを持つ → セーブスキーマ拡張は最小変更で可能。
4. Web版（itch.io）でクリップボード・shell_open はユーザージェスチャ起点なら動作する見込み。失敗時フォールバックを設計に含める。

---

## Research Log

### 調査 1: シーン間データ受け渡し

**問題:** SceneManager（scene_manager.gd:19）は `change_scene_to_file()` の薄いラッパーで、シーン間でデータを渡せない。BriefingScreen で選んだケースを InvestigationScreen にどう渡すか。

**結論:** `CaseManager`（Autoload）をデータバスとして使う。
- `CaseManager.current_case: CaseData` に選択ケースを保持
- 各画面は `_ready()` で `CaseManager.current_case` を参照
- 再挑戦（要件4-9）も同じ `current_case` を再利用するため経路が初回と統一される（前回設計で問題になった「初回と RETRY で経路が別」を解消）

**リスク:** `current_case` が null のままケース画面に入るとクラッシュ → 各画面の `_ready()` で null ガードし、null なら CaseSelect へ戻す。

---

### 調査 2: タイマー所有とポーズ連動

**問題:** カウントダウン（要件2）を誰が持つか。ポーズ中停止（要件2-5）をどう実現するか。

**結論:** `CaseManager` がタイマーを所有し `_process(delta)` で進める。
- 既存 PuzzleManager（puzzle_manager.gd:19-21）の `GameManager.state == PLAYING` チェックと同パターンを採用
- ステートを `INVESTIGATING` のときのみ減算 → ポーズ（PAUSED）・判決（VERDICT）・結末（OUTCOME）では自動停止
- `time_remaining <= 0` で `verdict_submitted("insufficient")` を発火し OUTCOME へ

**リスク:** なし（既存実装パターンの踏襲）

---

### 調査 3: 旧パズルコードの破棄範囲

**問題:** どのファイルを消すと何が壊れるか。

**結論（3観点レビューで破棄対象を完全洗い出し）:**
| 破棄ファイル | 依存していたもの | 置換 |
|------------|----------------|------|
| `scenes/game/game_screen.*` | main_menu の遷移先（main_menu.gd:224） | CaseSelect へ変更 |
| `scenes/game/investigation_panel.*` | game_screen が instantiate | 削除 |
| `scenes/game/code_panel.*` | game_screen が instantiate | 削除 |
| `scenes/ui/game_hud.*` | **game_screen が instantiate・旧シグナル参照（:21-23,83,93,104,123-125）** | Investigation 内に再実装 |
| `scenes/ui/pause_menu.*` | **game_screen が instantiate・`level_restarted`参照（:94）** | Investigation 内に再実装 |
| `scenes/ui/result_screen.*` | puzzle_completed フロー・RESULT/PLAYING 参照（:38,248） | OutcomeScreen へ置換 |
| `autoloads/puzzle_manager.gd` | save_manager（:15,:83）・EventBus シグナル | CaseManager へ置換 |
| `scripts/data/puzzle_data.gd`・`puzzle_question.gd` | puzzle_manager・level_001.tres・`puzzle_loaded`型 | 新リソースへ置換 |
| `resources/puzzles/level_001.tres` | — | `resources/cases/case_001.tres` へ |
| `tests/unit/test_puzzle_manager.gd` | — | test_case_manager.gd |
| `tests/unit/test_save_manager.gd`（:95-149 旧パズル部分） | — | case_resolved テストへ置換 |
| `tests/unit/test_game_manager.gd`（:104-110 RESULT 依存） | — | 新 GameState へ更新 |
| `tests/unit/test_score_calc*.gd` | スコア廃止（要件4-4） | 破棄 |

**致命的（レビュー A-1/B-1）:** `game_hud.gd`・`pause_menu.gd` は当初リストから漏れていたが、削除シグナル・GameState を参照しており、破棄漏れだと**起動時パースエラー**になる。`signal puzzle_loaded(puzzle: PuzzleData)` は `PuzzleData` 型に依存するため、リソース破棄とシグナル削除は**同一コミットで原子的に**行う。

**game_manager 修正（レビュー B-2/B-3）:** `_on_game_started`/`_on_game_over` を撤去（新フローはスコア概念なし）。`_on_game_paused` を state 退避・復元方式に変更。`PLAYING` を削除し `INVESTIGATING` 等へ再定義、`PAUSED` は維持。

---

### 調査 4: Web版クリップボード・shell_open

**問題:** 要件4-6（クリップボード）・要件5-5（shell_open）は Web（itch.io）で動くか。

**結論:**
- `DisplayServer.clipboard_set()` は**戻り値で成否を判定できない**（テスター指摘）。Web では無音失敗しうるため、`OS.has_feature("web")` 判定で**常にフォールバックLabelを併置**する（「失敗時のみ」ではなく Web は常時）。
- `OS.shell_open(url)` は Web で新規タブを開く。ユーザー操作起点なら通常許可される。
- どちらも `GameManager` 定数から取得し、エクスポート前に確定。

**リスク:** 中。Web実機での検証を release-checklist に含める。

---

### 調査 5: エクスポート後の .tres ロード（レビュー F-1）

**問題:** CaseSelect で `DirAccess` により `resources/cases/*.tres` を走査する設計は、エクスポート（.pck）・Web で破綻するか。

**結論:** **破綻リスク高。** エクスポート時に `.tres` が `.remap`/バイナリへ変換され、`DirAccess.get_files()` が `.tres.remap` を返す/ファイルが見えない等が起きる。Web は仮想FSでさらに不安定。
→ **`resources/cases/case_manifest.tres`（`class_name CaseManifest` / `Array[CaseData]`）経由でロードする。** 要件5-2「ハードコードリスト禁止」はデータ駆動の manifest で満たす（.gd ベタ書きではない）。

---

### 調査 6: ポーズ機構の破綻（レビュー A-2）

**問題:** CaseManager._process が `state == INVESTIGATING` でのみ減算する当初設計は、ポーズで動くか。

**結論:** **動かない。** GameManager._on_game_paused は `get_tree().paused = true` をセットするため、`process_mode` が ALWAYS でない限り `_process` 自体が止まる。さらに解除時 state は当初 `PLAYING` に戻り `INVESTIGATING` 条件と不一致でタイマーが永久停止。
→ CaseManager を `PROCESS_MODE_ALWAYS` とし、`EventBus.game_paused` 購読の `_paused` フラグでタイマーを制御。state 依存を排除。GameManager は state 退避・復元方式へ修正。

---

### 調査 7: outcomes の型表現（レビュー F-2）

**問題:** `outcomes: Dictionary`（outcome_key→OutcomeData）の .tres export は型安全か。

**結論:** Godot 4.4 は型付き Dictionary の export 未対応で、素の Dictionary になり Inspector 編集性・型安全性に難。`get()` が Variant を返し強制キャスト禁止規約に抵触。
→ `outcomes: Array[OutcomeData]`（各要素が `outcome_key` を保持）へ変更。`get_outcome(key)` は配列検索 + null フォールバック。型安全で Inspector 編集も容易。

---

### アーキテクチャ決定記録

| 決定 | 選択 | 却下した選択肢 | 理由 |
|------|------|-------------|------|
| 調査進行の所有者 | CaseManager（Autoload） | 各シーン | シーンにビジネスロジック禁止 |
| シーン間データ | CaseManager.current_case | SceneManager 拡張 | 最小変更・経路統一 |
| UI構築方式 | GDScript 動的構築 | .tscn エディタ構築 | 既存全シーンと統一 |
| 旧パズルコード | 破棄（削除） | 共存・放置 | 後戻り防止・lint/test の混乱回避 |
| タイマー減算条件 | state == INVESTIGATING | 専用 bool フラグ | 既存パターン踏襲・ポーズ自動連動 |
| hint_for_replay 所在 | OutcomeData のみ | VerdictChoice | 要件内矛盾を解消（実装観点指摘） |
| シェア失敗時 | 選択可能Label表示 | 無視 | Web版機能不全回避（営業観点指摘） |
| 結末コレクション | outcome_key 配列を保存 | 単一値上書き | リプレイ動機の可視化（面白さ観点指摘） |
