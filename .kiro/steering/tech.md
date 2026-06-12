# Tech — AI Code Leak

## 技術スタック

| 役割 | 採用技術 | 備考 |
|------|---------|------|
| エンジン | Godot 4.4 | GL Compatibility レンダラー |
| 言語 | GDScript 2.0（typed） | 全変数・引数・戻り値に型アノテーション必須 |
| テスト | GUT 4.x（Godot Unit Testing） | `tests/unit/` に配置 |
| Lint / Format | gdtoolkit（gdlint + gdformat） | コミット前に必ず実行 |
| CI | GitHub Actions（barichello/godot-ci） | `.github/workflows/ci.yml` |
| セーブデータ | SaveManager（ConfigFile） | `user://save_data.cfg` |
| 設定データ | SaveManager（ConfigFile） | `user://settings.cfg` |
| オーディオ | AudioManager（AudioStreamPlayer プール） | BGM/SFX 分離 |
| シーン管理 | SceneManager Autoload | |
| グローバルイベント | EventBus Autoload | Autoload間通信はすべてEventBus経由 |
| ログ | Logger Autoload | print() 禁止・Logger.info() / Logger.error() を使う |
| エクスポート | Godot Export Templates | PC + Web(HTML5) |

## パズルデータ形式

- パズル定義は `resources/puzzles/` 以下の `.tres` / `.res` ファイルまたは JSON
- レベルデータは `class_name PuzzleData extends Resource` で型安全に管理

## 新しいプラグイン・アドオン

追加が必要な場合は **実装前にユーザーに確認すること**。

## Web エクスポート注意事項

- AudioContext のブラウザ制限: ユーザー操作後に初期化する
- SharedArrayBuffer: COOP/COEP ヘッダーが必要（itch.io は設定済み）
- スレッドは使用しない（Web制約）
