# Research Log — ゲームプレイ画面

## Summary

既存の Autoload（`GameManager`・`EventBus`・`SaveManager`）のパターンを分析し、ゲームプレイ画面の設計に統合した。

- **Discovery 種別:** Extension（既存 Autoload への拡張 + 新規シーン追加）
- **既存パターン:** EventBus 経由の疎結合、`_exit_tree()` でのシグナル切断、ConfigFile による永続化
- **主な設計決定:** PuzzleQuestion を Dictionary ではなく Resource で型安全に管理

---

## Research Log

### 1. 既存 Autoload パターン分析

**調査対象:** `autoloads/game_manager.gd`, `autoloads/event_bus.gd`, `autoloads/save_manager.gd`

**発見:**
- `GameManager.transition_to()` が GameState 遷移の標準 API
- `EventBus` シグナルはすべて `snake_case` の過去形/動詞形
- `SaveManager` は `get_value(section, key, default)` で汎用アクセス可能
- `_exit_tree()` でのシグナル切断が全 Autoload で実装済み

**影響:** `PuzzleManager` も同パターンに従い、`_exit_tree()` でシグナル切断を実装する

### 2. GameState 拡張の判断

**問題:** 既存 `GameState` に `PLAYING`・`PAUSED`・`GAME_OVER` のみ存在。パズルゲーム固有の状態（ANIMATING・LEVEL_CLEAR 等）が未定義。

**決定:** `GameManager` の enum に以下を追加
- `LEVEL_SELECT` — レベル選択画面
- `ANIMATING` — フィードバック演出中（入力無効）
- `LEVEL_CLEAR` — クリア演出中
- `GAME_CLEAR` — 全レベルクリア

`LEVEL_FAILED` は不要（即リトライのため ANIMATING から PLAYING に戻る）

### 3. PuzzleQuestion の型設計

**要件 8.2:** `questions: Array[Dictionary]` と記述

**問題:** GDScript の `Array[Dictionary]` は型安全でなく、キーのタイポが実行時エラーになる

**決定:** `class_name PuzzleQuestion extends Resource` で別クラス化し、`PuzzleData.questions: Array[PuzzleQuestion]` とする

**理由:**
- GDScript typed array でコンパイル時チェック可能
- Godot エディタのインスペクターで編集可能
- `.tres` リソースとして保存・読み込み可能

### 4. スコア計算の分離

**決定:** `scripts/utils/score_calc.gd` に純粋関数として切り出す

**理由:** Autoload に直接書くとテストが難しい（`get_tree()` 依存なしの純粋関数にすることで GUT でシンプルにテスト可能）

**ランク定義:** S(900+) / A(700-899) / B(500-699) / C(300-499) / D(100-299)

### 5. コードパネルの行選択実装方針

**問題:** Godot で各コード行をクリック可能にするには Button または入力受付 Label が必要

**決定:** 各行を `Button` (flat style, custom StyleBox) で実装。行番号は別の `Label` で左に配置。`HBoxContainer` で横並び。

**理由:** Button は `mouse_entered` / `pressed` シグナルが標準提供されており、ホバー・クリックの両方を扱いやすい。StyleBox で通常/ホバー/押下/選択の4状態を定義する。
