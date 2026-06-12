# Storage — セーブデータ・設定永続化

## ストレージの選択基準

| データ種類 | 保存先 | API |
|----------|--------|-----|
| ゲームの進行・スコア | `user://save_data.cfg` | `SaveManager.save_game()` |
| 設定（音量・言語） | `user://settings.cfg` | `SaveManager.save_settings()` |
| 機密データ（購入状態） | 暗号化ファイル | `docs/data/security.md` 参照 |
| セッション内の一時データ | Autoload の var | 保存不要 |

---

## SaveManager の使い方

```gdscript
# ✅ セーブ（EventBus 経由）
EventBus.save_requested.emit()

# ✅ ロード（EventBus 経由）
EventBus.load_requested.emit()

# ✅ 直接呼び出し（main.gd の初期化時のみ）
SaveManager.load_game()

# ✅ カスタムデータの保存・読み込み
SaveManager.set_value("player", "level", 5)
var level: int = SaveManager.get_value("player", "level", 1)
SaveManager.save_game()  # 明示的に保存
```

---

## ConfigFile の構造

```ini
; user://save_data.cfg の例
[player]
high_score=1500
level=3
total_play_time=7200.0

[meta]
saved_at="2026-06-07T12:34:56"
save_version=1
```

---

## セーブデータのバージョン管理

セーブデータの構造変更時はバージョン番号でマイグレーションする。

```gdscript
# autoloads/save_manager.gd に追加
const SAVE_VERSION: int = 1

func _migrate_if_needed() -> void:
    var version: int = _save_config.get_value("meta", "save_version", 0)
    if version < 1:
        _migrate_v0_to_v1()
    _save_config.set_value("meta", "save_version", SAVE_VERSION)

func _migrate_v0_to_v1() -> void:
    # v0 → v1 の変更: high_score → player.high_score に移動
    var old_score: int = _save_config.get_value("game", "score", 0)
    _save_config.set_value("player", "high_score", old_score)
    _save_config.erase_section_key("game", "score")
    Logger.info("Migrated save from v0 to v1")
```

---

## ファイルパスの規則

| 用途 | パス |
|------|------|
| セーブデータ | `user://save_data.cfg` |
| 設定 | `user://settings.cfg` |
| ログファイル | `user://logs/game.log` |
| スクリーンショット | `user://screenshots/` |

`user://` は OS によって異なる実際のパスにマッピングされる:
- Windows: `%APPDATA%\Godot\app_userdata\{GameName}\`
- macOS: `~/Library/Application Support/Godot/app_userdata/{GameName}/`
- Linux: `~/.local/share/godot/app_userdata/{GameName}/`
