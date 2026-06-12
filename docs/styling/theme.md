# Theme — テーマ設定・ダークモード対応

## Godot のテーマシステム

テーマは `resources/themes/` に `.tres` ファイルとして保存し、プロジェクト設定で適用する。

```
Project Settings → General → GUI → Theme → Custom Theme
→ resources/themes/default.tres
```

---

## テーマの基本設定

```gdscript
# resources/themes/ でインスペクターを使って設定する
# 主要な設定項目:

# Button
# - Normal: 通常状態のスタイルボックス
# - Hover: ホバー状態
# - Pressed: 押下状態
# - Disabled: 無効状態
# - Font Color

# Label
# - Font Color
# - Font Size

# LineEdit
# - Normal / Focus スタイルボックス
```

---

## カラーパレットの管理

プロジェクトで使用するカラーは `resources/themes/colors.gd` に集約する。

```gdscript
# resources/themes/colors.gd
class_name GameColors
extends RefCounted

const PRIMARY: Color = Color(0.2, 0.6, 1.0)        # #3399FF
const PRIMARY_DARK: Color = Color(0.1, 0.4, 0.8)   # #1A66CC
const SECONDARY: Color = Color(1.0, 0.7, 0.0)       # #FFB300
const DANGER: Color = Color(0.9, 0.2, 0.2)          # #E63333
const SUCCESS: Color = Color(0.2, 0.8, 0.4)         # #33CC66
const TEXT_PRIMARY: Color = Color(1.0, 1.0, 1.0)    # #FFFFFF
const TEXT_SECONDARY: Color = Color(0.7, 0.7, 0.7)  # #B3B3B3
const BACKGROUND: Color = Color(0.1, 0.1, 0.15)     # #1A1A26
```

ハードコードされたカラー値（`Color(0.2, 0.6, 1.0)` 等）を直接シーンに書かない。
必ず `GameColors.PRIMARY` 等を使う。

---

## ダークモード対応

Godot 4 はシステムのダークモード設定を `DisplayServer.is_dark_mode()` で取得できる。

```gdscript
# autoloads/game_manager.gd に追加する場合
var is_dark_mode: bool = false

func _ready() -> void:
    is_dark_mode = DisplayServer.is_dark_mode()
    DisplayServer.dark_mode_changed.connect(_on_dark_mode_changed)

func _on_dark_mode_changed() -> void:
    is_dark_mode = DisplayServer.is_dark_mode()
    EventBus.settings_changed.emit("dark_mode", is_dark_mode)
```

---

## フォントの設定

フォントは `assets/fonts/` に配置し、テーマで設定する。

```
assets/fonts/
├── NotoSansJP-Regular.ttf
├── NotoSansJP-Bold.ttf
└── NotoSansJP-Black.ttf
```

```gdscript
# スクリプトからフォントを変更する場合
var font: FontFile = load("res://assets/fonts/NotoSansJP-Bold.ttf")
label.add_theme_font_override("font", font)
label.add_theme_font_size_override("font_size", 24)
```
