# Scene Patterns — シーン設計パターン

## Composite パターン（複合シーン）

複数のサブシーンを組み合わせて1つの画面を構成する。

```
main_menu.tscn
├── Background (TextureRect)
├── MenuContent (VBoxContainer)
│   ├── TitleLabel (Label)
│   ├── StartButton (Button)  ← button_start.tscn でも可
│   ├── SettingsButton (Button)
│   └── QuitButton (Button)
└── VersionLabel (Label)
```

```gdscript
# scenes/ui/main_menu.gd
extends Control

@onready var start_button: Button = $MenuContent/StartButton
@onready var settings_button: Button = $MenuContent/SettingsButton

func _ready() -> void:
    start_button.pressed.connect(_on_start_pressed)
    settings_button.pressed.connect(_on_settings_pressed)

func _on_start_pressed() -> void:
    EventBus.sfx_play_requested.emit("click")
    SceneManager.go_to("res://scenes/game/game_world.tscn")

func _on_settings_pressed() -> void:
    EventBus.sfx_play_requested.emit("click")
    EventBus.scene_change_requested.emit("res://scenes/ui/settings.tscn", "fade")
```

---

## HUD パターン（Canvas Layer）

HUD は CanvasLayer でゲームワールドの上に重ねる。

```
game_world.tscn
├── World (Node2D)
│   └── ... ゲームオブジェクト
└── HUD (CanvasLayer)        ← layer=1 でゲームワールドの上
    └── hud.tscn インスタンス
```

```gdscript
# scenes/ui/hud.gd
extends Control

@onready var score_label: Label = $ScoreLabel
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
    EventBus.score_changed.connect(_on_score_changed)
    EventBus.health_changed.connect(_on_health_changed)

func _on_score_changed(new_score: int) -> void:
    score_label.text = str(new_score)

func _on_health_changed(hp: int, max_hp: int) -> void:
    health_bar.value = float(hp) / float(max_hp) * 100.0
```

---

## リストアイテムパターン（Spawner + Item）

```gdscript
# scenes/ui/item_list.gd
extends VBoxContainer

const ITEM_SCENE: PackedScene = preload("res://scenes/ui/list_item.tscn")

var _items: Array[ItemData] = []

func set_items(items: Array[ItemData]) -> void:
    _clear_items()
    _items = items
    for item: ItemData in items:
        var node: Control = ITEM_SCENE.instantiate()
        add_child(node)
        node.setup(item)
        node.selected.connect(_on_item_selected.bind(item))

func _clear_items() -> void:
    for child: Node in get_children():
        child.queue_free()
    _items.clear()

func _on_item_selected(item: ItemData) -> void:
    EventBus.item_selected.emit(item)
```

```gdscript
# scenes/ui/list_item.gd
extends Control

signal selected(item: ItemData)

var _item: ItemData = null
@onready var name_label: Label = $NameLabel
@onready var icon: TextureRect = $Icon

func setup(item: ItemData) -> void:
    _item = item
    name_label.text = item.display_name
    icon.texture = item.icon

func _on_button_pressed() -> void:
    selected.emit(_item)
```

---

## ローディング状態パターン

```gdscript
# ✅ 3状態（Loading / Error / Empty / Content）を実装する
extends Control

enum ViewState { LOADING, ERROR, EMPTY, CONTENT }

@onready var loading_view: Control = $LoadingView
@onready var error_view: Control = $ErrorView
@onready var empty_view: Control = $EmptyView
@onready var content_view: Control = $ContentView

func _set_state(state: ViewState) -> void:
    loading_view.visible = state == ViewState.LOADING
    error_view.visible = state == ViewState.ERROR
    empty_view.visible = state == ViewState.EMPTY
    content_view.visible = state == ViewState.CONTENT

func _ready() -> void:
    _set_state(ViewState.LOADING)
    EventBus.data_loaded.connect(_on_data_loaded)

func _on_data_loaded(items: Array) -> void:
    if items.is_empty():
        _set_state(ViewState.EMPTY)
    else:
        _populate(items)
        _set_state(ViewState.CONTENT)
```
