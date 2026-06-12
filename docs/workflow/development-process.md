# 開発プロセスワークフロー

このドキュメントは「いつ・何をするか」を定義するプロセスマップです。
各ステップの「やり方」は参照先ドキュメントを読むこと。

---

## まず確認：どのパスを使うか

```
全条件を満たす → Quick Fix パス（仕様フェーズをスキップ）
1つでも外れる → Full Spec パス（仕様フェーズから開始）
```

### Quick Fix の適用条件（全て満たすこと）

```
□ 既存ファイルの修正のみ（新規ファイルを作らない）
□ 設計・シグナル・Autoload の変更なし
□ 影響範囲が 1〜3 ファイル以内
□ 実装内容を着手前にほぼ確定できる（設計判断・選択肢の検討が不要）
□ 新しいプラグイン・アドオンを追加しない
```

#### Quick Fix / Full Spec の判定早見表

| 変更の内容 | パス |
|-----------|------|
| バグ修正（既存の関数の動作を直す） | Quick Fix |
| 定数値・閾値の変更 | Quick Fix |
| 既存メソッドへの条件分岐の追加（1〜2行） | Quick Fix |
| テキスト・ラベルの修正 | Quick Fix |
| 新しい `var` フィールドを Autoload に追加 | **Full Spec** |
| 新しい EventBus シグナルを追加 | **Full Spec** |
| 新しい Autoload メソッド（公開API）を追加 | **Full Spec** |
| シーンの構成・ノード構造を変える | **Full Spec** |
| 既存シグナルのパラメータを変更 | **Full Spec** |

> **迷ったら Full Spec パスを選ぶ。**

---

## 全体像

```
Quick Fix パス
  └─ 関連ドキュメントを読む → 実装 → DoD チェック → コミット

Full Spec パス（Phase 1〜3）
  Phase 1: 仕様策定（Spec）
    └─ spec-init → requirements → design → tasks → 各フェーズの人間レビュー

  Phase 2: 実装（Impl）
    └─ タスクごとに TDD サイクル → DoD を満たしてからコミット

  Phase 3: リリース前（Pre-release）
    └─ 動作確認 → バージョン更新 → エクスポート → ストア提出
```

---

## Quick Fix パス

### QF-1. 実装前の確認

```
□ 変更するファイル・実装内容を特定した
□ CLAUDE.md の「タスク別必読ドキュメント」テーブルで該当行を全て確認した
□ 該当するドキュメントを Read ツールで開いて読んだ
```

### QF-2. 実装

- Quick Fix 適用条件の範囲内で実装する
- 想定外の変更が必要になった場合は **即座に Full Spec パスへ切り替える**

### QF-3. 完了の定義（DoD）

```
□ 実装コードを書いた
□ 既存テストが壊れていないことを確認した
□ GUT → 全テスト PASS
□ gdlint → エラー 0 件
□ gdformat --check → 差分 0
□ /godot-spec-check → Critical なし
```

---

## Full Spec パス

### Phase 0: 事前確認（spec-init 実行前に必ず確認）

```
□ .kiro/steering/product.md に {{GAME_NAME}} が含まれていない（_init.md の初期化済み）
□ .kiro/steering/architecture.md に {{DIMENSION}} が含まれていない（初期化済み）
□ docs/architecture/initial-decisions.md の Physics Layer / InputMap / GameState が決定済み
```

未完了の場合は **初期化を先に完了させる**。未初期化の steering で spec を開始すると、不完全な設計ドキュメントが生成される。

### Phase 1: 仕様策定

```
/kiro:spec-init "機能名"
  ↓
/kiro:spec-requirements
  ↓ ── 人間レビュー・承認 ──── ← STOP
/kiro:spec-design          ← docs/workflow/spec-design-template.md の構造に従うこと
  ↓ ── 人間レビュー・承認 ──── ← STOP
/kiro:spec-tasks
  ↓ ── 人間レビュー・承認 ──── ← STOP
/kiro:spec-impl
```

#### 各フェーズで参照するドキュメント

| フェーズ | 参照先 |
|---------|--------|
| 設計判断 | `.kiro/steering/architecture.md`, `docs/core/architecture.md` |
| 状態設計 | `docs/core/state-management.md` |
| シーン・遷移設計 | `docs/core/scene-design.md` |
| テスト要件の定義 | `docs/quality/testing.md`, `docs/gameplay/testing-game.md` |
| **design.md の出力形式** | **`docs/workflow/spec-design-template.md`（必読）** |

#### 仕様フェーズのゲート条件

```
□ 要件が「何を達成するか」で書かれているか（HOW ではなく WHAT）
□ 各タスクが 1〜3 時間で完了できる粒度か
□ テスト要件が設計に含まれているか
□ 既存 Autoload / シーンへの影響範囲が明示されているか
```

---

### Phase 2: 実装（タスクごとの TDD サイクル）

> **原則**: 1タスク = 1サイクル。複数タスクをまとめて実装しない。

#### 2-1. タスク開始前の確認

```
□ tasks.md で対象タスクが未完了（- [ ]）であることを確認した
□ CLAUDE.md の「タスク別必読ドキュメント」テーブルで該当行を全て確認した
□ 該当するドキュメントを Read ツールで開いて読んだ
```

#### 2-2. TDD サイクル

```
RED   → テストを書く（まだ実装コードはない）
GREEN → 最小限の実装でテストを通す
REFACTOR → コードを整理する（テストは引き続き通る）
```

**参照先**: `docs/quality/testing.md`

#### 2-3. タスク完了の定義（Definition of Done）

```
□ 実装コードを書いた
□ scripts/utils / autoloads の新規ファイルには test_{name}.gd を書いた
□ GUT → 全テスト PASS
□ gdlint → エラー 0 件
□ gdformat --check → 差分 0
□ /godot-spec-check → Critical なし
□ UI/UX チェックリスト全項目確認済み（docs/styling/ux-standards.md を Read して確認）
□ ゲームプレイに関わる変更の場合: docs/gameplay/game-ux.md のゲームUXチェックリストも確認
□ ゲームプレイに関わる変更の場合: ゴールデンパス（タイトル→ゲーム開始→ゲームオーバー→リトライ）を手動確認した
□ 手動確認した内容を tasks.md の該当タスクにコメントとして記録した
□ tasks.md の該当タスクを [x] にした
```

#### 2-3-a. バグ修正の判定フロー

バグ修正が Quick Fix か Full Spec か迷った場合は以下で判定する。

```
バグを修正するために…

新しいシグナル・Autoloadメソッドが必要か？
  Yes → Full Spec

既存ファイルの修正だけで直るか？
  Yes → 続く

テストファイルの追加が必要か？
  Yes（かつ修正ファイルが1〜3件以内）→ Quick Fix OK
  ※ テストファイルは「新規作成」でも修正が Quick Fix 条件内なら Quick Fix で処理可

修正前に設計判断（どのアプローチが正しいか）が必要か？
  Yes → Full Spec（設計が確定していないため）
  No → Quick Fix
```

#### 2-4. コミット前の追加確認

```
□ print() を本番コードに残していない（Logger を使う）
□ 型アノテーションのない変数・パラメータ・戻り値がない
□ get_node() のハードコードパスを使っていない
□ _process() 内に重い処理がない
□ Autoload が別 Autoload を直接 call() していない
```

#### 2-5. 新規ファイルを作成した場合の追加対応

| 新規ファイルの種類 | 必須の追加対応 |
|-----------------|-------------|
| `scripts/utils/*.gd` | `tests/unit/test_*.gd` を作成 |
| `autoloads/*.gd` のロジック部分 | `tests/unit/test_*.gd` を作成 |
| `scenes/ui/*.tscn` | テスト任意（ロジックをAutoloadに切り出す） |
| 新シーン | `docs/core/scene-design.md` を確認 |
| 新 Autoload | `docs/core/state-management.md` を確認 |

#### 2-6. 自動化されていること（手動対応不要）

| タイミング | 自動実行内容 |
|----------|-----------|
| `git commit` | gdlint + gdformat チェック |
| `git push` | GUT 全テスト実行（失敗するとブロック） |
| CI（GitHub Actions） | lint + format + テスト + エクスポート確認 |

---

### Phase 3: リリース前チェック

#### 3-1. 品質ゲート

```
□ GUT → 全テスト PASS（カバレッジ確認）
□ gdlint → エラー 0 件
□ gdformat --check → 差分 0
□ git status → 未コミットの変更がない
```

#### 3-2. 動作確認

```
□ ターゲットプラットフォームで動作確認（PC / Web / モバイル）
□ 実装した機能のゴールデンパスを手動で操作確認
□ 既存機能に回帰がないことを確認
□ セーブ・ロードが正常に動作することを確認
```

#### 3-3. バージョン管理

```
□ project.godot の config/version を更新した
□ CHANGELOG.md（または git tag）にリリース内容を記録した
```

#### 3-4. ビルド・提出

```
□ Godot Export でリリースビルドを作成した
□ ターゲットプラットフォームにインストールして最終確認した
□ 各ストア / プラットフォームに提出した
```

**参照先**: `docs/ops/operations.md`

---

## よくある実装漏れのパターンと防止策

| 漏れのパターン | 発生フェーズ | 防止チェック |
|-------------|-----------|-----------|
| Quick Fix のつもりが新規 Autoload 追加になった | Quick Fix | 実装中に適用条件を外れたら即 Full Spec へ |
| シグナル接続を忘れてシーン削除後にエラー | Phase 2 | `docs/ui/signals.md` を事前に読む |
| Autoload の循環依存が発生 | Phase 2 | EventBus 経由に修正 |
| Control の minimum_size と size を混同 | Phase 2 | `docs/styling/control-pitfalls.md` を読む |
| 型アノテーションなしで gdlint エラー | Phase 2 | pre-commit フックが検出する |
