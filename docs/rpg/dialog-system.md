# Dialog System — NPC 会話・テキスト表示

**対象:** Godot 4.4+ / 2D JRPG ダイアログシステム

---

## Claude Code 実装停止チェックリスト

```
□ 会話テキストをシーンスクリプトにハードコードしようとしている
□ ダイアログ中の入力受け付け制御を GameManager.state で管理していない
□ ダイアログボックスの表示制御をシーンから直接行おうとしている（EventBus 経由にする）
□ 選択肢の結果処理をシーンスクリプトに書こうとしている（FlagManager に委譲する）
```

---

## 1. ダイアログシーン階層

```
DialogLayer（CanvasLayer, layer=10）  ← 全シーンに共通。Autoload の子として add_child
└── DialogBox（Control）
    ├── BackgroundNinePatch（NinePatchRect）
    ├── PortraitFrame（TextureRect）    ← キャラクター顔グラ（任意）
    ├── NameLabel（Label）
    ├── MessageLabel（RichTextLabel）   ← テキストスクロール表示
    ├── ContinueCursor（AnimatedSprite2D）  ← ▼ アイコン
    └── ChoiceContainer（VBoxContainer）   ← 選択肢表示（非表示で待機）
        ├── Choice_0（Button）
        ├── Choice_1（Button）
        └── Choice_2（Button）
```

---

## 2. ダイアログデータ形式（JSON）

```json
{
  "id": "village_elder_001",
  "speaker": "村長",
  "portrait": "res://assets/sprites/portraits/elder.png",
  "pages": [
    {
      "text": "おお、勇者よ。よく来てくれた。\n魔王が復活し、世界が危機に瀕しておる。",
      "choices": null
    },
    {
      "text": "お前に頼みがある。引き受けてくれるか？",
      "choices": [
        {"label": "はい", "next_id": "village_elder_002_yes", "flag": "quest_accepted"},
        {"label": "いいえ", "next_id": "village_elder_002_no", "flag": null}
      ]
    }
  ]
}
```

**保存先:** `resources/dialogs/{npc_id}/{dialog_id}.json`

---

## 3. DialogManager 設計

```gdscript
# autoloads/dialog_manager.gd
extends Node

var _dialog_layer: CanvasLayer = null
var _current_dialog: Dictionary = {}
var _current_page: int = 0

func _ready() -> void:
    EventBus.dialog_requested.connect(_on_dialog_requested)
    # ダイアログUIシーンをロードして自身の子に追加
    var dialog_scene: PackedScene = preload("res://scenes/ui/dialog_box.tscn")
    _dialog_layer = dialog_scene.instantiate()
    add_child(_dialog_layer)
    _dialog_layer.visible = false

func _exit_tree() -> void:
    EventBus.dialog_requested.disconnect(_on_dialog_requested)

func _on_dialog_requested(dialog_id: String) -> void:
    var path: String = _resolve_dialog_path(dialog_id)
    if not FileAccess.file_exists(path):
        Logger.error("Dialog not found", {"id": dialog_id})
        return
    var text: String = FileAccess.get_file_as_string(path)
    var data: Variant = JSON.parse_string(text)
    if not data is Dictionary:
        Logger.error("Invalid dialog JSON", {"id": dialog_id})
        return
    _start_dialog(data)

func _start_dialog(dialog: Dictionary) -> void:
    _current_dialog = dialog
    _current_page = 0
    GameManager.change_state(GameManager.GameState.DIALOG)
    _dialog_layer.visible = true
    _show_page(0)

func advance() -> void:
    var pages: Array = _current_dialog.get("pages", [])
    if _current_page >= pages.size() - 1:
        _end_dialog()
        return
    var page: Dictionary = pages[_current_page]
    if page.get("choices") != null:
        return  # 選択肢待ち中は advance しない
    _current_page += 1
    _show_page(_current_page)

func select_choice(index: int) -> void:
    var pages: Array = _current_dialog.get("pages", [])
    var page: Dictionary = pages[_current_page]
    var choices: Array = page.get("choices", [])
    if index >= choices.size():
        return
    var choice: Dictionary = choices[index]
    var flag: Variant = choice.get("flag")
    if flag is String and not flag.is_empty():
        FlagManager.set_flag(flag)
    var next_id: Variant = choice.get("next_id")
    if next_id is String and not next_id.is_empty():
        _on_dialog_requested(next_id)
    else:
        _end_dialog()

func _end_dialog() -> void:
    _dialog_layer.visible = false
    GameManager.change_state(GameManager.GameState.FIELD)
    EventBus.dialog_ended.emit(_current_dialog.get("id", ""))
    _current_dialog = {}
    _current_page = 0

func _show_page(page_index: int) -> void:
    var pages: Array = _current_dialog.get("pages", [])
    if page_index >= pages.size():
        return
    var page: Dictionary = pages[page_index]
    EventBus.dialog_page_shown.emit(
        _current_dialog.get("speaker", ""),
        _current_dialog.get("portrait", ""),
        page.get("text", ""),
        page.get("choices")
    )

func _resolve_dialog_path(dialog_id: String) -> String:
    # "village_elder_001" → "res://resources/dialogs/village_elder/village_elder_001.json"
    var parts: PackedStringArray = dialog_id.rsplit("_", false, 1)
    if parts.size() < 2:
        return "res://resources/dialogs/%s.json" % dialog_id
    return "res://resources/dialogs/%s/%s.json" % [parts[0], dialog_id]
```

---

## 4. DialogBox シーンスクリプト

```gdscript
# scenes/ui/dialog_box.gd
extends CanvasLayer

@onready var message_label: RichTextLabel = $DialogBox/MessageLabel
@onready var name_label: Label = $DialogBox/NameLabel
@onready var portrait: TextureRect = $DialogBox/PortraitFrame
@onready var cursor: AnimatedSprite2D = $DialogBox/ContinueCursor
@onready var choice_container: VBoxContainer = $DialogBox/ChoiceContainer

func _ready() -> void:
    EventBus.dialog_page_shown.connect(_on_page_shown)
    process_mode = Node.PROCESS_MODE_ALWAYS

func _exit_tree() -> void:
    EventBus.dialog_page_shown.disconnect(_on_page_shown)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_just_pressed("confirm"):
        if _is_scrolling:
            _skip_scroll()
        elif choice_container.visible:
            pass  # 選択肢はボタンの pressed シグナルで処理
        else:
            DialogManager.advance()

func _on_page_shown(
    speaker: String,
    portrait_path: String,
    text: String,
    choices: Variant
) -> void:
    name_label.text = speaker
    if portrait_path.is_empty():
        portrait.visible = false
    else:
        portrait.visible = true
        portrait.texture = load(portrait_path)
    _start_scroll(text)
    _show_choices(choices)

func _start_scroll(text: String) -> void:
    _is_scrolling = true
    cursor.visible = false
    message_label.visible_ratio = 0.0
    message_label.text = text
    var tween: Tween = create_tween()
    var duration: float = float(text.length()) * 0.03
    tween.tween_property(message_label, "visible_ratio", 1.0, duration)
    tween.tween_callback(func() -> void:
        _is_scrolling = false
        if not choice_container.visible:
            cursor.visible = true
    )

func _skip_scroll() -> void:
    message_label.visible_ratio = 1.0
    _is_scrolling = false
    if not choice_container.visible:
        cursor.visible = true

func _show_choices(choices: Variant) -> void:
    for child: Node in choice_container.get_children():
        child.queue_free()
    if not choices is Array or choices.is_empty():
        choice_container.visible = false
        return
    cursor.visible = false
    choice_container.visible = true
    for i: int in range(choices.size()):
        var btn: Button = Button.new()
        btn.text = choices[i].get("label", "")
        var idx: int = i
        btn.pressed.connect(func() -> void: DialogManager.select_choice(idx))
        choice_container.add_child(btn)
    # 最初の選択肢にフォーカスを当てる
    await get_tree().process_frame
    if choice_container.get_child_count() > 0:
        choice_container.get_child(0).grab_focus()

var _is_scrolling: bool = false
```

---

## 5. EventBus シグナル設計（ダイアログ系）

```gdscript
signal dialog_requested(dialog_id: String)
signal dialog_page_shown(
    speaker: String,
    portrait_path: String,
    text: String,
    choices: Variant   # Array[Dictionary] or null
)
signal dialog_ended(dialog_id: String)
```

---

## 6. ダイアログファイルのディレクトリ構成

```
resources/
└── dialogs/
    ├── system/
    │   ├── battle_intro.json     ← 戦闘開始演出テキスト
    │   └── game_over.json        ← ゲームオーバーメッセージ
    ├── village_elder/
    │   ├── village_elder_001.json
    │   └── village_elder_002_yes.json
    └── shop_keeper/
        └── shop_keeper_001.json
```
