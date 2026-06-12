# Async UI — Loading / Error / Empty 状態パターン

## 3状態の実装ルール

非同期処理（セーブロード・リソース読み込み等）を含むUIには必ず3状態を実装する。

```
□ Loading: 処理中の表示（ProgressBar / AnimationPlayer ループ）
□ Error: エラーメッセージ + リトライボタン
□ Empty: データが0件の場合の案内
```

---

## ローディング画面パターン

```gdscript
# scenes/ui/loading_screen.gd
extends CanvasLayer

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
    EventBus.loading_started.connect(_on_loading_started)
    EventBus.loading_finished.connect(_on_loading_finished)

func _on_loading_started(label: String) -> void:
    visible = true
    status_label.text = label
    progress_bar.value = 0

func _on_loading_finished() -> void:
    visible = false
```

---

## リソース非同期ロード

```gdscript
# ✅ ResourceLoader の非同期ロードを使う（大きなアセット）
func load_level_async(path: String) -> void:
    EventBus.loading_started.emit("レベルを読み込み中...")
    ResourceLoader.load_threaded_request(path)
    _loading_path = path

func _process(_delta: float) -> void:
    if _loading_path.is_empty():
        return
    var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_loading_path)
    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            pass  # 継続中
        ResourceLoader.THREAD_LOAD_LOADED:
            var resource: Resource = ResourceLoader.load_threaded_get(_loading_path)
            _loading_path = ""
            EventBus.loading_finished.emit()
            _on_level_loaded(resource)
        ResourceLoader.THREAD_LOAD_FAILED:
            _loading_path = ""
            EventBus.loading_finished.emit()
            EventBus.notification_requested.emit("読み込みに失敗しました", "error")
```

---

## await によるシーン内非同期処理

```gdscript
# ✅ シグナルを await して非同期処理を直列化
func _show_result_with_delay() -> void:
    _set_state(ViewState.LOADING)
    await get_tree().create_timer(1.5).timeout  # 演出待機
    _set_state(ViewState.CONTENT)

# ✅ Tween の完了を待つ
func _fade_in() -> void:
    modulate.a = 0.0
    var tween: Tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)
    await tween.finished
    # フェードイン完了後の処理
```
