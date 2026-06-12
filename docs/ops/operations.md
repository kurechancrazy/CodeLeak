# Operations — ビルド・エクスポート・リリース

## エクスポートの前提

Godot のエクスポートには **Export Templates** が必要。
エディタ → Editor → Manage Export Templates → Download Templates

---

## エクスポートプロファイルの設定

```
Project → Export → Add プラットフォームを追加:

Windows Desktop:
- Architecture: x86_64
- Debug テンプレートも設定

macOS:
- codesign が必要（App Store 配布の場合）

Android:
- Android SDK のパスを設定
- keystore ファイルを用意

iOS:
- Xcode が必要（macOS のみ）
- Apple Developer アカウントが必要

HTML5/Web:
- スレッドを有効化する場合は CORS ヘッダーが必要
```

---

## エクスポートコマンド

```bash
# コマンドラインエクスポート
# Windows
godot --export-release "Windows Desktop" export/windows/game.exe

# macOS
godot --export-release "macOS" export/macos/game.dmg

# Web
godot --export-release "HTML5" export/web/index.html

# Android
godot --export-release "Android" export/android/game.apk
```

---

## バージョン管理

```ini
; project.godot に追加
[application]
config/version="1.0.0"
```

```gdscript
# バージョン番号を取得
var version: String = ProjectSettings.get_setting("application/config/version", "1.0.0")
```

セマンティックバージョニング（MAJOR.MINOR.PATCH）を使う:
- MAJOR: 後方互換性のない変更（セーブデータの破壊的変更等）
- MINOR: 後方互換性のある機能追加
- PATCH: バグ修正

---

## リリースチェックリスト

```
□ project.godot の config/version を更新した
□ デバッグログが本番に混入していない（Logger.debug のみで使用）
□ 開発用のチートコード・デバッグ機能を無効化した
□ 全プラットフォームで動作確認した
□ セーブ・ロードが正常に動作することを確認した
□ エクスポートテンプレートが最新バージョンか確認した
□ CHANGELOG.md / git tag を作成した
```

---

## Web エクスポートのTips

```
□ SharedArrayBuffer が必要な場合（スレッド使用時）は CORS ヘッダーを設定
□ HTTP サーバーで配信（file:// プロトコルでは動作しない）
□ itch.io の場合は「SharedArrayBuffer Support」を有効化

itch.io での配信:
1. HTML5 エクスポートを zip に圧縮
2. itch.io にアップロード
3. "This file will be played in the browser" を選択
4. "SharedArrayBuffer Support" を有効化
```

---

## モバイルエクスポートのTips

**Android:**
```
□ minSdkVersion: 24（Godot 4 の最低要件）
□ keystore を作成して project.godot に登録
□ Google Play の審査要件を確認
```

**iOS:**
```
□ Xcode 最新版が必要
□ Apple Developer Program に加入
□ Provisioning Profile と Signing Certificate を設定
□ App Store Connect でアプリを登録
```

---

## CI でのエクスポート確認

`.github/workflows/ci.yml` でエクスポートビルドの成功を確認する（`docs/quality/linting.md` 参照）。
