# Research — リザルト画面

## Summary

既存 Autoload（GameManager・PuzzleManager・SaveManager・SceneManager）との統合に集中した **Extension** 型の発見作業。新規外部依存なし。

---

## Research Log

### 1. puzzle_completed シグナルのデータフロー

**調査内容**: `puzzle_completed(score, miss_count, elapsed_time)` の発火タイミングと SaveManager との実行順序  
**発見**: `game_screen.gd._on_secured_sequence_done()` が `puzzle_completed` を emit → SaveManager が同フレームで `_on_puzzle_completed()` を実行しスコアを `progress/scores` に保存 → その後 `scene_change_requested` で遷移。  
**含意**: リザルト画面が読み込まれた時点では **すでに保存済み**。「前回スコア」は遷移前に取得・保存しなければならない。

### 2. ハイスコア比較のタイミング問題

**調査内容**: SaveManager でのスコア上書き条件  
**発見**: `if score > int(scores.get(level_id, 0))` のみ上書き。リザルト画面到達時点でスコアはすでに更新済み。  
**結論**: `is_new_high_score` フラグは **`puzzle_completed` emit 前**に確定して GameManager に格納する必要がある。

### 3. GameManager への結果データ格納

**調査内容**: シーン間データ受け渡しの既存パターン  
**発見**: SceneManager はメタデータ渡し機能を持たない。GameManager は `score: int`, `high_score: int` などシンプルな var を保持。  
**決定**: GameManager に `last_result: Dictionary` フィールドを追加し、結果データを格納する。型安全のため内容キーを文書化する。

### 4. PuzzleManager の永続性

**調査内容**: シーン遷移後も PuzzleManager の状態が残るか  
**発見**: Autoload はシーン遷移をまたいで保持される。`current_puzzle.title`, `.bug_type`, `.level_id` はリザルト画面からも参照可能。  
**含意**: レベルタイトル・バグ種別は GameManager に複製せず、PuzzleManager から直接読む。

### 5. GameState 拡張

**調査内容**: `LEVEL_CLEAR` と `RESULT` の分離が必要か  
**発見**: `LEVEL_CLEAR` は `game_screen.gd` 内の演出中に使われる。リザルト画面はゲームプレイ外の独立した状態。  
**決定**: `RESULT` ステートを GameManager enum に追加する。`LEVEL_CLEAR` と区別することで将来のゲームフロー（マルチレベル等）での状態判定が明確になる。

---

## Architecture Decision

| 決定 | 選択肢 | 理由 |
|------|-------|------|
| データ渡し方法 | GameManager.last_result Dictionary | Autoload は全シーン共有。SceneManager に機能追加不要 |
| ハイスコア比較時点 | game_screen.gd 内・emit 前 | SaveManager が同フレームで書き込むため、emit 後では比較不能 |
| is_new_high_score の読み取り | SaveManager.get_value("progress", "scores") を直接参照 | 公開 API `get_value()` が存在するため追加実装不要 |
| GameState | RESULT を追加 | LEVEL_CLEAR と責任を分離し将来的なフロー拡張に備える |
