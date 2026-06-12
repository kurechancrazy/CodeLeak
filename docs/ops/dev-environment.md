# Dev Environment — 開発環境構築

## 必要なツール

| ツール | 確認コマンド | 必要バージョン | 入手先 |
|--------|-------------|--------------|--------|
| Godot 4 | `godot --version` | 4.4.x | godotengine.org |
| Python | `python3 --version` | 3.8+ | python.org |
| gdtoolkit | `gdlint --version` | 最新 | pip install gdtoolkit |
| Git | `git --version` | 2.x | git-scm.com |

---

## macOS セットアップ

```bash
# Homebrew でインストール
brew install python git

# Godot 4 をダウンロードしてインストール
# https://godotengine.org/download/macos/ からダウンロード
# .app を /Applications/ に移動

# Godot をコマンドラインから使えるようにエイリアス設定
echo 'alias godot="/Applications/Godot.app/Contents/MacOS/Godot"' >> ~/.zshrc
source ~/.zshrc

# gdtoolkit インストール
pip3 install gdtoolkit

# バージョン確認
godot --version
gdlint --version
```

---

## Windows セットアップ

```powershell
# winget でインストール
winget install Python.Python.3
winget install Git.Git

# Godot 4 をダウンロード
# https://godotengine.org/download/windows/ からダウンロード
# PATH に Godot.exe のディレクトリを追加

# gdtoolkit インストール
pip install gdtoolkit
```

---

## Linux セットアップ

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install python3 python3-pip git

# Godot 4 をダウンロード
wget https://downloads.tuxfamily.org/godotengine/4.4/Godot_v4.4-stable_linux.x86_64.zip
unzip Godot_v4.4-stable_linux.x86_64.zip
sudo mv Godot_v4.4-stable_linux.x86_64 /usr/local/bin/godot
chmod +x /usr/local/bin/godot

pip3 install gdtoolkit
```

---

## エディタ設定（推奨）

### Godot エディタ設定

```
Editor Settings:
- Text Editor / Indent / Type: Spaces
- Text Editor / Indent / Size: 4（GDScriptのデフォルト）
- Text Editor / Completion / Add Type Hints: true  ← 重要
- Text Editor / Completion / Auto Brace Complete: true
```

### VS Code 拡張（任意）

- **godot-tools**: GDScript の補完・定義ジャンプ
- **GDScript**: シンタックスハイライト

---

## GUT プラグインのインストール

```bash
# 方法1: Godot Asset Library（推奨）
# エディタ → AssetLib → "GUT" で検索 → インストール

# 方法2: Git clone
git clone https://github.com/bitwes/Gut.git addons/gut

# インストール後
# Project → Project Settings → Plugins → GUT → Enable
```

---

## よくあるセットアップ問題

**Q. `godot: command not found` が出る場合（macOS）**
```bash
echo 'alias godot="/Applications/Godot.app/Contents/MacOS/Godot"' >> ~/.zshrc
source ~/.zshrc
```

**Q. gdlint が ImportError を出す場合**
```bash
pip3 install --upgrade gdtoolkit
```

**Q. GUT テストが "addons/gut not found" を出す場合**
Godot エディタで GUT プラグインを有効化していない可能性。
Project Settings → Plugins → GUT → Enable を確認。
