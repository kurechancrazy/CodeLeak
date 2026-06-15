# Architecture — AI Code Leak

## 次元

UI専用（Control ノード中心）

## Physics Layer

UI専用のため Physics Layer は使用しない。

## Input Map

| アクション名 | キー | 説明 |
|-----------|-----|------|
| `confirm` | Enter / Space | 選択肢を確定・コード行を選択 |
| `cancel` | Escape | キャンセル・前の画面に戻る |
| `pause` | Escape | ポーズメニュー |
| `move_up` | ↑ / W | コード行の上に移動 |
| `move_down` | ↓ / S | コード行の下に移動 |

## GameState 拡張

ナラティブ調査型（tension-gameplay）への再設計に伴い、旧クイズ系ステートを破棄し以下を使用する。

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    CASE_SELECT,    # ケース選択画面
    BRIEFING,       # ミッションブリーフィング
    INVESTIGATING,  # 証拠調査・カウントダウン進行中
    VERDICT,        # 判決選択
    OUTCOME,        # 結末ナラティブ
    PAUSED,
}
```

旧ステート（`LEVEL_SELECT`・`PLAYING`・`ANIMATING`・`LEVEL_CLEAR`・`LEVEL_FAILED`・`GAME_OVER`・`GAME_CLEAR`）は破棄。

## Autoload 計画

| Autoload | 役割 | 初期化順 |
|----------|------|---------|
| Logger | ログ出力 | 1 |
| EventBus | グローバルイベント | 2 |
| GameManager | GameState管理・設定・DEMO/URL定数 | 3 |
| CaseManager | ケース進行・調査タイマー・判決管理 | 4 |
| SceneManager | シーン遷移 | 5 |
| SaveManager | セーブ・ロード | 6 |
| AudioManager | BGM/SFX | 7 |

初期化順序: Logger → EventBus → GameManager → CaseManager → SceneManager → SaveManager → AudioManager

旧 `PuzzleManager` はナラティブ調査型への再設計に伴い破棄し、`CaseManager` で置換する。

## ポーズ設定

| ノード | Process Mode |
|-------|-------------|
| 調査画面ルート（InvestigationScreen） | PROCESS_MODE_PAUSABLE |
| ポーズメニュー（CanvasLayer） | PROCESS_MODE_WHEN_PAUSED |
| カウントダウン表示 | PROCESS_MODE_PAUSABLE |
| BGM（AudioStreamPlayer） | PROCESS_MODE_ALWAYS |

カウントダウン本体は CaseManager が所有し、`GameState == INVESTIGATING` のときのみ減算するため、ポーズ（PAUSED）で自動停止する。

## セーブスキーマ（v1）

| section | key | 型 | デフォルト値 | 説明 |
|---------|-----|----|------------|------|
| `meta` | `save_version` | `int` | `1` | スキーマバージョン |
| `meta` | `saved_at` | `String` | `""` | 保存日時 |
| `meta` | `play_time` | `float` | `0.0` | 累積プレイ時間（秒） |
| `progress` | `cases_resolved` | `String` | `"[]"` | クリア済みケースIDリスト（JSON配列） |
| `progress` | `case_verdicts` | `String` | `"{}"` | ケース別の到達 outcome_key 配列（JSON dict） |

旧スキーマ（`level_reached`・`levels_cleared`・`scores`）はナラティブ調査型への再設計に伴い破棄。

GameSettings は `class_name GameSettings extends Resource` で型安全に定義する。

## COPPA / GDPR

COPPA対応は不要。GDPR基本同意フローを実装すること。
