# Observability — ログ設計・イベント分析

## Logger Autoload の使い方

```gdscript
# ✅ 本番でも残るログ（Logger 経由）
Logger.info("scene_loaded", {"path": scene_path})
Logger.warn("Low memory", {"available_mb": OS.get_static_memory_usage() / 1024 / 1024})
Logger.error("Save failed", {"error": error_code, "path": save_path})

# ✅ デバッグビルドのみ出力
Logger.debug("raw_collision_data", {"data": collision_result})

# ❌ 本番コードに print() を残す（禁止）
print("item saved")
```

---

## ログレベルの選択基準

| レベル | 用途 | 本番での出力 |
|--------|------|-----------|
| `Logger.debug()` | 開発時の詳細情報 | しない |
| `Logger.info()` | 重要なイベント（シーン遷移・セーブ等） | する |
| `Logger.warn()` | 異常ではないが注意が必要 | する（push_warning） |
| `Logger.error()` | エラー・失敗 | する（push_error） |

---

## イベント分析（Analytics）

外部分析ツールを使う場合は Logger の拡張として実装する。

```gdscript
# autoloads/logger.gd に追加
func track_event(event_name: String, params: Dictionary = {}) -> void:
    # analytics ツールへの送信（オプション）
    info("analytics_event", params.merged({"event": event_name}))
    # 例: Firebase Analytics、GameAnalytics 等
    # _analytics_client.log_event(event_name, params)
```

---

## パフォーマンス計測

```gdscript
# ✅ Godot の組み込みプロファイラーを使う
# デバッグモードで起動: godot --debug

# ✅ スクリプトからパフォーマンスを計測
func _process(_delta: float) -> void:
    if OS.is_debug_build():
        var fps: float = Engine.get_frames_per_second()
        if fps < 30.0:
            Logger.warn("Low FPS", {"fps": fps})
```

---

## クラッシュレポート

Godot には組み込みのクラッシュレポートがない。
外部ツールを使う場合は `_notification()` でキャッチする。

```gdscript
# ✅ アプリ終了時にログをフラッシュ
func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        Logger.info("app_closing")
        SaveManager.save_game()
        get_tree().quit()
```
