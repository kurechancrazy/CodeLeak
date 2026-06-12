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

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LEVEL_SELECT,
    PLAYING,       # コード表示・選択肢待ち
    ANIMATING,     # 結果フィードバック演出中
    LEVEL_CLEAR,   # レベルクリア演出
    LEVEL_FAILED,  # 誤答・失敗演出
    PAUSED,
    GAME_OVER,
    GAME_CLEAR     # 全レベルクリア
}
```

## Autoload 計画

| Autoload | 役割 | 初期化順 |
|----------|------|---------|
| Logger | ログ出力 | 1 |
| EventBus | グローバルイベント | 2 |
| GameManager | GameState管理・設定 | 3 |
| PuzzleManager | パズル進行・レベル管理 | 4 |
| SceneManager | シーン遷移 | 5 |
| SaveManager | セーブ・ロード | 6 |
| AudioManager | BGM/SFX | 7 |

初期化順序: Logger → EventBus → GameManager → PuzzleManager → SceneManager → SaveManager → AudioManager

## ポーズ設定

| ノード | Process Mode |
|-------|-------------|
| ゲームプレイ画面ルート | PROCESS_MODE_PAUSABLE |
| ポーズメニュー（CanvasLayer） | PROCESS_MODE_WHEN_PAUSED |
| HUD（CanvasLayer） | PROCESS_MODE_WHEN_PAUSED |
| BGM（AudioStreamPlayer） | PROCESS_MODE_ALWAYS |

## セーブスキーマ（v1）

| section | key | 型 | デフォルト値 | 説明 |
|---------|-----|----|------------|------|
| `meta` | `save_version` | `int` | `1` | スキーマバージョン |
| `meta` | `saved_at` | `String` | `""` | 保存日時 |
| `meta` | `play_time` | `float` | `0.0` | 累積プレイ時間（秒） |
| `progress` | `level_reached` | `int` | `1` | 到達済み最大レベル番号 |
| `progress` | `levels_cleared` | `String` | `"[]"` | クリア済みレベルIDリスト（JSON） |
| `progress` | `scores` | `String` | `"{}"` | レベル別スコア（JSON dict） |

GameSettings は `class_name GameSettings extends Resource` で型安全に定義する。

## COPPA / GDPR

COPPA対応は不要。GDPR基本同意フローを実装すること。
