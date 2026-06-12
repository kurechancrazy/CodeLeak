# Linting — gdtoolkit・pre-commit・CI 設定

## gdtoolkit

gdtoolkit は `gdlint`（Linter）と `gdformat`（Formatter）を提供する。

```bash
# インストール
pip3 install gdtoolkit

# Lint チェック
gdlint scripts/ autoloads/

# Format チェック（差分表示）
gdformat --check scripts/ autoloads/

# Format 適用
gdformat scripts/ autoloads/
```

---

## gdlint の主なルール

| ルール | 内容 |
|--------|------|
| `function-name` | 関数名は snake_case |
| `class-name` | クラス名は PascalCase |
| `max-line-length` | 1行 100文字以内 |
| `max-file-lines` | デフォルト 1000行（要設定変更） |
| `no-elif-return` | return 後の elif を禁止 |
| `unnecessary-pass` | 不要な pass を禁止 |

---

## .gdlintrc 設定

プロジェクトルートに配置する。

```ini
# .gdlintrc
[gdlint]
max-line-length = 100
max-file-lines = 500
disable = ["no-elif-return"]  # プロジェクトに合わせて調整
```

---

## Git フック設定

### .githooks/pre-commit

```bash
#!/bin/bash
set -e

echo "🔍 Running gdlint..."
gdlint scripts/ autoloads/ || { echo "❌ gdlint failed"; exit 1; }

echo "🔧 Checking gdformat..."
gdformat --check scripts/ autoloads/ || {
    echo "❌ gdformat: フォーマットが必要なファイルがあります。"
    echo "   gdformat scripts/ autoloads/ を実行してください。"
    exit 1
}

echo "✅ Lint & Format checks passed"
```

### .githooks/pre-push

```bash
#!/bin/bash
set -e

echo "🧪 Running GUT tests..."
godot --headless -s addons/gut/gut_cmdln.gd \
    -gdir=tests/unit \
    -gexit \
    -glog=2 || { echo "❌ Tests failed"; exit 1; }

echo "✅ All tests passed"
```

### フックを有効化

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
chmod +x .githooks/pre-push
```

---

## CI（GitHub Actions）設定

`.github/workflows/ci.yml` を参照。
CI では以下を実行する:
1. gdlint チェック
2. gdformat --check
3. GUT テスト（ヘッドレスモード）
4. エクスポート確認（オプション）
