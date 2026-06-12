# Feedback — 通知・トースト・Haptics パターン

## 通知（トースト相当）

EventBus の `notification_requested` シグナルを使って HUD に通知を表示する。

```gdscript
# どこからでも通知を発行
EventBus.notification_requested.emit("アイテムを入手！", "success")
EventBus.notification_requested.emit("保存に失敗しました", "error")
EventBus.notification_requested.emit("ヒント: ジャンプでコインが取れます", "info")
```

```gdscript
# scenes/ui/notification_manager.gd（HUD内に配置）
extends Control

const NOTIFICATION_SCENE: PackedScene = preload("res://scenes/ui/notification_toast.tscn")
const DISPLAY_DURATION: float = 2.5

func _ready() -> void:
    EventBus.notification_requested.connect(_show_notification)

func _show_notification(message: String, type: String) -> void:
    var toast: Control = NOTIFICATION_SCENE.instantiate()
    add_child(toast)
    toast.setup(message, type)
    await get_tree().create_timer(DISPLAY_DURATION).timeout
    var tween: Tween = create_tween()
    tween.tween_property(toast, "modulate:a", 0.0, 0.3)
    await tween.finished
    toast.queue_free()
```

---

## ダイアログ（確認・警告）

`docs/ui/popups.md` を参照。

---

## Haptics（振動フィードバック）

モバイルプラットフォーム向け。

```gdscript
# ✅ プラットフォーム確認後に使用
func trigger_haptic(intensity: float = 0.5, duration: float = 0.1) -> void:
    var os_name: String = OS.get_name()
    if os_name == "Android" or os_name == "iOS":
        Input.vibrate_handheld(int(duration * 1000))

# 使用例
func _on_player_took_damage() -> void:
    trigger_haptic(1.0, 0.2)
    EventBus.sfx_play_requested.emit("damage")
```

---

## サウンドフィードバック

```gdscript
# ✅ EventBus 経由で AudioManager に委譲
func _on_button_pressed() -> void:
    EventBus.sfx_play_requested.emit("click")

func _on_item_collected() -> void:
    EventBus.sfx_play_requested.emit("collect")
    EventBus.sfx_play_requested.emit("score_up")
```
