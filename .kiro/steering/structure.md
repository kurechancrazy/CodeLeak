# Structure — AI Code Leak

## ディレクトリ構成

```
CodeLeak/
├── project.godot                    ← Godot プロジェクト設定
├── CLAUDE.md                        ← Claude Code 毎回自動読込
├── _init.md                         ← 初期化フロー（削除しない）
├── SETUP.md                         ← セットアップ手順
├── icon.svg
├── .kiro/
│   └── steering/
│       ├── product.md               ← ゲーム概要・UX方針
│       ├── tech.md                  ← 技術スタック
│       ├── structure.md             ← このファイル
│       └── architecture.md         ← アーキテクチャ設計
├── .kiro/specs/                     ← 機能仕様（spec-init で生成）
├── autoloads/                       ← Autoload シングルトン
│   ├── logger.gd
│   ├── event_bus.gd
│   ├── game_manager.gd
│   ├── scene_manager.gd
│   ├── save_manager.gd
│   ├── audio_manager.gd
│   └── puzzle_manager.gd            ← 追加予定
├── scenes/
│   ├── main.tscn                    ← エントリポイント
│   ├── ui/
│   │   ├── main_menu.tscn
│   │   ├── level_select.tscn
│   │   ├── hud.tscn
│   │   └── pause_menu.tscn
│   └── game/
│       ├── game_screen.tscn         ← パズルプレイ画面
│       └── result_screen.tscn
├── scripts/
│   └── utils/                       ← ユーティリティ（テスト対象）
├── resources/
│   ├── themes/                      ← Godot テーマファイル
│   └── puzzles/                     ← PuzzleData リソース
│       └── level_001.tres
├── assets/
│   └── fonts/                       ← モノスペースフォント（等幅）
├── addons/
│   └── gut/                         ← GUT テストフレームワーク
└── tests/
    └── unit/                        ← GUT テストファイル
```

## 命名規則

| 対象 | 規則 | 例 |
|-----|------|-----|
| スクリプト | snake_case | `puzzle_manager.gd` |
| シーン | snake_case | `game_screen.tscn` |
| クラス名 | PascalCase | `PuzzleManager`, `PuzzleData` |
| 定数 | UPPER_SNAKE_CASE | `MAX_LEVELS` |
| シグナル | snake_case（過去形・動詞） | `puzzle_solved`, `level_failed` |
| テストファイル | `test_` プレフィックス | `test_puzzle_manager.gd` |

## ファイル配置ルール

- シーンスクリプトは同名の `.gd` をシーンと同ディレクトリに置く
- ユーティリティ関数（純粋関数）は `scripts/utils/` に置き、テストを書く
- ゲームデータ（パズル定義）は `resources/puzzles/` に `.tres` で管理
- フォントは `assets/fonts/` に配置し、テーマから参照する
