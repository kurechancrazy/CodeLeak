# セットアップ手順

**対象:** Godot 4.4+ / GDScript 2.0

---

## 0. 開発環境の準備（初回のみ）

**詳細手順 → `docs/ops/dev-environment.md` を参照**

以下が揃っているか確認する。

| ツール | 確認コマンド | 必要バージョン |
|--------|-------------|--------------|
| Godot 4 | `godot --version` | 4.4.x |
| Python | `python3 --version` | 3.8+ |
| gdtoolkit | `gdlint --version` | 最新 |
| Git | `git --version` | 2.x |
| GitHub CLI（任意） | `gh --version` | 最新 |

```bash
# gdtoolkit をインストール
pip3 install gdtoolkit
```

---

## 1. テンプレートをコピー

このテンプレートディレクトリの中身を **プロジェクトルート** にコピーする。

```bash
TEMPLATE=/path/to/GodotDefault
PROJECT=/path/to/your-game

cp -r "$TEMPLATE/." "$PROJECT/"
```

または新規プロジェクトとして使う場合:

```bash
git clone <this-repo> your-game-name
cd your-game-name
git remote remove origin
git init  # 新しいリポジトリとして初期化する場合
```

---

## 2. Godot エディタでプロジェクトを開く

```bash
# Godot GUI でプロジェクトを開く
godot project.godot
```

または Godot エディタの **Project Manager** から `Import` → `project.godot` を選択。

---

## 3. GUT（テストプラグイン）をインストール

GUT は Godot のテストフレームワーク。Godot Asset Library からインストールする。

### GUI でのインストール（推奨）

1. Godot エディタ上部の `AssetLib` タブを開く
2. `GUT` で検索
3. `Gut - Godot Unit Testing` をインストール
4. `Project → Project Settings → Plugins → GUT` を **Enable** にする

### 手動インストール

```bash
# GUTリポジトリをaddons/gutにクローン
git clone https://github.com/bitwes/Gut.git addons/gut
```

その後、Godot エディタで `Project → Project Settings → Plugins → GUT` を Enable にする。

### project.godot の更新

GUT を有効化すると `project.godot` の `[editor_plugins]` が自動更新される:

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

---

## 4. Git フックを設定する

pre-commit フックでコミット前にLint・Formatを自動実行する。

```bash
# .githooks/ を Git フックディレクトリとして使う
git config core.hooksPath .githooks

# フックファイルに実行権限を付与
chmod +x .githooks/pre-commit
chmod +x .githooks/pre-push
```

| フック | タイミング | 内容 |
|--------|----------|------|
| pre-commit | `git commit` | gdlint + gdformat チェック |
| pre-push | `git push` | GUT 全テスト実行（失敗するとpushブロック） |

---

## 5. project.godot のプレースホルダーを確認

`project.godot` の以下を埋める（Claude Code の初期化フローでも設定される）:

| プレースホルダー | 設定すべき値 |
|---------------|------------|
| `{{GAME_NAME_EN}}` | ゲームの英語名 |
| `{{GAME_DESCRIPTION}}` | ゲームの説明 |

---

## 6. Claude Code を起動する

```bash
claude
```

起動すると Claude Code が自動的に:
1. `CLAUDE.md` を読む
2. `.kiro/steering/product.md` の `{{GAME_NAME}}` を検出する
3. `_init.md` の初期化フローを開始する

質問に答えるだけで `product.md`・`architecture.md`・`project.godot` が書き換えられ、プロジェクト固有の設定が完了する。

---

## 7. ディレクトリ構成

```
your-game/
├── project.godot              ← Godot プロジェクト設定
├── CLAUDE.md                  ← Claude Code が毎回自動読込
├── _init.md                   ← 初回のみ実行する初期化フロー
├── SETUP.md                   ← この手順書
├── icon.svg                   ← アプリアイコン
├── .githooks/
│   ├── pre-commit             ← gdlint + gdformat
│   └── pre-push               ← GUT 全テスト
├── .github/
│   └── workflows/
│       └── ci.yml             ← GitHub Actions CI
├── .kiro/
│   └── steering/
│       ├── product.md         ← {{PLACEHOLDER}} 状態（初期化前）
│       ├── tech.md            ← 技術スタック（固定）
│       ├── structure.md       ← ディレクトリ構成（固定）
│       └── architecture.md   ← 設計原則（一部初期化で書き換え）
├── docs/
│   ├── README.md
│   ├── workflow/
│   ├── core/
│   ├── ui/
│   ├── styling/
│   ├── data/
│   ├── quality/
│   └── ops/
├── autoloads/                 ← Autoload シングルトン
│   ├── logger.gd
│   ├── event_bus.gd
│   ├── game_manager.gd
│   ├── scene_manager.gd
│   ├── save_manager.gd
│   └── audio_manager.gd
├── scenes/                    ← .tscn シーンファイル
│   ├── main.tscn
│   ├── ui/
│   └── game/
├── scripts/                   ← 非Autoload スクリプト
│   └── utils/
├── resources/                 ← .tres / .res リソース
│   └── themes/
├── assets/                    ← メディアファイル
│   ├── audio/
│   ├── sprites/
│   └── fonts/
├── addons/                    ← プラグイン（GUT等）
└── tests/                     ← GUT テスト
    └── unit/
```

---

## よくある質問

**Q. Godot がコマンドラインから起動できない場合は？**
macOS の場合: `alias godot="/Applications/Godot.app/Contents/MacOS/Godot"` を `.zshrc` に追加。

**Q. gdtoolkit の gdlint でエラーが出る場合は？**
`docs/quality/linting.md` を参照。特に `class_name` と `tool` の扱いに注意。

**Q. GUT テストが通らない場合は？**
`docs/quality/testing.md` を参照。テストシーンの設定・GUT バージョンとの互換性を確認する。

**Q. テンプレートを更新したい場合は？**
`.kiro/steering/*.md` と `docs/*.md` を直接編集する。
`CLAUDE.md` は基本変えない（ルールの変更はユーザーの明示的な指示が必要）。

**Q. 2D・3D・UIの切り替えは？**
初期化フロー（`_init.md`）で選択する。初期化後に変更する場合は `project.godot` を直接編集し、メインシーンのノードタイプを変更する。

**Q. Web（HTML5）エクスポートが動かない場合は？**
`docs/ops/operations.md` の「WebエクスポートのTips」を参照。スレッド・AudioContext のブラウザ制限に注意。
