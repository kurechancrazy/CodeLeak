# Godot 4 — Claude Code Instructions

---

## 【最優先】起動時の動作

**セッション開始時に必ず最初に実行すること（順序厳守・例外なし）：**

1. `.kiro/steering/product.md` を読む
2. `{{GAME_NAME}}` という文字列が含まれているか確認する
   - **含まれている → 未初期化。** `_init.md` を読んで初期化フローを実行する。他の作業は一切始めない。
   - **含まれていない → 初期化済み。** 手順 3 へ進む。
3. 以下を **全て** Read ツールで開いて読む（判断不要・毎回必須）
   - `docs/workflow/development-process.md` — パス判定・DoD
   - `docs/core/architecture.md` — レイヤー設計・依存ルール
   - `docs/core/conventions.md` — GDScript・コーディング規約
   - `docs/styling/control-pitfalls.md` — Control ノードの地雷パターン
   - `docs/quality/responsiveness.md` — 入力レスポンス・もっさり防止ルール

---

## コンテキスト読み込み規則

**実装タスクを始める前に、該当ドキュメントを必ず Read ツールで開いて内容を確認してから実装する。**
「読む予定」は「読んだ」と同義ではない。1行もコードを書く前に Read ツールを実行すること。

### なぜ必須か（実例）

| 未読ドキュメント | 発生した問題 | 代償 |
|----------------|------------|------|
| `docs/styling/control-pitfalls.md` | Control の `size` と `minimum_size` を混同 → レイアウト崩壊 | 全画面修正 |
| `docs/core/state-management.md` | Autoload を直接参照し合い循環依存が発生 | アーキテクチャ見直し |
| `docs/ui/signals.md` | シグナル未接続のままシーン削除 → スタックメモリリーク | バグ調査・修正 |

### 実装前プロトコル（省略不可）

**ステップ 1: パス判定と宣言（コードに触れる前）**

```
docs/workflow/development-process.md のパス判定基準を確認し、
Quick Fix / Full Spec のどちらを使うかをユーザーに宣言する。
迷ったら Full Spec を選ぶ。宣言なしに実装を始めない。
```

**ステップ 2: タスク別必読ドキュメントの確認（判断不要）**

触れるファイル・実装内容に該当する行を全て読む。「迷ったら読む」。

| 触れるファイル / 実装内容 | 実装前に読むドキュメント |
|------------------------|----------------------|
| `scenes/` 以下を作成・変更する | `docs/core/scene-design.md` |
| `autoloads/` を変更する | `docs/core/startup.md`, `docs/core/state-management.md` |
| UIシーン（Control派生）を作成する | `docs/ui/scene-patterns.md`, `docs/ui/scene-principles.md`, `docs/styling/ux-standards.md` |
| `autoloads/save_manager.gd` を変更する | `docs/data/storage.md`, `docs/data/security.md` |
| Loading / Error / Empty 状態を実装する | `docs/ui/async-ui.md` |
| 入力フォームを実装する | `docs/ui/input-forms.md` |
| シグナル・EventBusを使う | `docs/ui/signals.md` |
| EventBusに新しいシグナルを追加する / EventBusの設計を変更する | `docs/core/event-bus-design.md` |
| ダイアログ・ポップアップを実装する | `docs/ui/popups.md` |
| 通知・トースト・フィードバック UI を実装する | `docs/ui/feedback.md` |
| Tween / AnimationPlayer を使う | `docs/styling/animation.md` |
| テーマ・スタイルを変更する | `docs/styling/ux-standards.md`, `docs/styling/theme.md` |
| テキスト・フォントを変更する | `docs/styling/typography.md` |
| タッチ / マウス / キーボード / ゲームパッド入力 | `docs/styling/platform-input.md` |
| Control ノードのレイアウトを変更する | `docs/styling/control-pitfalls.md` |
| `_process` / `_physics_process` を使う | `docs/gameplay/game-loop.md` |
| 物理演算・コリジョンを実装する（Area2D・CharacterBody 等） | `docs/gameplay/physics.md` |
| AudioManager を使う / BGM・SFX を追加する | `docs/gameplay/audio.md` |
| ノードを動的生成・破棄する（instantiate / queue_free） | `docs/gameplay/objects.md` |
| ゲーム初期設計を決定する（Physics Layer・InputMap・GameState・Autoload計画） | `docs/architecture/initial-decisions.md` |
| ジャンル別の Physics Layer・InputMap・GameState をまとめて確認する | `docs/architecture/genre-starters.md` |
| セーブデータのスキーマ・バージョン設計を行う | `docs/architecture/save-schema.md` |
| エラー処理・例外処理を実装する / ファイルI/Oやセーブ破損に対処する | `docs/core/error-handling.md` |
| デバッグ機能を実装する | `docs/architecture/debug-features.md` |
| アセット（画像・音声・モデル）を追加・管理する | `docs/workflow/asset-workflow.md` |
| リリース前QAを実施する | `docs/workflow/release-checklist.md` |
| プラットフォーム別UXを設計する（セーフエリア・解像度・Web制約） | `docs/ux/platform-ux.md` |
| ゲーム初期のUX方針を決める（難易度・色覚対応・字幕・リマップ） | `docs/ux/early-decisions.md` |
| 2D ゲームを実装する（Node2D・TileMap・CharacterBody2D・HUD） | `docs/2d/patterns.md` |
| 3D ゲームを実装する（Node3D・CharacterBody3D・Camera3D・Light） | `docs/3d/patterns.md` |
| アセット（画像・音声・3Dモデル）を追加・管理する | `docs/assets/asset-management.md` |
| Logger を使う / ログレベルを判断する | `docs/core/logging.md` |
| ログ・分析を実装する | `docs/data/observability.md` |
| 多言語対応を変更する | `docs/data/i18n.md` |
| アクセシビリティ属性を変更する | `docs/quality/accessibility.md` |
| spec-design で design.md を作成する | `docs/workflow/spec-design-template.md` |
| テストを書く（utils / autoloads の単体テスト） | `docs/quality/testing.md` |
| gdlint / gdformat を実行する・CI を設定する | `docs/quality/linting.md` |
| パフォーマンス最適化・プロファイリングを行う | `docs/quality/performance.md` |
| 開発環境のセットアップを行う | `docs/ops/dev-environment.md` |
| ゲームロジックのテストを書く（スコア・勝敗・EventBus） | `docs/gameplay/testing-game.md` |
| ゲームフィール・HUD・ポーズ・ゲームオーバー画面を実装する | `docs/gameplay/game-ux.md` |
| エクスポート・リリースを操作する | `docs/ops/operations.md` |
| 新しいプラグインを追加する | `.kiro/steering/tech.md` |
| ファイル配置・命名を決定する | `.kiro/steering/structure.md` |
| プロジェクト固有の設計方針を確認する | `.kiro/steering/architecture.md` |
| **【RPG】ドット絵のプロジェクト設定を行う（Nearest フィルタ・解像度設計）** | `docs/rpg/pixel-art-setup.md` |
| **【RPG】ターンベース戦闘システムを実装する** | `docs/rpg/battle-system.md` |
| **【RPG】フィールドマップ・ランダムエンカウントを実装する** | `docs/rpg/field-system.md` |
| **【RPG】NPC 会話・ダイアログシステムを実装する** | `docs/rpg/dialog-system.md` |
| **【RPG】RPG メニュー（アイテム・装備・ステータス）を実装する** | `docs/rpg/menu-system.md` |
| **【RPG】ジャンル初期設定（Physics Layer・InputMap・Autoload構成）を決定する** | `docs/architecture/genre-starters.md`（バンドル 5: 2D JRPG） |
| **【ジャンル共通】ジャンル一覧・除外手順を確認する** | `docs/genres/_index.md` |
| **【2D アクション】プラットフォーマーを実装する** | `docs/genres/2d-action.md` |
| **【メトロイドヴァニア】マップ状態・アビリティゲート・部屋遷移を実装する** | `docs/genres/metroidvania.md` |
| **【シューティング】弾幕・ウェーブスクリプト・ObjectPool を実装する** | `docs/genres/shmup.md` |
| **【見下ろし ARPG】8 方向移動・攻撃判定タイミング・クエストを実装する** | `docs/genres/arpg-topdown.md` |
| **【ローグライク】ラン管理・ダンジョン生成・ドロップテーブルを実装する** | `docs/genres/roguelike.md` |
| **【タワーディフェンス】グリッド配置・ウェーブ管理・タワー射撃 AI を実装する** | `docs/genres/tower-defense.md` |
| **【SRPG】グリッド移動・ターンフロー・敵 AI を実装する** | `docs/genres/srpg.md` |
| **【農業シム】ゲーム内時計・作物成長・農地グリッドを実装する** | `docs/genres/farming-sim.md` |
| **【カードゲーム】デッキ管理・カードドラッグ操作・エフェクトを実装する** | `docs/genres/card-game.md` |
| **【格闘】フレームデータ・コンボ入力バッファ・ラウンド管理を実装する** | `docs/genres/fighting.md` |
| **【2D ホラー】サニティゲージ・NavigationAgent・セーブポイント制限を実装する** | `docs/genres/horror-2d.md` |
| **【パズル】グリッド移動・Undo・アニメーション中入力無効を実装する** | `docs/genres/puzzle.md` |
| **【ビジュアルノベル】テキスト表示・選択肢・バックログを実装する** | `docs/genres/visual-novel.md` |
| **【ベルトスクロールアクション】多方向攻撃・ノックバック・スクリーンスクロールを実装する** | `docs/genres/belt-scroll-action.md` |
| **【ステルス】視野円錐・警戒ステート・音検知・隠れ場所を実装する** | `docs/genres/stealth.md` |
| **【ポイント・アンド・クリック】ホットスポット・インベントリ・動詞アクションを実装する** | `docs/genres/point-and-click.md` |
| **【落ち物パズル】重力ループ・ウォールキック回転・ライン消去を実装する** | `docs/genres/falling-puzzle.md` |
| **【マッチ3パズル】マッチ検出・カスケード・グリッド補充を実装する** | `docs/genres/match3.md` |
| **【スポーツ】ボール物理・プレイヤー切り替え・得点・試合タイマーを実装する** | `docs/genres/sports.md` |
| **【音楽・リズム】ノートスポーン・タイミング判定・コンボを実装する** | `docs/genres/rhythm.md` |
| **【サンドボックス・クラフト】ブロック採掘/設置・クラフトレシピを実装する** | `docs/genres/sandbox-craft.md` |
| **【パーティーゲーム】ミニゲームシーケンサー・プレイヤー登録・スコア集計を実装する** | `docs/genres/party-game.md` |
| **【クイズゲーム】QuizQuestion Resource・タイマー・正誤判定を実装する** | `docs/genres/quiz.md` |
| **【放置・クリッカー】通貨ループ・自動生産・オフライン収益を実装する** | `docs/genres/idle-clicker.md` |
| **【3D プラットフォーマー】CharacterBody3D・SpringArm・コヨーテタイムを実装する** | `docs/genres/3d-platformer.md` |
| **【3D アクション】ロックオンカメラ・コンボ・NavigationAgent3D を実装する** | `docs/genres/3d-action.md` |
| **【FPS/TPS】マウスカメラ・Hitscan 射撃・武器システムを実装する** | `docs/genres/fps-tps.md` |
| **【3D 探索】インタラクト・建物入退場・PathFollow3D 乗り物を実装する** | `docs/genres/exploration-3d.md` |
| **【3D RPG】昼夜サイクル・エリアストリーミング・クエスト管理を実装する** | `docs/genres/3d-rpg.md` |
| **【3D ストラテジー】俯瞰カメラ・ボックス選択・NavigationAgent3D 命令を実装する** | `docs/genres/3d-strategy.md` |
| **【3D レース】VehicleBody3D・チェックポイント・ラップタイムを実装する** | `docs/genres/3d-race.md` |
| **【3D ホラー】視線チェック・フラッシュライト・NavigationAgent3D を実装する** | `docs/genres/3d-horror.md` |
| **【3D パズル】RigidBody3D 把持・ギミック連動・ヒントシステムを実装する** | `docs/genres/3d-puzzle.md` |
| **【共通】ウェーブ進行（シューティング・タワーディフェンス）を実装する** | `docs/genres/shmup.md`, `docs/genres/tower-defense.md` |
| **【共通】ゲーム内時計・昼夜サイクルを実装する** | `docs/genres/farming-sim.md`, `docs/genres/3d-rpg.md` |
| **【共通】コンボ入力バッファを実装する** | `docs/genres/fighting.md`, `docs/genres/3d-action.md` |
| **【共通】3D ゲームで弾・投射物を撃つ（三人称・非 FPS）** | `docs/genres/fps-tps.md`, `docs/genres/3d-action.md` |
| **【共通】実績・アンロック・統計を実装する（ProgressManager）** | `docs/genres/_index.md` |
| **【共通】グリッド座標変換・移動範囲計算を実装する（GridUtils）** | `docs/genres/srpg.md`, `docs/genres/tower-defense.md` |
| **【共通】重み付き乱数・シャッフルを実装する（RngUtils）** | `docs/genres/roguelike.md`, `docs/genres/shmup.md` |

---

## 禁止事項（即時適用・例外なし）

### GDScript — 型
- 型アノテーションなし **禁止** → 全変数・パラメータ・戻り値に型を明示
- `var x = something as Type` の強制キャスト **禁止** → `is` チェック + 型ガードで代替
- `Variant` を過度に使う **禁止** → 具体的な型を使う（やむを得ない場合のみ）

### GDScript — パターン
- `print()` を本番コードに残す **禁止** → `Logger.info()` / `Logger.error()` を使う
- `get_node("../../SomeNode")` のハードコードパス **禁止** → `@onready var` または シグナル経由
- `_process()` 内の重い処理（ファイルI/O・複雑なループ）**禁止** → スレッドまたはキャッシュ
- `await get_tree().process_frame` をループで使う **禁止** → シグナルベースに書き直す
- グローバルスコープへの変数定義（class_nameなし）**禁止** → Autoloadまたはクラスに移す

### レスポンス・ゲームフィール（もっさり防止）
- `_process` のポーリングだけで入力受付 **禁止** → `_input()` でフラグを立て `_physics_process` で処理
- `_process` 内で `load()` / `instantiate()` を呼ぶ **禁止** → 事前ロード・ObjectPool を使う
- Tween / アニメーション中に入力を一切受け付けない設計 **禁止** → 先行入力キューを実装する
- `get_node()` / `find_child()` を `_process` で毎フレーム呼ぶ **禁止** → `@onready` で固定
- ジャンプ・攻撃にバッファ（コヨーテタイム・先行入力）を実装しない **禁止** → 必ずバッファを設ける
- 不要なノードで `_process` / `_physics_process` を動かし続ける **禁止** → `set_process(false)` で停止
- 物理移動を `_process` に書く **禁止** → 必ず `_physics_process` に書く

詳細 → `docs/quality/responsiveness.md`（起動時必読）

### アーキテクチャ
- シーンスクリプトにビジネスロジック **禁止** → Autoloadに移す
- Autoloadから別Autoloadを直接参照（循環依存）**禁止** → EventBus経由
- UIがゲームロジックを直接制御 **禁止** → シグナルで分離
- テストコードに `get_tree()` の副作用 **禁止** → モック or GUTのシーンヘルパーを使う

### ノード・シーン
- 深すぎるノード階層（5段以上）**禁止** → シーン分割で解消
- 1スクリプト500行超 **禁止** → サブスクリプトまたはシーン分割
- `get_parent()` を3段以上辿る **禁止** → シグナルまたはAutoload経由
- `find_child()` による名前検索を本番コードで使う **禁止** → `@export` または `@onready`

### ストレージ・セキュリティ
- 機密データをConfigFileに平文で保存 **禁止** → 暗号化ファイルを使う（`docs/data/security.md`）
- APIキー・シークレットをソースコードに直書き **禁止** → 環境変数またはサーバーサイド

---

## 技術スタック（変更・追加はユーザー確認必須）

| 役割 | 採用技術 |
|------|---------|
| エンジン | Godot 4.4 |
| 言語 | GDScript 2.0（typed） |
| テスト | GUT 4.x（Godot Unit Testing） |
| Lint / Format | gdtoolkit（gdlint + gdformat） |
| CI | GitHub Actions（barichello/godot-ci） |
| セーブデータ | SaveManager（ConfigFile + JSON） |
| オーディオ | AudioManager（AudioStreamPlayer プール） |
| シーン管理 | SceneManager Autoload |
| グローバルイベント | EventBus Autoload |
| ログ | Logger Autoload |
| エクスポート | Godot Export Templates |

新しいプラグイン・アドオンが必要な場合は **実装前にユーザーに確認する**。

---

## テスト必須ルール（省略不可・例外なし）

**テストは実装の一部である。「後でテストを書く」は存在しない。**

### タスク完了の定義

1タスクは以下が**全て**満たされて初めて「完了」とする:

```
□ 実装コードを書いた
□ 対応テストファイルを書いた（utils / autoloads のロジックは必須）
□ GUT → 全テスト PASS（gut -d tests/）
□ gdlint scripts/ autoloads/ → エラー 0 件
□ gdformat --check scripts/ autoloads/ → 差分 0
□ UI/UX チェックリスト全項目確認済み（docs/styling/ux-standards.md を Read して確認）
```

### 新規ファイルのテスト必須対応表

| 新規作成するファイル | 必須テストファイル |
|------------------|-----------------|
| `scripts/utils/foo.gd` | `tests/unit/test_foo.gd` |
| `autoloads/foo_manager.gd` のロジック部分 | `tests/unit/test_foo_manager.gd` |
| `scenes/ui/foo.tscn` + スクリプト | テスト任意（ロジックをAutoloadに切り出す） |

### テストの3区分（全て必須）

| 区分 | 内容 |
|------|------|
| 正常系 | 期待する入力で期待する出力が得られる |
| 異常系 | エラー・不正入力が適切に処理される |
| 境界値 | `0`, `null`, `""`, 空配列, 最大値で壊れない |

**詳細なテスト設計規則 → `docs/quality/testing.md` を Read ツールで開いて確認してから書く**

---

## 実装ワークフロー（順序厳守）

詳細は `docs/workflow/development-process.md` を参照。

### Quick Fix パス（簡易改修）

以下の**全条件**を満たす場合のみ使用可。1つでも外れたら Full Spec へ。

```
□ 既存ファイルの修正のみ（新規ファイルを作らない）
□ 設計・API・状態管理の変更なし
□ 影響範囲が 1〜3 ファイル以内
□ 実装内容を着手前にほぼ確定できる（設計判断・選択肢の検討が不要）
□ 新しいプラグイン・アドオンを追加しない
```

詳細な判定早見表 → `docs/workflow/development-process.md`

### Full Spec パス（新機能・設計変更）

```
/kiro:spec-init "機能名"
  ↓
/kiro:spec-requirements → ユーザー承認待ち
  ↓
/kiro:spec-design       → ユーザー承認待ち（テスト要件を含むこと）
  ↓
/kiro:spec-tasks        → ユーザー承認待ち
  ↓
/kiro:spec-impl         → 各タスク完了 = 実装 + テスト PASS
```

### DoD（両パス共通・コミット前に全チェック）

```
□ 実装コードを書いた
□ 対応テストファイルを書いた（utils / autoloads は必須）
□ GUT → 全テスト PASS
□ gdlint → エラー 0 件
□ gdformat --check → 差分 0
□ /godot-spec-check → Critical なし
□ print() を本番コードに残していない
□ 型アノテーションのない変数・パラメータ・戻り値がない
□ UI/UX チェックリスト全項目確認済み
```

---

## 判断に迷ったとき

1. 該当ドキュメントを読む（上記テーブル参照）
2. それでも判断できない場合は **ユーザーに確認する**
3. 「たぶんこれでいい」という推測で実装しない
