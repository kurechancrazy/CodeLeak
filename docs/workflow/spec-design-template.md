# Spec Design Template — design.md の必須構造

**対象:** `/kiro:spec-design` が出力する `design.md` は、このテンプレートの全セクションを含むこと。
セクションを省略したまま `/kiro:spec-tasks` に進まない。

---

## 事前チェック（spec-design 開始前）

```
□ .kiro/steering/product.md に {{GAME_NAME}} が含まれていない（初期化済み）
□ .kiro/steering/architecture.md に {{DIMENSION}} が含まれていない（初期化済み）
□ docs/architecture/initial-decisions.md の Physics Layer / InputMap / GameState が決定済み
□ requirements.md がユーザーに承認済み
```

未完了の項目がある場合は **実装を停止してユーザーに確認する**。

---

## テンプレート（以下を design.md にコピーして埋める）

```markdown
# Design: {機能名}

## 概要

{この設計が解決する問題と実装アプローチを1〜3文で説明}

---

## ファイル配置計画

| ファイルパス | レイヤー | 行数上限 | 内容 |
|------------|--------|---------|------|
| `autoloads/{name}.gd` | Application | 150 | {状態管理 + EventBus emit のみ} |
| `scripts/utils/{name}.gd` | Domain | 80 | {純粋関数・副作用なし} |
| `scenes/{category}/{name}.tscn` + `.gd` | Presentation | 100 | {UI接続・シグナル emit のみ} |
| `tests/unit/test_{name}.gd` | Test | 200 | {GUT テスト} |

> 新規 Autoload を追加する場合: `project.godot` の [autoload] セクションへの挿入位置も記載する

---

## アーキテクチャ制約チェック

実装前にこの設計が以下を満たしているか確認する。

```
□ Autoload は EventBus 経由でのみ他Autoload と通信する（直接 call() しない）
□ scenes/ スクリプトにビジネスロジックを書かない（Autoload に移す）
□ scripts/utils/ は副作用なし（ファイルI/O・状態更新をしない）
□ 全変数・パラメータ・戻り値に型アノテーション
□ print() を使わない（Logger を使う）
□ get_node("../../xxx") のハードコードパスを使わない
□ 新規ファイルの行数が上限以内か
□ 新規 Autoload には _exit_tree() でシグナル切断を実装する
```

---

## テスト要件

| ファイル | テスト必須 | テスト対象 |
|---------|----------|----------|
| `autoloads/{name}.gd` | **必須** | 正常系・異常系・境界値 (各3件以上) |
| `scripts/utils/{name}.gd` | **必須** | 全パブリック関数 |
| `scenes/{name}.gd` | 任意 | ロジックは Autoload に切り出してそこをテスト |

テスト不可領域（`_process`・Tween・物理衝突）は手動確認とし、`tasks.md` の該当タスクに記録する。

---

## EventBus の変更

新しいシグナルを追加する場合は以下を記載する。
追加しない場合は「変更なし」と明記する。

| シグナル名 | パラメータ | 発行者 | 購読者 | 命名パターン |
|-----------|----------|--------|--------|-------------|
| `{signal_name}` | `{type}` | `{autoload}` | `{scene/autoload}` | `[名詞]_[過去分詞]` |

> 命名規則: `docs/core/state-management.md` の「シグナル命名パターン」を参照

---

## データフロー（ASCII図）

{ユーザー操作からデータが流れる経路を示す}

```
例:
ユーザー操作（ボタン押下）
  → scenes/ui/hud.gd: button.pressed.emit()
    → EventBus.save_requested.emit()
      → autoloads/save_manager.gd: save_game()
        → EventBus.save_completed.emit(success)
          → scenes/ui/hud.gd: _on_save_completed(success) → 表示更新
```

---

## セーブデータへの影響

セーブデータのフィールドを追加・変更する場合は以下を記載する。
変更しない場合は「変更なし」と明記する。

| section | key | 型 | 変更内容 | SAVE_VERSION の更新要否 |
|---------|-----|----|---------|----------------------|
| | | | | |

> セーブスキーマ設計 → `docs/architecture/save-schema.md` を参照

---

## 実装順序（tasks.md のたたき台）

1. `{最初に作るファイル}` — {内容}（テスト: 必須/任意）
2. `{次に作るファイル}` — {内容}（テスト: 必須/任意）
3. `{UIシーン}` — {内容}（テスト: 任意）
4. 手動確認: {ゴールデンパスの操作手順}
```

---

## 記入例（スコア表示パネル追加）

```markdown
# Design: スコア表示パネル

## 概要
ゲームプレイ中にリアルタイムでスコアを表示するHUDパネルを追加する。
GameManager がスコアを管理し、EventBus 経由で HUD に通知する。

---

## ファイル配置計画

| ファイルパス | レイヤー | 行数上限 | 内容 |
|------------|--------|---------|------|
| `autoloads/game_manager.gd` | Application | 150 | score_changed シグナル追加・add_score() 拡張 |
| `autoloads/event_bus.gd` | Application | 150 | score_changed シグナル定義追加 |
| `scenes/ui/score_panel.tscn` + `.gd` | Presentation | 100 | EventBus.score_changed を購読してラベル更新 |
| `tests/unit/test_game_manager.gd` | Test | 200 | add_score() の正常系・境界値テスト追加 |

---

## アーキテクチャ制約チェック

```
✅ GameManager は EventBus.score_changed を emit するだけ
✅ scenes/ui/score_panel.gd はシグナルを受けて表示更新するだけ
✅ 全変数・関数に型アノテーション
✅ print() なし → Logger を使用
```

---

## テスト要件

| ファイル | テスト必須 | テスト対象 |
|---------|----------|----------|
| `autoloads/game_manager.gd` | **必須** | add_score() 正常系・負の値・0 |
| `scenes/ui/score_panel.gd` | 任意 | ロジックは game_manager にないため skip |

---

## EventBus の変更

| シグナル名 | パラメータ | 発行者 | 購読者 |
|-----------|----------|--------|--------|
| `score_changed` | `new_score: int` | GameManager | ScorePanel |

---

## データフロー

```
プレイヤーがコインを踏む
  → scenes/game/player.gd: EventBus.sfx_play_requested.emit("coin")
    → EventBus.item_collected.emit("coin", 100)
      → autoloads/game_manager.gd: add_score(100) → score_changed.emit(new_score)
        → scenes/ui/score_panel.gd: _on_score_changed(new_score) → label.text = str(new_score)
```

---

## セーブデータへの影響

変更なし（スコアはゲームオーバー時に high_score として保存済み）

---

## 実装順序

1. `autoloads/event_bus.gd` — score_changed シグナル追加（テスト: なし）
2. `autoloads/game_manager.gd` — score_changed emit 追加（テスト: **必須**）
3. `scenes/ui/score_panel.tscn` + `.gd` — HUDパネル実装（テスト: 任意）
4. 手動確認: ゲーム開始 → コイン取得 → スコアが HUD に表示されること
```
