# Popups — ダイアログ・ポップアップ設計

## Godot の Popup ノード

| ノード型 | 用途 |
|---------|------|
| `AcceptDialog` | 情報・警告（OKボタンのみ） |
| `ConfirmationDialog` | 確認（OK + キャンセル） |
| `Popup` | カスタムポップアップのベース |
| `PopupPanel` | パネル付きカスタムポップアップ |

---

## 確認ダイアログパターン

```gdscript
# ✅ ConfirmationDialog を直接生成
func _show_quit_confirm() -> void:
    var dialog: ConfirmationDialog = ConfirmationDialog.new()
    dialog.title = "終了確認"
    dialog.dialog_text = "ゲームを終了しますか？\n進行状況は保存されます。"
    dialog.ok_button_text = "終了する"
    dialog.cancel_button_text = "キャンセル"
    add_child(dialog)
    dialog.confirmed.connect(_on_quit_confirmed)
    dialog.canceled.connect(dialog.queue_free)
    dialog.popup_centered()

func _on_quit_confirmed() -> void:
    SaveManager.save_game()
    get_tree().quit()
```

---

## カスタムポップアップパターン

```gdscript
# scenes/ui/custom_popup.gd
extends PopupPanel

signal confirmed(data: Dictionary)
signal cancelled()

@onready var confirm_button: Button = $Content/ConfirmButton
@onready var cancel_button: Button = $Content/CancelButton

func _ready() -> void:
    confirm_button.pressed.connect(_on_confirmed)
    cancel_button.pressed.connect(_on_cancelled)
    close_requested.connect(_on_cancelled)  # Escキー・外クリック

func _on_confirmed() -> void:
    confirmed.emit({"result": "ok"})
    hide()

func _on_cancelled() -> void:
    cancelled.emit()
    hide()
```

```gdscript
# 呼び出し側
func _show_item_detail(item: ItemData) -> void:
    var popup: CustomPopup = preload("res://scenes/ui/custom_popup.tscn").instantiate()
    add_child(popup)
    popup.setup(item)
    popup.confirmed.connect(_on_item_action_confirmed)
    popup.cancelled.connect(popup.queue_free)
    popup.popup_centered()
```

---

## ポップアップを使う場合の禁止事項

```
□ ポップアップ内でゲームロジックを直接実行しない → シグナルで通知
□ ポップアップが Autoload を直接呼ばない → シグナル経由
□ AcceptDialog を確認用途に使わない → ConfirmationDialog を使う
□ ポップアップを queue_free() せずに放置しない → hide() または queue_free() を使う
```

---

## 通知とポップアップの選択基準

| 状況 | 使うもの |
|------|---------|
| 操作完了の通知（保存完了等） | EventBus.notification_requested（トースト） |
| ユーザーへの警告（リトライ不要） | AcceptDialog |
| ユーザーの確認が必要 | ConfirmationDialog |
| 複雑な入力が必要 | カスタム PopupPanel シーン |
