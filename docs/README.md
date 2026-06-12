# Architecture Docs

**策定日:** 2026-06-07
**対象:** Godot 4.4+ / GDScript 2.0

このドキュメント群はプロジェクトの土台となるアーキテクチャ規約です。
Claude Code はタスク実行前に該当ドキュメントを読んでから実装します（CLAUDE.md 参照）。

---

## ディレクトリ構成

```
docs/
├── workflow/   開発プロセス。いつ・何をするかのプロセスマップ
├── core/       設計の根幹。実装タスク全般で常時参照
├── ui/         UI実装パターン。シーン・シグナル・フォーム
├── styling/    スタイリング・アニメーション・プラットフォーム差異
├── data/       ストレージ・セキュリティ・ログ・国際化
├── quality/    テスト・Lint・アクセシビリティ・パフォーマンス
└── ops/        ビルド・リリース・開発環境
```

---

## workflow/ — 開発プロセス

| ファイル | 内容 | 読むタイミング |
|---------|------|-------------|
| [development-process.md](./workflow/development-process.md) | 開発フローのプロセスマップ | セッション開始時・タスク着手前 |

---

## core/ — 設計の根幹

| ファイル | 内容 | 読むタイミング |
|---------|------|-------------|
| [architecture.md](./core/architecture.md) | レイヤー構成・依存ルール・データフロー | 実装タスク全般（常時） |
| [conventions.md](./core/conventions.md) | GDScript・コーディング規約 | コード全般（常時） |
| [state-management.md](./core/state-management.md) | Autoload パターン・EventBus | 状態追加時 |
| [scene-design.md](./core/scene-design.md) | シーン設計・遷移パターン | シーン追加時 |
| [startup.md](./core/startup.md) | 起動シーケンス・Autoload 初期化順序 | main.tscn / Autoload 変更時 |

---

## ui/ — UI実装パターン

| ファイル | 内容 | 読むタイミング |
|---------|------|-------------|
| [scene-patterns.md](./ui/scene-patterns.md) | シーン設計パターン（Composite・Template） | シーン作成時 |
| [scene-principles.md](./ui/scene-principles.md) | 設計原則・追加基準 | シーン追加・設計判断時 |
| [async-ui.md](./ui/async-ui.md) | Loading/Error/Empty 状態パターン | 非同期処理を含むUI実装時 |
| [signals.md](./ui/signals.md) | シグナル設計・EventBus パターン | シグナル追加・設計時 |
| [feedback.md](./ui/feedback.md) | 通知・トースト・Haptics パターン | ユーザーフィードバック実装時 |
| [input-forms.md](./ui/input-forms.md) | フォーム・入力バリデーション設計 | 入力フォーム実装時 |
| [popups.md](./ui/popups.md) | ダイアログ・ポップアップ設計 | ダイアログ実装時 |

---

## styling/ — スタイリング・見た目

| ファイル | 内容 | 読むタイミング |
|---------|------|-------------|
| [ux-standards.md](./styling/ux-standards.md) | UI/UX標準（スペーシング・カラー・インタラクション） | 画面実装時（常時） |
| [theme.md](./styling/theme.md) | テーマ設定・ダークモード対応 | テーマ・スタイル変更時 |
| [typography.md](./styling/typography.md) | タイポグラフィ・フォントスケール | テキスト・フォント指定時 |
| [animation.md](./styling/animation.md) | Tween・AnimationPlayer 設計 | アニメーション実装時 |
| [platform-input.md](./styling/platform-input.md) | タッチ/マウス/キーボード/ゲームパッド入力 | 入力処理実装時 |
| [control-pitfalls.md](./styling/control-pitfalls.md) | Control ノードの地雷パターン | UIレイアウト実装時（常時） |

---

## data/ — データ・インフラ

| ファイル | 内容 | 読むタイミング |
|---------|------|-------------|
| [storage.md](./data/storage.md) | セーブデータ・設定永続化 | ストレージ実装時 |
| [security.md](./data/security.md) | 機密データ・暗号化基準 | セキュリティ関連実装時 |
| [observability.md](./data/observability.md) | ログ設計・イベント分析 | ログ実装・機能追加時 |
| [i18n.md](./data/i18n.md) | 多言語対応・RTL・日時フォーマット | 文字列追加・多言語対応時 |

---

## quality/ — 品質保証

| ファイル | 内容 | 読むタイミング |
|---------|------|-------------|
| [testing.md](./quality/testing.md) | GUT テスト規約・パターン | テスト作成時 |
| [linting.md](./quality/linting.md) | gdtoolkit・pre-commit・CI 設定 | Lint・Format・CI 設定時 |
| [accessibility.md](./quality/accessibility.md) | アクセシビリティ対応 | UI実装時 |
| [performance.md](./quality/performance.md) | パフォーマンス基準・プロファイリング | 最適化・ボトルネック調査時 |

---

## ops/ — 開発・運用

| ファイル | 内容 | 読むタイミング |
|---------|------|-------------|
| [dev-environment.md](./ops/dev-environment.md) | 開発環境構築（Godot・gdtoolkit） | 初回セットアップ時 |
| [operations.md](./ops/operations.md) | ビルド・エクスポート・リリース | デプロイ時 |

---

## 設計の大原則

1. **ローカルファースト** — サーバー不要。全データはデバイス内で完結
2. **型安全** — GDScript typed mode。`Variant` は最小限
3. **シグナルファースト** — ノード間通信はシグナル経由
4. **コスト完全ゼロ** — 有料サービスの無料枠のみ使用可
5. **AI開発対応** — Claude Code が自律的に実装できる粒度でルールを定義
