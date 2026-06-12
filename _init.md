# 初期化フロー

**このファイルは `.kiro/steering/product.md` に `{{GAME_NAME}}` が含まれている場合に実行する。**
初期化が完了したら通常の開発を始める。`_init.md` 自体は削除しない。

---

## 初期化ステータスの確認

初期化フローを実行する前に以下を確認すること。

```
□ .kiro/steering/product.md に {{GAME_NAME}} が含まれている → 未初期化（このファイルを実行）
□ .kiro/steering/architecture.md に {{DIMENSION}} が含まれている → 未初期化（このファイルを実行）
```

**どちらか一方でもプレースホルダーが残っている場合、`/kiro:spec-init` を含む全ての Kiro コマンドを実行しない。**
この初期化フローを完了させてから開発を始めること。

---

## Step 1: プロジェクト情報を質問する

以下を **1問ずつ順番に** 聞く。まとめて聞かない。
回答が得られたら次の質問に進む。

---

**Q1. ゲームの次元を教えてください。**

- **2D** — 横スクロール・見下ろし・パズル等
- **3D** — 3次元空間のゲーム
- **UI専用** — ノベル・カードゲーム・ボードゲーム等（Control ノード中心）

> この回答によって `project.godot` のデフォルト設定・基底シーンの種類が変わります。

---

**Q2. ゲーム名を教えてください。**
日本語名・英語名の2つ。

例の回答:
- 日本語名: 宇宙パズル
- 英語名: SpacePuzzle

---

**Q3. このゲームは何をするゲームですか？**
1〜2文で説明してください。

---

**Q4. ジャンルを教えてください。**
例: アクション / パズル / RPG / ノベル / タワーディフェンス / その他

---

**Q5. 主なターゲットユーザーは誰ですか？**
年齢層・プレイスタイルを教えてください。

例: 学生〜社会人向けのカジュアルゲーマー

---

**Q6. ターゲットプラットフォームを教えてください（複数可）。**
- PC（Windows / macOS / Linux）
- Web（HTML5）
- モバイル（iOS / Android）
- コンソール（Nintendo Switch / PlayStation / Xbox）

---

**Q7. 収益モデルを教えてください。**
- 買い切り（Steam / itch.io）
- 広告（AdMob）
- アプリ内課金
- 無料（収益化なし）
- その他

---

**Q8. 13歳未満の子供が主なターゲットですか？（Yes / No）**
COPPA・児童向け広告規制の設定に影響します。

---

## Step 2: 回答をもとにファイルを書き換える

### `.kiro/steering/product.md` のプレースホルダーを置換

| プレースホルダー | 置き換える値 |
|---------------|------------|
| `{{GAME_NAME}}` | Q2の日本語名 |
| `{{GAME_NAME_EN}}` | Q2の英語名 |
| `{{GAME_DESCRIPTION}}` | Q3の回答 |
| `{{GAME_GENRE}}` | Q4の回答 |
| `{{TARGET_USER}}` | Q5の回答 |
| `{{TARGET_PLATFORM}}` | Q6の回答（箇条書き） |
| `{{REVENUE_MODEL}}` | Q7の回答 |
| `{{IS_CHILD_GAME}}` | Q8の回答（Yes / No） |

### `project.godot` のプレースホルダーを置換

| プレースホルダー | 置き換える値 |
|---------------|------------|
| `{{GAME_NAME_EN}}` | Q2の英語名 |
| `{{GAME_DESCRIPTION}}` | Q3の回答 |

### Q1（2D/3D）に応じた `project.godot` の追加設定

**2D の場合、`[application]` セクションに追加:**
```ini
config/features=PackedStringArray("4.4", "GL Compatibility")
```
（デフォルトのまま）

**3D の場合、`[display]` セクションを変更:**
```ini
window/size/viewport_width=1920
window/size/viewport_height=1080
```
また `[rendering]` を Forward+ に変更:
```ini
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="mobile"
```

**UI専用の場合、`[display]` を変更:**
```ini
window/size/viewport_width=1080
window/size/viewport_height=1920
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

### `.kiro/steering/architecture.md` のプレースホルダーを置換

| プレースホルダー | 置き換える値 |
|---------------|------------|
| `{{DIMENSION}}` | Q1の回答（2D / 3D / UI専用） |
| `{{CHILD_DIRECTED}}` | Q8が Yes → `AdMob に tagForChildDirectedTreatment: true を設定すること（COPPA必須）。外部リンク・チャット・UGC機能は禁止。` / No → `COPPA対応は不要。GDPR基本同意フローを実装すること。` |

---

## Step 2.5: アーキテクチャ・UX 方針の決定

**ファイル書き換え完了後、実装を始める前に以下を実施する。**

### 2.5-A. アーキテクチャ決定（必須）

`docs/architecture/initial-decisions.md` を Read ツールで開き、以下をユーザーと確認・決定する：

1. **Physics Layer 設計** — ゲームジャンルに合ったレイヤー構成を選び、`project.godot` に追記する
2. **Input Map 定義** — ジャンル別推奨アクション名を確認し、`project.godot` に追記する
3. **GameState 拡張** — ジャンルに合った state を `autoloads/game_manager.gd` の enum に追加する
4. **Autoload 追加計画** — ゲームに必要な Autoload を事前にリストアップし、初期化順序を確認する
5. **ポーズ範囲の決定** — Process Mode 設定表を確認し、何を止めるかを決める

### 2.5-B. セーブスキーマ設計（必須）

`docs/architecture/save-schema.md` を Read ツールで開き、以下を決定する：

- セーブフィールド定義テンプレートを埋める（保存対象データの一覧）
- GameSettings を Resource クラス化するかどうか決める

### 2.5-C. UX 方針の確認（必須）

`docs/ux/early-decisions.md` を Read ツールで開き、以下をユーザーに確認して `.kiro/steering/product.md` に追記する：

- ターゲット層・難易度方針・リトライ形式
- 色覚多様性対応レベル
- 字幕・音声依存度の確認
- 操作カスタマイズの有無

### 2.5-D. デバッグ機能の確認（任意）

`docs/architecture/debug-features.md` を Read ツールで開き、必要なデバッグ機能をリストアップする。

---

## Step 3: 初期化完了を報告する

以下のメッセージで完了を伝える：

```
初期化が完了しました。

ゲーム名: {GAME_NAME}
ジャンル: {GAME_GENRE}
次元: {DIMENSION}
ターゲットプラットフォーム: {TARGET_PLATFORM}

開発を始める準備ができています。
最初の機能を実装する場合は /kiro:spec-init "機能名" を使ってください。
```

### 次元別の必読ドキュメント案内

**Q1 が 2D の場合、以下を追加で伝える：**
```
2D ゲームを実装する前に必ず以下を読んでください：
- docs/2d/patterns.md — シーン階層・TileMap・Camera2D・HUD の設計ルール
- docs/gameplay/physics.md — CharacterBody2D・Area2D・コリジョン設定
- docs/gameplay/game-loop.md — _process vs _physics_process の使い分け
```

**Q1 が 3D の場合、以下を追加で伝える：**
```
3D ゲームを実装する前に必ず以下を読んでください：
- docs/3d/patterns.md — シーン階層・CharacterBody3D・Camera3D・ライティング
- docs/gameplay/physics.md — 物理演算・コリジョン設定（2D/3D共通事項）
- docs/gameplay/game-loop.md — _process vs _physics_process の使い分け
```

**Q1 が UI専用 の場合、以下を追加で伝える：**
```
UI専用ゲームを実装する前に必ず以下を読んでください：
- docs/ui/scene-patterns.md — Control シーンの設計パターン
- docs/styling/control-pitfalls.md — Control ノードの地雷パターン
- docs/ui/signals.md — UI シグナルの接続パターン
```

その後、ユーザーからの指示を待つ。
